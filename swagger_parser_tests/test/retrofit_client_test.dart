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

typedef _FilesByMode = Map<ResponseMode, Map<String, String>>;

// Source metadata can differ between equivalent versioned contracts.
Map<String, String> _clientFiles(Map<String, String> files) => {
  for (final entry in files.entries)
    if (entry.key != 'api.dart' && !entry.key.endsWith('_metadata.dart'))
      entry.key: entry.value,
};

void main() {
  test('keeps untagged routes in one ApiClient', () async {
    const loader = FileSchemaSourceLoader();
    final SchemaSource source = await loader.loadPath(
      'test/fixtures/http/grouping/client_groups.yaml',
    );
    final GenerationResult result = await const SwaggerParserRunner().generate(
      source,
      loader: loader,
    );
    final Map<String, String> files = {
      for (final file in result.files) file.relativePath: file.content,
    };
    expect(
      files.keys,
      unorderedEquals([
        'api.dart',
        'exports.dart',
        'default_client/models/status.dart',
        'default_client/api_client.dart',
        'api2/api_client2.dart',
        'station/station_client.dart',
      ]),
    );
    expect(
      files['default_client/api_client.dart'],
      contains('getByTenantStatus('),
    );
    expect(files['default_client/api_client.dart'], contains("@GET('/')"));
    expect(files['default_client/api_client.dart'], contains('getV1Stations('));
    expect(files['default_client/api_client.dart'], contains('getV1Users('));
    expect(files['default_client/api_client.dart'], contains('getWorkOrders('));
    expect(
      files['default_client/api_client.dart'],
      contains('getWorkOrders2('),
    );
    expect(files['api2/api_client2.dart'], contains('getVersions('));
    expect(files['station/station_client.dart'], contains('getUsers('));
    expect(result.diagnostics, isEmpty);
    expect(files['default_client/api_client.dart'], contains('postImport('));
  });

  test('reports unsupported deepObject parameters at their source', () async {
    const loader = FileSchemaSourceLoader();
    final SchemaSource source = await loader.loadPath(
      'test/fixtures/http/parameters/deep_object_unsupported.yaml',
    );
    final GenerationResult result = await const SwaggerParserRunner().generate(
      source,
      loader: loader,
    );
    expect(
      result.diagnostics.map((d) => d.documentPath),
      unorderedEquals([
        for (final path in ['array', 'nested', 'implicit', 'false'])
          '/paths/~1$path/get/parameters/0',
      ]),
    );
    expect(
      result.diagnostics.map((d) => d.code),
      everyElement('unsupportedClientOperation'),
    );
    expect(
      result.files.where((f) => f.relativePath.endsWith('_client.dart')),
      isEmpty,
    );
  });

  test('reports nested object properties in path, header, and form query parameters', () async {
    const loader = FileSchemaSourceLoader();
    final SchemaSource source = await loader.loadPath(
      'test/fixtures/http/parameters/nested_object_params.yaml',
    );
    for (final ResponseMode mode in ResponseMode.values) {
      final GenerationResult result = await const SwaggerParserRunner()
          .generate(
            source,
            loader: loader,
            config: GenerationConfig(responseMode: mode),
          );
      expect(
        result.files.where((f) => f.relativePath.endsWith('_client.dart')),
        isEmpty,
      );
      expect(
        result.diagnostics.map((d) => d.code),
        everyElement('unsupportedClientOperation'),
      );
      expect(
        result.diagnostics.map((d) => d.documentPath),
        unorderedEquals([
          '/paths/~1stations~1{selector}/get/parameters/0',
          '/paths/~1stations/get/parameters/0',
          '/paths/~1filter/get/parameters/0',
        ]),
      );
    }
  });

  test('builds and calls generated clients from JSON and YAML', () async {
    final ClientConsumer consumer = await ClientConsumer.create('retrofit');
    final Uri library = (await Isolate.resolvePackageUri(
      Uri.parse('package:swagger_parser/swagger_parser.dart'),
    ))!;
    final Uri contracts = library.resolve('../test/fixtures/extraction/');
    const loader = FileSchemaSourceLoader();
    Future<Map<String, String>> generate(
      Uri uri, {
      ResponseMode mode = ResponseMode.firstSuccess,
      bool inferRequired = true,
    }) async {
      final GenerationResult result = await const SwaggerParserRunner()
          .generate(
            await loader.load(uri),
            loader: loader,
            config: GenerationConfig(
              responseMode: mode,
              inferMissingRequired: inferRequired,
              streamBinaryResponses: true,
            ),
          );
      expect(result.diagnostics, isEmpty);
      return {for (final f in result.files) f.relativePath: f.content};
    }

    final Map<String, String> stations = await generate(
      contracts.resolve('swagger_v2.yaml'),
    );
    expect(
      stations.keys,
      containsAll([
        'api.dart',
        'exports.dart',
        'default_client/api_client.dart',
        'default_client/models/station.dart',
        'models/unused.dart',
      ]),
    );
    final String client = stations['default_client/api_client.dart']!;
    expect(client, contains('abstract class ApiClient'));
    expect(client, contains('=> _ApiClientWithOptions(dio);'));
    expect(client, contains("@Path('id')"));
    expect(client, contains("@Query('tag')"));
    expect(client, contains("@POST('/stations')"));
    expect(client, contains('@Body() required Station body'));
    final Uri example = Directory.current.uri.resolve('example/stations/');
    final Map<String, String> exampleFiles = await generate(
      contracts.resolve('open_api_v3_2.yaml'),
    );
    for (final MapEntry<String, String> file in exampleFiles.entries) {
      expect(
        await File.fromUri(example.resolve(file.key)).readAsString(),
        file.value,
        reason: 'Rebuild the station example.',
      );
    }
    for (final family in [
      'swagger_v2',
      'open_api_v3_0',
      'open_api_v3_1',
      'open_api_v3_2',
    ]) {
      for (final ext in ['json', 'yaml']) {
        final Map<String, String> files = await generate(
          contracts.resolve('$family.$ext'),
        );
        expect(_clientFiles(files), _clientFiles(stations));
      }
    }
    final Uri fixtures = Directory.current.uri.resolve('test/fixtures/');
    final Uri responses = library.resolve('../test/fixtures/responses/');
    final Map<String, String> statuses = await generate(
      responses.resolve('status_v2_0.yaml'),
    );
    final Map<String, String> all = await generate(
      responses.resolve('status_v2_0.yaml'),
      mode: ResponseMode.allStatuses,
    );
    expect(statuses.keys, contains('default_client/api_client.dart'));
    expect(
      statuses['default_client/api_client.dart'],
      contains('Future<void> invalid({'),
    );
    expect(
      statuses['default_client/api_client.dart'],
      contains('Future<Station?> lookupStation('),
    );
    expect(
      all.keys,
      containsAll([
        'default_client/api_client.dart',
        'default_client/api_client_results.dart',
        'exports.dart',
      ]),
    );
    expect(
      all['default_client/api_client_results.dart'],
      contains('sealed class LookupStationResult'),
    );
    final Map<String, String> ranges = await generate(
      fixtures.resolve('http/responses/status_ranges.yaml'),
      mode: ResponseMode.allStatuses,
    );
    for (final version in ['2_0', '3_0', '3_1', '3_2']) {
      for (final format in ['json', 'yaml']) {
        final Uri uri = responses.resolve('status_v$version.$format');
        expect(_clientFiles(await generate(uri)), _clientFiles(statuses));
        expect(
          _clientFiles(await generate(uri, mode: ResponseMode.allStatuses)),
          _clientFiles(all),
        );
      }
    }
    expect(
      statuses['default_client/api_client.dart'],
      contains("@Header('X-Request-ID')"),
    );
    expect(
      statuses['default_client/api_client.dart'],
      contains("@Header('X-Revision')"),
    );
    final Map<String, String> readings = await generate(
      fixtures.resolve('dto/unions/reading.yaml'),
    );
    expect(
      await generate(fixtures.resolve('dto/unions/reading.json')),
      readings,
    );
    expect(
      readings.keys,
      containsAll([
        'default_client/api_client.dart',
        'exports.dart',
        'sensor/sensor_client.dart',
      ]),
    );
    expect(readings['sensor/sensor_client.dart'], contains('readSensor('));
    expect(readings['default_client/api_client.dart'], contains('@Body()'));
    final arrayClients = <String, Map<String, String>>{};
    for (final ResponseMode mode in ResponseMode.values) {
      for (final version in ['2_0', '3_0', '3_1', '3_2']) {
        final stem = 'http/parameters/query_arrays_v$version';
        final Map<String, String> files = await generate(
          fixtures.resolve('$stem.yaml'),
          mode: mode,
        );
        expect(
          await generate(fixtures.resolve('$stem.json'), mode: mode),
          files,
        );
        final family = version == '2_0' ? 'swagger' : 'openapi';
        final dir = '${family}_${mode.name}';
        expect(
          _clientFiles(files),
          _clientFiles(arrayClients.putIfAbsent(dir, () => files)),
        );
      }
    }
    Future<_FilesByMode> generateVersions(
      String fixture,
      List<String> versions,
    ) async {
      // Keep literal required rules when testing omitted parameter properties.
      final clients = <ResponseMode, Map<String, String>>{};
      for (final ResponseMode mode in ResponseMode.values) {
        for (final version in versions) {
          final stem = '${fixture}_v$version';
          final Map<String, String> files = await generate(
            fixtures.resolve('$stem.yaml'),
            mode: mode,
            inferRequired: false,
          );
          expect(
            await generate(
              fixtures.resolve('$stem.json'),
              mode: mode,
              inferRequired: false,
            ),
            files,
          );
          expect(
            _clientFiles(files),
            _clientFiles(clients.putIfAbsent(mode, () => files)),
          );
        }
      }
      return clients;
    }

    final _FilesByMode httpClients = await generateVersions(
      'http/streaming/http',
      ['3_2'],
    );
    final _FilesByMode swaggerForms = await generateVersions(
      'http/forms/form_data',
      ['2_0'],
    );
    expect(
      httpClients[ResponseMode.firstSuccess]!['default_client/api_client.dart'],
      contains("@QUERY('/search')"),
    );
    expect(
      swaggerForms[ResponseMode
          .firstSuccess]!['default_client/api_client.dart'],
      contains('@MultiPart()'),
    );
    expect(
      httpClients[ResponseMode.firstSuccess]!['default_client/api_client.dart'],
      contains('@FormUrlEncoded()'),
    );
    final String documented =
        httpClients[ResponseMode
            .firstSuccess]!['default_client/api_client.dart']!;
    expect(
      documented,
      contains(
        '/// Read stations.\n  ///\n  /// One station per line.\n  /// The stream uses UTF-8.',
      ),
    );
    final GenerationResult without = await const SwaggerParserRunner().generate(
      await loader.load(fixtures.resolve('http/streaming/http_v3_2.yaml')),
      loader: loader,
      config: const GenerationConfig(generateDocs: false),
    );
    final String code = without.files
        .singleWhere((f) => f.relativePath == 'default_client/api_client.dart')
        .content;
    expect(code, isNot(contains('/// Read stations.')));
    expect(code, contains('@Deprecated('));
    expect(code, contains('Future<List<int>> echoBytes('));
    final _FilesByMode objectClients = await generateVersions(
      'http/parameters/deep_object',
      ['3_0', '3_1', '3_2'],
    );
    final _FilesByMode updateClients = await generateVersions(
      'http/bodies/station_updates',
      ['2_0', '3_0', '3_1', '3_2'],
    );
    final _FilesByMode parameterClients = await generateVersions(
      'http/parameters/object_params',
      ['3_0', '3_1', '3_2'],
    );
    final _FilesByMode queryForms = await generateVersions(
      'http/parameters/query_form',
      ['3_0', '3_1', '3_2'],
    );
    final _FilesByMode pathClients = await generateVersions(
      'http/parameters/path_styles',
      ['3_0', '3_1', '3_2'],
    );
    final _FilesByMode batchClients = await generateVersions(
      'http/forms/batch_formats',
      ['2_0'],
    );
    for (final method in ['PUT', 'PATCH', 'DELETE', 'POST']) {
      expect(
        updateClients[ResponseMode
            .firstSuccess]!['default_client/api_client.dart'],
        contains("@$method('/stations')"),
      );
    }
    expect(
      objectClients[ResponseMode
          .firstSuccess]!['default_client/api_client.dart'],
      contains("@Query('filter')"),
    );
    for (final (dir, files) in [
      for (final entry in httpClients.entries)
        ('http_${entry.key.name}', entry.value),
      for (final entry in swaggerForms.entries)
        ('swagger_forms_${entry.key.name}', entry.value),
      ('stations', stations),
      ('readings', readings),
      ('statuses', statuses),
      ('all', all),
      ('ranges', ranges),
      for (final entry in updateClients.entries)
        ('updates_${entry.key.name}', entry.value),
      for (final entry in parameterClients.entries)
        ('parameters_${entry.key.name}', entry.value),
      for (final entry in queryForms.entries)
        ('form_${entry.key.name}', entry.value),
      for (final entry in pathClients.entries)
        ('paths_${entry.key.name}', entry.value),
      for (final entry in batchClients.entries)
        ('batch_${entry.key.name}', entry.value),
      for (final entry in objectClients.entries)
        ('objects_${entry.key.name}', entry.value),
      for (final entry in arrayClients.entries) (entry.key, entry.value),
    ]) {
      for (final MapEntry<String, String> f in files.entries) {
        await consumer.write('lib/$dir/${f.key}', f.value);
      }
    }
    await consumer.write('pubspec.yaml', '''
name: client_check
environment:
  sdk: ^3.13.0
dependencies:
  dio: ^5.11.0
  retrofit: ^4.10.0
dev_dependencies:
  build_runner: ^2.15.1
  retrofit_generator: ^10.2.12
  test: ^1.33.0
''');
    await consumer.write('bin/check.dart', _driver);
    await consumer.write('bin/check_http.dart', httpTransportDriver);
    await consumer.dart(['pub', 'get', '--offline']);
    await consumer.dart(['run', 'build_runner', 'build']);
    final part = File.fromUri(
      consumer.uri.resolve('lib/stations/default_client/api_client.g.dart'),
    );
    expect(
      await part.readAsString(),
      contains('class _ApiClient extends ApiClient'),
    );
    final String multipartPart = await File.fromUri(
      consumer.uri.resolve(
        'lib/swagger_forms_firstSuccess/default_client/api_client.g.dart',
      ),
    ).readAsString();
    expect(multipartPart, contains('FormData()'));
    expect(multipartPart, contains("MapEntry('photo', photo)"));
    await consumer.dart(['analyze']);
    await consumer.dart(['--enable-asserts', 'bin/check.dart']);
    await consumer.dart(['--enable-asserts', 'bin/check_http.dart']);
    await checkClientPlatforms(consumer, http: false);
  });
}

