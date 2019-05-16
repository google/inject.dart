import 'dart:async';

import 'package:inject/inject.dart';
import 'package:test/test.dart';

import 'package:inject.example.coffee/coffee_app.dart';

import 'coffee_app_test.inject.dart' as gen;

List<String> _printLog = <String>[];

void main() {
  group('overriding', () {
    setUp(() {
      _printLog.clear();
    });

    test('can be done by mixing test modules', _interceptPrint(() async {
      var coffee =
          await TestCoffee.create(new DripCoffeeModule(), new TestModule());
      coffee.getCoffeeMaker().brew();
      expect(_printLog, [
        'test heater turned on',
        ' [_]P coffee! [_]P',
        ' Thanks for using TestCoffeeMachine by Coffee by Dart Inc.',
      ]);
    }));
  });
}

/// Overrides production services.
@module
class TestModule {
  /// Let's override what the [Heater] does.
  @provide
  Heater testHeater(Electricity _) => new _TestHeater();

  /// Let's also override the model name.
  @modelName
  @provide
  String testModel() => 'TestCoffeeMachine';
}

class _TestHeater implements Heater {
  @override
  bool isHot = false;

  @override
  void on() {
    print('test heater turned on');
    isHot = true;
  }

  @override
  void off() {
    isHot = false;
  }
}

/// Demonstrates overriding dependencies in a test by mixing in test modules.
@Injector(const [DripCoffeeModule, TestModule])
abstract class TestCoffee {
  /// Note test modules being used.
  static final create = gen.TestCoffee$Injector.create;

  /// Provides a coffee maker.
  @provide
  CoffeeMaker getCoffeeMaker();
}

/// Forwards [print] messages to [_printLog].
Function _interceptPrint(testFn()) {
  return () {
    return Zone.current.fork(specification: new ZoneSpecification(
      print: (_, __, ___, String message) {
        _printLog.add(message);
      },
    )).run(testFn);
  };
}
