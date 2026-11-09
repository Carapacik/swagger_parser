@TestOn('vm')
@Timeout(Duration(minutes: 2))
library;

import 'dart:io';
import 'dart:isolate';

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/src/cli/remote_schema_loader.dart';
import 'package:swagger_parser/src/cli/schema_download_config.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _fixtures = 'test/fixtures/schema_download';
const _environment = {
  'SCHEMA_AUTHORIZATION': 'Bearer source-secret',
  'CHILD_AUTHORIZATION': 'Bearer child-secret',
  'SHARED_SCHEMA_KEY': 'destination-secret',
};

typedef _Request = ({String server, String path, Map<String, String?> headers});

void main() {
  late Directory root;
  late HttpServer first;
  late HttpServer second;
  late String executable;
  final requests = <_Request>[];
  File file(String path) => File.fromUri(root.uri.resolve(path));
  String getBase(HttpServer server) => 'http://127.0.0.1:${server.port}';

  Future<String> fixture(String name, String ext) async =>
      (await File('$_fixtures/$name.$ext').readAsString())
          .replaceAll('PORT_A', '${first.port}')
          .replaceAll('PORT_B', '${second.port}')
          .replaceAll('EXT', ext);

  Future<CliConfig> config(String name, String ext, {String? source}) async {
    String text = await fixture(name, ext);
    if (source != null) {
      text = text.replaceAll('${getBase(first)}/start.$ext', source);
    }
    await file('config.$ext').writeAsString(text);
    return await CliConfig.load(configPath: file('config.$ext').path);
  }

  Future<ProcessResult> cli(String ext, [List<String> args = const []]) =>
      Process.run(
        Platform.resolvedExecutable,
        [executable, ...args, '-f', 'config.$ext'],
        workingDirectory: root.path,
        environment: _environment,
      );

  Future<void> serve(HttpRequest request, String server) async {
    requests.add((
      server: server,
      path: request.uri.path,
      headers: {
        for (final name in [
          'authorization',
          'x-schema-key',
          'cookie',
          'x-api-key',
        ])
          name: request.headers.value(name),
      },
    ));
    final String path = request.uri.path;
    final ext = path.endsWith('.yaml') ? 'yaml' : 'json';
    final HttpResponse response = request.response;
    response.headers.contentType = ext == 'json'
        ? ContentType.json
        : ContentType('application', 'yaml');
    if (path.startsWith('/status/')) {
      response.statusCode = int.parse(path.split('/').last.split('.').first);
      response.headers.set('location', '/plain.$ext');
    } else if (path == '/start.$ext') {
      response.statusCode = 302;
      response.headers.set('location', '/version/openapi.$ext');
    } else if (path == '/cross-start.$ext') {
      response.statusCode = 302;
      response.headers.set(
        'location',
        '${getBase(second)}/version/openapi.$ext',
      );
    } else if (path == '/cross-ref.$ext') {
      response.statusCode = 307;
      response.headers.set('location', '${getBase(second)}/shared.$ext');
    } else if (path == '/loop') {
      response.statusCode = 308;
      response.headers.set('location', '/loop');
    } else if (path == '/userinfo') {
      response.statusCode = 302;
      response.headers.set(
        'location',
        'http://user:redirect-secret@127.0.0.1:${second.port}/plain.json',
      );
    } else if (path == '/missing-location') {
      response.statusCode = 301;
    } else if (path == '/error') {
      response
        ..statusCode = 401
        ..reasonPhrase = 'source-secret';
    } else if (path == '/version/openapi.$ext') {
      response.write(await fixture('entry', ext));
    } else if (path == '/plain.$ext') {
      response.write(await fixture('plain', ext));
    } else if (path == '/version/models/station.$ext' ||
        path == '/shared.$ext') {
      response.write(await fixture('station', ext));
    } else {
      response.statusCode = 404;
    }
    await response.close();
  }

  setUpAll(() async {
    final Directory compiled = await Directory.systemTemp.createTemp(
      'auth_cli_',
    );
    addTearDown(() => compiled.delete(recursive: true));
    executable = File.fromUri(compiled.uri.resolve('cli.dill')).path;
    final ProcessResult result = await Process.run(
      Platform.resolvedExecutable,
      [
        'compile',
        'kernel',
        'bin/swagger_parser.dart',
        '-o',
        executable,
        '--packages=${(await Isolate.packageConfig)!.toFilePath()}',
      ],
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });

  setUp(() async {
    root = await Directory.systemTemp.createTemp('schema_auth_');
    first = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    second = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    requests.clear();
    first.listen((request) => serve(request, 'first'));
    second.listen((request) => serve(request, 'second'));
    addTearDown(() async {
      await first.close(force: true);
      await second.close(force: true);
      await root.delete(recursive: true);
    });
  });

  test(
    'normalizes origins and rejects invalid credential config without values',
    () async {
      for (final ext in ['json', 'yaml']) {
        final CliConfig normalized = await config('normalize', ext);
        final SchemaDownloadConfig download = normalized.schemaDownload;
        expect(
          download.headersFor(
            Uri.parse('https://example.com/schema'),
            _environment,
          ),
          {'authorization': 'Bearer source-secret'},
        );
        for (final uri in [
          'http://example.com/schema',
          'https://sub.example.com/schema',
          'https://example.com:8443/schema',
          'https://example.com.evil/schema',
        ]) {
          expect(download.headersFor(Uri.parse(uri), _environment), isEmpty);
        }
        for (final name in [
          'duplicate_origin',
          'duplicate_header',
          'bad_origin',
          'wildcard',
          'header_name',
          'literal_newline',
          'env_type',
          'env_missing',
          'env_unknown',
          'null_list',
        ]) {
          try {
            await config('invalid_$name', ext);
            fail('Accepted $name.');
          } on FormatException catch (error) {
            expect(error.message, isNot(contains('literal-secret')));
            expect(error.message, isNot(contains('origin-secret')));
          }
        }
      }
    },
  );

  test('loads complete documents and external refs without forwarding source credentials', () async {
    for (final ext in ['json', 'yaml']) {
      for (final withDestination in [false, true]) {
        requests.clear();
        final CliConfig settings = await config(
          withDestination ? 'other_origin' : 'single',
          ext,
        );
        final loader = RemoteSchemaLoader(
          config: settings.schemaDownload,
          environment: _environment,
        );
        try {
          final SchemaSource source = await loader.load(settings.input);
          expect(
            source.uri,
            Uri.parse('${getBase(first)}/version/openapi.$ext'),
          );
          expect(
            await const SwaggerParserRunner().validate(source, loader: loader),
            isEmpty,
          );
          expect(
            requests.where((r) => r.server == 'first').map((r) => r.path),
            containsAll([
              '/start.$ext',
              '/version/openapi.$ext',
              '/version/models/station.$ext',
              '/cross-ref.$ext',
            ]),
          );
          expect(requests.where((r) => r.server == 'second'), isNotEmpty);
          for (final r in requests) {
            if (r.server == 'first') {
              expect(r.headers['authorization'], 'Bearer source-secret');
              expect(r.headers['x-schema-key'], 'literal-source-key');
              expect(r.headers['cookie'], 'session=source-cookie');
              expect(r.headers['x-api-key'], isNull);
            } else {
              expect(r.headers['authorization'], isNull);
              expect(r.headers['x-schema-key'], isNull);
              expect(r.headers['cookie'], isNull);
              expect(
                r.headers['x-api-key'],
                withDestination ? 'destination-secret' : null,
              );
            }
          }
        } finally {
          loader.close();
        }
      }
    }
  });

  test('reselects credentials on cross-origin entry redirects and all GET redirect statuses', () async {
    for (final ext in ['json', 'yaml']) {
      final CliConfig settings = await config('other_origin', ext);
      final loader = RemoteSchemaLoader(
        config: settings.schemaDownload,
        environment: _environment,
      );
      try {
        final SchemaSource source = await loader.load(
          Uri.parse('${getBase(first)}/cross-start.$ext'),
        );
        expect(
          source.uri,
          Uri.parse('${getBase(second)}/version/openapi.$ext'),
        );
        await const SwaggerParserRunner().validate(source, loader: loader);
        expect(
          requests.where((r) => r.server == 'second').map((r) => r.path),
          contains('/version/models/station.$ext'),
        );
        for (final _Request r in requests.where((r) => r.server == 'second')) {
          expect(r.headers['authorization'], isNull);
          expect(r.headers['cookie'], isNull);
          expect(r.headers['x-api-key'], 'destination-secret');
        }
        requests.clear();
        for (final code in [301, 302, 303, 307, 308]) {
          await loader.load(Uri.parse('${getBase(first)}/status/$code.$ext'));
        }
        expect(requests, hasLength(10));
        expect(
          requests.map((r) => r.headers['authorization']),
          everyElement('Bearer source-secret'),
        );
      } finally {
        loader.close();
        requests.clear();
      }
    }
  });

  test('uses auth in CLI generate and checks without writing it to output or copies', () async {
    for (final ext in ['json', 'yaml']) {
      await config('single', ext);
      final ProcessResult generated = await cli(ext);
      expect(
        generated.exitCode,
        0,
        reason: '${generated.stdout}\n${generated.stderr}',
      );
      expect(
        await file('openapi.$ext').readAsString(),
        await fixture('entry', ext),
      );
      for (final args in [
        ['validate'],
        ['--check'],
      ]) {
        final ProcessResult checked = await cli(ext, args);
        expect(checked.exitCode, 0, reason: checked.stderr.toString());
      }
      final output = '${generated.stdout}\n${generated.stderr}';
      for (final String secret in [
        ..._environment.values,
        'literal-source-key',
        'source-secret',
        'source-cookie',
      ]) {
        expect(output, isNot(contains(secret)));
        await for (final FileSystemEntity entity in Directory.fromUri(
          root.uri.resolve('out/'),
        ).list(recursive: true)) {
          if (entity is File && entity.path.endsWith('.dart')) {
            expect(await entity.readAsString(), isNot(contains(secret)));
          }
        }
      }
      requests.clear();
      await config(
        'single',
        ext,
        source: '${getBase(first)}/error?token=source-secret',
      );
      final ProcessResult error = await cli(ext);
      expect(error.exitCode, 1);
      expect(error.stderr.toString(), contains('HTTP 401'));
      expect(error.stderr.toString(), contains('[redacted]'));
      expect(error.stderr.toString(), isNot(contains('source-secret')));
      expect(requests, hasLength(1));
    }
  });

  test(
    'keeps missing environment values and config syntax errors out of logs',
    () async {
      for (final ext in ['json', 'yaml']) {
        await config('single', ext);
        final ProcessResult result = await Process.run(
          Platform.resolvedExecutable,
          [executable, '-f', 'config.$ext'],
          workingDirectory: root.path,
          environment: {..._environment, 'SCHEMA_AUTHORIZATION': ''},
        );
        expect(result.exitCode, 1);
        expect(result.stderr.toString(), contains('SCHEMA_AUTHORIZATION'));
        expect(requests, isEmpty);
      }
      await File('$_fixtures/invalid_syntax.yaml')
          .copy(file('config.yaml').path);
      final ProcessResult syntax = await cli('yaml');
      expect(syntax.exitCode, 64);
      expect(syntax.stderr.toString(), isNot(contains('syntax-secret')));
      expect(requests, isEmpty);
    },
  );

  test(
    'isolates inherited, replaced, and cleared credentials across inputs',
    () async {
      for (final ext in ['json', 'yaml']) {
        requests.clear();
        await file('config.$ext').writeAsString(await fixture('inputs', ext));
        final ProcessResult result = await cli(ext);
        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );
        expect(requests.map((r) => r.headers['authorization']), [
          'Bearer source-secret',
          'Bearer child-secret',
          null,
        ]);
        expect(requests.map((r) => r.headers['cookie']), [
          'session=source-cookie',
          null,
          null,
        ]);
        for (final id in ['inherited', 'replaced', 'cleared']) {
          expect(file('batch/$id/api.dart').existsSync(), isTrue);
          expect(file('${id}_plain.$ext').existsSync(), isTrue);
        }
        requests.clear();
        expect((await cli(ext, ['validate'])).exitCode, 0);
        expect(requests.map((r) => r.headers['authorization']), [
          'Bearer source-secret',
          'Bearer child-secret',
          null,
        ]);
      }
    },
  );

  test(
    'authenticates remote refs from local JSON and YAML entry files',
    () async {
      for (final ext in ['json', 'yaml']) {
        requests.clear();
        await file('local_entry.$ext')
            .writeAsString(await fixture('local_entry', ext));
        await config('local', ext);
        final ProcessResult result = await cli(ext);
        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );
        expect(requests, hasLength(1));
        expect(requests.single.path, '/version/models/station.$ext');
        expect(
          requests.single.headers['authorization'],
          'Bearer source-secret',
        );
        expect(result.stdout.toString(), isNot(contains('Downloaded')));
      }
    },
  );

  test(
    'fails selected missing or invalid environment values before a request',
    () async {
      final CliConfig settings = await config('single', 'yaml');
      for (final env in <Map<String, String>>[
        {},
        {'SCHEMA_AUTHORIZATION': ''},
        {'SCHEMA_AUTHORIZATION': 'bad\r\nvalue'},
      ]) {
        final loader = RemoteSchemaLoader(
          config: settings.schemaDownload,
          environment: env,
        );
        try {
          await expectLater(
            loader.load(settings.input),
            throwsA(isA<OpenApiException>()),
          );
          expect(requests, isEmpty);
          await loader.load(Uri.parse('${getBase(second)}/plain.json'));
          expect(requests.single.headers['authorization'], isNull);
        } finally {
          loader.close();
          requests.clear();
        }
      }
    },
  );

  test(
    'limits redirects and rejects userinfo before the destination request',
    () async {
      final CliConfig settings = await config('single', 'yaml');
      final loader = RemoteSchemaLoader(
        config: settings.schemaDownload,
        environment: _environment,
      );
      try {
        await expectLater(
          loader.load(Uri.parse('${getBase(first)}/loop')),
          throwsA(
            isA<OpenApiException>().having(
              (e) => e.message,
              'message',
              contains('limit'),
            ),
          ),
        );
        expect(requests, hasLength(6));
        requests.clear();
        await expectLater(
          loader.load(Uri.parse('${getBase(first)}/userinfo')),
          throwsA(isA<OpenApiException>()),
        );
        expect(requests, hasLength(1));
        expect(requests.single.server, 'first');
        await expectLater(
          loader.load(Uri.parse('${getBase(first)}/missing-location')),
          throwsA(isA<OpenApiException>()),
        );
      } finally {
        loader.close();
      }
    },
  );

  test(
    'rejects HTTPS downgrade before sending credentials or a request',
    () async {
      final File certificateFile = file('localhost_cert.pem');
      final File keyFile = file('localhost_key.pem');
      final ProcessResult generated = await Process.run('openssl', [
        'req',
        '-x509',
        '-newkey',
        'rsa:2048',
        '-nodes',
        '-days',
        '1',
        '-subj',
        '/CN=localhost',
        '-keyout',
        keyFile.path,
        '-out',
        certificateFile.path,
      ]);
      expect(generated.exitCode, 0, reason: 'OpenSSL: ${generated.stderr}');
      final context = SecurityContext()
        ..useCertificateChain(certificateFile.path)
        ..usePrivateKey(keyFile.path);
      final HttpServer tls = await HttpServer.bindSecure(
        InternetAddress.loopbackIPv4,
        0,
        context,
      );
      addTearDown(() => tls.close(force: true));
      final Uri uri = Uri.parse('https://127.0.0.1:${tls.port}');
      final headers = <String?>[];
      tls.listen((request) async {
        headers.add(request.headers.value('authorization'));
        request.response.statusCode = 302;
        request.response.headers.set(
          'location',
          '${getBase(second)}/plain.json',
        );
        await request.response.close();
      });
      final String certificate = await certificateFile.readAsString();
      final client = HttpClient()
        ..badCertificateCallback = (cert, host, port) =>
            host == uri.host &&
            port == uri.port &&
            cert.pem.trim() == certificate.trim();
      final loader = RemoteSchemaLoader(
        client: client,
        config: SchemaDownloadConfig(
          credentials: [
            SchemaDownloadCredential(uri, const {
              'authorization': SchemaDownloadHeader(value: 'Bearer tls-secret'),
            }),
          ],
        ),
      );
      try {
        await expectLater(
          loader.load(uri.resolve('/start')),
          throwsA(
            isA<OpenApiException>().having(
              (e) => e.message,
              'message',
              contains('HTTPS-to-HTTP'),
            ),
          ),
        );
        expect(headers, ['Bearer tls-secret']);
        expect(requests, isEmpty);
      } finally {
        loader.close();
      }
    },
  );
}
