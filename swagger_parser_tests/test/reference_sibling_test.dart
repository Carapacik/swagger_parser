@TestOn('vm')
@Timeout(Duration(minutes: 12))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/test_platforms.dart';

void main() {
  test('builds and decodes union reference chains with every serializer', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_reference_siblings_');
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
    for (final DtoSerializer serializer in DtoSerializer.values) {
      final String folder = serializer.name;
      folders.add(folder);
      final GenerationResult result = await const SwaggerParserRunner()
          .generate(
            await loader.loadPath(
              '../swagger_parser/test/fixtures/reference_siblings/object_union_v3_1.yaml',
            ),
            config: GenerationConfig(serializer: serializer),
          );
      expect(result.diagnostics, isEmpty);
      for (final GeneratedFile file in result.files) {
        await write('$folder/${file.relativePath}', file.content);
      }
      await write('${folder}_checks.dart', _driver(folder));
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

String _driver(String folder) =>
    '''
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:test/test.dart';

import '$folder/api.dart' as api;

Object? wire(Object? value) => jsonDecode(jsonEncode(value));

void main() {
  test('round trips typed properties through aliases and nested unions', () {
    for (final branch in [
      <String, dynamic>{'channel': 'events'},
      <String, dynamic>{'reason': 'closed'},
    ]) {
      final json = <String, dynamic>{
        'frame': branch, 'alias': branch, 'exclusive': branch, 'nested': branch,
      };
      final dto = api.Envelope.fromJson(json);
      final api.Frame frame = dto.alias.value.value;
      expect(wire(frame), branch);
      expect(wire(dto), json);
    }
  });
  test('keeps oneOf exclusivity through a typed reference', () {
    expect(
      () => api.ExclusiveAlias.fromJson({'channel': 'events', 'reason': 'closed'}),
      throwsFormatException,
    );
    expect(() => api.FrameAliasChain.fromJson('wrong type'), throwsFormatException);
  });
  test('decodes typed union responses through reference chains', () async {
    final adapter = Adapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    addTearDown(() => dio.close(force: true));
    final root = api.Api(dio);
    for (final branch in [
      <String, dynamic>{'channel': 'events'},
      <String, dynamic>{'reason': 'closed'},
    ]) {
      adapter.json = branch;
      expect(wire(await root.api.getFrame()), branch);
      final api.FrameAliasChain alias = await root.api.getAlias();
      expect(wire(alias.value.value), branch);
      expect(wire(await root.api.getExclusive()), branch);
      expect(wire(await root.api.getNested()), branch);
    }
  });
}

class Adapter implements HttpClientAdapter {
  Map<String, dynamic> json = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(json),
    200,
    headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
  );

  @override
  void close({bool force = false}) {}
}
''';
