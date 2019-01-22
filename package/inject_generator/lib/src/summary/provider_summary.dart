// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of inject.src.summary;

/// The kind of provider.
enum ProviderKind {
  /// The provider is implemented as a constructor or a `factory`.
  constructor,

  /// The provider is implemented as a method.
  method,

  /// The provider is implemented as a getter.
  getter,
}

/// Maps between [ProviderKind] enum values and their names.
final _providerKindNames = new BiMap<ProviderKind, String>()
  ..[ProviderKind.constructor] = 'constructor'
  ..[ProviderKind.method] = 'method'
  ..[ProviderKind.getter] = 'getter';

/// Converts provider [name] to the corresponding `enum` reference.
ProviderKind providerKindFromName(String name) {
  ProviderKind kind = _providerKindNames.inverse[name];

  if (kind == null) {
    throw new ArgumentError.value(name, 'name', 'Invalid provider kind name');
  }

  return kind;
}

/// Converts a provider [kind] to its name.
///
/// See also [providerKindFromName].
String provideKindName(ProviderKind kind) {
  String name = _providerKindNames[kind];

  if (name == null) {
    throw new ArgumentError.value(kind, 'kind', 'Unrecognized provider kind');
  }

  return name;
}

/// Contains information about a method, constructor, factory or a getter
/// annotated with `@provide`.
class ProviderSummary {
  /// Name of the annotated method.
  final String name;

  /// Provider kind.
  final ProviderKind kind;

  /// Type of the instance that will be returned.
  final InjectedType injectedType;

  /// Whether or not this provider provides a singleton.
  final bool isSingleton;

  /// Whether this provider is annotated with `@asynchronous`.
  final bool isAsynchronous;

  /// Dependencies required to create an instance of [injectedType].
  final List<InjectedType> dependencies;

  /// Create a new summary of a provider that returns an instance of
  /// [injectedType].
  factory ProviderSummary(
    InjectedType injectedType,
    String name,
    ProviderKind kind, {
    List<InjectedType> dependencies: const [],
    bool singleton: false,
    bool asynchronous: false,
  }) {
    if (injectedType == null) {
      throw new ArgumentError.notNull('lookupKey');
    }
    if (name == null) {
      throw new ArgumentError.notNull('name');
    }
    if (kind == null) {
      throw new ArgumentError.notNull('providerKind');
    }
    if (dependencies == null) {
      throw new ArgumentError.notNull('dependencies');
    }
    if (singleton == null) {
      throw new ArgumentError.notNull('singleton');
    }
    if (asynchronous && kind != ProviderKind.method) {
      throw new ArgumentError(
          'Only methods can be asynchronous providers but found $kind $name.');
    }
    return new ProviderSummary._(
      name,
      kind,
      injectedType,
      singleton,
      asynchronous,
      new List<InjectedType>.unmodifiable(dependencies),
    );
  }

  ProviderSummary._(
    this.name,
    this.kind,
    this.injectedType,
    this.isSingleton,
    this.isAsynchronous,
    this.dependencies,
  );

  /// Serializes this summary to JSON.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'kind': provideKindName(kind),
      'injectedType': injectedType,
      'singleton': isSingleton,
      'asynchronous': isAsynchronous,
      'dependencies': dependencies
    };
  }

  @override
  String toString() =>
      '$ProviderSummary ' +
      {
        'name': name,
        'kind': kind,
        'injectedType': injectedType,
        'singleton': isSingleton,
        'asynchronous': isAsynchronous,
        'dependencies': dependencies
      }.toString();
}
