@TestOn('vm')
@Timeout(Duration(minutes: 3))
library;

import 'dart:io';
import 'dart:isolate';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/client_consumer.dart';
import 'support/client_platforms.dart';
import 'support/http_transport_driver.dart';

void main() {
  test('runs generated clients with only Dio installed', () async {
    final ClientConsumer consumer = await ClientConsumer.create('dio');
    final Uri parser = (await Isolate.resolvePackageUri(
      Uri.parse('package:swagger_parser/swagger_parser.dart'),
    ))!;
    final Uri contracts = parser.resolve('../test/fixtures/extraction/');
    const loader = FileSchemaSourceLoader();
    Future<Map<String, String>> generate(Uri stem, ResponseMode mode) async {
      Future<Map<String, String>> read(String ext) async {
        final GenerationResult result = await const SwaggerParserRunner()
            .generate(
              await loader.load(Uri.parse('$stem.$ext')),
              loader: loader,
              config: GenerationConfig(
                httpClient: HttpClientBackend.dio,
                streamBinaryResponses: true,
                responseMode: mode,
              ),
            );
        expect(result.diagnostics, isEmpty);
        return {for (final f in result.files) f.relativePath: f.content};
      }

      final Map<String, String> files = await read('json');
      expect(await read('yaml'), files);
      return files;
    }

    Future<void> install(String dir, Map<String, String> files) async {
      for (final MapEntry<String, String> entry in files.entries) {
        expect(entry.key, isNot(endsWith('.g.dart')));
        expect(entry.value, isNot(contains('package:retrofit/')));
        expect(entry.value, isNot(contains("part '")));
        await consumer.write('lib/$dir/${entry.key}', entry.value);
      }
    }

    final Uri fixtures = Directory.current.uri.resolve('test/fixtures/');
    for (final ResponseMode mode in ResponseMode.values) {
      final Map<String, String> stations = await generate(
        contracts.resolve('swagger_v2'),
        mode,
      );
      for (final family in [
        'open_api_v3_0',
        'open_api_v3_1',
        'open_api_v3_2',
      ]) {
        final Map<String, String> files = await generate(
          contracts.resolve(family),
          mode,
        );
        expect(
          {...files}..remove('api.dart'),
          {...stations}..remove('api.dart'),
        );
      }
      await install('stations_${mode.name}', stations);
      await install(
        'http_${mode.name}',
        await generate(fixtures.resolve('http/streaming/http_v3_2'), mode),
      );
    }
    await install(
      'swagger_forms_firstSuccess',
      await generate(
        fixtures.resolve('http/forms/form_data_v2_0'),
        ResponseMode.firstSuccess,
      ),
    );
    await consumer.write('pubspec.yaml', '''
name: client_check
environment:
  sdk: ^3.13.0
dependencies:
  dio: ^5.11.1
dev_dependencies:
  test: ^1.33.0
''');
    await consumer.write('bin/check_http.dart', httpTransportDriver);
    await consumer.write('bin/check_stations.dart', _stationDriver);
    await consumer.dart(['pub', 'get', '--offline']);
    await consumer.dart(['analyze']);
    await consumer.dart(['--enable-asserts', 'bin/check_stations.dart']);
    await consumer.dart(['--enable-asserts', 'bin/check_http.dart']);
    await checkClientPlatforms(consumer, http: false);
  });
}

const _stationDriver = """
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:client_check/stations_firstSuccess/api.dart';
import 'package:client_check/stations_allStatuses/api.dart' as all;
import 'check_http.dart' show Probe;

Future<void> main() async {
  final probe = Probe();
  final dio = Dio(BaseOptions(baseUrl: 'https://station.example'))..httpClientAdapter = probe;
  final client = ApiClient(dio);
  ResponseBody json(String body, int code) => ResponseBody.fromString(body, code, headers: {'content-type': ['application/json']});
  probe.reply = () => json('{"id":"north"}', 200);
  final station = await client.getStationsById(id: 'north/west', tag: ['a', 'b']);
  assert(station.id == 'north');
  assert(probe.request.uri.pathSegments.last == 'north/west');
  assert(probe.request.uri.queryParametersAll['tag']!.join('|') == 'a|b');
  probe.reply = () => json('{"id":"west"}', 201);
  assert((await client.postStations(body: const Station(id: 'west'))).id == 'west');
  assert(jsonDecode(utf8.decode(probe.sent))['id'] == 'west');

  probe.reply = () => json('{"detail":"missing"}', 404);
  final error = await all.ApiClient(dio).getStationsById(id: 'missing');
  assert(error is all.GetStationsById404 && error.value.detail == 'missing');
  try {
    await client.getStationsById(id: 'missing');
    throw StateError('Expected a DioException.');
  } on DioException catch (e) {
    assert(e.response?.statusCode == 404);
  }
  dio.close();
}
""";
