import 'package:swagger_parser/swagger_parser.dart';

String responseContractDriver(String folder, HttpClientBackend backend) {
  final http = backend == HttpClientBackend.http;
  return '''
import 'dart:convert';
TRANSPORT_IMPORT
import 'package:test/test.dart';
import 'IMPORT_firstSuccess/api.dart' as first;
import 'IMPORT_allStatuses/api.dart' as all;

void main() {
  late Probe probe;
  late first.ApiClient client;
  late all.ApiClient statuses;
  setUp(() {
    probe = Probe();
    CREATE_CLIENTS
  });
  test('decodes one 201, an inline enum at 207, and the lowest exact 2xx', () async {
    probe.respond(201, {'id': 'created'});
    final Future<first.CreatedStation> result = client.created();
    expect((await result).id, 'created');
    expect((await statuses.created() as all.Created201).value.id, 'created');
    for (final state in ['accepted', 'partial']) {
      probe.respond(207, {'state': state});
      expect((await client.multiStatus()).state.toJson(), state);
      expect((await statuses.multiStatus() as all.MultiStatus207).value.state.toJson(), state);
    }
    probe.respond(226, {'token': 'lowest'});
    final first.Ticket ticket = await client.lateSuccess();
    expect(ticket.token, 'lowest');
    expect((await statuses.lateSuccess() as all.LateSuccess226).value.token, 'lowest');
    probe.respond(299, {'id': 'last'});
    expect((await statuses.lateSuccess() as all.LateSuccess299).value.id, 'last');
    probe.respond(200, {'name': 'selected'});
    final first.Station? station = await client.lookupStation(xRequestId: 'test');
    expect(station!.name, 'selected');
  });
  test('returns a distinct typed variant for each declared status', () async {
    String read(all.LookupStationResult result) => switch (result) {
      all.LookupStation200(:final value) => value.name,
      all.LookupStation201(:final value) => value.id,
      all.LookupStation202(:final value) => value.token,
      all.LookupStation204() => 'empty',
      all.LookupStation400(:final value) => value.field,
      all.LookupStation404(:final value) => value.detail,
      all.LookupStation500(:final value) => value.requestId,
    };
    for (final (code, body, text) in [
      (200, {'name': 'station'}, 'station'),
      (201, {'id': 'created'}, 'created'),
      (202, {'token': 'waiting'}, 'waiting'),
      (204, null, 'empty'),
      (400, {'field': 'name'}, 'name'),
      (404, {'detail': 'missing'}, 'missing'),
      (500, {'requestId': 'trace'}, 'trace'),
    ]) {
      probe.respond(code, body);
      expect(read(await statuses.lookupStation(xRequestId: 'test')), text);
    }
  });
  test('keeps transport errors and error DTOs in first success mode', () async {
    expect(first.ValidationError.fromJson({'field': 'name'}).field, 'name');
    expect(first.Problem.fromJson({'detail': 'missing'}).detail, 'missing');
    expect(first.ServerError.fromJson({'requestId': 'trace'}).requestId, 'trace');
    for (final (code, body) in [
      (400, {'field': 'name'}),
      (404, {'detail': 'missing'}),
      (500, {'requestId': 'trace'}),
    ]) {
      probe.respond(code, body);
      await expectLater(client.lookupStation(xRequestId: 'test'), throwsA(STATUS_ERROR));
    }
    probe.respond(400, {'field': 'only-error'});
    final Future<void> result = client.invalid();
    await expectLater(result, throwsA(STATUS_ERROR_400));
    expect((await statuses.invalid() as all.Invalid400).value.field, 'only-error');
  });
  test('distinguishes a 200 list from a bodyless 204', () async {
    probe.respond(200, [{'name': 'north'}, {'name': 'south'}]);
    final List<first.Station>? value = await client.listed();
    expect(value!.map((s) => s.name), ['north', 'south']);
    expect((await statuses.listed() as all.Listed200).value.map((s) => s.name), ['north', 'south']);
    probe.respond(200, []);
    expect(await client.listed(), isEmpty);
    expect((await statuses.listed() as all.Listed200).value, isEmpty);
    probe.respond(204, null);
    expect(await statuses.listed(), isA<all.Listed204>());
    expect(await client.listed(), isNull);
  });
  test('returns null for declared bodyless success before decoding the payload', () async {
    for (final withOptions in [false, true]) {
      final options = withOptions ? ${http ? 'first.HttpRequestOptions()' : 'dio.Options()'} : null;
      probe.respond(204, null);
      final Future<first.Station?> result = client.lookupStation(xRequestId: 'test', options: options);
      expect(await result, isNull);
      probe.respond(200, {'name': 'reply'});
      expect((await client.lookupStation(xRequestId: 'test', options: options))!.name, 'reply');
      for (final body in ['', 'null', '{', '{}']) {
        probe.body = body;
        await expectLater(client.lookupStation(xRequestId: 'test', options: options), throwsA(anything));
      }
      probe.respond(204, null);
      await expectLater(client.getStation(id: 'test', xRequestId: 'test', options: options), throwsA(anything));
    }
  });
  test('uses void for bodyless 200 and only 204 responses', () async {
    probe.respond(200, null);
    final Future<void> noContent = client.noContent();
    await noContent;
    expect(await statuses.noContent(), isA<all.NoContent200>());
    probe.respond(204, null);
    final Future<void> empty = client.empty();
    await empty;
    expect(await statuses.empty(), isA<all.Empty204>());
  });
  test('keeps unconstrained JSON distinct from no response schema', () async {
    for (final value in [null, false, 0, '', 'text', [1, null], {'extra': true}]) {
      probe.respond(200, value, jsonNull: true);
      final Object? decoded = await client.unconstrained();
      expect(decoded, value);
      expect((await statuses.unconstrained() as all.Unconstrained200).value, value);
    }
  });
  test('rejects undescribed statuses without inventing result variants', () async {
    for (final code in [203, 503]) {
      probe.respond(code, {'detail': 'undescribed'});
      await expectLater(statuses.lookupStation(xRequestId: 'test'), throwsA(STATUS_ERROR));
    }
  });
  test('keeps transport and decode failures outside status variants', () async {
    probe.respond(200, {'name': 12});
    await expectLater(client.lookupStation(xRequestId: 'test'), throwsA(anything));
    await expectLater(statuses.lookupStation(xRequestId: 'test'), throwsA(anything));
    probe.body = '{';
    await expectLater(statuses.lookupStation(xRequestId: 'test'), throwsA(anything));
    probe.fail = true;
    await expectLater(client.created(), throwsA(TRANSPORT_ERROR));
    await expectLater(statuses.created(), throwsA(TRANSPORT_ERROR));
  });
}

class Probe TRANSPORT_BASE {
  int status = 200;
  String body = '';
  bool fail = false;
  void respond(int status, Object? value, {bool jsonNull = false}) {
    this.status = status;
    body = value == null && !jsonNull ? '' : jsonEncode(value);
  }
  TRANSPORT_SEND
}
'''
      .replaceAll('IMPORT_', '${folder}_')
      .replaceAll(
        'TRANSPORT_IMPORT',
        http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart' as dio;",
      )
      .replaceAll(
        'CREATE_CLIENTS',
        http
            ? "addTearDown(probe.close); client = first.Api(probe, baseUrl: Uri.parse('https://example.test')).api; statuses = all.Api(probe, baseUrl: Uri.parse('https://example.test')).api;"
            : "final transport = dio.Dio(dio.BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = probe; addTearDown(() => transport.close(force: true)); client = first.Api(transport).api; statuses = all.Api(transport).api;",
      )
      .replaceAll(
        'STATUS_ERROR_400',
        http
            ? "isA<http.ClientException>().having((e) => e.message, 'status', contains('400'))"
            : "isA<dio.DioException>().having((e) => e.response?.statusCode, 'status', 400)",
      )
      .replaceAll(
        'STATUS_ERROR',
        http
            ? "isA<http.ClientException>().having((e) => e.message, 'status', contains(code.toString()))"
            : "isA<dio.DioException>().having((e) => e.response?.statusCode, 'status', code)",
      )
      .replaceAll(
        'TRANSPORT_ERROR',
        http ? 'isA<http.ClientException>()' : 'isA<dio.DioException>()',
      )
      .replaceAll(
        'TRANSPORT_BASE',
        http ? 'extends http.BaseClient' : 'implements dio.HttpClientAdapter',
      )
      .replaceAll(
        'TRANSPORT_SEND',
        http
            ? '''
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await request.finalize().drain<void>();
    if (fail) throw http.ClientException('Network failed.', request.url);
    return http.StreamedResponse(Stream.value(utf8.encode(body)), status, headers: {'content-type':'application/json'}, request: request);
  }
'''
            : '''
  @override
  Future<dio.ResponseBody> fetch(dio.RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    await requestStream?.drain<void>();
    if (fail) throw dio.DioException.connectionError(requestOptions: options, reason: 'Network failed.');
    return dio.ResponseBody.fromString(body, status, headers: {'content-type':['application/json']});
  }
  @override
  void close({bool force = false}) {}
''',
      );
}
