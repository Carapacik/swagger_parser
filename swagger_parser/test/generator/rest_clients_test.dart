import 'package:swagger_parser/src/generator/fill_controller.dart';
import 'package:swagger_parser/src/generator/models/programming_lang.dart';
import 'package:swagger_parser/src/generator/models/universal_rest_client.dart';
import 'package:test/test.dart';

void main() {
  group('Empty rest client', () {
    test('dart + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [],
      );
      const fillController = FillController();
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'rest_client.g.dart';

@RestApi()
abstract class Client {
  factory Client(Dio dio, {required String baseUrl}) = _Client;
}
''';
      expect(filledContent.contents, expectedContents);
    });
    test('kotlin + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [],
      );
      const fillController =
          FillController(programmingLanguage: ProgrammingLanguage.kotlin);
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface Client {}
''';
      expect(filledContent.contents, expectedContents);
    });
  });
  group('Empty rest client with squish clients', () {
    test('dart + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [],
      );
      const fillController = FillController(squishClients: true);
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'class_name.g.dart';

@RestApi()
abstract class ClassNameClient {
  factory ClassNameClient(Dio dio, {required String baseUrl}) = _ClassNameClient;
}
''';
      expect(filledContent.contents, expectedContents);
    });
    test('kotlin + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [],
      );
      const fillController = FillController(
        programmingLanguage: ProgrammingLanguage.kotlin,
        squishClients: true,
      );
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface ClassNameClient {}
''';
      expect(filledContent.contents, expectedContents);
    });
  });
}
