import 'package:build/build.dart';

import 'src/builder/codegen_builder.dart';
import 'src/builder/summary_builder.dart';

/// Create a [Builder] which produces `*.inject.dart` files from `*.dart` files.
Builder generate([_]) => const InjectCodegenBuilder();

/// Create a [Builder] which produces intermediate files used by [generate].
Builder summarize([_]) => const InjectSummaryBuilder();
