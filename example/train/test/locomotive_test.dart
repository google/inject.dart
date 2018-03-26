import 'package:test/test.dart';

import 'package:inject.example.train/bike.dart';
import 'package:inject.example.train/common.dart';
import 'package:inject.example.train/food.dart';
import 'package:inject.example.train/locomotive.dart';

void main() {
  group('locomotive', () {
    test('can instantiate TrainServices', () async {
      final services = await TrainServices.create(
        new BikeServices(),
        new FoodServices(),
        new CommonServices(),
      );
      services.bikeRack;
      services.kitchen;
    });
  });
}
