@TestOn('vm')
@Timeout(Duration(minutes: 2))
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:test/test.dart';

void main() {
  test('loads relative templates and checks the rendered files', () async {
    final Directory root = await Directory.systemTemp.createTemp(
      'template_cli_',
    );
    addTearDown(() => root.delete(recursive: true));
    File file(String name) => File.fromUri(root.uri.resolve(name));
    final Uri packages = (await Isolate.packageConfig)!;
    Future<ProcessResult> run(List<String> args) => Process.run(
      Platform.resolvedExecutable,
      ['run', 'swagger_parser_templates', ...args],
      workingDirectory: root.path,
    );
    final Uri workspace = Directory.current.parent.uri;
    await file('pubspec.yaml').writeAsString("""
name: template_consumer
environment:
  sdk: ^3.13.0
dev_dependencies:
  swagger_parser: ^2.0.0
  swagger_parser_templates:
    path: ${jsonEncode(workspace.resolve('swagger_parser_templates').toFilePath())}
dependency_overrides:
  swagger_parser:
    path: ${jsonEncode(workspace.resolve('swagger_parser').toFilePath())}
  swagger_parser_core:
    path: ${jsonEncode(workspace.resolve('swagger_parser_core').toFilePath())}
""");
    final ProcessResult get = await Process.run(Platform.resolvedExecutable, [
      'pub',
      'get',
      '--offline',
    ], workingDirectory: root.path);
    expect(get.exitCode, 0, reason: get.stderr.toString());
    await file('config/templates/routes.mustache').parent
        .create(recursive: true);
    await File.fromUri(
      workspace.resolve(
        'swagger_parser/test/fixtures/extraction/open_api_v3_2.yaml',
      ),
    ).copy(file('config/entry.yaml').path);
    await File('test/fixtures/rendering/routes.mustache')
        .copy(file('config/templates/routes.mustache').path);
    await file('config/templates/model.mustache')
        .writeAsString('{{defaultSource}}\n// Custom model.');
    await file('config/templates/station.mustache')
        .writeAsString('{{defaultSource}}\nconst customStation = true;');
    await file('config/settings.yaml').writeAsString('''
schema_path: entry.yaml
output_directory: ../out
generation:
  http_client: http
  templates:
    client: templates/routes.mustache
    models: templates/model.mustache
    default_client/models/station.dart: templates/station.mustache
''');
    const args = ['-f', 'config/settings.yaml'];
    final ProcessResult builtin = await Process.run(
      Platform.resolvedExecutable,
      ['run', 'swagger_parser', ...args],
      workingDirectory: root.path,
    );
    expect(builtin.exitCode, 64);
    expect(builtin.stderr.toString(), contains('generation.templates'));
    final ProcessResult first = await run(args);
    expect(first.exitCode, 0, reason: first.stderr.toString());
    const station = 'out/default_client/models/station.dart';
    final String before = await file(station).readAsString();
    expect(before, contains('const customStation = true;'));
    expect(before, isNot(contains('// Custom model.')));
    expect(
      await file('out/models/unused.dart').readAsString(),
      contains('// Custom model.'),
    );
    expect((await run(['--check', ...args])).exitCode, 0);

    await file('probe.dart').writeAsString("""
import 'out/default_client/api_client.dart';
void main() => print(ApiClientRoutes.getStationsById);
""");
    final ProcessResult probe = await Process.run(Platform.resolvedExecutable, [
      '--packages=${packages.toFilePath()}',
      file('probe.dart').path,
    ]);
    expect(probe.exitCode, 0, reason: probe.stderr.toString());
    expect(probe.stdout.toString().trim(), '/stations/{id}');

    await file('config/templates/api.mustache')
        .writeAsString('{{defaultSource}}\n// Shared API.');
    await file('config/templates/child.mustache')
        .writeAsString('{{defaultSource}}\n// Child model.');
    for (final ext in ['json', 'yaml']) {
      await File('test/fixtures/cli/inputs.$ext')
          .copy(file('config/inputs.$ext').path);
      final inputArgs = ['-f', 'config/inputs.$ext'];
      final ProcessResult batch = await run(inputArgs);
      expect(batch.exitCode, 0, reason: '${batch.stdout}\n${batch.stderr}');
      expect(
        await file('batch/first/api.dart').readAsString(),
        contains('// Shared API.'),
      );
      expect(
        await file('batch/second/custom_api.dart').readAsString(),
        contains('// Shared API.'),
      );
      expect(
        await file('batch/first/default_client/models/station.dart')
            .readAsString(),
        contains('// Custom model.'),
      );
      final String child = await file(
        'batch/second/default_client/models/station.dart',
      ).readAsString();
      expect(child, contains('// Child model.'));
      expect(child, isNot(contains('// Custom model.')));
      expect((await run(['--check', ...inputArgs])).exitCode, 0);
    }

    final HttpServer server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(() => server.close(force: true));
    final received = <String?>[];
    final List<int> entry = await file('config/entry.yaml').readAsBytes();
    server.listen((request) async {
      received.add(request.headers.value('authorization'));
      request.response.add(entry);
      await request.response.close();
    });
    for (final ext in ['json', 'yaml']) {
      final String source = await File('test/fixtures/cli/auth.$ext')
          .readAsString();
      await file('config/auth.$ext')
          .writeAsString(source.replaceAll('PORT', '${server.port}'));
      final ProcessResult auth = await Process.run(
        Platform.resolvedExecutable,
        ['run', 'swagger_parser_templates', '-f', 'config/auth.$ext'],
        workingDirectory: root.path,
        environment: {'TEMPLATE_SCHEMA_AUTH': 'Bearer template-secret'},
      );
      expect(auth.exitCode, 0, reason: '${auth.stdout}\n${auth.stderr}');
      expect(
        await file('auth/api.dart').readAsString(),
        contains('// Shared API.'),
      );
      expect(
        await file('auth/api.dart').readAsString(),
        isNot(contains('template-secret')),
      );
      expect(
        '${auth.stdout}\n${auth.stderr}',
        isNot(contains('template-secret')),
      );
    }
    expect(received, ['Bearer template-secret', 'Bearer template-secret']);

    for (final invalid in ['{{#unclosed}}', 'class {']) {
      await file('config/templates/station.mustache').writeAsString(invalid);
      final ProcessResult failed = await run(args);
      expect(failed.exitCode, 1);
      expect(
        failed.stderr.toString(),
        contains('default_client/models/station.dart'),
      );
      expect(await file(station).readAsString(), before);
    }
  });
}
