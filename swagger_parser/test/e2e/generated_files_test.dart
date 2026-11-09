@TestOn('vm')
@Tags(['e2e'])
@Timeout(Duration(minutes: 2))
library;

import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

const _fixtures = 'test/fixtures/e2e';

void main() {
  late String executable;

  setUpAll(() async {
    final Directory compiled = await Directory.systemTemp.createTemp(
      'swagger_e2e_cli_',
    );
    addTearDown(() => compiled.delete(recursive: true));
    executable = p.join(compiled.path, 'cli.dill');
    final Uri library = (await Isolate.resolvePackageUri(
      Uri.parse('package:swagger_parser/swagger_parser.dart'),
    ))!;
    final ProcessResult result = await Process.run(
      Platform.resolvedExecutable,
      [
        'compile',
        'kernel',
        library.resolve('../bin/swagger_parser.dart').toFilePath(),
        '-o',
        executable,
        '--packages=${(await Isolate.packageConfig)!.toFilePath()}',
      ],
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });

  final List<File> manifests =
      Directory(_fixtures)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => p.basename(file.path) == 'cases.yaml')
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  if (manifests.isEmpty) {
    throw StateError('No e2e manifests in $_fixtures.');
  }
  for (final manifest in manifests) {
    final Directory scenario = manifest.parent;
    final cases =
        (loadYaml(manifest.readAsStringSync()) as YamlMap)['cases'] as YamlList;
    if (cases.isEmpty) {
      throw StateError('No cases in ${manifest.path}.');
    }
    group(p.relative(scenario.path, from: _fixtures), () {
      for (final YamlMap entry in cases.cast<YamlMap>()) {
        test(entry['name'] as String, () async {
          final Directory work = await Directory.systemTemp.createTemp(
            'swagger_e2e_',
          );
          addTearDown(() => work.delete(recursive: true));
          for (final folder in ['inputs', 'configs']) {
            final source = Directory(p.join(scenario.path, folder));
            await for (final File file
                in source
                    .list(recursive: true, followLinks: false)
                    .where((entity) => entity is File)
                    .cast<File>()) {
              final target = File(
                p.join(work.path, p.relative(file.path, from: scenario.path)),
              );
              await target.parent.create(recursive: true);
              await file.copy(target.path);
            }
          }
          final ProcessResult result = await Process.run(
            Platform.resolvedExecutable,
            [executable, '-f', entry['config'] as String],
            workingDirectory: work.path,
          );
          expect(
            result.exitCode,
            0,
            reason: '${result.stdout}\n${result.stderr}',
          );
          expect(result.stderr, isEmpty, reason: 'Unexpected diagnostics.');

          final expected = <String, String>{};
          final outputs = entry['expected'] as YamlMap;
          expect(outputs, isNotEmpty);
          for (final MapEntry<String, YamlList> output
              in outputs.cast<String, YamlList>().entries) {
            for (final String layer in output.value.cast<String>()) {
              final directory = Directory(p.join(scenario.path, layer));
              final Map<String, String> files = await _readFiles(directory);
              expect(files, isNotEmpty, reason: directory.path);
              for (final MapEntry<String, String> file in files.entries) {
                expect(file.key, endsWith('.golden'), reason: directory.path);
                final String path = p.posix.join(
                  output.key,
                  file.key.substring(0, file.key.length - '.golden'.length),
                );
                expect(expected, isNot(contains(path)), reason: path);
                expected[path] = file.value;
              }
            }
          }
          final Map<String, String> actual = await _readFiles(
            Directory(p.join(work.path, entry['output'] as String)),
          );
          expect(
            actual.keys.toList()..sort(),
            expected.keys.toList()..sort(),
            reason: 'Generated file set differs.',
          );
          for (final String path in expected.keys.toList()..sort()) {
            expect(
              actual[path],
              expected[path],
              reason: 'Generated file: $path',
            );
          }
        });
      }
    });
  }
}

Future<Map<String, String>> _readFiles(Directory directory) async => {
  await for (final FileSystemEntity entity in directory.list(
    recursive: true,
    followLinks: false,
  ))
    if (entity is File)
      p.split(p.relative(entity.path, from: directory.path)).join('/'):
          await entity.readAsString(),
};
