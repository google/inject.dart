part of '../graph.dart';

/// Can [read] a JSON file as a [LibrarySummary].
abstract class SummaryReader {
  /// Given a [package] and a [path], return a [LibrarySummary].
  Future<LibrarySummary> read(String package, String path);
}
