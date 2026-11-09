@TestOn('vm')
@Timeout(Duration(minutes: 4))
library;

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/client_consumer.dart';
import 'support/client_platforms.dart';

void main() {
  test('runs standalone package:http clients on VM and Chrome', () async {
    final ClientConsumer consumer = await ClientConsumer.create('http');
    const loader = FileSchemaSourceLoader();
    for (final ResponseMode mode in ResponseMode.values) {
      for (final (fixture, dir) in [
        ('http/streaming/http_v3_2', 'http'),
        ('http/forms/form_data_v2_0', 'swagger_forms'),
        ('http/responses/status_ranges', 'ranges'),
      ]) {
        Future<Map<String, String>> generate(String ext) async {
          final GenerationResult result = await const SwaggerParserRunner()
              .generate(
                await loader.loadPath('test/fixtures/$fixture.$ext'),
                loader: loader,
                config: GenerationConfig(
                  httpClient: HttpClientBackend.http,
                  streamBinaryResponses: true,
                  responseMode: mode,
                ),
              );
          expect(
            result.diagnostics.map((d) => d.documentPath),
            fixture == 'http/streaming/http_v3_2'
                ? ['/paths/~1photos/post/requestBody']
                : isEmpty,
          );
          return {for (final f in result.files) f.relativePath: f.content};
        }

        final Map<String, String> files = await generate('yaml');
        if (fixture != 'http/responses/status_ranges') {
          expect(await generate('json'), files);
        }
        for (final MapEntry<String, String> entry in files.entries) {
          expect(entry.value, isNot(contains('package:dio')));
          await consumer.write(
            'lib/${dir}_${mode.name}/${entry.key}',
            entry.value,
          );
        }
      }
    }
    await consumer.write('pubspec.yaml', '''
name: client_check
environment:
  sdk: ^3.13.0
dependencies:
  http: ^1.6.0
dev_dependencies:
  test: ^1.33.0
''');
    await consumer.dart(['pub', 'get', '--offline']);
    await consumer.write('test/status_test.dart', _statusChecks);
    await consumer.dart(['analyze']);
    await consumer.dart(['test', 'test/status_test.dart']);
    await checkClientPlatforms(consumer, http: true);
  });
}

const _statusChecks = """
import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:client_check/http_firstSuccess/api.dart' as api;
import 'package:client_check/http_firstSuccess/api.dart' as models;
import 'package:client_check/http_allStatuses/api.dart' as all;
import 'package:client_check/ranges_allStatuses/api.dart' as ranges;

void main() {
  test('sends QUERY and selects exact, range, and default responses', () async {
    var status = 200;
    late Request sent;
    final transport = MockClient((request) async {
      sent = request;
      return Response('{"term":"east"}', status);
    });
    addTearDown(transport.close);
    final base = Uri.parse('https://stations.example/v1/');
    final client = api.ApiClient(transport, baseUrl: base, prepareRequest: (request, extra) {
      expect(extra['openapi.servers'], isNotEmpty);
      request.headers['X-Test'] = 'yes';
    });
    expect((await client.search(body: const models.Search(term: 'west'))).term, 'east');
    expect(sent.method, 'QUERY');
    expect(sent.url.path, '/v1/search');
    expect(sent.headers['x-test'], 'yes');
    expect(jsonDecode(sent.body), {'term':'west'});
    status = 204;
    await client.filter(area: {'north':2}, location: {'name':'east'}, session: 'a b');
    expect(sent.url.queryParameters, {'area':'north|2','location':'name east'});
    expect(sent.headers['cookie'], 'session=a%20b');
    status = 404;
    final failures = all.ApiClient(transport, baseUrl: base);
    final result = await failures.events() as all.Events404;
    expect(result.value.term, 'east');
    await expectLater(client.search(body: const models.Search(term: 'west')), throwsA(isA<ClientException>()));
    final fallback = ranges.ApiClient(transport, baseUrl: base);
    expect(await fallback.getCheck(), isA<ranges.GetCheck404>());
    status = 429;
    expect((await fallback.getCheck() as ranges.GetCheck4xx).statusCode, 429);
    status = 503;
    expect((await fallback.getCheck() as ranges.GetCheckDefault).statusCode, 503);
  });
}
""";
