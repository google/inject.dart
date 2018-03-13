import 'dart:async';

import 'package:inject.example.coffee/coffee_app.dart';

/// An example application that simulates running the `Coffee` application.
Future<Null> main() async {
  var coffee = await Coffee.create(new DripCoffeeModule());
  coffee.getCoffeeMaker().brew();
}
