// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as pkg_path;
import 'package:quiver/core.dart';

/// Represents the absolute canonical location of a [symbol] within Dart.
///
/// A [symbol] is mapped to a [path] within a [package]. For example:
///     // A reference to package:collection/collection.dart#MapEquality
///     new SymbolPath('collection', 'lib/collection.dart', 'MapEquality')
///
///     // A reference to dart:core#List
///     new SymbolPath.dartSdk('core', 'List')
class SymbolPath implements Comparable<SymbolPath> {
  /// Path to the `@Qualifier` annotation.
  static const qualifier = const SymbolPath._standard('Qualifier');

  /// Path to the `@Module` annotation.
  static const module = const SymbolPath._standard('Module');

  /// Path to the `@Provide` annotation.
  static const provide = const SymbolPath._standard('Provide');

  /// Path to the `@Singleton` annotation.
  static const singleton = const SymbolPath._standard('Singleton');

  /// Path to the `@Asynchronous` annotation.
  static const asynchronous = const SymbolPath._standard('Asynchronous');

  /// Path to the `@Injector` annotation.
  static const injector = const SymbolPath._standard('Injector');

  static const String _dartExtension = '.dart';
  static const String _dartPackage = 'dart';

  /// An alias to `new SymbolPath.fromAbsoluteUri(Uri.parse(...))`.
  static SymbolPath parseAbsoluteUri(String assetUri, [String symbolName]) {
    return new SymbolPath.fromAbsoluteUri(Uri.parse(assetUri), symbolName);
  }

  /// Name of the package containing the Dart source code.
  ///
  /// If 'dart', is special cased to the Dart SDK. See [isDartSdk].
  final String package;

  /// Location relative to the package root.
  ///
  /// A fully qualified path in a Dart package (*not* a package URI):
  ///   - 'lib/foo.dart'
  ///   - 'bin/bar.dart'
  ///   - 'test/some/file.dart'
  final String path;

  /// Name of the top-level symbol within the Dart source code referenced.
  final String symbol;

  /// Constructor.
  ///
  /// [package] is the name of the Dart package containing the symbol. For Dart
  /// core libraries use "dart" as the [package].
  ///
  /// [path] is path to the library within the package. Unlike `import`
  /// statements, [path] must include "lib", "web", "bin", "test" parts of the
  /// path, for example "lib/src/coffee.dart". Paths for Dart core libraries
  /// must be their names without the "lib" prefix, for example "async" for
  /// "dart:async".
  ///
  /// [symbol] is the symbol defined in the library.
  ///
  /// [package], [path] and [symbol] must not be `null` or empty.
  factory SymbolPath(String package, String path, String symbol) {
    if (package == null || package.isEmpty) {
      throw new ArgumentError.value(
          package, 'package', 'Non-empty value required');
    }
    if (path == null ||
        path.isEmpty ||
        package != _dartPackage && !path.endsWith(_dartExtension)) {
      throw new ArgumentError.value(
          path, 'path', 'Must have a .dart extension');
    }
    if (symbol == null || symbol.isEmpty) {
      throw new ArgumentError.value(
          symbol, 'symbol', 'Non-empty value required');
    }
    return new SymbolPath._(package, path, symbol);
  }

  /// Within the dart SDK, reference [symbol] found at [path].
  factory SymbolPath.dartSdk(String path, String symbol) {
    return new SymbolPath(_dartPackage, path, symbol);
  }

  /// Defines a global symbol that is not scoped to a package/path.
  const SymbolPath.global(this.symbol)
      : package = null,
        path = null;

  /// Create a [SymbolPath] using [assetUri].
  factory SymbolPath.fromAbsoluteUri(Uri assetUri, [String symbolName]) {
    assetUri = toAssetUri(assetUri);
    symbolName ??= assetUri.fragment;
    if (assetUri.scheme == _dartPackage) {
      return new SymbolPath.dartSdk(assetUri.path, symbolName);
    }
    if (assetUri.scheme == 'global') {
      return new SymbolPath.global(symbolName);
    }
    var paths = assetUri.path.split('/');
    var package = paths.first;
    var path = paths.skip(1).join('/');
    return new SymbolPath(package, path, symbolName);
  }

