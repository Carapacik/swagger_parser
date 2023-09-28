import 'package:swagger_parser/src/generator/fill_controller.dart';
import 'package:swagger_parser/src/generator/models/universal_rest_client.dart';
import 'package:test/test.dart';

void main() {
  group('Empty root interface', () {
    test('dart', () async {
      const fillController = FillController.forTests();
      final filledContent = fillController.fillRootInterface([]);
      const expectedContents = '';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('Root interface with one client', () {
    test('dart', () async {
      final clients = [
        const UniversalRestClient(name: 'One', imports: {}, requests: []),
      ];
      const fillController = FillController.forTests();
      final filledContent = fillController.fillRootInterface(clients);
      const expectedContents = '''
import 'package:dio/dio.dart';

import 'one/one_client.dart';

abstract class IRestClient {
  OneClient get one;
}

class RestClient implements IRestClient {
  RestClient({
    required Dio dio,
    required String baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String _baseUrl;

  OneClient? _one;

  @override
  OneClient get one => _one ??= OneClient(_dio, baseUrl: _baseUrl);
}
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('Root interface with multiple clients', () {
    test('dart', () async {
      final clients = [
        const UniversalRestClient(name: 'One', imports: {}, requests: []),
        const UniversalRestClient(name: 'Two', imports: {}, requests: []),
        const UniversalRestClient(name: 'Three', imports: {}, requests: []),
        const UniversalRestClient(name: 'Four', imports: {}, requests: []),
        const UniversalRestClient(name: 'Five', imports: {}, requests: []),
      ];
      const fillController = FillController.forTests();
      final filledContent = fillController.fillRootInterface(clients);
      const expectedContents = '''
import 'package:dio/dio.dart';

import 'one/one_client.dart';
import 'two/two_client.dart';
import 'three/three_client.dart';
import 'four/four_client.dart';
import 'five/five_client.dart';

abstract class IRestClient {
  OneClient get one;

  TwoClient get two;

  ThreeClient get three;

  FourClient get four;

  FiveClient get five;
}

class RestClient implements IRestClient {
  RestClient({
    required Dio dio,
    required String baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String _baseUrl;

  OneClient? _one;
  TwoClient? _two;
  ThreeClient? _three;
  FourClient? _four;
  FiveClient? _five;

  @override
  OneClient get one => _one ??= OneClient(_dio, baseUrl: _baseUrl);

  @override
  TwoClient get two => _two ??= TwoClient(_dio, baseUrl: _baseUrl);

  @override
  ThreeClient get three => _three ??= ThreeClient(_dio, baseUrl: _baseUrl);

  @override
  FourClient get four => _four ??= FourClient(_dio, baseUrl: _baseUrl);

  @override
  FiveClient get five => _five ??= FiveClient(_dio, baseUrl: _baseUrl);
}
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('Root interface with one client and squish', () {
    test('dart', () async {
      final clients = [
        const UniversalRestClient(name: 'One', imports: {}, requests: []),
      ];
      const fillController = FillController.forTests(squishClients: true);
      final filledContent = fillController.fillRootInterface(clients);
      const expectedContents = '''
import 'package:dio/dio.dart';

import 'clients/one_client.dart';

abstract class IRestClient {
  OneClient get one;
}

class RestClient implements IRestClient {
  RestClient({
    required Dio dio,
    required String baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String _baseUrl;

  OneClient? _one;

  @override
  OneClient get one => _one ??= OneClient(_dio, baseUrl: _baseUrl);
}
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('Root interface with multiple clients and squish', () {
    test('dart', () async {
      final clients = [
        const UniversalRestClient(name: 'One', imports: {}, requests: []),
        const UniversalRestClient(name: 'Two', imports: {}, requests: []),
        const UniversalRestClient(name: 'Three', imports: {}, requests: []),
        const UniversalRestClient(name: 'Four', imports: {}, requests: []),
        const UniversalRestClient(name: 'Five', imports: {}, requests: []),
      ];
      const fillController = FillController.forTests(squishClients: true);
      final filledContent = fillController.fillRootInterface(clients);
      const expectedContents = '''
import 'package:dio/dio.dart';

import 'clients/one_client.dart';
import 'clients/two_client.dart';
import 'clients/three_client.dart';
import 'clients/four_client.dart';
import 'clients/five_client.dart';

abstract class IRestClient {
  OneClient get one;

  TwoClient get two;

  ThreeClient get three;

  FourClient get four;

  FiveClient get five;
}

class RestClient implements IRestClient {
  RestClient({
    required Dio dio,
    required String baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String _baseUrl;

  OneClient? _one;
  TwoClient? _two;
  ThreeClient? _three;
  FourClient? _four;
  FiveClient? _five;

  @override
  OneClient get one => _one ??= OneClient(_dio, baseUrl: _baseUrl);

  @override
  TwoClient get two => _two ??= TwoClient(_dio, baseUrl: _baseUrl);

  @override
  ThreeClient get three => _three ??= ThreeClient(_dio, baseUrl: _baseUrl);

  @override
  FourClient get four => _four ??= FourClient(_dio, baseUrl: _baseUrl);

  @override
  FiveClient get five => _five ??= FiveClient(_dio, baseUrl: _baseUrl);
}
''';
      expect(filledContent.contents, expectedContents);
    });
  });
}
