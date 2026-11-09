import 'dart:io';

import 'package:path/path.dart' as p;

/// Rejects equal or nested batch destinations, including symlink aliases.
void validateOutputPaths(Map<String, String> outputs) {
  final resolved = <String, String>{};
  for (final MapEntry<String, String> entry in outputs.entries) {
    final String physical = resolveOutputPath(entry.value);
    for (final MapEntry<String, String> previous in resolved.entries) {
      if (p.equals(previous.value, physical) ||
          p.isWithin(previous.value, physical) ||
          p.isWithin(physical, previous.value)) {
        throw FormatException(
          'Output directories overlap: ${previous.key} and ${entry.key}.',
        );
      }
    }
    resolved[entry.key] = physical;
  }
}

/// Resolves existing ancestors. Rejects file or broken-link ancestors.
String resolveOutputPath(String path) {
  String ancestor = p.normalize(p.absolute(path));
  final tail = <String>[];
  while (FileSystemEntity.typeSync(ancestor, followLinks: false) ==
      FileSystemEntityType.notFound) {
    tail.add(p.basename(ancestor));
    ancestor = p.dirname(ancestor);
  }
  if (!Directory(ancestor).existsSync()) {
    throw FileSystemException('Invalid output directory', ancestor);
  }
  final String physical = p.joinAll([
    Directory(ancestor).resolveSymbolicLinksSync(),
    ...tail.reversed,
  ]);
  return Platform.isMacOS || Platform.isWindows
      ? physical.toLowerCase()
      : physical;
}
