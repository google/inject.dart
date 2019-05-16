// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library inject.example.coffee;

import 'package:inject/inject.dart';

import 'coffee_app.inject.dart' as $G;
import 'src/drip_coffee_module.dart';
import 'src/coffee_maker.dart';

/// An example injector class.
///
/// This injector uses [DripCoffeeModule] as a source of dependency providers.
@Injector(const [DripCoffeeModule])
abstract class Coffee {
  /// A generated `async` static function, which takes a [DripCoffeeModule] and
  /// asynchronously returns an instance of [Coffee].
  static final create = $G.Coffee$Injector.create;

  /// An accessor to an object that an application may use.
  @provide
  CoffeeMaker getCoffeeMaker();
}
