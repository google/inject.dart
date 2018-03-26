import 'dart:async';

import 'package:inject/inject.dart';

import 'bike.dart';
import 'common.dart';
import 'food.dart';

import 'locomotive.inject.dart' as g;

/// The top level injector that stitches together multiple app features into
/// a complete app.
@Injector(const [BikeServices, FoodServices, CommonServices])
abstract class TrainServices implements BikeServiceLocator, FoodServiceLocator {
  static Future<TrainServices> create(
    BikeServices bikeModule,
    FoodServices foodModule,
    CommonServices commonModule,
  ) async {
    var services = await g.TrainServices$Injector.create(
      bikeModule,
      foodModule,
      commonModule,
    );

    bikeServices = services;
    foodServices = services;
    return services;
  }
}
