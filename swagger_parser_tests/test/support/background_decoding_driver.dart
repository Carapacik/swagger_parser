import 'package:swagger_parser/swagger_parser.dart';

/// Exercises generated clients against raw HTTP responses on VM and web.
String backgroundDecodingDriver(
  String folder,
  HttpClientBackend backend,
  ResponseMode mode,
  String baseUrl, {
  bool wrapped = true,
}) {
  final http = backend == HttpClientBackend.http;
  final all = mode == ResponseMode.allStatuses;
  String value(String call, String op) => all
      ? '((await $call) as api.${op}200).value'
      : !wrapped
      ? '(await $call)'
      : '(await $call).data${backend == HttpClientBackend.dio && !op.startsWith('GetNullable') ? '!' : ''}';
  final stop = http ? 'Completer<void>()' : 'CancelToken()';
  final cancel = http ? 'stop.complete()' : "stop.cancel('Cancelled')";
  final arg = http ? 'abortTrigger: stop.future' : 'cancelToken: stop';
  final error = http
      ? 'isA<http.RequestAbortedException>()'
      : 'isA<DioException>().having((e) => e.type, "type", DioExceptionType.cancel)';
  return '''
import 'dart:async';
import 'package:test/test.dart';
${http ? "import 'package:http/http.dart' as http;" : "import 'package:dio/dio.dart';"}
import '$folder/api.dart' as api;

void main() {
  late api.Api root;
  late ${http ? 'http.Client' : 'Dio'} transport;
  setUp(() {
    transport = ${http ? 'http.Client()' : "Dio(BaseOptions(baseUrl: '$baseUrl'))"};
    root = api.Api(transport${http ? ", baseUrl: Uri.parse('$baseUrl')" : ''});
  });
  tearDown(() => transport.${http ? 'close()' : 'close(force: true)'});
  test('reads DTOs, enums, nulls, and empty responses', () async {
    final station = ${value("root.api.getStation(scenario: 'normal')", 'GetStation')};
    expect(station.name, 'Север');
    expect(station.state.toJson(), 'paused');
    final states = ${value('root.api.getStates()', 'GetStates')};
    expect(states.map((s) => s.toJson()), ['active', 'paused']);
    final state = ${value('root.api.getState()', 'GetState')};
    expect(state.toJson(), 'paused');
    expect(${value('root.api.getNullableStates()', 'GetNullableStates')}, isNull);
    expect(${value('root.api.getNullable()', 'GetNullable')}, isNull);
    await root.api.getEmpty();
  });
  ${all
      ? '''
  test('decodes a declared error response', () async {
    final result = await root.api.getStation(scenario: 'error');
    expect((result as api.GetStation400).value.message, 'Missing station');
  });
  '''
      : !wrapped
      ? '''
  test('keeps HTTP errors in first success mode', () async {
    await expectLater(root.api.getStation(scenario: 'error'), throwsA(${http ? 'isA<http.ClientException>()' : "isA<DioException>().having((e) => (e.response?.data as Map<String, dynamic>?)?['message'], 'body', 'Missing station')"}));
  });
  '''
      : '''
  test('retains transport metadata and HTTP errors', () async {
    final response = await root.api.getStation(scenario: 'normal');
    expect(response.${backend == HttpClientBackend.dio ? 'statusCode' : 'response.statusCode'}, 200);
    expect(response.${backend == HttpClientBackend.dio
            ? 'headers.value("content-type")'
            : http
            ? 'response.headers["content-type"]'
            : 'response.headers.value("content-type")'}, contains('application/json'));
    ${http
            ? "expect((response.response as http.Response).body, contains('Север'));"
            : backend == HttpClientBackend.retrofit
            ? "expect((response.response.data as Map<String, dynamic>)['name'], 'Север');"
            : ''}
    await expectLater(root.api.getStation(scenario: 'error'), throwsA(${http ? 'isA<http.ClientException>()' : "isA<DioException>().having((e) => (e.response?.data as Map<String, dynamic>?)?['message'], 'body', 'Missing station')"}));
  });
  '''}
  ${all ? '' : '''
  test('keeps text error bodies', () async {
    await expectLater(root.api.getStation(scenario: 'errorText'), throwsA(${http ? 'isA<http.ClientException>()' : "isA<DioException>().having((e) => e.response?.data, 'body', 'Missing station')"}));
  });
  '''}
  for (final scenario in ['badJson', 'badDto', 'badEnum']) {
    test('propagates decode errors: \$scenario', () async {
      await expectLater(root.api.getStation(scenario: scenario), throwsA(anything));
      final station = ${value("root.api.getStation(scenario: 'normal')", 'GetStation')};
      expect(station.name, 'Север');
    });
  }
  test('cancels before sending', () async {
    final stop = $stop;
    $cancel;
    await expectLater(root.api.getStation(scenario: 'normal', $arg), throwsA($error));
  });
  for (final scenario in ['wait', 'chunks']) {
    test('cancels during response: \$scenario', () async {
      final stop = $stop;
      final call = root.api.getStation(scenario: scenario, $arg);
      final check = expectLater(call, throwsA($error));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      $cancel;
      await check;
    });
  }
}
''';
}

