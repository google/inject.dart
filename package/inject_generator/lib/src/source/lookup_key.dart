// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:inject_generator/src/source/symbol_path.dart';
import 'package:quiver/core.dart';

/// A representation of a key in the dependency injection graph.
///
/// Equality of all the fields indicate that two types are the same.
class LookupKey {
  /// [SymbolPath] of the root type.
  ///
  /// For example, for the type `@qualifier A<B, C>`, this will be `A`.
  final SymbolPath root;

  /// Optional qualifier for the type.
  final Optional<SymbolPath> qualifier;

  LookupKey(this.root, {SymbolPath qualifier})
      : this.qualifier = new Optional.fromNullable(qualifier);

  /// Returns a new instance from the JSON encoding of an instance.
  ///
  /// See also [LookupKey.toJson].
  factory LookupKey.fromJson(Map<String, dynamic> json) {
    return new LookupKey(
        new SymbolPath.fromAbsoluteUri(Uri.parse(json['root'])),
        qualifier: json['qualifier'] == null
            ? null
            : new SymbolPath.fromAbsoluteUri(Uri.parse(json['qualifier'])));
  }

  /// A human-readable representation of the dart Symbol of this type.
  String toPrettyString() {
    final qualifierString =
        qualifier.transform((symbolPath) => '@${symbolPath.symbol} ').or('');
    return '$qualifierString${root.symbol}';
  }

  /// Returns the JSON encoding of this instance.
  ///
  /// See also [LookupKey.fromJson].
  Map<String, dynamic> toJson() {
    return {
      'root': root.toAbsoluteUri().toString(),
      'qualifier': qualifier
          .transform((symbol) => symbol.toAbsoluteUri().toString())
          .orNull,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LookupKey &&
          runtimeType == other.runtimeType &&
          root == other.root &&
          qualifier == other.qualifier;

  @override
  int get hashCode => hash2(root.hashCode, qualifier.hashCode);

  @override
  String toString() => '$LookupKey{root: $root, qualifier: $qualifier}';
}
