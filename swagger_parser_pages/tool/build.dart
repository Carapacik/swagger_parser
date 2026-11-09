import 'dart:io';

import 'build_reference.dart';

/// Builds the client-only site without Jaspr code generation.
Future<void> main() async {
  final output = Directory('build/site');
  if (output.existsSync()) {
    await output.delete(recursive: true);
  }
  await output.create(recursive: true);
  for (final entry in ['main', 'worker']) {
    final ProcessResult result = await Process.run(
      Platform.resolvedExecutable,
      [
        'compile',
        'js',
        '-O2',
        'web/$entry.dart',
        '-o',
        '${output.path}/$entry.dart.js',
      ],
    );
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode != 0) {
      exitCode = result.exitCode;
      return;
    }
  }
  for (final name in [
    'index.html',
    'styles.css',
    'favicon.svg',
    'github.svg',
  ]) {
    await File('web/$name').copy('${output.path}/$name');
  }
  final String index = await File('web/index.html').readAsString();
  for (final route in ['template', 'config']) {
    final directory = Directory('${output.path}/$route');
    await directory.create();
    await File('${directory.path}/index.html').writeAsString(
      index.replaceFirst('<head>', '<head>\n  <base href="../">'),
    );
  }
  await buildReference(output);
  stdout.writeln('Site: ${output.path}');
}
