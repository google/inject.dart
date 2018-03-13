part of '../graph.dart';

/// A provider defined on an `@Injector` class.
class InjectorProvider {
  /// The type this provides.
  final InjectedType injectedType;

  /// The name of the method or getter to `@override`.
  final String methodName;

  /// Whether this provider is a getter.
  final bool isGetter;

  InjectorProvider._(this.injectedType, this.methodName, this.isGetter);
}

/// A dependency resolved to a concrete provider.
abstract class ResolvedDependency {
  /// The key of the dependency.
  final LookupKey lookupKey;

  /// Whether or not this dependency is a singleton.
  final bool isSingleton;

  /// Whether this provider is annotated with `@asynchronous`.
  final bool isAsynchronous;

  /// Transitive dependencies.
  final List<InjectedType> dependencies;

  /// Constructor.
  const ResolvedDependency(
      this.lookupKey, this.isSingleton, this.isAsynchronous, this.dependencies);
}

/// A dependency provided by a module class.
class DependencyProvidedByModule extends ResolvedDependency {
  /// Module that provides the dependency.
  final SymbolPath moduleClass;

  /// Name of the method in the class.
  final String methodName;

  DependencyProvidedByModule._(
      LookupKey lookupKey,
      bool singleton,
      bool asynchronous,
      List<InjectedType> dependencies,
      this.moduleClass,
      this.methodName)
      : super(
          lookupKey,
          singleton,
          asynchronous,
          dependencies,
        );
}

/// A dependency provided by an injectable class.
class DependencyProvidedByInjectable extends ResolvedDependency {
  /// Summary about the injectable class.
  final InjectableSummary summary;

  DependencyProvidedByInjectable._(
    InjectableSummary summary,
  )   : this.summary = summary,
        super(
          new LookupKey(summary.clazz),
          summary.constructor.isSingleton,
          false,
          summary.constructor.dependencies,
        );
}

/// A dependency that failed to resolve to a provider.
class UnprovidedDependency extends ResolvedDependency {
  /// Constructor.
  UnprovidedDependency(SymbolPath key)
      : super(
          new LookupKey(key),
          false,
          false,
          const [],
        );
}

/// All of the data that is needed to generate an `@Injector` class.
class InjectorGraph {
  /// Modules used by the injector.
  final List<SymbolPath> includeModules;

  /// Providers that should be generated.
  final List<InjectorProvider> providers;

  /// Dependencies resolved to concrete providers mapped from key.
  final Map<SymbolPath, ResolvedDependency> mergedDependencies;

  InjectorGraph._(this.includeModules, this.providers, this.mergedDependencies);
}
