part of '../graph.dart';

/// Assists code generation by doing compile-time analysis of an `@Injector`.
///
/// To use, create an [InjectorGraphResolver] for a `@Injector`-annotated class:
///     var resolver = new InjectorGraphResolver(summaryReader, injectorSummary);
///     var graph = await resolver.resolve();
class InjectorGraphResolver {
  static const String _librarySummaryExtension = '.inject.summary';

  final InjectorSummary _injectorSummary;
  final List<SymbolPath> _modules = <SymbolPath>[];
  final List<ProviderSummary> _providers = <ProviderSummary>[];
  final SummaryReader _reader;

  /// To prevent rereading the same summaries, we cache them here.
  final Map<SymbolPath, LibrarySummary> _summaryCache =
      <SymbolPath, LibrarySummary>{};

  /// Create a new resolver that uses a [SummaryReader].
  InjectorGraphResolver(this._reader, this._injectorSummary) {
    _injectorSummary.modules.forEach(_modules.add);
    _injectorSummary.providers.forEach(_providers.add);
  }

  Future<LibrarySummary> _readFromPath(SymbolPath p,
      {@required SymbolPath requestedBy}) async {
    var _cachedSummary = _summaryCache[p];
    if (_cachedSummary != null) return _cachedSummary;

    var package = p.package;
    var filePath = path.withoutExtension(p.path) + _librarySummaryExtension;
    try {
      return _summaryCache[p] = await _reader.read(package, filePath);
    } on FileSystemException catch (_) {
      builderContext.rawLogger.severe(
          '''Unable to locate metadata about ${p.symbol} defined in ${p.toAbsoluteUri().removeFragment()}.

This dependency is requested by ${requestedBy.symbol} defined in ${requestedBy.toAbsoluteUri().removeFragment()}.

A common reason for this error is the Dart file where this symbol is defined is
not listed in the "generate_for" attribute of the "dart_library" build target.
''');
      // Default to blank summary.
      return new LibrarySummary(p.toAbsoluteUri());
    }
  }

  /// Return a resolved graph that can be used to generate a `$Injector` class.
  Future<InjectorGraph> resolve() async {
    // For every module, load the corresponding library summary that should have
    // already been built in the dependency tree. We then lookup the specific
    // module summary from the library summary.
    var modulesToLoad = _modules.map<Future<ModuleSummary>>((module) async {
      var moduleSummaries =
          (await _readFromPath(module, requestedBy: _injectorSummary.clazz))
              .modules;
      return moduleSummaries.firstWhere((s) => s.clazz == module, orElse: () {
        // We're lenient to programming errors. It is possible that an injector
        // refers to a module for which we failed to produce a summary. So we
        // emit a warning but keep on trucking.
        builderContext.rawLogger.warning(
            'Failed to locate summary for module ${module.toAbsoluteUri()} ',
            'specified in injector ${_injectorSummary.clazz.symbol}.');
        return null;
      });
    });
    List<ModuleSummary> allModules =
        (await Future.wait<ModuleSummary>(modulesToLoad))
            .where((ModuleSummary s) => s != null)
            .toList();

    var providersByModules = <LookupKey, DependencyProvidedByModule>{};

    // We compute the providers by modules in two passes. The first pass finds
    // all keys that are explicitly provided.
    for (ModuleSummary module in allModules) {
      for (ProviderSummary provider in module.providers) {
        final lookupKey = _extractLookupKey(provider.injectedType);
        providersByModules[lookupKey] = new DependencyProvidedByModule._(
          lookupKey,
          provider.isSingleton,
          provider.isAsynchronous,
          provider.dependencies,
          module.clazz,
          provider.name,
        );
      }
    }

    var injectables = <LookupKey, InjectableSummary>{};

    Future<Null> addInjectableIfExists(LookupKey key,
        {@required SymbolPath requestedBy}) async {
      // Modules take precedence.
      bool isProvidedByAModule = providersByModules.containsKey(key);
      bool isSeen = injectables.containsKey(key);
      if (isProvidedByAModule || isSeen) {
        return null;
      }
      if (!key.root.isGlobal) {
        LibrarySummary lib =
            await _readFromPath(key.root, requestedBy: requestedBy);
        for (InjectableSummary injectable in lib.injectables) {
          if (injectable.clazz == key.root) {
            injectables[key] = injectable;
            for (InjectedType dependency
                in injectable.constructor.dependencies) {
              await addInjectableIfExists(dependency.lookupKey,
                  requestedBy: injectable.clazz);
            }
          }
        }
      }
    }

    // The second pass looks at all the dependencies for the providers, and if
    // that dependency isn't already met by a module, it satisfies the
    // dependency by using the type's injectable constructor.
    for (ModuleSummary module in allModules) {
      for (ProviderSummary provider in module.providers) {
        for (InjectedType dependency in provider.dependencies) {
          await addInjectableIfExists(dependency.lookupKey,
              requestedBy: module.clazz);
        }
      }
    }

    for (ProviderSummary injectorProvider in _injectorSummary.providers) {
      await addInjectableIfExists(injectorProvider.injectedType.lookupKey,
          requestedBy: _injectorSummary.clazz);
    }

    var providersByInjectables = <LookupKey, DependencyProvidedByInjectable>{};
    injectables.forEach((LookupKey symbol, InjectableSummary summary) {
      providersByInjectables[symbol] =
          new DependencyProvidedByInjectable._(summary);
    });

    // Combined dependencies provided by injectables with those provided by
    // modules, giving modules a higher precedence.
    var mergedDependencies = <LookupKey, ResolvedDependency>{}
      ..addAll(providersByInjectables)
      ..addAll(providersByModules);

    // Providers defined on the injector class.
    var injectorProviders = <InjectorProvider>[];
    for (ProviderSummary p in _providers) {
      injectorProviders.add(new InjectorProvider._(
        p.injectedType,
        p.name,
        p.kind == ProviderKind.getter,
      ));
    }

    _detectAndWarnAboutCycles(mergedDependencies);

    return new InjectorGraph._(
      new List<SymbolPath>.unmodifiable(allModules.map((m) => m.clazz)),
      new List<InjectorProvider>.unmodifiable(injectorProviders),
      new Map<SymbolPath, ResolvedDependency>.unmodifiable(mergedDependencies),
    );
  }

