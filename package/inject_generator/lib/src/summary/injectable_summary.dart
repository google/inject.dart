// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of inject.src.summary;

/// Result of analyzing a class whose constructor is annotated with `@Provide()`.
class InjectableSummary {
  /// Location of the analyzed class.
  final SymbolPath clazz;

  /// Summary about the constructor annotated with `@Provide()`.
  final ProviderSummary constructor;

  /// Constructor.
  ///
  /// [clazz] is the path to the injectable class. [constructor] carries summary
  /// about the constructor annotated with `@Provide()`.
  factory InjectableSummary(SymbolPath clazz, ProviderSummary constructor) {
    if (clazz == null) {
      throw new ArgumentError.notNull('clazz');
    }
    if (constructor == null) {
      throw new ArgumentError.value(
          constructor, 'constructor', 'Must not be null');
    }
    return new InjectableSummary._(clazz, constructor);
  }

  InjectableSummary._(this.clazz, this.constructor);

  /// Serializes this summary to JSON.
  Map<String, dynamic> toJson() {
    return {'name': clazz.symbol, 'constructor': constructor};
  }

  @override
  String toString() =>
      '$InjectableSummary ' +
      {'clazz': clazz, 'constructor': constructor}.toString();
}