/// Proves worker execution, typed errors, and cancellation during decoding.
String workerDriver(String folder) =>
    '''
@TestOn('vm')
library;
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:test/test.dart';
import '$folder/_response_decoder.dart' as decoder;

int isolateId(Object? value) => Isolate.current.hashCode;
Object? Function(Object?) waitForCancel(SendPort port) => (value) {
  port.send(true);
  while (true) {}
};

void main() {
  test('runs the converter in another isolate', () async {
    final value = await decoder.decodeResponse(Stream.value(utf8.encode('{}')), isolateId);
    expect(value, isNot(Isolate.current.hashCode));
  });
  test('retains typed errors', () async {
    await expectLater(decoder.decodeResponse(Stream.value(utf8.encode('{')), isolateId), throwsA(isA<FormatException>()));
    await expectLater(decoder.decodeResponse(Stream.value(utf8.encode('{}')), (value) => throw StateError('Codec failed')), throwsA(isA<StateError>().having((e) => e.message, 'message', 'Codec failed')));
  });
  test('kills a running decoder on cancellation', () async {
    final started = ReceivePort();
    addTearDown(started.close);
    final port = started.sendPort;
    final stop = Completer<Object>();
    final call = decoder.decodeResponse(Stream.value(utf8.encode('{}')), waitForCancel(port), cancelled: stop.future);
    final check = expectLater(call, throwsA(isA<StateError>().having((e) => e.message, 'message', 'Cancelled')));
    await started.first.timeout(const Duration(seconds: 5));
    stop.complete(StateError('Cancelled'));
    await check.timeout(const Duration(seconds: 2));
  });
}
''';

/// Tests shared cancellation cleanup and the web fallback.
String decoderDriver(String folder) =>
    '''
import 'dart:async';
import 'dart:convert';
import 'package:test/test.dart';
import '$folder/_response_decoder.dart' as decoder;

void main() {
  test('keeps cancellation errors when stream cleanup fails', () async {
    final source = StreamController<List<int>>(onCancel: () => Future<void>.error(StateError('Cleanup failed')));
    final stop = Completer<Object>();
    final call = decoder.readResponseBytes(source.stream, cancelled: stop.future);
    final check = expectLater(call, throwsA(isA<StateError>().having((e) => e.message, 'message', 'Cancelled')));
    stop.complete(StateError('Cancelled'));
    await check;
    await source.close();
    await Future<void>.delayed(Duration.zero);
  });
  test('retains source stream errors', () async {
    await expectLater(decoder.readResponseBytes(Stream.error(StateError('Read failed'))), throwsA(isA<StateError>().having((e) => e.message, 'message', 'Read failed')));
  });
  test('runs web conversion in the caller zone', () async {
    final value = await runZoned(() => decoder.decodeResponse(Stream.value(utf8.encode('{}')), (value) => Zone.current[#marker]), zoneValues: {#marker: 42});
    expect(value, 42);
  }, skip: !const bool.fromEnvironment('dart.library.js_interop'));
}
''';
