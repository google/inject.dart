import 'package:build/build.dart';

import 'src/build/codegen_builder.dart';
import 'src/build/summary_builder.dart';

/// Create a [Builder] which produces `*.inject.dart` files from `*.dart` files.
Builder generateBuilder([_]) => const InjectCodegenBuilder();

/// Create a [Builder] which produces summary files used by [generateBuilder].
Builder summarizeBuilder([_]) => const InjectSummaryBuilder();
