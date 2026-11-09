@TestOn('vm')
@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
    'builds batch CLI output for all HTTP backends with separate imports',
    () async {
      final Directory dir = await Directory('test')
          .createTemp('generated_inputs_');
      addTearDown(() => dir.delete(recursive: true));
      final fixtures = Directory('../swagger_parser/test/fixtures/inputs');
      await for (final FileSystemEntity entity in fixtures.list()) {
        if (entity is File) {
          await entity.copy(
            dir.uri.resolve(entity.uri.pathSegments.last).toFilePath(),
          );
        }
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

      Future<Map<String, String>> sources() async => {
        await for (final entity in dir.list(recursive: true))
          if (entity is File && entity.path.endsWith('.dart'))
            entity.path.substring(dir.path.length + 1): await entity
                .readAsString(),
      };
      await dart(['run', 'swagger_parser', '-f', '${dir.path}/config.json']);
      final Map<String, String> json = await sources();
      await dart(['run', 'swagger_parser', '-f', '${dir.path}/config.yaml']);
      expect(await sources(), json);
      await File('${dir.path}/analysis_options.yaml')
          .writeAsString('analyzer:\n  language:\n    strict-casts: true\n');
      await File('${dir.path}/main.dart').writeAsString(_driver);
      await dart(['run', 'build_runner', 'build']);
      await dart(['analyze', dir.path]);
      await dart(['--enable-asserts', '${dir.path}/main.dart']);
    },
  );
}

const _driver = '''
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'out/legacy/api.dart' as legacy;
import 'out/current/api.dart' as current;
import 'out/modern/api.dart' as modern;
import 'custom/latest/latest_api.dart' as latest;

Future<void> main() async {
  final paths = <String>[];
  String reply(Uri uri) {
    paths.add(uri.path);
    return jsonEncode({'id': uri.pathSegments.last});
  }
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.httpClientAdapter = Adapter(reply);
  final transport = MockClient((request) async => http.Response(reply(request.url), 200, headers: {'content-type':'application/json'}));
  final legacyApi = legacy.Api(dio);
  final currentApi = current.Api(dio);
  final modernApi = modern.Api(transport, baseUrl: Uri.parse('https://example.test'));
  final latestApi = latest.LatestApi(transport, baseUrl: Uri.parse('https://example.test'));
  final legacy.Station a = await legacyApi.stations.getStation(id:'one');
  final current.Station b = await currentApi.stations.getStation(id:'two');
  final modern.Station c = await modernApi.stations.getStation(id:'three');
  final latest.Station d = await latestApi.stations.getStation(id:'four');
  assert(a.id=='one' && b.id=='two' && c.id=='three' && d.id=='four');
  assert(paths.join(',')=='/stations/one,/stations/two,/stations/three,/stations/four');
  assert(a.toJson()['id']=='one' && d.toJson()['id']=='four');
  assert(legacy.Unused.fromJson({'note':'kept'}).toJson()['note']=='kept');
  assert(current.Unused.fromJson({'note':'kept'}).toJson()['note']=='kept');
  assert(modern.Unused.fromJson({'note':'kept'}).toJson()['note']=='kept');
  assert(latest.Unused.fromJson({'note':'kept'}).toJson()['note']=='kept');
  dio.close(force: true);
  transport.close();
}
class Adapter implements HttpClientAdapter {
  Adapter(this.reply);
  final String Function(Uri) reply;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body, Future<void>? cancel) async => ResponseBody.fromString(reply(options.uri), 200, headers:{Headers.contentTypeHeader:['application/json']});
  @override
  void close({bool force=false}) {}
}
''';
