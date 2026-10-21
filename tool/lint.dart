import 'dart:io';

import 'package:bloc_lint/bloc_lint.dart';

/// File URIs preserve Windows drive letters and spaces, unlike the current
/// bloc_tools CLI's path-to-URI conversion.
void main() {
  final results = const Linter().analyze(uri: Directory('lib').absolute.uri);
  if (results.isEmpty) {
    stderr.writeln('No Dart files analyzed. Run this from the project root.');
    exitCode = 2;
    return;
  }
  var count = 0;
  for (final entry in results.entries) {
    for (final diagnostic in entry.value) {
      count++;
      stdout.writeln(
        '${entry.key}:${diagnostic.range.start.line + 1}: '
        '${diagnostic.code}: ${diagnostic.message}',
      );
    }
  }
  stdout.writeln('$count Bloc lint issues in ${results.length} files.');
  if (count > 0) exitCode = 1;
}