  /// Converts [libUri] to an absolute "asset:" [Uri].
  ///
  /// If [libUri] is already absolute, it is left unchanged.
  ///
  /// Relative URI are rejected with an exception.
  static Uri toAssetUri(Uri libUri) {
    if (libUri.scheme == null || libUri.scheme.isEmpty) {
      throw 'Relative library URI not supported: ${libUri}';
    }

    if (libUri.scheme != 'package') {
      return libUri;
    }

    var inSegments = libUri.path.split('/');
    var outSegments = <String>[inSegments.first, 'lib']
      ..addAll(inSegments.skip(1));

    return libUri.fragment != null && libUri.fragment.isNotEmpty
        ? new Uri(
            scheme: 'asset',
            pathSegments: outSegments,
            fragment: libUri.fragment,
          )
        : new Uri(
            scheme: 'asset',
            pathSegments: outSegments,
          );
  }

  /// For standard annotations defined by `package:inject`.
  const SymbolPath._standard(String symbol)
      : this._('inject', 'lib/src/api/annotations.dart', symbol);

  const SymbolPath._(this.package, this.path, this.symbol);

  /// Whether the [path] points within the Dart SDK, not a pub package.
  bool get isDartSdk => package == _dartPackage;

  ///  Whether [symbol] is a global key.
  bool get isGlobal => package == null && path == null;

  @override
  bool operator ==(Object other) {
    if (other is SymbolPath) {
      return package == other.package &&
          path == other.path &&
          symbol == other.symbol;
    }
    return false;
  }

  @override
  int get hashCode => hash3(package, path, symbol);

  @override
  int compareTo(SymbolPath symbolPath) {
    var order = package.compareTo(symbolPath.package);
    if (order == 0) {
      order = path.compareTo(symbolPath.path);
    }
    if (order == 0) {
      order = symbol.compareTo(symbolPath.symbol);
    }
    return order;
  }

  /// Returns a new absolute 'dart:', 'asset:', or 'global:' [Uri].
  Uri toAbsoluteUri() {
    if (isGlobal) {
      return new Uri(scheme: 'global', fragment: symbol);
    }
    return new Uri(
      scheme: isDartSdk ? _dartPackage : 'asset',
      path: isDartSdk ? path : '$package/$path',
      fragment: symbol,
    );
  }

  /// Returns a [Uri] for this path that can be used in a Dart import statement.
  Uri toDartUri({Uri relativeTo}) {
    if (isGlobal) {
      throw new UnsupportedError('Global keys do not map to Dart source.');
    }

    if (isDartSdk) {
      return new Uri(scheme: 'dart', path: path);
    }

    if (relativeTo != null) {
      // Attempt to construct relative import.
      Uri normalizedBase = relativeTo.normalizePath();
      List<String> baseSegments = normalizedBase.path.split('/')..removeLast();
      List<String> targetSegments = toAbsoluteUri().path.split('/');
      if (baseSegments.first == targetSegments.first &&
          baseSegments[1] == targetSegments[1]) {
        // Ok, we're in the same package and in the same top-level directory.
        String relativePath = pkg_path.relative(
            targetSegments.skip(2).join('/'),
            from: baseSegments.skip(2).join('/'));
        return new Uri(path: pkg_path.split(relativePath).join('/'));
      }
    }

    var pathSegments = path.split('/');

    if (pathSegments.first != 'lib') {
      throw new StateError(
          'Cannot construct absolute import URI from ${relativeTo} '
          'to a non-lib Dart file: ${toAbsoluteUri()}');
    }

    var packagePath = pathSegments.sublist(1).join('/');
    return new Uri(
        scheme: isDartSdk ? _dartPackage : 'package',
        path: isDartSdk ? path : '$package/$packagePath');
  }

  /// Absolute path to this symbol for use in log messages.
  String toHumanReadableString() => '${toDartUri()}#${symbol}';

  @override
  String toString() => '$SymbolPath {${toAbsoluteUri()}}';
}
