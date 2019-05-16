// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Contains typed classes that represent collected metadata used by Inject.
///
/// Internal library, **do not export**.
library inject.src.summary;

import 'package:inject_generator/src/source/injected_type.dart';
import 'package:inject_generator/src/source/symbol_path.dart';
import 'package:quiver/collection.dart';

part 'summary/injectable_summary.dart';
part 'summary/injector_summary.dart';
part 'summary/library_summary.dart';
part 'summary/module_summary.dart';
part 'summary/provider_summary.dart';
