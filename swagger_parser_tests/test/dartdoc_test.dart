@TestOn('vm')
@Timeout(Duration(minutes: 10))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/consumer_matrix.dart';

void main() {
  test('builds documented and deprecated APIs', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_dartdoc_');
    addTearDown(() => dir.delete(recursive: true));
    Future<void> write(String path, String value) async {
      final file = File('${dir.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString(value);
    }

    Future<ProcessResult> dart(List<String> args, {bool success = true}) async {
      final ProcessResult result = await Process.run(
        Platform.resolvedExecutable,
        args,
      );
      if (success) {
        expect(
          result.exitCode,
          0,
          reason: '${args.join(' ')}\n${result.stdout}\n${result.stderr}',
        );
      }
      return result;
    }

    await write(
      'analysis_options.yaml',
      'analyzer:\n  language:\n    strict-casts: true\n',
    );
    for (final family in ['v2', 'v3_2']) {
      for (final DtoSerializer serializer in DtoSerializer.values) {
        for (final HttpClientBackend backend in HttpClientBackend.values) {
          if (!isFocusedConsumer(serializer, backend)) {
            continue;
          }
          for (final docs in [false, true]) {
            final folder = '${family}_${serializer.name}_${backend.name}_$docs';
            Map<String, String>? expected;
            for (final ext in ['json', 'yaml']) {
              const loader = FileSchemaSourceLoader();
              final GenerationResult
              result = await const SwaggerParserRunner().generate(
                await loader.loadPath(
                  '../swagger_parser/test/fixtures/documentation/$family.$ext',
                ),
                loader: loader,
                config: GenerationConfig(
                  serializer: serializer,
                  httpClient: backend,
                  generateDocs: docs,
                  applyParameterDefaults: true,
                  bodyPositional: true,
                ),
              );
              final Map<String, String> files = {
                for (final f in result.files) f.relativePath: f.content,
              };
              expected ??= files;
              expect(files, expected);
            }
            for (final MapEntry<String, String> f in expected!.entries) {
              await write('$folder/${f.key}', f.value);
            }
            await write('${folder}_test.dart', _driver(folder, backend));
          }
        }
      }
    }
    final String checks = await groupConsumerTests(dir);
    await dart(['run', 'build_runner', 'build']);
    await dart(['analyze', dir.path]);
    await dart(['test', '--concurrency=1', checks]);
  });
}

String _driver(String folder, HttpClientBackend backend) {
  final http = backend == HttpClientBackend.http;
  return '''
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http; import 'package:http/testing.dart';" : "import 'dart:typed_data'; import 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/api.dart';

void main() {
  test('calls documented APIs without changing wire values', () async {
    final wire = {'id':'north', 'kind':'rail'};
    final station = Station.fromJson(wire);
    expect(station.toJson()['id'], 'north');
    final requests = <String>[];
    String reply(Uri uri, String? body) {
      requests.add(uri.path);
      if (uri.queryParameters.containsKey('limit')) expect(uri.queryParameters['limit'], '2');
      if (body != null && uri.path == '/stations') expect((jsonDecode(body) as Map)['id'],'north');
      return jsonEncode(wire);
    }
    ${http ? "final transport = MockClient((r) async => http.Response(reply(r.url, r.method == 'POST' ? r.body : null),r.method == 'GET' ? 200 : 204,headers:{'content-type':'application/json'})); final api=Api(transport,baseUrl:Uri.parse('https://example.test'));" : "final transport = Dio(BaseOptions(baseUrl:'https://example.test')); transport.httpClientAdapter=Adapter(reply); final api=Api(transport);"}
    expect((await api.api.getStation(limit:2)).id,'north');
    await api.api.saveStation(station);
    await api.api.sendForm(label:'old');
    expect(requests,['/stations','/stations','/form']);
    transport.${http ? 'close()' : 'close(force:true)'};
  });
}
${http ? '' : '''
class Adapter implements HttpClientAdapter {
  Adapter(this.reply);
  final String Function(Uri,String?) reply;
  @override Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancel) async {
    final bytes = <int>[];
    if (stream != null) await for (final chunk in stream) { bytes.addAll(chunk); }
    return ResponseBody.fromString(reply(options.uri,options.method=='POST' ? utf8.decode(bytes):null),options.method=='GET'?200:204,headers:{'content-type':['application/json']});
  }
  @override void close({bool force=false}) {}
}
'''}
''';
}
