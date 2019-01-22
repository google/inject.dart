// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of inject.src.summary;

/// JSON-serializable subset of code analysis information about an injector
/// class pertaining to an injector class.
class InjectorSummary {
  /// Modules that are part of the object graph.
  final List<SymbolPath> modules;

  /// Methods that will need to be implemented by the generated class.
  final List<ProviderSummary> providers;

  /// Location of the analyzed class.
  final SymbolPath clazz;

  /// Constructor.
  ///
  /// [clazz], [modules] and [providers] must not be `null` or empty.
  factory InjectorSummary(SymbolPath clazz, List<SymbolPath> modules,
      List<ProviderSummary> providers) {
    if (clazz == null) {
      throw new ArgumentError.notNull('clazz');
    }
    if (modules == null) {
      throw new ArgumentError.value(modules, 'modules', 'Must not be null.');
    }
    if (providers == null) {
      throw new ArgumentError.value(modules, 'providers', 'Must not be null.');
    }
    return new InjectorSummary._(
        clazz,
        new List<SymbolPath>.unmodifiable(modules),
        new List<ProviderSummary>.unmodifiable(providers));
  }

  InjectorSummary._(this.clazz, this.modules, this.providers);

  /// Serializes this summary to JSON.
  Map<String, dynamic> toJson() {
    return {
      "name": clazz.symbol,
      "providers": providers,
      "modules":
          modules.map((summary) => summary.toAbsoluteUri().toString()).toList()
    };
  }
}
