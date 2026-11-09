@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/src/cli/output_paths.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _fixtures = 'test/fixtures/inputs';

void main() {
  test('inherits fields and replaces lists in JSON and YAML inputs', () async {
    for (final ext in ['json', 'yaml']) {
      final List<CliConfig> configs = await CliConfig.loadAll(
        configPath: '$_fixtures/config.$ext',
      );
      expect(configs.map((c) => c.inputId), [
        'legacy',
        'current',
        'modern',
        'latest',
      ]);
      final [legacy, current, modern, latest] = configs;
      expect(legacy.generation.decodeResponsesInBackground, isTrue);
      expect(current.generation.decodeResponsesInBackground, isFalse);
      expect(modern.generation.decodeResponsesInBackground, isTrue);
      expect(latest.generation.decodeResponsesInBackground, isTrue);
      expect(configs.map((c) => c.parse.maxDepth), everyElement(64));
      expect(configs.map((c) => c.generation.pageWidth), everyElement(90));
      expect(legacy.generation.httpClient, HttpClientBackend.retrofit);
      expect(current.generation.httpClient, HttpClientBackend.dio);
      expect(modern.generation.httpClient, HttpClientBackend.http);
      expect(latest.generation.httpClient, HttpClientBackend.http);
      expect(legacy.generation.generateDocs, isTrue);
      expect(current.generation.generateDocs, isFalse);
      expect(current.parse.captureSourceLocations, isFalse);
      expect(modern.parse.captureSourceLocations, isTrue);
      expect(current.normalize.explicitParameterSerialization, isFalse);
      expect(modern.normalize.explicitParameterSerialization, isTrue);
      expect(current.generation.operationFilters.includePaths, isNull);
      expect(current.generation.operationFilters.excludeTags, isEmpty);
      expect(modern.generation.operationFilters.includePaths, ['/stations/**']);
      expect(modern.generation.operationFilters.excludeTags, ['Internal']);
      expect(latest.generation.serializer, DtoSerializer.jsonSerializable);
      expect(modern.generation.serializer, DtoSerializer.plain);
      expect(latest.generation.rootApiClassName, 'LatestApi');
      expect(modern.generation.rootApiClassName, 'Api');
      expect(legacy.output, p.absolute('$_fixtures/out/legacy'));
      expect(latest.output, p.absolute('$_fixtures/custom/latest'));
      expect(current.input, File('$_fixtures/stations_v3_0.json').absolute.uri);
      final List<CliConfig> defaults = await CliConfig.loadAll(
        configPath: '$_fixtures/default_output.$ext',
      );
      expect(
        defaults.first.output,
        p.absolute('$_fixtures/lib/generated/legacy'),
      );
      final CliConfig empty = await CliConfig.load(
        configPath: '$_fixtures/empty_selection.$ext',
      );
      expect(empty.generation.operationFilters.includePaths, isEmpty);
      expect(empty.generation.operationFilters.excludeTags, ['Internal']);
      final CliConfig single = await CliConfig.load(
        configPath: '$_fixtures/single_old.$ext',
      );
      expect(single.inputId, isNull);
      expect(single.generation.decodeResponsesInBackground, isFalse);
      expect(single.generation.httpClient, HttpClientBackend.dio);
    }
  });

  test('rejects ambiguous input config and output roots', () async {
    for (final ext in ['json', 'yaml']) {
      for (final name in [
        'same',
        'nested',
        'normalized',
        'empty',
        'list',
        'null',
        'id',
        'source',
        'mixed',
        'source_conflict',
      ]) {
        await expectLater(
          CliConfig.loadAll(configPath: '$_fixtures/bad_$name.$ext'),
          throwsA(isA<FormatException>()),
          reason: name,
        );
      }
      await expectLater(
        CliConfig.load(configPath: '$_fixtures/config.$ext'),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        CliConfig.loadAll(configPath: '$_fixtures/config.$ext', output: 'one'),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        CliConfig.loadAll(
          configPath: '$_fixtures/config.$ext',
          schemaPath: 'one.yaml',
        ),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test('detects physical output aliases and invalid ancestors', () async {
    final Directory root = await Directory.systemTemp.createTemp(
      'input_roots_',
    );
    addTearDown(() => root.delete(recursive: true));
    final Directory real = await Directory(p.join(root.path, 'real')).create();
    final link = Link(p.join(root.path, 'alias'));
    await link.create(real.path);
    expect(
      () => validateOutputPaths({
        'one': p.join(real.path, 'output'),
        'two': p.join(link.path, 'output'),
      }),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => validateOutputPaths({
        'one': real.path,
        'two': p.join(link.path, 'nested'),
      }),
      throwsA(isA<FormatException>()),
    );
    validateOutputPaths({
      'one': p.join(real.path, 'one'),
      'two': p.join(link.path, 'two'),
    });
    if (Platform.isMacOS || Platform.isWindows) {
      expect(
        () => validateOutputPaths({
          'one': p.join(real.path, 'Output'),
          'two': p.join(real.path, 'output'),
        }),
        throwsA(isA<FormatException>()),
      );
    }
    final File file = await File(p.join(root.path, 'file'))
        .writeAsString('Keep.');
    expect(
      () => resolveOutputPath(p.join(file.path, 'output')),
      throwsA(isA<FileSystemException>()),
    );
    final broken = Link(p.join(root.path, 'broken'));
    await broken.create(p.join(root.path, 'missing'));
    expect(
      () => resolveOutputPath(p.join(broken.path, 'output')),
      throwsA(isA<FileSystemException>()),
    );
  });
}
