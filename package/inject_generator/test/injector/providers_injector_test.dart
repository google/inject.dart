import 'package:inject/inject.dart';
import 'package:test/test.dart';

// ignore: uri_does_not_exist
import 'providers_injector_test.inject.dart' as $generated;

/// Qualifier for a manually written [CounterFactory] for the purpose of testing
/// getting a [Provider] in a module provide method.
const manual = const Qualifier(#manual);

/// A custom typedef for providing a type.
typedef T Provider<T>();

/// Injector whose purpose is to test binding providers.
@Injector(const [CounterModule])
abstract class ProvidersInjector {
  static final create = $generated.ProvidersInjector$Injector.create;

  /// Returns a [CounterFactory].
  ///
  /// Tests injecting a [Provider] in a class.
  @provide
  CounterFactory get counterFactory;

  /// Returns a [Provider] of [Counter].
  ///
  /// Tests getting a [Provider] from an injector.
  @provide
  Provider<Counter> get counter;

  /// Returns a [CounterFactory].
  ///
  /// Tests getting a [Provider] from a module provider method.
  @provide
  @manual
  CounterFactory get manualCounterFactory;
}

@module
class CounterModule {
  @provide
  @manual
  CounterFactory provideCounterProvider(Counter counter()) =>
      new CounterFactory(counter);
}

@provide
class CounterFactory {
  Provider<Counter> counter;

  CounterFactory(this.counter);

  Counter create() => counter();
}

/// A simple stateful class for the purpose of testing [Provider]s.
@provide
class Counter {
  int value = 0;

  void increment() => value++;
}

// Tests for providers.
void main() {
  group(ProvidersInjector, () {
    ProvidersInjector injector;

    setUp(() async {
      injector = await ProvidersInjector.create(new CounterModule());
    });

    test('provider from injector', () async {
      final counter1 = injector.counter();
      final counter2 = injector.counter();
      counter1.increment();

      expect(counter1.value, 1);
      expect(counter2.value, 0);
    });

    test('provider injected in class', () async {
      final counterFactory = injector.counterFactory;
      final counter1 = counterFactory.create();
      final counter2 = counterFactory.create();
      counter1.increment();

      expect(counter1.value, 1);
      expect(counter2.value, 0);
    });

    test('provider in module method', () async {
      final counterFactory = injector.counterFactory;
      final counter1 = counterFactory.create();
      final counter2 = counterFactory.create();
      counter1.increment();

      expect(counter1.value, 1);
      expect(counter2.value, 0);
    });
  }, skip: 'Currently not working with the extenral build system');
}
