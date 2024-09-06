import 'package:swagger_parser/src/generator/config/generator_config.dart';
import 'package:swagger_parser/src/generator/generator/fill_controller.dart';
import 'package:swagger_parser/src/parser/swagger_parser_core.dart';
import 'package:test/test.dart';

void main() {
  group('Empty root client', () {
    test('dart', () async {
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: ''),
      );
      final filledContent = fillController.fillRootClient([]);
      const expectedContents = '';
      expect(filledContent.content, expectedContents);
    });
  });

  group('Version getter', () {
    test('dart', () async {
      final clients = [
        const UniversalRestClient(name: 'One', imports: {}, requests: []),
      ];
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: ''),
        info: OpenApiInfo(apiVersion: '1.0.0', schemaVersion: OAS.v3_1),
      );
      final filledContent = fillController.fillRootClient(clients);
      const expectedContents = '''
import 'package:dio/dio.dart';

import 'one/one_client.dart';

///  `v1.0.0`
class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '1.0.0';

  OneClient? _one;

  OneClient get one => _one ??= OneClient(_dio, baseUrl: _baseUrl);
}
''';
      expect(filledContent.content, expectedContents);
    });
  });

  group('root client with one client', () {
    test('dart', () async {
      final clients = [
        const UniversalRestClient(name: 'One', imports: {}, requests: []),
      ];
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: ''),
      );
      final filledContent = fillController.fillRootClient(clients);
      const expectedContents = '''
import 'package:dio/dio.dart';

import 'one/one_client.dart';

class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '';

  OneClient? _one;

  OneClient get one => _one ??= OneClient(_dio, baseUrl: _baseUrl);
}
''';
      expect(filledContent.content, expectedContents);
    });
  });

  group('root client with multiple clients', () {
    test('dart', () async {
      final clients = [
        const UniversalRestClient(name: 'One', imports: {}, requests: []),
        const UniversalRestClient(name: 'Two', imports: {}, requests: []),
        const UniversalRestClient(name: 'Three', imports: {}, requests: []),
        const UniversalRestClient(name: 'Four', imports: {}, requests: []),
        const UniversalRestClient(name: 'Five', imports: {}, requests: []),
      ];
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: ''),
      );
      final filledContent = fillController.fillRootClient(clients);
      const expectedContents = '''
import 'package:dio/dio.dart';

import 'one/one_client.dart';
import 'two/two_client.dart';
import 'three/three_client.dart';
import 'four/four_client.dart';
import 'five/five_client.dart';

class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '';

  OneClient? _one;
  TwoClient? _two;
  ThreeClient? _three;
  FourClient? _four;
  FiveClient? _five;

  OneClient get one => _one ??= OneClient(_dio, baseUrl: _baseUrl);

  TwoClient get two => _two ??= TwoClient(_dio, baseUrl: _baseUrl);

  ThreeClient get three => _three ??= ThreeClient(_dio, baseUrl: _baseUrl);

  FourClient get four => _four ??= FourClient(_dio, baseUrl: _baseUrl);

  FiveClient get five => _five ??= FiveClient(_dio, baseUrl: _baseUrl);
}
''';
      expect(filledContent.content, expectedContents);
    });
  });

  group('root client with one client and put clients in folder', () {
    test('dart', () async {
      final clients = [
        const UniversalRestClient(name: 'One', imports: {}, requests: []),
      ];
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          putClientsInFolder: true,
        ),
      );
      final filledContent = fillController.fillRootClient(clients);
      const expectedContents = '''
import 'package:dio/dio.dart';

import 'clients/one_client.dart';

class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '';

  OneClient? _one;

  OneClient get one => _one ??= OneClient(_dio, baseUrl: _baseUrl);
}
''';
      expect(filledContent.content, expectedContents);
    });
  });

  group('root client with multiple clients and put clients in folder', () {
    test('dart', () async {
      final clients = [
        const UniversalRestClient(name: 'One', imports: {}, requests: []),
        const UniversalRestClient(name: 'Two', imports: {}, requests: []),
        const UniversalRestClient(name: 'Three', imports: {}, requests: []),
        const UniversalRestClient(name: 'Four', imports: {}, requests: []),
        const UniversalRestClient(name: 'Five', imports: {}, requests: []),
      ];
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          putClientsInFolder: true,
        ),
      );
      final filledContent = fillController.fillRootClient(clients);
      const expectedContents = '''
import 'package:dio/dio.dart';

import 'clients/one_client.dart';
import 'clients/two_client.dart';
import 'clients/three_client.dart';
import 'clients/four_client.dart';
import 'clients/five_client.dart';

class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '';

  OneClient? _one;
  TwoClient? _two;
  ThreeClient? _three;
  FourClient? _four;
  FiveClient? _five;

  OneClient get one => _one ??= OneClient(_dio, baseUrl: _baseUrl);

  TwoClient get two => _two ??= TwoClient(_dio, baseUrl: _baseUrl);

  ThreeClient get three => _three ??= ThreeClient(_dio, baseUrl: _baseUrl);

  FourClient get four => _four ??= FourClient(_dio, baseUrl: _baseUrl);

  FiveClient get five => _five ??= FiveClient(_dio, baseUrl: _baseUrl);
}
''';
      expect(filledContent.content, expectedContents);
    });
  });
}
