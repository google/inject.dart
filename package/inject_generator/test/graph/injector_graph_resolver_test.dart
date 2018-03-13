import 'dart:async';
import 'dart:io';

import 'package:build/src/builder/build_step.dart';
import 'package:inject_generator/src/context.dart';
import 'package:inject_generator/src/graph.dart';
import 'package:inject_generator/src/source/injected_type.dart';
import 'package:inject_generator/src/source/lookup_key.dart';
import 'package:inject_generator/src/source/symbol_path.dart';
import 'package:inject_generator/src/summary.dart';
import 'package:logging/logging.dart';
import 'package:quiver/testing/equality.dart';
import 'package:test/test.dart';

void main() {
  group('$InjectorGraphResolver', () {
    FakeSummaryReader reader;

    setUp(() {
      reader = new FakeSummaryReader({
        'foo/foo.inject.summary': new LibrarySummary(
          Uri.parse('asset:foo/foo.dart'),
          modules: [
            new ModuleSummary(
                SymbolPath.parseAbsoluteUri('asset:foo/foo.dart#FooModule'), [
              new ProviderSummary(
                new InjectedType(new LookupKey(
                    SymbolPath.parseAbsoluteUri('asset:foo/foo.dart', 'Foo'))),
                'provideFoo',
                ProviderKind.method,
              ),
            ]),
          ],
        )
      });
    });

    test('should correctly resolve an object graph', () async {
      final foo = new InjectedType(
          new LookupKey(SymbolPath.parseAbsoluteUri('asset:foo/foo.dart#Foo')));
      final injectorSummary = new InjectorSummary(
        new SymbolPath('foo', 'foo.dart', 'FooInjector'),
        [SymbolPath.parseAbsoluteUri('asset:foo/foo.dart#FooModule')],
        [
          new ProviderSummary(
            foo,
            'getFoo',
            ProviderKind.method,
          )
        ],
      );
      final resolver = new InjectorGraphResolver(reader, injectorSummary);
      final resolvedGraph = await resolver.resolve();

      expect(resolvedGraph.includeModules, hasLength(1));
      final fooModule = resolvedGraph.includeModules.first;
      expect(
          fooModule.toAbsoluteUri().toString(), 'asset:foo/foo.dart#FooModule');

      expect(resolvedGraph.providers, hasLength(1));
      final fooProvider = resolvedGraph.providers.first;
      expect(fooProvider.injectedType, foo);
      expect(fooProvider.methodName, 'getFoo');
    });

    test('should correctly resolve a qualifier in an object graph', () async {
      final qualifiedFoo = new InjectedType(new LookupKey(
          SymbolPath.parseAbsoluteUri('asset:foo/foo.dart', 'Foo'),
          qualifier: const SymbolPath.global('uniqueName')));
      var injectorSummary = new InjectorSummary(
        new SymbolPath('foo', 'foo.dart', 'FooInjector'),
        [
          SymbolPath.parseAbsoluteUri('asset:foo/foo.dart#FooModule'),
        ],
        [
          new ProviderSummary(
            qualifiedFoo,
            'provideName',
            ProviderKind.method,
          ),
        ],
      );
      var resolver = new InjectorGraphResolver(reader, injectorSummary);
      var resolvedGraph = await resolver.resolve();

      expect(resolvedGraph.includeModules, hasLength(1));
      var fooModule = resolvedGraph.includeModules.first;
      expect(
        fooModule.toAbsoluteUri().toString(),
        'asset:foo/foo.dart#FooModule',
      );
      expect(resolvedGraph.providers, hasLength(1));

      var nameProvider = resolvedGraph.providers.first;
      expect(
        nameProvider.injectedType,
        qualifiedFoo,
      );
      expect(nameProvider.methodName, 'provideName');
    });

    test('should log a useful message when a summary is missing', () async {
      var ctx = new _FakeBuilderContext();
      await runZoned(
        () async {
          var injectorSummary = new InjectorSummary(
            new SymbolPath('foo', 'foo.dart', 'FooInjector'),
            [],
            [
              new ProviderSummary(
                new InjectedType(new LookupKey(
                    SymbolPath.parseAbsoluteUri('asset:foo/missing.dart#Foo'))),
                'getFoo',
                ProviderKind.method,
              )
            ],
          );
          var resolver = new InjectorGraphResolver(reader, injectorSummary);
          await resolver.resolve();
        },
        zoneValues: {#builderContext: ctx},
      );
      expect(
          ctx.records.any((r) =>
              r.level == Level.SEVERE &&
              r.message.contains(
                  'Unable to locate metadata about Foo defined in asset:foo/missing.dart') &&
              r.message.contains(
                  'This dependency is requested by FooInjector defined in asset:foo/foo.dart.')),
          isTrue);
    });
  }, skip: 'Currently not working with the extenral build system');

  group('$Cycle', () {
    test('has order-independent hashCode and operator==', () {
      var sA = new LookupKey(new SymbolPath('package', 'path.dart', 'A'));
      var sB = new LookupKey(new SymbolPath('package', 'path.dart', 'B'));
      var sC = new LookupKey(new SymbolPath('package', 'path.dart', 'C'));
      var sD = new LookupKey(new SymbolPath('package', 'path.dart', 'D'));

      var cycle1 = new Cycle([sA, sB, sC, sA]);
      var cycle2 = new Cycle([sB, sC, sA, sB]);
      var cycle3 = new Cycle([sC, sA, sB, sC]);

      var diffNodes1 = new Cycle([sA, sB, sA]);
      var diffNodes2 = new Cycle([sA, sB, sC, sD, sA]);

      var diffEdges = new Cycle([sA, sC, sB, sA]);

      expect({
        'base': [cycle1, cycle2, cycle3],
        'different node': [diffNodes1],
        'another different node': [diffNodes2],
        'different edges': [diffEdges],
      }, areEqualityGroups);
    });
  });
}

class _FakeBuilderContext implements BuilderContext {
  final List<LogRecord> records = <LogRecord>[];

  @override
  final Logger rawLogger = new Logger("_FakeBuilderContextLogger");

  _FakeBuilderContext() {
    rawLogger.onRecord.listen(records.add);
    rawLogger.onRecord.listen(print);
  }

  @override
  BuildStep get buildStep => null;

  @override
  BuilderLogger get log => null;
}

/// An in-memory implementation of [SummaryReader].
///
/// When [read] is called, it returns the mock summary.
class FakeSummaryReader implements SummaryReader {
  final Map<String, LibrarySummary> _summaries;

  /// Create a fake summary reader with previously created summaries.
  ///
  /// __Example use:__
  ///     return new FakeSummary({
  ///       'foo/foo.dart': new LibrarySummary(...)
  ///     });
  FakeSummaryReader(this._summaries);

  @override
  Future<LibrarySummary> read(String package, String path) {
    var fullPath = '$package/$path';
    var summary = _summaries[fullPath];
    if (summary == null) {
      throw new FileSystemException('File not found', fullPath);
    }
    return new Future<LibrarySummary>.value(summary);
  }
}
