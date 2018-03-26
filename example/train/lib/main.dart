import 'dart:async';

import 'bike.dart';
import 'common.dart';
import 'food.dart';
import 'locomotive.dart';

Future<Null> main() async {
  final services = await TrainServices.create(
    new BikeServices(),
    new FoodServices(),
    new CommonServices(),
  );
  print(services.bikeRack.pleaseFix());
}
