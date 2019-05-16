// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:inject/inject.dart';

import 'heater.dart';
import 'pump.dart';

class Thermosiphon implements Pump {
  final Heater _heater;

  @provide
  Thermosiphon(this._heater);

  @override
  void pump() {
    if (_heater.isHot) {
      print('pumping water');
    }
  }
}
