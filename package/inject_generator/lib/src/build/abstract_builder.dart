// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';

/// A base builder class for Inject.
///
/// Used to simplify the input/output file API and support common use cases.
abstract class AbstractInjectBuilder implements Builder {
  /// Constructor.
  const AbstractInjectBuilder();

  /// File type that is consumed by the builder.
  String get inputExtension;

  /// File type that is output by the builder.
  String get outputExtension;

  @override
  Future<Null> build(BuildStep buildStep) async {
    var outputFile = buildStep.inputId.changeExtension('.$outputExtension');
    var outputContents = await buildOutput(buildStep);
    buildStep.writeAsString(outputFile, outputContents);
  }

  /// Implement in order to return the output file.
  Future<String> buildOutput(BuildStep buildStep);

  @override
  Map<String, List<String>> get buildExtensions => {
        '.$inputExtension': ['.$outputExtension']
      };
}
