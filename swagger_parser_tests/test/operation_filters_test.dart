@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  test('builds and calls filtered clients through one public import', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_filters_');
    addTearDown(() => dir.delete(recursive: true));
    Future<void> write(String path, String source) async {
      final file = File('${dir.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString(source);
    }

    Future<void> dart(List<String> args) async {
      final ProcessResult result = await Process.run(
        Platform.resolvedExecutable,
        args,
      );
      expect(
        result.exitCode,
        0,
        reason: '${args.join(' ')}\n${result.stdout}\n${result.stderr}',
      );
    }

    await write(
      'analysis_options.yaml',
      'analyzer:\n  language:\n    strict-casts: true\n',
    );
    const base = '../swagger_parser/test/fixtures/operation_filters';
    final CliConfig config = await CliConfig.load(
      configPath: '$base/config.yaml',
    );
    final drivers = <String>[];
    for (final version in ['2_0', '3_0', '3_1', '3_2']) {
      for (final HttpClientBackend backend in HttpClientBackend.values) {
        for (final ResponseMode mode in ResponseMode.values) {
          final folder = '${backend.name}_${version}_${mode.name}';
          Map<String, String>? expected;
          for (final ext in ['json', 'yaml']) {
            final GenerationResult result = await const SwaggerParserRunner()
                .generate(
                  await const FileSchemaSourceLoader().loadPath(
                    '$base/routes_v$version.$ext',
                  ),
                  config: GenerationConfig(
                    httpClient: backend,
                    responseMode: mode,
                    operationFilters: config.generation.operationFilters,
                  ),
                );
            expect(result.diagnostics, isEmpty);
            final Map<String, String> files = {
              for (final file in result.files) file.relativePath: file.content,
            };
            expected ??= files;
            expect(files, expected);
          }
          for (final MapEntry<String, String> file in expected!.entries) {
            await write('$folder/${file.key}', file.value);
          }
          await write('$folder.dart', _driver(folder, backend, mode));
          drivers.add('${dir.path}/$folder.dart');
        }
      }
    }
    await dart(['run', 'build_runner', 'build']);
    await dart(['analyze', dir.path]);
    for (final driver in drivers) {
      await dart(['--enable-asserts', driver]);
    }
  });
}

String _driver(String folder, HttpClientBackend backend, ResponseMode mode) {
  final http = backend == HttpClientBackend.http;
  String call(String expression, String result) =>
      mode == ResponseMode.firstSuccess
      ? 'await $expression'
      : '((await $expression) as ${result}200).value';
  return '''
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;\nimport 'package:http/testing.dart';" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import '$folder/api.dart';

Future<void> main() async {
  final paths = <String>[];
  Object reply(Uri uri) {
    paths.add(uri.path);
    return {'name': 'North', 'status': 'active'};
  }
  ${http ? "final transport = MockClient((request) async => http.Response(jsonEncode(reply(request.url)), 200, headers: {'content-type': 'application/json'}));\nfinal api = Api(transport, baseUrl: Uri.parse('https://example.test'));" : "final transport = Dio(BaseOptions(baseUrl: 'https://example.test'));\ntransport.httpClientAdapter = Adapter(reply);\nfinal api = Api(transport);"}
  final Station listed = ${call('api.stations.listStations()', 'ListStations')};
  final Station station = ${call("api.stations.getStation(id: 's1')", 'GetStation')};
  final Station history = ${call("api.public.getHistory(id: 's1')", 'GetHistory')};
  assert(listed.name == 'North' && station.name == 'North' && history.name == 'North');
  assert(station.toJson()['status'] == 'active');
  assert(paths.join(',') == '/stations,/stations/s1,/stations/s1/history');
  assert(Secret.fromJson({'token':'retained'}).toJson()['token'] == 'retained');
  assert(Unused.fromJson({'detail':{'count':2}}).toJson()['detail'] is Map);
  assert(UnusedEnum.values.length == 2);
  transport.${http ? 'close()' : 'close(force: true)'};
}
${http ? '' : '''
class Adapter implements HttpClientAdapter {
  Adapter(this.reply);
  final Object Function(Uri) reply;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body, Future<void>? cancel) async => ResponseBody.fromString(jsonEncode(reply(options.uri)), 200, headers: {Headers.contentTypeHeader: ['application/json']});
  @override
  void close({bool force = false}) {}
}
'''}
''';
}
