// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of inject.src.summary;

/// Result of analyzing a `@Module()` annotated-class.
class ModuleSummary {
  /// Location of the analyzed class.
  final SymbolPath clazz;

  /// Providers that are part of the module.
  final List<ProviderSummary> providers;

  /// Create a new summary of a module [clazz] of [providers].
  factory ModuleSummary(SymbolPath clazz, List<ProviderSummary> providers) {
    if (clazz == null) {
      throw new ArgumentError.notNull('clazz');
    }

    if (providers == null || providers.isEmpty) {
      throw new ArgumentError.value(
          providers, 'providers', 'Must not be null or empty.');
    }

    return new ModuleSummary._(
        clazz, new List<ProviderSummary>.unmodifiable(providers));
  }

  ModuleSummary._(this.clazz, this.providers);

  /// Serializes this summary to JSON.
  Map<String, dynamic> toJson() {
    return {"name": clazz.symbol, "providers": providers};
  }

  @override
  String toString() =>
      '$ModuleSummary ' + {'clazz': clazz, 'providers': providers}.toString();
}
