@TestOn('vm')
@Timeout(Duration(minutes: 2))
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  late Directory root;
  late Uri fixtures;
  late String bin;
  late String executable;

  Future<ProcessResult> run(List<String> arguments) => Process.run(
    Platform.resolvedExecutable,
    [executable, ...arguments],
    workingDirectory: root.path,
  );

  File file(String name) => File(p.join(root.path, name));

  Future<void> copy(String fixture, String destination) async {
    await file(destination).parent.create(recursive: true);
    await File.fromUri(fixtures.resolve(fixture)).copy(file(destination).path);
  }

  setUpAll(() async {
    final Uri lib = (await Isolate.resolvePackageUri(
      Uri.parse('package:swagger_parser/swagger_parser.dart'),
    ))!;
    fixtures = lib.resolve('../test/fixtures/');
    bin = lib.resolve('../bin/swagger_parser.dart').toFilePath();
    final Directory compiled = await Directory.systemTemp.createTemp(
      'swagger_cli_kernel_',
    );
    addTearDown(() => compiled.delete(recursive: true));
    executable = p.join(compiled.path, 'cli.dill');
    final ProcessResult result = await Process.run(
      Platform.resolvedExecutable,
      [
        'compile',
        'kernel',
        bin,
        '-o',
        executable,
        '--packages=${(await Isolate.packageConfig)!.toFilePath()}',
      ],
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });
  setUp(() async {
    root = await Directory.systemTemp.createTemp('swagger_cli_');
    addTearDown(() => root.delete(recursive: true));
  });

  Future<void> copyInputs() async {
    final source = Directory.fromUri(fixtures.resolve('inputs/'));
    await for (final FileSystemEntity entity in source.list()) {
      if (entity is File) {
        await entity.copy(file(p.basename(entity.path)).path);
      }
    }
  }

  Future<Map<String, String>> generatedSnapshot() async => {
    await for (final entity in root.list(recursive: true))
      if (entity is File && entity.path.endsWith('.dart'))
        p.relative(entity.path, from: root.path): await entity.readAsString(),
  };

  test('reads explicit inputs without scanning neighboring files', () async {
    for (final ext in ['json', 'yaml']) {
      await copy('references/v3_2.$ext', 'v3_2.$ext');
      await copy('references/v3_2_targets.$ext', 'v3_2_targets.$ext');
      await copy('cli/reference_input.$ext', 'config.$ext');
      final String config = await file('config.$ext').readAsString();
      for (final serializer in [
        'plain',
        'json_serializable',
        'freezed',
        'dart_mappable',
      ]) {
        final String configured = ext == 'json'
            ? config.replaceFirst(
                '"http_client": "dio"',
                '"http_client": "dio", "serializer": "$serializer"',
              )
            : '$config  "serializer": "$serializer"\n';
        await file('config.$ext').writeAsString(configured);
        final args = ['-f', 'config.$ext'];
        final ProcessResult before = await run(args);
        expect(
          before.exitCode,
          0,
          reason: '${before.stdout}\n${before.stderr}',
        );
        final Map<String, String> expected = await generatedSnapshot();
        expect(expected.keys, contains('out/api.dart'));
        for (final name in [
          '.DS_Store',
          '.hidden.json',
          '.hidden.yaml',
          'unrelated.json',
          'unrelated.yaml',
        ]) {
          await file(name).writeAsString('This is not a schema.');
        }
        final ProcessResult after = await run(args);
        expect(after.exitCode, 0, reason: '${after.stdout}\n${after.stderr}');
        expect(await generatedSnapshot(), expected);
        for (final name in [
          '.DS_Store',
          '.hidden.json',
          '.hidden.yaml',
          'unrelated.json',
          'unrelated.yaml',
        ]) {
          await file(name).delete();
        }
      }
    }
  });

  test(
    'runs inherited input configs without replacing sibling outputs',
    () async {
      await copyInputs();
      for (final ext in ['json', 'yaml']) {
        final args = ['-f', 'config.$ext'];
        final ProcessResult result = await run(args);
        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );
        final Map<String, String> before = await generatedSnapshot();
        expect(
          before.keys,
          containsAll([
            'out/legacy/api.dart',
            'out/current/api.dart',
            'out/modern/api.dart',
            'custom/latest/latest_api.dart',
            'out/legacy/exports.dart',
            'out/current/exports.dart',
            'out/modern/exports.dart',
          ]),
        );
        expect(
          before['out/legacy/stations/stations_client.dart'],
          contains('@GET('),
        );
        expect(
          before['out/current/stations/stations_client.dart'],
          isNot(contains('@GET(')),
        );
        expect(
          before['out/modern/stations/stations_client.dart'],
          contains('package:http/'),
        );
        expect(
          before['out/current/default_client/api_client.dart'],
          contains('getHealth('),
        );
        expect(
          before.keys,
          isNot(contains('out/modern/default_client/api_client.dart')),
        );
        expect(
          before['custom/latest/stations/models/station.dart'],
          contains('@JsonSerializable'),
        );
        expect((await run(args)).exitCode, 0);
        expect(await generatedSnapshot(), before);
        expect((await run(['--check', ...args])).exitCode, 0);
        expect((await run(['validate', ...args])).exitCode, 0);
        expect(result.stdout.toString(), contains('[legacy] Generated'));
        expect(result.stdout.toString(), contains('[latest] Generated'));
        await file('out/modern/api.dart')
            .writeAsString('// Drift.\n', mode: FileMode.append);
        final ProcessResult drift = await run(['--check', ...args]);
        expect(drift.exitCode, 1);
        expect(drift.stderr.toString(), contains('[modern] Changed: api.dart'));
        expect((await run(args)).exitCode, 0);
      }
    },
  );

  test('leaves all outputs unchanged when a later input fails', () async {
    await copyInputs();
    expect((await run(['-f', 'config.yaml'])).exitCode, 0);
    final Map<String, String> before = await generatedSnapshot();
    final String original = await file('stations_v2_0.yaml').readAsString();
    await file('stations_v2_0.yaml').writeAsString(
      original.replaceFirst('Get a station.', 'Read the updated station.'),
    );
    for (final ext in ['json', 'yaml']) {
      final ProcessResult result = await run(['-f', 'generation_failure.$ext']);
      expect(result.exitCode, 1);
      expect(result.stderr.toString(), contains('[latest]'));
      expect(await generatedSnapshot(), before);
    }
    await file('out/legacy/api.dart')
        .writeAsString('// Keep drift.\n', mode: FileMode.append);
    final Map<String, String> drift = await generatedSnapshot();
    await file('custom/latest/stations/stations_client.dart')
        .writeAsString('User file.');
    final ProcessResult conflict = await run(['-f', 'config.yaml']);
    expect(conflict.exitCode, 1);
    expect(conflict.stderr.toString(), contains('[latest]'));
    expect(
      await file('out/legacy/api.dart').readAsString(),
      drift['out/legacy/api.dart'],
    );
    expect(
      await file('custom/latest/stations/stations_client.dart').readAsString(),
      'User file.',
    );
  });

  test('rejects overlapping input destinations before writing files', () async {
    await copyInputs();
    for (final ext in ['json', 'yaml']) {
      for (final name in ['same', 'nested', 'normalized']) {
        final ProcessResult result = await run(['-f', 'bad_$name.$ext']);
        expect(result.exitCode, 64);
        expect(result.stderr.toString(), contains('overlap'));
        expect(await generatedSnapshot(), isEmpty);
      }
    }
    await Directory(p.join(root.path, 'same')).create();
    await Link(p.join(root.path, 'alias')).create(p.join(root.path, 'same'));
    final String config = await file('bad_same.json').readAsString();
    await file('aliased.json').writeAsString(
      config.replaceFirst(
        '"output_directory": "same"',
        '"output_directory": "alias"',
      ),
    );
    final ProcessResult alias = await run(['-f', 'aliased.json']);
    expect(alias.exitCode, 64);
    expect(await generatedSnapshot(), isEmpty);
  });

  test(
    'keeps remote batch copies distinct and resolves relative references',
    () async {
      await copyInputs();
      final HttpServer server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      addTearDown(() => server.close(force: true));
      final requested = <String>[];
      final List<int> first = await file('stations_v2_0.json').readAsBytes();
      final List<int> second = await file('remote_entry.json').readAsBytes();
      final List<int> paths = await file('remote_paths.json').readAsBytes();
      server.listen((request) async {
        requested.add(request.uri.path);
        request.response.headers.contentType = ContentType.json;
        switch (request.uri.path) {
          case '/first/openapi.json':
            request.response.add(first);
          case '/second/openapi.json':
            request.response.add(second);
          case '/second/paths.json':
            request.response.add(paths);
          default:
            request.response.statusCode = HttpStatus.notFound;
        }
        await request.response.close();
      });
      for (final ext in ['json', 'yaml']) {
        final String template = await file('remote.$ext').readAsString();
        await file('remote_config.$ext')
            .writeAsString(template.replaceAll('PORT', '${server.port}'));
        final args = ['-f', 'remote_config.$ext'];
        final ProcessResult result = await run(args);
        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );
        expect(await file('first_openapi.json').readAsBytes(), first);
        expect(await file('second_openapi.json').readAsBytes(), second);
        expect(requested, contains('/second/paths.json'));
        expect(file('remote_out/first/exports.dart').existsSync(), isTrue);
        expect(file('remote_out/second/exports.dart').existsSync(), isTrue);
        await file('first_openapi.json').delete();
        await file('second_openapi.json').delete();
        expect((await run(['validate', ...args])).exitCode, 0);
        expect((await run(['--check', ...args])).exitCode, 0);
        expect(file('first_openapi.json').existsSync(), isFalse);
        expect(file('second_openapi.json').existsSync(), isFalse);
      }
    },
  );

  test('filters operations from JSON and YAML CLI config', () async {
    await copy('operation_filters/routes_v3_2.yaml', 'routes_v3_2.yaml');
    for (final ext in ['json', 'yaml']) {
      await copy('operation_filters/config.$ext', 'config.$ext');
      final ProcessResult result = await run(['-f', 'config.$ext', '-o', ext]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(file('$ext/stations/stations_client.dart').existsSync(), isTrue);
      expect(file('$ext/trips/trips_client.dart').existsSync(), isFalse);
      expect(file('$ext/internal/internal_client.dart').existsSync(), isFalse);
      expect(file('$ext/models/unused_enum.dart').existsSync(), isTrue);
      expect(file('$ext/stations/models/status.dart').existsSync(), isTrue);
    }
  });

  test('generates unknown-value policies from JSON and YAML config', () async {
    await copy('unknown_values/unknown_v3_2.yaml', 'unknown_v3_2.yaml');
    for (final ext in ['json', 'yaml']) {
      for (final mode in ['reject', 'preserve']) {
        await copy('unknown_values/config_$mode.$ext', 'config.$ext');
        final ProcessResult result = await run(['-f', 'config.$ext']);
        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );
        final List<File> generated =
            await Directory(p.join(root.path, 'output'))
                .list(recursive: true)
                .where((entry) => entry is File && entry.path.endsWith('.dart'))
                .cast<File>()
                .toList();
        final String source = (await Future.wait(
          generated.map((entry) => entry.readAsString()),
        )).join();
        expect(source.contains('class StatusUnknown'), mode == 'preserve');
        expect(source.contains('class StopUnknown'), mode == 'preserve');
      }
    }
  });

  test('uses core parse options for entry and referenced documents', () async {
    await copy('cli/parse_entry.yaml', 'parse_entry.yaml');
    await copy('cli/parse_library.json', 'parse_library.json');

    Future<ProcessResult> validate(String input, [String options = '']) async {
      await file('swagger_parser.yaml').writeAsString(
        'schema_path: $input\n${options.isEmpty ? '' : 'parse:\n$options\n'}',
      );
      return await run(['validate']);
    }

    for (final input in ['parse_library.json', 'parse_entry.yaml']) {
      final ProcessResult defaults = await validate(input);
      expect(defaults.exitCode, 0, reason: defaults.stderr.toString());

      const strict = '  unknown_fields: reject';
      final ProcessResult located = await validate(input, strict);
      expect(located.exitCode, 1);
      expect(
        located.stderr.toString(),
        contains('parse_library.json:6:14#/info/extra'),
      );

      final ProcessResult unlocated = await validate(
        input,
        '$strict\n  capture_source_locations: false',
      );
      expect(unlocated.exitCode, 1);
      expect(
        unlocated.stderr.toString(),
        contains('parse_library.json#/info/extra'),
      );

      final ProcessResult limited = await validate(input, '  max_depth: 5');
      expect(limited.exitCode, 1);
      expect(limited.stderr.toString(), contains('parse_library.json:14:26'));
      expect(
        limited.stderr.toString(),
        contains('Maximum nesting depth exceeded.'),
      );
    }
  });

  test('generates renamed libraries from JSON and YAML configs', () async {
    await copy('naming/naming_v3_2.yaml', 'naming_v3_2.yaml');
    for (final extension in ['json', 'yaml']) {
      await copy('naming/config.$extension', 'config.$extension');
      final ProcessResult result = await run(['-f', 'config.$extension']);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(
        await file('lib/generated/stations/stations_client.dart')
            .readAsString(),
        contains('Future<Station?> getStation('),
      );
      expect(
        await file('lib/generated/default_client/common_client.dart')
            .readAsString(),
        contains('class CommonClient'),
      );
      expect(
        await file('lib/generated/models/k_user_status.dart').readAsString(),
        contains('enum kUserStatus'),
      );
      final ProcessResult checked = await run([
        '--check',
        '-f',
        'config.$extension',
      ]);
      expect(checked.exitCode, 0, reason: checked.stderr.toString());
    }
  });

  test('formats the same DTO at two configured page widths', () async {
    await copy('extraction/open_api_v3_2.yaml', 'entry.yaml');
    Future<String> render(int width) async {
      await file('swagger_parser.yaml').writeAsString(
        'schema_path: entry.yaml\ngeneration:\n  page_width: $width\n',
      );
      final ProcessResult result = await run(['-o', 'out']);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      return await file('out/default_client/models/station.dart')
          .readAsString();
    }

    expect(await render(45), contains('const Station({\n'));
    expect(
      await render(120),
      contains('const Station({required this.id, this.parent,'),
    );
    await file('swagger_parser.yaml')
        .writeAsString('input: entry.yaml\ngeneration:\n  page_width: 0\n');
    final ProcessResult invalid = await run([]);
    expect(invalid.exitCode, 64);
    expect(
      invalid.stderr.toString(),
      contains('generation.page_width must be positive'),
    );
  });

  test('selects the DTO serializer from config', () async {
    await copy('extraction/open_api_v3_2.yaml', 'entry.yaml');
    for (final (option, marker) in [
      ('jsonSerializable', '@JsonSerializable('),
      ('freezed', '@Freezed('),
      ('dartMappable', '@MappableClass('),
      ('plain', 'class Station'),
    ]) {
      await file('swagger_parser.yaml').writeAsString(
        'input: entry.yaml\ngeneration:\n  serializer: $option\n',
      );
      final ProcessResult result = await run(['-o', 'lib/generated']);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(
        await file('lib/generated/default_client/models/station.dart')
            .readAsString(),
        contains(marker),
      );
    }
  });

  test(
    'generates from a consumer package and resolves config-relative references',
    () async {
      final Uri core = (await Isolate.resolvePackageUri(
        Uri.parse('package:swagger_parser_core/swagger_parser_core.dart'),
      ))!;
      await file('pubspec.yaml').writeAsString('''
name: cli_consumer
environment:
  sdk: ^3.13.0
dependencies:
  swagger_parser:
    path: ${jsonEncode(p.dirname(p.dirname(bin)))}
dependency_overrides:
  swagger_parser_core:
    path: ${jsonEncode(core.resolve('../').toFilePath())}
''');
      await copy('cli/swagger_parser.yaml', 'config/settings.yaml');
      await copy('extraction/mounted.yaml', 'config/specs/mounted.yaml');
      await copy('extraction/library.json', 'config/specs/library.json');
      for (final args in [
        ['pub', 'get', '--offline'],
        ['run', 'swagger_parser', '-f', 'config/settings.yaml'],
      ]) {
        final ProcessResult result = await Process.run(
          Platform.resolvedExecutable,
          args,
          workingDirectory: root.path,
        );
        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );
      }
      final String packages = await file('.dart_tool/package_config.json')
          .readAsString();
      expect(packages, isNot(contains('"mustache_template"')));
      expect(packages, isNot(contains('"swagger_parser_templates"')));
      expect(
        await file('config/generated/default_client/api_client.dart')
            .readAsString(),
        contains('package:http/http.dart'),
      );
      expect(
        await file('config/generated/default_client/api_client_results.dart')
            .readAsString(),
        contains('sealed class'),
      );
      expect(
        await file('config/generated/default_client/models/station.dart')
            .readAsString(),
        contains('class Station'),
      );
      await file('config/specs/library.json').delete();
      final ProcessResult failed = await run(['-f', 'config/settings.yaml']);
      expect(failed.exitCode, 1);
      expect(failed.stderr.toString(), contains('library.json'));
    },
  );

  test(
    'produces identical files for JSON and YAML and preserves user files',
    () async {
      await copy('extraction/open_api_v3_2.yaml', 'api.yaml');
      await copy('extraction/open_api_v3_2.json', 'api.json');
      await file('pubspec.yaml')
          .writeAsString('swagger_parser:\n  input: api.yaml\n  output: out\n');
      final ProcessResult first = await run([]);
      expect(first.exitCode, 0, reason: first.stderr.toString());
      final String client = await file('out/default_client/api_client.dart')
          .readAsString();
      await file('out/extra.dart').writeAsString('user file');
      await copy('cli/swagger_parser.yaml', 'swagger_parser.yaml');
      final ProcessResult second = await run(['api.json', '-o', 'out']);
      expect(second.exitCode, 0, reason: second.stderr.toString());
      expect(
        file('out/default_client/api_client_results.dart').existsSync(),
        isTrue,
      );
      await file('swagger_parser.yaml').delete();
      await copy('cli/config.json', 'settings.json');
      final ProcessResult third = await run(['--file', 'settings.json']);
      expect(third.exitCode, 0, reason: third.stderr.toString());
      expect(
        await file('out/default_client/api_client.dart').readAsString(),
        client,
      );
      expect(
        file('out/default_client/api_client_results.dart').existsSync(),
        isFalse,
      );
      expect(await file('out/extra.dart').readAsString(), 'user file');

      await file('out/default_client/models/station.dart')
          .writeAsString('user model');
      final ProcessResult collision = await run(['api.json']);
      expect(collision.exitCode, 1);
      expect(collision.stderr.toString(), contains('station.dart'));
      expect(
        await file('out/default_client/models/station.dart').readAsString(),
        'user model',
      );
      expect(
        await file('out/default_client/api_client.dart').readAsString(),
        client,
      );
    },
  );

  test('reports warnings and serializes concurrent output updates', () async {
    await copy('cli/warnings.yaml', 'filter.yaml');
    final ProcessResult warned = await run(['filter.yaml', '-o', 'out']);
    expect(warned.exitCode, 0, reason: warned.stderr.toString());
    expect(
      warned.stderr.toString(),
      contains(
        'filter.yaml#/paths/~1stations/get/parameters/0 warning [unsupportedClientOperation]',
      ),
    );
    await copy('extraction/models_only.yaml', 'models.yaml');
    await copy('extraction/open_api_v3_2.json', 'stations.json');
    final List<ProcessResult> results = await Future.wait([
      run(['stations.json', '-o', 'out']),
      run(['models.yaml', '-o', 'out']),
    ]);
    for (final r in results) {
      expect(r.exitCode, 0, reason: r.stderr.toString());
    }
    final bool hasClient = file('out/default_client/api_client.dart')
        .existsSync();
    expect(
      file('out/default_client/models/station.dart').existsSync(),
      hasClient,
    );
    expect(file('out/models/reading.dart').existsSync(), !hasClient);
  });

  test('loads scalar mappings from config and writes public exports', () async {
    await copy('type_mappings/mapped_v3_2.yaml', 'mapped_v3_2.yaml');
    await copy('type_mappings/config_v3_2.yaml', 'swagger_parser.yaml');
    final ProcessResult result = await run([]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    final String exports = await file('lib/generated/exports.dart')
        .readAsString();
    expect(exports, contains('custom_types.dart'));
    expect(exports, isNot(contains('custom_codecs.dart')));
    final String source = await file(
      'lib/generated/default_client/models/station.dart',
    ).readAsString();
    expect(source, contains('mapped1.StationId'));
    expect(source, contains('mapped2.stationIdFromJson'));
  });

  test(
    'loads object mappings and constants from JSON and YAML config',
    () async {
      for (final ext in ['json', 'yaml']) {
        await copy('object_mappings/objects_v3_2.$ext', 'objects_v3_2.$ext');
        await copy('object_mappings/config_v3_2.$ext', 'settings.$ext');
        final ProcessResult result = await run(['-f', 'settings.$ext']);
        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );
        final String model = await file(
          'lib/generated/default_client/models/station.dart',
        ).readAsString();
        expect(model, contains('mapped3.origin'));
        expect(model, contains('mapped3.unknownStationId'));
        expect(
          await file('lib/generated/exports.dart').readAsString(),
          isNot(contains('object_defaults.dart')),
        );
      }
    },
  );

  test('loads directional mappings from JSON and YAML config', () async {
    for (final ext in ['json', 'yaml']) {
      await copy(
        'directional_mappings/directional_v3_2.yaml',
        'directional_v3_2.yaml',
      );
      await copy('directional_mappings/config_v3_2.$ext', 'settings.$ext');
      final ProcessResult result = await run(['-f', 'settings.$ext']);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      final List<FileSystemEntity> files =
          await Directory('${root.path}/lib/generated')
              .list(recursive: true)
              .where((e) => e is File && e.path.endsWith('.dart'))
              .toList();
      final String source = (await Future.wait(
        files.map((e) => File(e.path).readAsString()),
      )).join();
      expect(source, contains('mapped1.CreateStation'));
      expect(source, contains('mapped1.Station'));
      expect(source, contains(r'Envelope$Request'));
      expect(source, contains(r'Envelope$Response'));
    }
  });

  test('validates external path items without generating Dart files', () async {
    await copy('cli/invalid_mount.yaml', 'api.yaml');
    await copy('extraction/library.json', 'library.json');
    final ProcessResult invalid = await run(['validate', 'api.yaml']);
    expect(invalid.exitCode, 1);
    expect(invalid.stderr.toString(), contains('[missingPathParameter]'));
    await copy('extraction/mounted.yaml', 'api.yaml');
    final ProcessResult valid = await run([
      'validate',
      '--schema_path',
      'api.yaml',
    ]);
    expect(valid.exitCode, 0, reason: valid.stderr.toString());
    await copy('cli/warnings.yaml', 'unsupported.yaml');
    final ProcessResult skipped = await run(['validate', 'unsupported.yaml']);
    expect(skipped.exitCode, 0);
    expect(skipped.stderr, isEmpty);
    await file('library.json').delete();
    final ProcessResult unresolved = await run(['validate', 'api.yaml']);
    expect(unresolved.exitCode, 1);
    expect(unresolved.stderr.toString(), contains('library.json'));
    expect(Directory(p.join(root.path, 'lib')).existsSync(), isFalse);
    expect((await run(['validate', '--check', 'api.yaml'])).exitCode, 64);
  });

  test(
    'checks missing, changed, obsolete, and conflicting output without writing',
    () async {
      await copy('extraction/open_api_v3_2.json', 'api.json');
      await copy('cli/config.json', 'settings.json');
      const args = ['-f', 'settings.json'];
      final ProcessResult missing = await run([...args, '--check']);
      expect(missing.exitCode, 1);
      expect(
        missing.stderr.toString(),
        contains('Missing: default_client/api_client.dart'),
      );
      expect(Directory(p.join(root.path, 'out')).existsSync(), isFalse);
      expect((await run(args)).exitCode, 0);
      await file('out/extra.dart').writeAsString('user file');
      await file('out/default_client/api_client.g.dart')
          .writeAsString('// GENERATED CODE');
      final File lock = file('out/.swagger_parser.lock');
      await lock.delete();
      final ProcessResult clean = await run([...args, '--check']);
      expect(clean.exitCode, 0, reason: clean.stderr.toString());
      final File model = file('out/default_client/models/station.dart');
      final String original = await model.readAsString();
      await file('out/old.dart').writeAsString(original);
      await model.writeAsString('${original}extra');
      await file('out/default_client/api_client.dart')
          .writeAsString('user client');
      final ProcessResult drift = await run([...args, '--check']);
      expect(drift.exitCode, 1);
      expect(drift.stderr.toString().trim().split('\n'), [
        'Conflict: default_client/api_client.dart',
        'Changed: default_client/models/station.dart',
        'Obsolete: old.dart',
      ]);
      expect(await model.readAsString(), '${original}extra');
      expect(await file('out/old.dart').readAsString(), original);
      expect(
        await file('out/default_client/api_client.dart').readAsString(),
        'user client',
      );
      expect(lock.existsSync(), isFalse);
    },
  );

  test(
    'renames the facade and keeps nested output inside the target',
    () async {
      await copy('extraction/open_api_v3_2.yaml', 'entry.yaml');
      await file('swagger_parser.yaml').writeAsString(
        'schema_path: entry.yaml\noutput_directory: out\ngeneration:\n  root_api_class_name: TransitApi\n  http_client: dio\n  response_mode: first_success\n',
      );
      expect((await run([])).exitCode, 0);
      expect(
        await file('out/transit_api.dart').readAsString(),
        contains('class TransitApi'),
      );
      expect((await run(['--check'])).exitCode, 0);
      await run(['-f', 'swagger_parser.yaml', '-o', 'other']);
      await file('swagger_parser.yaml')
          .writeAsString('input: entry.yaml\noutput: out\n');
      expect((await run([])).exitCode, 0);
      expect(file('out/api.dart').existsSync(), isTrue);
      expect(file('out/transit_api.dart').existsSync(), isFalse);

      await Directory(file('unsafe').path).create();
      await Link(file('unsafe/default_client').path)
          .create(file('other/default_client').absolute.path);
      expect((await run(['-o', 'unsafe'])).exitCode, 1);
      expect((await run(['-o', 'unsafe', '--check'])).exitCode, 1);
      expect(file('unsafe/api.dart').existsSync(), isFalse);
      await file('swagger_parser.yaml').writeAsString(
        'input: entry.yaml\ngeneration:\n  root_api_class_name: Exports\n',
      );
      expect((await run([])).exitCode, 64);
    },
  );

  test('loads wrapped configs and accepts legacy path options', () async {
    await copy('cli/legacy_config.yaml', 'swagger_parser.yaml');
    await copy('extraction/open_api_v3_2.yaml', 'specs/stations.yaml');
    await copy('extraction/models_only.yaml', 'models.yaml');
    await file('pubspec.yaml')
        .writeAsString('name: app\nswagger_parser:\n  input: missing.yaml\n');
    final ProcessResult configured = await run([]);
    expect(configured.exitCode, 0, reason: configured.stderr.toString());
    expect(
      file('generated/default_client/api_client.dart').existsSync(),
      isTrue,
    );
    final ProcessResult override = await run([
      '-f',
      'swagger_parser.yaml',
      '--schema_path',
      'models.yaml',
      '--output_directory',
      'models',
    ]);
    expect(override.exitCode, 0, reason: override.stderr.toString());
    expect(
      await file('models/models/reading.dart').readAsString(),
      contains('class Reading '),
    );
    final ProcessResult help = await run(['-h']);
    expect(help.exitCode, 0);
    expect(help.stdout.toString(), contains('--schema_url'));
  });

  test(
    'downloads the entry bytes and resolves references after a redirect',
    () async {
      final HttpServer server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      addTearDown(() => server.close(force: true));
      final Uri base = Uri.parse('http://127.0.0.1:${server.port}');
      final List<int> entry = await File.fromUri(
        fixtures.resolve('extraction/mounted.yaml'),
      ).readAsBytes();
      final List<int> library = await File.fromUri(
        fixtures.resolve('extraction/library.json'),
      ).readAsBytes();
      final List<int> json = await File.fromUri(
        fixtures.resolve('extraction/open_api_v3_2.json'),
      ).readAsBytes();
      final requested = <String>[];
      int libraryStatus = HttpStatus.ok;
      server.listen((request) async {
        requested.add(request.uri.toString());
        final HttpResponse response = request.response;
        switch (request.uri.path) {
          case '/latest':
            response.statusCode = HttpStatus.found;
            response.headers.set('Location', '/spec/stations.yaml?version=2');
          case '/spec/stations.yaml':
            response.add(entry);
          case '/spec/library.json':
            response
              ..statusCode = libraryStatus
              ..add(library);
          case '/pubspec.yaml':
            response.add(entry);
          case '/library.json':
            response.add(library);
          case '/api-docs':
            response.headers.contentType = ContentType.json;
            response.add(json);
          default:
            response.statusCode = HttpStatus.notFound;
        }
        await response.close();
      });
      final String template = await File.fromUri(
        fixtures.resolve('cli/legacy_url.yaml'),
      ).readAsString();
      await file('swagger_parser.yaml')
          .writeAsString(template.replaceFirst('PORT', server.port.toString()));
      final ProcessResult valid = await run(['validate']);
      expect(valid.exitCode, 0, reason: valid.stderr.toString());
      final ProcessResult unchecked = await run(['--check']);
      expect(unchecked.exitCode, 1);
      expect(
        unchecked.stderr.toString(),
        contains('Missing: default_client/models/station.dart'),
      );
      expect(file('stations.yaml').existsSync(), isFalse);
      expect(Directory(p.join(root.path, 'generated')).existsSync(), isFalse);
      final ProcessResult configured = await run([]);
      expect(configured.exitCode, 0, reason: configured.stderr.toString());
      expect(
        requested,
        containsAllInOrder([
          '/latest',
          '/spec/stations.yaml?version=2',
          '/spec/library.json',
        ]),
      );
      expect(await file('stations.yaml').readAsBytes(), entry);
      expect(file('library.json').existsSync(), isFalse);
      expect(
        await file('generated/default_client/models/station.dart')
            .readAsString(),
        contains('class Station '),
      );
      await file('stations.yaml').writeAsString('existing download');
      final ProcessResult checked = await run(['--check']);
      expect(checked.exitCode, 0, reason: checked.stderr.toString());
      expect(await file('stations.yaml').readAsString(), 'existing download');
      libraryStatus = HttpStatus.notFound;
      final ProcessResult brokenRef = await run([]);
      expect(brokenRef.exitCode, 1);
      expect(
        brokenRef.stderr.toString(),
        contains('/spec/library.json: HTTP 404'),
      );
      await file('swagger_parser.yaml').delete();
      for (final args in [
        ['--schema_url', '$base/api-docs', '-o', 'other'],
        ['$base/api-docs', '-o', 'other'],
      ]) {
        final ProcessResult downloaded = await run(args);
        expect(downloaded.exitCode, 0, reason: downloaded.stderr.toString());
        expect(await file('openapi.json').readAsBytes(), json);
      }
      final ProcessResult failed = await run([
        '--schema_url',
        '$base/missing/stations.yaml',
        '-o',
        'unused',
      ]);
      expect(failed.exitCode, 1);
      expect(failed.stderr.toString(), contains('HTTP 404'));
      expect(await file('stations.yaml').readAsBytes(), entry);
      expect(Directory(p.join(root.path, 'unused')).existsSync(), isFalse);
      await file('pubspec.yaml').writeAsString('name: consumer\n');
      final ProcessResult reserved = await run([
        '$base/pubspec.yaml',
        '-o',
        'other',
      ]);
      expect(reserved.exitCode, 0, reason: reserved.stderr.toString());
      expect(await file('pubspec.yaml').readAsString(), 'name: consumer\n');
      expect(await file('openapi.yaml').readAsBytes(), entry);
      final ProcessResult invalid = await run(['--schema_url', 'api.yaml']);
      expect(invalid.exitCode, 64);
    },
  );

  test('detects extensionless downloads independently of media headers', () async {
    final HttpServer server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      final String version = request.uri.queryParameters['version']!;
      final String format = request.uri.queryParameters['format']!;
      final String header = request.uri.queryParameters['header']!;
      if (header != 'missing') {
        request.response.headers.contentType = ContentType.parse(
          header == 'wrong'
              ? (format == 'json' ? 'application/yaml' : 'application/json')
              : (format == 'json' ? 'application/json' : 'application/yaml'),
        );
      }
      request.response.add(
        await File.fromUri(
          fixtures.resolve('collections/nullability/$version.$format'),
        ).readAsBytes(),
      );
      await request.response.close();
    });
    for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
      for (final format in ['json', 'yaml']) {
        for (final header in ['correct', 'missing', 'wrong']) {
          final url =
              'http://127.0.0.1:${server.port}/api-json?version=$version&format=$format&header=$header';
          final ProcessResult result = await run([url, '-o', 'generated']);
          expect(result.exitCode, 0, reason: result.stderr.toString());
          expect(
            await file('openapi.$format').readAsBytes(),
            await File.fromUri(
              fixtures.resolve('collections/nullability/$version.$format'),
            ).readAsBytes(),
          );
          expect(
            result.stdout.toString(),
            contains('Downloaded openapi.$format.'),
          );
          expect(file('generated/api.dart').existsSync(), isTrue);
        }
      }
    }
  });

  test(
    'reports missing inputs and invalid output destinations without a stack',
    () async {
      final ProcessResult missing = await run(['missing.yaml']);
      expect(missing.exitCode, 1);
      expect(missing.stderr.toString(), contains('missing.yaml'));
      expect(missing.stderr.toString(), isNot(contains('#0')));
      await copy('extraction/open_api_v3_2.yaml', 'schema.yaml');
      await file('occupied').writeAsString('user file');
      final ProcessResult blocked = await run([
        'schema.yaml',
        '-o',
        'occupied',
      ]);
      expect(blocked.exitCode, isNot(0));
      expect(await file('occupied').readAsString(), 'user file');
      for (final args in [
        ['-o'],
        ['-f'],
        ['--unknown'],
      ]) {
        final ProcessResult invalid = await run(args);
        expect(invalid.exitCode, 64);
        expect(invalid.stderr.toString(), isNot(contains('#0')));
      }
      for (final String output in ['relative', p.join(root.path, 'absolute')]) {
        final ProcessResult result = await run(['schema.yaml', '-o', output]);
        expect(result.exitCode, 0, reason: result.stderr.toString());
        expect(
          File(p.join(root.path, output, 'api.dart')).existsSync(),
          isTrue,
        );
      }
    },
  );

  test(
    'runs the documented default config and public library examples',
    () async {
      final String readme = await File.fromUri(
        fixtures.resolve('../../README.md'),
      ).readAsString();
      final String config = RegExp(r'```yaml\n(.*?)\n```', dotAll: true)
          .allMatches(readme)
          .map((match) => match.group(1)!)
          .singleWhere((block) {
            final Object? value = loadYaml(block);
            return value is YamlMap && value.containsKey('swagger_parser');
          });
      await file('swagger_parser.yaml').writeAsString(config);
      await copy('extraction/open_api_v3_2.yaml', 'api/stations.yaml');
      final ProcessResult generated = await run([]);
      expect(generated.exitCode, 0, reason: generated.stderr.toString());
      expect(file('lib/generated/api.dart').existsSync(), isTrue);
      for (final (example, output) in [
        (
          'example/swagger_parser_example.dart',
          'stations/stations_client.dart',
        ),
        (
          '../swagger_parser_core/example/swagger_parser_core_example.dart',
          '"swagger": "2.0"',
        ),
      ]) {
        final ProcessResult result = await Process.run(
          Platform.resolvedExecutable,
          [
            '--packages=${(await Isolate.packageConfig)!.toFilePath()}',
            example,
          ],
        );
        expect(result.exitCode, 0, reason: '$example: ${result.stderr}');
        expect(result.stdout.toString(), contains(output));
      }
    },
  );

  test('reports config and schema failures before writing output', () async {
    await copy('cli/invalid_config.json', 'bad.json');
    final ProcessResult config = await run(['-f', 'bad.json']);
    expect(config.exitCode, 64);
    expect(config.stderr.toString(), contains('generation.http_client'));
    final ProcessResult help = await run(['--help']);
    expect(help.exitCode, 0);
    expect(help.stdout.toString(), contains('--output'));
    await copy('cli/incomplete.json', 'invalid.json');
    final ProcessResult schema = await run(['invalid.json', '-o', 'out']);
    expect(schema.exitCode, 1);
    expect(
      schema.stderr.toString(),
      matches(RegExp(r'invalid\.json:\d+:\d+ error')),
    );
    expect(Directory(p.join(root.path, 'out')).existsSync(), isFalse);
  });
}
