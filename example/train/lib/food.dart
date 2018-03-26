import 'package:inject/inject.dart';

import 'common.dart';

/// Provides service locator for food car feature code.
FoodServiceLocator foodServices;

/// Declares dependencies used by the food car.
abstract class FoodServiceLocator {
  @provide
  Kitchen get kitchen;
}

/// Declares dependencies needed by the food car.
@module
class FoodServices {
  @provide
  Kitchen kitchen(CarMaintenance cm) => new Kitchen(cm);
}

class Kitchen {
  Kitchen(CarMaintenance cm);
}
