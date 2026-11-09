@TestOn('vm')
@Timeout(Duration(minutes: 2))
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:test/test.dart';

void main() {
  test(
    'writes helper files and checks changes without partial output',
    () async {
      final Directory root = await Directory.systemTemp.createTemp(
        'helper_cli_',
      );
      addTearDown(() => root.delete(recursive: true));
      File file(String path) => File.fromUri(root.uri.resolve(path));
      final Uri packages = (await Isolate.packageConfig)!;
      final String cli = Directory.current.uri
          .resolve('bin/swagger_parser_templates.dart')
          .toFilePath();
      final String snapshot = file('templates.dill').path;
      final ProcessResult compiled = await Process.run(
        Platform.resolvedExecutable,
        [
          'compile',
          'kernel',
          '--packages=${packages.toFilePath()}',
          cli,
          '-o',
          snapshot,
        ],
      );
      expect(
        compiled.exitCode,
        0,
        reason: '${compiled.stdout}\n${compiled.stderr}',
      );
      Future<ProcessResult> run(List<String> args) => Process.run(
        Platform.resolvedExecutable,
        [snapshot, ...args],
        workingDirectory: root.path,
      );
      const fixtures = 'test/fixtures/pagination';
      for (final name in [
        'page',
        'stations_page',
        'exports',
        'internal',
        'plain',
      ]) {
        await File('$fixtures/$name.mustache')
            .copy(file('$name.mustache').path);
      }
      for (final ext in ['json', 'yaml']) {
        await File('$fixtures/config.$ext').copy(file('config.$ext').path);
        for (final version in ['2_0', '3_0', '3_1', '3_2']) {
          await File('$fixtures/v$version.$ext').copy(file('entry.$ext').path);
          final ProcessResult result = await run(['-f', 'config.$ext']);
          expect(
            result.exitCode,
            0,
            reason: '${result.stdout}\n${result.stderr}',
          );
          expect(
            await file('out/helpers/page.dart').readAsString(),
            contains('class Page<T>'),
          );
          expect(
            await file('out/exports.dart').readAsString(),
            contains('export "helpers/page.dart";'),
          );
          expect(
            await file('out/exports.dart').readAsString(),
            isNot(contains('helpers/internal.dart')),
          );
          expect((await run(['--check', '-f', 'config.$ext'])).exitCode, 0);
        }
      }
      final String original = await file('out/helpers/page.dart')
          .readAsString();
      await file('out/helpers/page.dart')
          .writeAsString('$original// Changed.\n');
      expect((await run(['--check', '-f', 'config.yaml'])).exitCode, 1);
      expect(
        await file('out/helpers/page.dart').readAsString(),
        '$original// Changed.\n',
      );
      expect((await run(['-f', 'config.yaml'])).exitCode, 0);
      expect(await file('out/helpers/page.dart').readAsString(), original);

      final String template = await file('page.mustache').readAsString();
      await file('page.mustache').writeAsString('class {');
      final ProcessResult invalid = await run(['-f', 'config.yaml']);
      expect(invalid.exitCode, 1);
      expect(invalid.stderr.toString(), contains('helpers/page.dart'));
      expect(await file('out/helpers/page.dart').readAsString(), original);
      await file('page.mustache').writeAsString(template);

      final config = jsonDecode(
        await file('config.json').readAsString(),
      ) as Map<String, Object?>;
      final generation = config['generation']! as Map<String, Object?>;
      final templates = generation['templates']! as Map<String, Object?>;
      for (final Object invalidFiles in [
        {},
        [null],
        [
          {'template': 'page.mustache'},
        ],
        [
          {
            'template': 'page.mustache',
            'output': 'page.dart',
            'export': 'true',
          },
        ],
        [
          {'template': 'page.mustache', 'output': 'page.dart', 'typo': true},
        ],
      ]) {
        templates['files'] = invalidFiles;
        await file('invalid.json').writeAsString(jsonEncode(config));
        final ProcessResult failed = await run(['-f', 'invalid.json']);
        expect(failed.exitCode, 64, reason: failed.stderr.toString());
        expect(await file('out/helpers/page.dart').readAsString(), original);
      }
      for (final path in [
        'exports.dart',
        '../page.dart',
        'helpers/Page.dart',
      ]) {
        templates['files'] = [
          {'template': 'page.mustache', 'output': 'helpers/page.dart'},
          {'template': 'page.mustache', 'output': path},
        ];
        await file('invalid.json').writeAsString(jsonEncode(config));
        final ProcessResult failed = await run(['-f', 'invalid.json']);
        expect(failed.exitCode, 1, reason: failed.stderr.toString());
        expect(failed.stderr.toString(), contains(path));
        expect(await file('out/helpers/page.dart').readAsString(), original);
      }
      for (final ext in ['json', 'yaml']) {
        await File('$fixtures/batch.$ext').copy(file('batch.$ext').path);
        final ProcessResult batch = await run(['-f', 'batch.$ext']);
        expect(batch.exitCode, 0, reason: batch.stderr.toString());
        expect(file('out/inherited/helpers/page.dart').existsSync(), isTrue);
        expect(file('out/disabled/helpers/page.dart').existsSync(), isFalse);
        expect(
          await file('out/disabled/exports.dart').readAsString(),
          isNot(contains('helpers/page.dart')),
        );
        expect((await run(['--check', '-f', 'batch.$ext'])).exitCode, 0);
      }
    },
  );
}
