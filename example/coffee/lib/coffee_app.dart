library inject.example.coffee;

import 'package:inject/inject.dart';

// This is a compile-time generated file and does not exist in source.
import 'coffee_app.inject.dart' as generated;
import 'src/drip_coffee_module.dart';
import 'src/coffee_maker.dart';

export 'src/coffee_maker.dart';
export 'src/drip_coffee_module.dart';
export 'src/electric_heater.dart';
export 'src/heater.dart';

/// An example injector class.
///
/// This injector uses [DripCoffeeModule] as a source of dependency providers.
@Injector(const [DripCoffeeModule])
abstract class Coffee {
  /// A generated `async` static function, which takes a [DripCoffeeModule] and
  /// asynchronously returns an instance of [Coffee].
  static final create = generated.Coffee$Injector.create;

  /// An accessor to an object that an application may use.
  @provide
  CoffeeMaker getCoffeeMaker();
}