const _driver = r"""
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:client_check/readings/api.dart' as readings;
import 'package:client_check/stations/api.dart';
import 'package:client_check/statuses/api.dart' as statuses;
import 'package:client_check/all/api.dart' as all;
import 'package:client_check/ranges/api.dart' as ranges;

import 'package:client_check/swagger_firstSuccess/api.dart' as swagger_arrays;
import 'package:client_check/swagger_allStatuses/api.dart' as swagger_all;
import 'package:client_check/openapi_firstSuccess/api.dart' as openapi_arrays;
import 'package:client_check/openapi_allStatuses/api.dart' as openapi_all;

import 'package:client_check/objects_firstSuccess/api.dart' as filters;
import 'package:client_check/objects_allStatuses/api.dart' as all_filters;

import 'package:client_check/updates_firstSuccess/api.dart' as updates;
import 'package:client_check/updates_allStatuses/api.dart' as all_updates;
import 'package:client_check/batch_firstSuccess/api.dart' as batch;
import 'package:client_check/batch_allStatuses/api.dart' as all_batch;

import 'package:client_check/paths_firstSuccess/api.dart' as paths;
import 'package:client_check/paths_allStatuses/api.dart' as all_paths;

import 'package:client_check/parameters_firstSuccess/api.dart' as params;
import 'package:client_check/parameters_allStatuses/api.dart' as all_params;

import 'package:client_check/form_firstSuccess/api.dart' as form;
import 'package:client_check/form_allStatuses/api.dart' as all_form;

class Probe implements HttpClientAdapter {
  late RequestOptions request;
  String? sent;
  var status = 200;
  var body = '{"id":"north","parent":{"id":"hub"}}';

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? stream, Future<void>? cancel) async {
    request = options;
    sent = stream == null ? null : await utf8.decoder.bind(stream).join();
    return ResponseBody.fromString(body, status,
        headers: {'content-type': ['application/json']});
  }

  @override
  void close({bool force = false}) {}
}

Future<void> main() async {
  final probe = Probe();
  final dio = Dio(BaseOptions(baseUrl: 'https://stations.example/v1',
      headers: {'X-Token':'abc'}, queryParameters: {'lang':'en'}))
    ..httpClientAdapter = probe;
  final client = ApiClient(dio);
  final id = Uri.encodeComponent('a/b #%?');
  final Station station = await client.getStationsById(id: id, tag: ['one two','x&y']);
  assert(station.id == 'north' && station.parent!.id == 'hub');
  assert(probe.request.method == 'GET');
  final uri = probe.request.uri;
  assert(uri.host == 'stations.example' && uri.pathSegments.join('|') == 'v1|stations|a/b #%?');
  assert(uri.queryParametersAll['tag']!.join('|') == 'one two|x&y');
  assert(uri.queryParameters['lang'] == 'en' && uri.fragment.isEmpty);
  assert(probe.request.headers['X-Token'] == 'abc');
  assert(probe.request.headers['Accept'] == 'application/json');
  probe.status = 201;
  dio.options.contentType = 'text/plain';
  final created = await client.postStations(body: const Station(
      id: 'new', parent: Station(id: 'west'), additionalProperties: {'label': null}));
  assert(created.id == 'north' && created.parent!.id == 'hub');
  assert(probe.request.method == 'POST' && probe.request.uri.path == '/v1/stations');
  assert(probe.request.contentType == 'application/json');
  final sent = jsonDecode(probe.sent!) as Map<String, dynamic>;
  assert(sent['id'] == 'new' && sent['parent']['id'] == 'west');
  assert(sent.containsKey('label') && sent['label'] == null);
  probe.status = 400;
  probe.body = '{"detail":"invalid id"}';
  try {
    await client.postStations(body: const Station(id: ''));
    throw StateError('Expected a bad request.');
  } on DioException catch (e) {
    assert(e.response?.statusCode == 400 && e.response?.data['detail'] == 'invalid id');
  }
  probe.status = 200;
  probe.body = '{"id":"north"}';
  await client.getStationsById(id: 'north');
  assert(!probe.request.uri.queryParameters.containsKey('tag'));
  dio.options.listFormat = ListFormat.csv;
  await client.getStationsById(id: 'north', tag: ['rail', 'bus']);
  assert(probe.request.uri.queryParameters['tag'] == 'rail,bus');
  probe.status = 404;
  try {
    await client.getStationsById(id: 'missing');
    throw StateError('Expected a bad response.');
  } on DioException catch (e) {
    assert(e.response?.statusCode == 404);
  }
  dio.options.validateStatus = (_) => true;
  assert((await client.getStationsById(id: 'north')).id == 'north');
  probe.status = 200;
  final api = readings.ApiClient(dio);
  probe.body = '{"id":"sensor"}';
  final sensor = await api.currentSensor(queryParameters2: 'active', sensorMode: 'near');
  assert(sensor.id == 'sensor');
  assert(probe.request.uri.queryParameters['queryParameters'] == 'active');
  assert(probe.request.uri.queryParameters['sensor-mode'] == 'near');
  probe.status = 201;
  await api.recordEvent(body: const readings.RecordEventRequest(message: 'ok'), body2: 'audit');
  assert(probe.request.uri.queryParameters['body'] == 'audit');
  assert((jsonDecode(probe.sent!) as Map)['message'] == 'ok');
  probe.status = 200;
  await api.setNote();
  assert(probe.sent == null || probe.sent!.isEmpty);
  await api.setNote(sendNullBody: true);
  assert(probe.sent == 'null');
  await api.setNote(body: 'platform 2');
  assert(probe.sent == '"platform 2"');
  probe.body = '["sensor", 2.5]';
  final feed = readings.Api(dio).sensor;
  final reading = await feed.readSensor(rack: 2, sensor: 'west/east');
  assert(reading.item1 == 'sensor' && reading.item2 == 2.5);
  assert(probe.request.uri.pathSegments.join('|') == 'v1|racks|2|sensors|west/east|reading');
  probe.body = '["sensor", false]';
  try {
    await feed.readSensor(rack: 2, sensor: 'east');
    throw StateError('Expected an invalid tuple.');
  } on FormatException {}
  final lookup = statuses.ApiClient(dio);
  dio.options.headers['Authorization'] = 'Bearer token';
  probe.status = 200;
  probe.body = '{"name":"central"}';
  await lookup.getStation(id: 'north', xRequestId: 'retrofit', xRevision: 7);
  assert(probe.request.headers['X-Request-ID'] == 'retrofit');
  assert(probe.request.headers['X-Revision'].toString() == '7');
  assert(probe.request.headers['Authorization'] == 'Bearer token');
  assert(!probe.request.uri.queryParameters.containsKey('X-Revision'));
  await lookup.getStation(id: 'north', xRequestId: 'retrofit');
  assert(!probe.request.headers.containsKey('X-Revision'));
  dio.options.headers['X-Revision'] = 'default';
  await lookup.getStation(id: 'north', xRequestId: 'retrofit');
  assert(probe.request.headers['X-Revision'] == 'default');
  await lookup.lookupStation(xRequestId: 'direct');
  assert(probe.request.headers['X-Revision'] == 'default');
  dio.options.headers.remove('X-Revision');
  final typed = all.ApiClient(dio);
  assert((await lookup.lookupStation(xRequestId: 'first'))!.name == 'central');
  assert((await typed.getStation(id: 'north', xRequestId: 'typed') as all.GetStation200).value.name == 'central');
  probe.status = 204;
  probe.body = '';
  await lookup.empty();
  assert(await typed.empty() is all.Empty204);
  probe.status = 400;
  probe.body = '{"field":"name"}';
  assert((await typed.invalid() as all.Invalid400).value.field == 'name');
  dio.options.validateStatus = (s) => s != null && s >= 200 && s < 300;
  try {
    await lookup.invalid();
    throw StateError('Expected a bad request.');
  } on DioException catch (e) { assert(e.response?.statusCode == 400); }
  String describe(all.LookupStationResult result) => switch (result) {
    all.LookupStation200(:final value) => value.name,
    all.LookupStation202(:final value) => value.token,
    all.LookupStation204() => 'empty',
    all.LookupStation201(:final value) => value.id,
    all.LookupStation400(:final value) => value.field,
    all.LookupStation404(:final value) => value.detail,
    all.LookupStation500(:final value) => value.requestId,
  };
  for (final (status, json, expected) in [
    (200, '{"name":"central"}', 'central'),
    (202, '{"token":"pending"}', 'pending'),
    (204, '', 'empty'),
    (201, '{"id":"created"}', 'created'),
    (400, '{"field":"name"}', 'name'),
    (404, '{"detail":"missing"}', 'missing'),
    (500, '{"requestId":"trace"}', 'trace'),
  ]) {
    probe.status = status;
    probe.body = json;
    assert(describe(await typed.lookupStation(xRequestId: 'direct', xRevision: status == 200 ? 0 : null)) == expected);
    assert(probe.request.headers['X-Request-ID'] == 'direct');
    assert(status == 200 ? probe.request.headers['X-Revision'].toString() == '0' : !probe.request.headers.containsKey('X-Revision'));
    assert(probe.request.headers['Authorization'] == 'Bearer token');
  }
  for (final status in [203, 503]) {
    probe.status = status;
    probe.body = '{"detail":"missing"}';
    try {
      await typed.lookupStation(xRequestId: 'direct');
      throw StateError('Expected a status error.');
    } on DioException catch (error) {
      assert(error.response?.statusCode == status && error.response?.data['detail'] == 'missing');
    }
  }
  final fallback = ranges.ApiClient(dio);
  probe.body = '';
  probe.status = 404;
  assert(await fallback.getCheck() is ranges.GetCheck404);
  probe.status = 429;
  assert((await fallback.getCheck() as ranges.GetCheck4xx).statusCode == 429);
  probe.status = 503;
  assert((await fallback.getCheck() as ranges.GetCheckDefault).statusCode == 503);
  probe.status = 204;
  probe.body = '';
  dio.options.listFormat = ListFormat.multiCompatible;
  const lines = ['N,E', 'South & West'];
  const modes = ['bus', 'rail'];
  const zones = [0, 2];
  const flags = [true, false];
  const stops = ['a', 'b+c'];
  void checkFilters({bool tabs = false}) {
    final uri = probe.request.uri;
    final query = uri.queryParametersAll;
    assert(uri.query.contains('line=N%2CE,South'));
    assert(query['line']!.single == 'N,E,South & West');
    assert(query['mode']!.single == 'bus|rail');
    assert(query['zone']!.single == '0 2');
    assert(query['active']!.join(',') == 'true,false');
    assert(query['lang']!.single == 'en');
    if (tabs) {
      assert(uri.query.contains('stop=a%09b%2Bc'));
    } else {
      assert(!query.containsKey('stop'));
    }
  }
  final swaggerFilters = swagger_arrays.ApiClient(dio);
  await swaggerFilters.filterStations(line: lines, mode: modes, zone: zones, active: flags, stop: stops);
  checkFilters(tabs: true);
  final swaggerResult = await swagger_all.ApiClient(dio).filterStations(
      line: lines, mode: modes, zone: zones, active: flags, stop: stops);
  assert(swaggerResult is swagger_all.FilterStations204);
  checkFilters(tabs: true);
  final openapiFilters = openapi_arrays.ApiClient(dio);
  await openapiFilters.filterStations(line: lines, mode: modes, zone: zones, active: flags);
  checkFilters();
  final openapiResult = await openapi_all.ApiClient(dio).filterStations(
      line: lines, mode: modes, zone: zones, active: flags);
  assert(openapiResult is openapi_all.FilterStations204);
  checkFilters();
  await openapiFilters.filterStations(line: []);
  final empty = probe.request.uri.queryParameters;
  assert(empty.length == 2 && empty['line'] == '' && empty['lang'] == 'en');
  final filtered = filters.ApiClient(dio);
  final typedFilters = all_filters.ApiClient(dio);
  const name = 'Central + West & 北';
  const scores = {'A&B': 0};
  void checkObject() {
    final uri = probe.request.uri;
    final query = uri.queryParametersAll;
    assert(query.length == 5 && query['lang']!.single == 'en');
    assert(query['filter[name]']!.single == name);
    assert(query['filter[active]']!.single == 'false');
    assert(query['filter[line-code]']!.single == '42');
    assert(query['scores[A&B]']!.single == '0');
    assert(uri.query.contains('scores%5BA%26B%5D=0'));
  }
  await filtered.listStations(filter: const filters.StationFilter(name: name, active: false, lineCode: 42), scores: scores);
  checkObject();
  final matches = await typedFilters.listStations(filter: const all_filters.StationFilter(name: name, active: false, lineCode: 42), scores: scores);
  assert(matches is all_filters.ListStations204);
  checkObject();
  await filtered.listStations(scores: {});
  assert(probe.request.uri.query == 'lang=en');
  await typedFilters.listStations(filter: const all_filters.StationFilter(), scores: {});
  assert(probe.request.uri.query == 'lang=en');
  await filtered.search(options2: const filters.SearchOptions(distance: 2.5, additionalProperties: {'city': 'Zürich'}));
  assert(probe.request.uri.queryParameters['options[distance]'] == '2.5');
  assert(probe.request.uri.queryParameters['options[city]'] == 'Zürich');
  final lastRequest = probe.request;
  try {
    await filtered.search(options2: const filters.SearchOptions(additionalProperties: {'nested': [1]}));
    throw StateError('Expected a scalar property.');
  } on ArgumentError catch (error) {
    assert(error.message.toString().contains('options[nested]'));
    assert(identical(lastRequest, probe.request));
  }
  await checkUpdates(dio, probe);
  await checkObjectParameters(dio, probe);
  await checkFormQuery(dio, probe);
  dio.close();
}

Future<void> checkFormQuery(Dio dio, Probe probe) async {
  final client = form.ApiClient(dio);
  final typed = all_form.ApiClient(dio);
  const packed = {'a,b': 'x,y + &', 'null': null};
  const expanded = {'a+b &': '北 &', 'skip': null, 'blank': ''};
  void check() {
    final uri = probe.request.uri;
    final query = uri.queryParametersAll;
    assert(uri.query.contains('filter=a%2Cb,x%2Cy+%2B+%26,id,0,active,false'));
    assert(query['id']!.single == '12' && query['active']!.single == 'false');
    assert(query['a+b &']!.single == '北 &' && query['blank']!.single.isEmpty);
    assert(!query.containsKey('skip') && !query.containsKey('by'));
    assert(query['page']!.single == '3' && query['open']!.single == 'true');
    assert(query['meta[site]']!.single == 'a/b' && query['lang']!.single == 'en');
  }
  await client.search(filter: const form.Filter(id: 0, active: false, additionalProperties: packed),
      by: const form.Filter(id: 12, active: false, additionalProperties: expanded),
      page: 3, flags: {'open': true}, meta: {'site': 'a/b'});
  check();
  assert(await typed.search(filter: const all_form.Filter(id: 0, active: false, additionalProperties: packed),
      by: const all_form.Filter(id: 12, active: false, additionalProperties: expanded),
      page: 3, flags: {'open': true}, meta: {'site': 'a/b'}) is all_form.Search204);
  check();
  await client.search(filter: const form.Filter(), by: const form.Filter(additionalProperties: {'empty': null}));
  assert(probe.request.uri.query == 'lang=en');
  final last = probe.request;
  for (final key in ['page', 'filter', 'meta[site]', 'open']) {
    try {
      await client.search(filter: const form.Filter(id: 1), by: form.Filter(additionalProperties: {key: 0}),
          page: 3, flags: {'open': true}, meta: {'site': 'a/b'});
      throw StateError('Expected a duplicate query key.');
    } on ArgumentError catch (error) {
      assert(error.message.toString().contains(key) && identical(last, probe.request));
    }
  }
  try {
    await typed.search(filter: const all_form.Filter(additionalProperties: {'nested': [1]}));
    throw StateError('Expected a scalar property.');
  } on ArgumentError catch (error) {
    assert(error.message.toString().contains('filter[nested]') && identical(last, probe.request));
  }
}

Future<void> checkObjectParameters(Dio dio, Probe probe) async {
  final client = params.ApiClient(dio);
  final typed = all_params.ApiClient(dio);
  const selector = params.Selector(stopId: 'a/b,c', active: false);
  const other = all_params.Selector(stopId: 'a/b,c', active: false);
  const modes = {'north/rail': params.Mode.eastBound, 'city': params.Mode.west};
  const otherModes = {'north/rail': all_params.Mode.eastBound, 'city': all_params.Mode.west};
  const packed = 'stop-id,a%2Fb%2Cc,active,false';
  const expanded = 'stop-id=a%2Fb%2Cc';
  void checkPacked() {
    assert(probe.request.uri.path == '/v1/packed/s$packed/l.$packed/m;matrix=$packed');
    assert(probe.request.headers['X-Modes'] == 'north/rail,east-bound,city,west');
  }
  void checkExpanded() {
    assert(probe.request.uri.path == '/v1/expanded/s$expanded,active=false/l.$expanded.active=false/m;$expanded;active=false');
    assert(probe.request.headers['X-Modes'] == 'north/rail=east-bound,city=west');
  }
  await client.packed(simple: selector, label: selector, matrix: selector, xModes: modes);
  checkPacked();
  assert(await typed.packed(simple: other, label: other, matrix: other, xModes: otherModes) is all_params.Packed204);
  checkPacked();
  await client.expanded(simple: selector, label: selector, matrix: selector, xModes: modes);
  checkExpanded();
  assert(await typed.expanded(simple: other, label: other, matrix: other, xModes: otherModes) is all_params.Expanded204);
  checkExpanded();

  const blank = params.Selector();
  const extras = params.Selector(additionalProperties: {'a/b': '', 'rank': 0, 'skip': null});
  dio.options.headers['X-Modes'] = 'default';
  await client.expanded(simple: blank, label: blank, matrix: extras);
  assert(probe.request.uri.path == '/v1/expanded/s/l/m;a%2Fb;rank=0');
  assert(probe.request.headers['X-Modes'] == 'default');
  await client.packed(simple: blank, label: blank, matrix: blank, xModes: {});
  assert(probe.request.headers['X-Modes'] == '');
  final last = probe.request;
  try {
    await client.packed(simple: const params.Selector(additionalProperties: {'nested': [1]}), label: blank, matrix: blank);
    throw StateError('Expected a scalar property.');
  } on ArgumentError catch (error) {
    assert(error.message.toString().contains('simple[nested]'));
    assert(identical(last, probe.request));
  }
}

Future<void> checkUpdates(Dio dio, Probe probe) async {
  final client = updates.ApiClient(dio);
  final typed = all_updates.ApiClient(dio);
  const ids = ['A/B', 'north,west', '#1?'];
  void checkRemoval() {
    final request = probe.request;
    assert(request.method == 'DELETE');
    assert(request.uri.path == '/v1/stations/A%2FB,north%2Cwest,%231%3F');
    assert(request.headers['X-Station-Ids'] == '12,34');
    assert(request.headers['X-Flags'] == 'true,false');
  }
  await client.removeStations(ids: ids, xStationIds: [12, 34], xFlags: [true, false]);
  checkRemoval();
  assert(await typed.removeStations(ids: ids, xStationIds: [12, 34], xFlags: [true, false]) is all_updates.RemoveStations204);
  checkRemoval();
  dio.options.headers['X-Station-Ids'] = 'default';
  await client.removeStations(ids: ['east'], xFlags: []);
  assert(probe.request.headers['X-Station-Ids'] == 'default');
  assert(probe.request.headers['X-Flags'] == '');
  await typed.removeStations(ids: ['east'], xStationIds: [], xFlags: []);
  assert(probe.request.headers['X-Station-Ids'] == '');
  final previous = probe.request;
  for (final invalid in [<String>[], ['.'], ['..']]) {
    try {
      await client.removeStations(ids: invalid, xFlags: []);
      throw StateError('Expected an invalid path segment.');
    } on ArgumentError { assert(identical(probe.request, previous)); }
  }

  const body = updates.Update(name: 'Central');
  const other = all_updates.Update(name: 'Central');
  void checkRequest(String method, {bool hasBody = false}) {
    assert(probe.request.method == method && probe.request.uri.path == '/v1/stations');
    if (hasBody) {
      assert(probe.request.contentType == 'application/json');
      assert((jsonDecode(probe.sent!) as Map)['name'] == 'Central');
    } else {
      assert(probe.sent == null || probe.sent!.isEmpty);
    }
  }
  await client.replaceStation(body: body);
  checkRequest('PUT', hasBody: true);
  assert(await typed.replaceStation(body: other) is all_updates.ReplaceStation204);
  checkRequest('PUT', hasBody: true);
  await client.renameStation(body: body);
  checkRequest('PATCH', hasBody: true);
  assert(await typed.renameStation(body: other) is all_updates.RenameStation204);
  checkRequest('PATCH', hasBody: true);
  await client.clearStations();
  checkRequest('DELETE');
  assert(await typed.clearStations() is all_updates.ClearStations204);
  checkRequest('DELETE');
  await client.refreshStations();
  checkRequest('POST');
  assert(await typed.refreshStations() is all_updates.RefreshStations204);
  checkRequest('POST');

  const parts = ['north', 'west'];
  void checkFormats() {
    final request = probe.request;
    assert(request.uri.path == '/v1/batch/north%20west/north%09west/north%7Cwest');
    assert(request.headers['X-Regions'] == 'north west');
    assert(request.headers['X-Zones'] == 'north\twest');
    assert(request.headers['X-Modes'] == 'north|west');
  }
  await batch.ApiClient(dio).batch(regions: parts, xRegions: parts, zones: parts, xZones: parts, modes: parts, xModes: parts);
  checkFormats();
  assert(await all_batch.ApiClient(dio).batch(regions: parts, xRegions: parts, zones: parts, xZones: parts, modes: parts, xModes: parts) is all_batch.Batch204);
  checkFormats();

  final selectors = paths.ApiClient(dio);
  final allSelectors = all_paths.ApiClient(dio);
  const lines = ['a;b', '', 'c=d'];
  const zones = ['a/b', 'n?'];
  const path = '/v1/select/line;line-id=a%3Bb;line-id;line-id=c%3Dd;group=1,2/area.a%2Fb.n%3F.3,4/point.A%23;sector=X%2FY';
  await selectors.selectStations(lineId: lines, group: [1, 2], zones: zones, tracks: [3, 4], label: 'A#', sector: 'X/Y');
  assert(probe.request.uri.path == path);
  assert(await allSelectors.selectStations(lineId: lines, group: [1, 2], zones: zones, tracks: [3, 4], label: 'A#', sector: 'X/Y') is all_paths.SelectStations204);
  assert(probe.request.uri.path == path);
  await selectors.selectStations(lineId: [], group: [], zones: [], tracks: [], label: '', sector: '');
  assert(probe.request.uri.path == '/v1/select/line/area/point.;sector');
}
""";