  void _detectAndWarnAboutCycles(
      Map<LookupKey, ResolvedDependency> mergedDependencies) {
    // Symbols we already inspected as potential roots of a cycle.
    var checkedRoots = new Set<LookupKey>();

    // Keeps track of cycles we already printed so we do not print them again.
    // This can happen when we find the same cycle starting from a different
    // node. Example, the following three are all the same cycle:
    //
    // a -> b -> c -> a
    // b -> c -> a -> b
    // c -> a -> b -> c
    var cycles = new Set<Cycle>();

    for (LookupKey dependency in mergedDependencies.keys) {
      if (checkedRoots.contains(dependency)) {
        // This symbol was already checked.
        continue;
      }
      checkedRoots.add(dependency);

      var chain = <LookupKey>[];
      void checkForCycles(LookupKey parent) {
        bool hasCycle = chain.contains(parent);
        chain.add(parent);
        if (hasCycle) {
          var cycle = chain.sublist(chain.indexOf(parent));
          if (cycles.add(new Cycle(cycle))) {
            String formattedCycle = cycle
                .map((s) => '  (${s.toPrettyString()} from ${s.root.path})')
                .join('\n');
            builderContext.rawLogger
                .severe('Detected dependency cycle:\n${formattedCycle}');
          }
        } else {
          Iterable<LookupKey> children = mergedDependencies[parent]
                  ?.dependencies
                  ?.map((injectedType) => injectedType.lookupKey) ??
              const [];
          for (var child in children) {
            checkForCycles(child);
          }
        }
        chain.removeLast();
      }

      checkForCycles(dependency);
    }
  }

  static LookupKey _extractLookupKey(InjectedType injectedType) {
    if (injectedType != new InjectedType(injectedType.lookupKey)) {
      throw new ArgumentError(
          'Extracting the LookupKey from an InjectedType that '
          'has additional metadata. This is a dart:inject bug. '
          'Please file a bug.');
    }
    return injectedType.lookupKey;
  }
}

/// An edge in a dependency graph.
@visibleForTesting
class DependencyEdge {
  /// The dependent node in the dependency graph.
  final LookupKey from;

  /// The dependee node in the dependency graph.
  final LookupKey to;

  DependencyEdge({@required this.from, @required this.to});

  @override
  int get hashCode => hash2(from, to);

  @override
  bool operator ==(Object o) =>
      o is DependencyEdge && o.from == this.from && o.to == this.to;
}

/// Represents a cycle inside a dependency graph.
///
/// Cycles containing identical sets of nodes and edges are considered equal.
/// For example the following cycles are equal:
///
/// A -> B -> C -> A
/// B -> C -> A -> B
/// C -> A -> B -> C
@visibleForTesting
class Cycle {
  static const _setEquality = const SetEquality<dynamic>();

  final Set<LookupKey> _nodes;
  final Set<DependencyEdge> _edges;

  Cycle(List<LookupKey> chain)
      : this._nodes = chain.toSet(),
        this._edges = _computeEdgeSet(chain) {
    assert(chain.length > 1);
    assert(chain.first == chain.last);
    assert(_nodes.length == chain.length - 1);
    assert(_edges.length == chain.length - 1);
  }

  static Set<DependencyEdge> _computeEdgeSet(List<LookupKey> chain) {
    var result = new Set<DependencyEdge>();
    for (int i = 0; i < chain.length - 1; i++) {
      result.add(new DependencyEdge(from: chain[i], to: chain[i + 1]));
    }
    return result;
  }

  /// Hashes only nodes, but not edges, because it should be good enough, and
  /// because hash code must be order-independent.
  // IMPORTANT: we intentionally do not use Quiver's hashObjects because it is
  // order-dependent.
  @override
  int get hashCode =>
      _nodes.fold(0, (int hash, LookupKey s) => hash + s.hashCode);

  @override
  bool operator ==(Object o) {
    if (o is Cycle) {
      return _setEquality.equals(this._nodes, o._nodes) &&
          _setEquality.equals(this._edges, o._edges);
    }
    return false;
  }
}
