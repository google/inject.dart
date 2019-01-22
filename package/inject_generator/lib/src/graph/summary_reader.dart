// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
part of inject.src.graph;

/// Can [read] a JSON file as a [LibrarySummary].
abstract class SummaryReader {
  /// Given a [package] and a [path], return a [LibrarySummary].
  Future<LibrarySummary> read(String package, String path);
}
