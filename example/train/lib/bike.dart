import 'package:inject/inject.dart';

import 'common.dart';

/// Provides the service locator to the bike car feature code.
BikeServiceLocator bikeServices;

/// Declares dependencies used by the bike car.
abstract class BikeServiceLocator {
  @provide
  BikeRack get bikeRack;
}

/// Declares dependencies needed by the bike car.
@module
class BikeServices {
  /// Note the dependency on [CarMaintenance] which this module does not itself
  /// provide. This tells `package:inject` to look for it when this module is
  /// mixed into an injector. The compiler will _statically_ check that this
  /// dependency is satisfied, and issue a warning if it's not.
  @provide
  BikeRack bikeRack(CarMaintenance cm) => new BikeRack(cm);
}

class BikeRack {
  final CarMaintenance maintenance;

  BikeRack(this.maintenance);

  String pleaseFix() {
    return maintenance.pleaseFix();
  }
}
