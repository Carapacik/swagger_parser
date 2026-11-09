import 'dart:io';

import 'package:test/test.dart';

/// A temporary package for generated client tests.
final class ClientConsumer._(
  /// Package root.
  final Uri uri,
) {
  /// Creates a package and schedules cleanup after the test.
  static Future<ClientConsumer> create(String backend) async {
    final Directory root = await Directory.systemTemp.createTemp(
      'swagger_${backend}_',
    );
    addTearDown(() => root.delete(recursive: true));
    return ClientConsumer._(root.uri);
  }

  /// Writes a package file and creates its parent directory.
  Future<void> write(String path, String content) async {
    final file = File.fromUri(uri.resolve(path));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  /// Runs the test SDK in this package.
  Future<void> dart(List<String> args) async {
    final ProcessResult run = await Process.run(
      Platform.resolvedExecutable,
      args,
      workingDirectory: uri.toFilePath(),
    );
    expect(
      run.exitCode,
      0,
      reason: '${args.join(' ')}\n${run.stdout}\n${run.stderr}',
    );
  }
}
