@TestOn('vm')
@Timeout(Duration(minutes: 12))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/naming_contracts_driver.dart';
import 'support/test_platforms.dart';

void main() {
  test('builds wire names and collisions with every serializer and HTTP client', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_naming_contracts_');
    addTearDown(() => dir.delete(recursive: true));
    Future<void> write(String path, String text) async {
      final file = File('${dir.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString(text);
    }

    Future<void> dart(List<String> args) async {
      final ProcessResult result = await Process.run(
        Platform.resolvedExecutable,
        args,
      );
      stdout.writeln(
        '${args.join(' ')}: ${(result.stdout as String).trim().split('\n').last}',
      );
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    }

    await write(
      'analysis_options.yaml',
      'analyzer:\n  language:\n    strict-casts: true\n',
    );
    const loader = FileSchemaSourceLoader();
    final folders = <String>[];
    for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
      for (final DtoSerializer serializer in DtoSerializer.values) {
        for (final HttpClientBackend backend in HttpClientBackend.values) {
          for (final enabled in [false, true]) {
            final folder =
                '${version}_${serializer.name}_${backend.name}_$enabled';
            folders.add(folder);
            Map<String, String>? expected;
            late DartGenerationModel mapped;
            for (final ext in ['json', 'yaml']) {
              final fixture = 'naming/contracts/$version.$ext';
              final mapper = _Mapper();
              final GenerationResult result =
                  await SwaggerParserRunner(mapper: mapper).generate(
                    await loader.loadPath(
                      '../swagger_parser/test/fixtures/$fixture',
                    ),
                    loader: loader,
                    config: GenerationConfig(
                      serializer: serializer,
                      httpClient: backend,
                      unknownEnumValues: enabled
                          ? UnknownValueMode.preserve
                          : UnknownValueMode.reject,
                      fallbackClientName: 'Api',
                      naming: enabled ? _naming : const NamingConfig(),
                    ),
                  );
              expect(result.diagnostics, isEmpty);
              mapped = mapper.model;
              final Map<String, String> files = {
                for (final file in result.files)
                  file.relativePath: file.content,
              };
              expected ??= files;
              expect(files, expected);
            }
            for (final MapEntry<String, String> file in expected!.entries) {
              await write('$folder/${file.key}', file.value);
            }
            await write(
              '${folder}_checks.dart',
              namingContractsDriver(
                folder,
                backend,
                serializer,
                mapped,
                enabled: enabled,
                values: await File(
                  '../swagger_parser/test/fixtures/naming/contracts/values.json',
                ).readAsString(),
                models: await File(
                  '../swagger_parser/test/fixtures/naming/contracts/models.json',
                ).readAsString(),
                words: await File(
                  '../swagger_parser/test/fixtures/naming/contracts/words.json',
                ).readAsString(),
              ),
            );
          }
        }
      }
    }
    await write(
      'checks_test.dart',
      [
        "import 'package:test/test.dart';",
        for (final (i, folder) in folders.indexed)
          "import '${folder}_checks.dart' as check$i;",
        'void main() {',
        for (final (i, folder) in folders.indexed)
          "group('$folder', check$i.main);",
        '}',
      ].join('\n'),
    );
    await dart(['run', 'build_runner', 'build']);
    await dart(['analyze', dir.path]);
    await dart(['test', '${dir.path}/checks_test.dart']);
    if (runChromeTests) {
      await dart(['test', '--platform=chrome', '${dir.path}/checks_test.dart']);
    }
  });
}

const _naming = NamingConfig(
  replaceRules: [
    NameReplacementRule(
      target: NamingTarget.models,
      pattern: r'^Already$',
      replacement: 'AlreadyDto',
    ),
    NameReplacementRule(
      target: NamingTarget.models,
      pattern: r'^(WireDto|Words|UserJWTPair)$',
      replacement: 'Renamed',
    ),
  ],
);

final class _Mapper() implements DartModelMapper {
  late DartGenerationModel model;
  @override
  DartGenerationModel map(ApiDefinition api, GenerationConfig config) =>
      model = const DartModelMapper().map(api, config);
}
