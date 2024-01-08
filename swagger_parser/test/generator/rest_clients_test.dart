// ignore_for_file: avoid_redundant_argument_values

import 'package:swagger_parser/src/generator/fill_controller.dart';
import 'package:swagger_parser/src/generator/models/programming_language.dart';
import 'package:swagger_parser/src/generator/models/universal_request.dart';
import 'package:swagger_parser/src/generator/models/universal_request_type.dart';
import 'package:swagger_parser/src/generator/models/universal_rest_client.dart';
import 'package:swagger_parser/src/generator/models/universal_type.dart';
import 'package:test/test.dart';

void main() {
  group('Empty rest client', () {
    test('dart + retrofit', () async {
      const restClient =
          UniversalRestClient(name: 'Some', imports: {}, requests: []);
      const fillController = FillController();
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'some_client.g.dart';

@RestApi()
abstract class SomeClient {
  factory SomeClient(Dio dio, {String? baseUrl}) = _SomeClient;
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + retrofit', () async {
      const restClient =
          UniversalRestClient(name: 'Some', imports: {}, requests: []);
      const fillController = FillController(
        programmingLanguage: ProgrammingLanguage.kotlin,
      );
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface SomeClient {}
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('Empty rest client with put clients in folder', () {
    test('dart + retrofit', () async {
      const restClient =
          UniversalRestClient(name: 'Some', imports: {}, requests: []);
      const fillController = FillController(putClientsInFolder: true);
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'some_client.g.dart';

@RestApi()
abstract class SomeClient {
  factory SomeClient(Dio dio, {String? baseUrl}) = _SomeClient;
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + retrofit', () async {
      const restClient =
          UniversalRestClient(name: 'Some', imports: {}, requests: []);
      const fillController = FillController(
        programmingLanguage: ProgrammingLanguage.kotlin,
        putClientsInFolder: true,
      );
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface SomeClient {}
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('Client postfix', () {
    test('dart + retrofit', () async {
      const restClient =
          UniversalRestClient(name: 'ClassName', imports: {}, requests: []);
      const fillController = FillController(clientPostfix: 'Api');
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'class_name_api.g.dart';

@RestApi()
abstract class ClassNameApi {
  factory ClassNameApi(Dio dio, {String? baseUrl}) = _ClassNameApi;
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + retrofit', () async {
      const restClient =
          UniversalRestClient(name: 'Some', imports: {}, requests: []);
      const fillController = FillController(
        programmingLanguage: ProgrammingLanguage.kotlin,
        clientPostfix: 'Api',
      );
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface SomeApi {}
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('Empty client postfix', () {
    test('dart + retrofit', () async {
      const restClient =
          UniversalRestClient(name: 'Some', imports: {}, requests: []);
      const fillController = FillController(clientPostfix: '');
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'some.g.dart';

@RestApi()
abstract class Some {
  factory Some(Dio dio, {String? baseUrl}) = _Some;
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + retrofit', () async {
      const restClient =
          UniversalRestClient(name: 'Some', imports: {}, requests: []);
      const fillController = FillController(
        programmingLanguage: ProgrammingLanguage.kotlin,
        clientPostfix: '',
      );
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface Some {}
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('Imports', () {
    test('dart + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {
          'camelClass',
          'snake_class',
          'kebab-class',
          'PascalClass',
          'Space class',
        },
        requests: [],
      );
      const fillController = FillController();
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/camel_class.dart';
import '../models/snake_class.dart';
import '../models/kebab_class.dart';
import '../models/pascal_class.dart';
import '../models/space_class.dart';

part 'class_name_client.g.dart';

@RestApi()
abstract class ClassNameClient {
  factory ClassNameClient(Dio dio, {String? baseUrl}) = _ClassNameClient;
}
''';
      expect(filledContent.contents, expectedContents);
    });
    test('kotlin + retrofit', () async {
      // Imports in Kotlin are not supported yet. You can always add PR
    });
  });

  group('One empty request', () {
    test('dart + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/',
            returnType: null,
            parameters: [],
          ),
        ],
      );
      const fillController = FillController();
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'class_name_client.g.dart';

@RestApi()
abstract class ClassNameClient {
  factory ClassNameClient(Dio dio, {String? baseUrl}) = _ClassNameClient;

  @GET('/')
  Future<void> getRequest();
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/',
            returnType: null,
            parameters: [],
          ),
        ],
      );
      const fillController = FillController(
        programmingLanguage: ProgrammingLanguage.kotlin,
      );
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface ClassNameClient {
    @GET("/")
    suspend fun getRequest()
}
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('All possible type of requests', () {
    test('dart + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/',
            returnType: null,
            parameters: [],
          ),
          UniversalRequest(
            name: 'postRequest',
            requestType: HttpRequestType.post,
            route: '/',
            returnType: null,
            parameters: [],
          ),
          UniversalRequest(
            name: 'putRequest',
            requestType: HttpRequestType.put,
            route: '/',
            returnType: null,
            parameters: [],
          ),
          UniversalRequest(
            name: 'headRequest',
            requestType: HttpRequestType.head,
            route: '/',
            returnType: null,
            parameters: [],
          ),
          UniversalRequest(
            name: 'deleteRequest',
            requestType: HttpRequestType.delete,
            route: '/',
            returnType: null,
            parameters: [],
          ),
          UniversalRequest(
            name: 'patchRequest',
            requestType: HttpRequestType.patch,
            route: '/',
            returnType: null,
            parameters: [],
          ),
          UniversalRequest(
            name: 'connectRequest',
            requestType: HttpRequestType.connect,
            route: '/',
            returnType: null,
            parameters: [],
          ),
          UniversalRequest(
            name: 'optionsRequest',
            requestType: HttpRequestType.options,
            route: '/',
            returnType: null,
            parameters: [],
          ),
          UniversalRequest(
            name: 'traceRequest',
            requestType: HttpRequestType.trace,
            route: '/',
            returnType: null,
            parameters: [],
          ),
        ],
      );
      const fillController = FillController();
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'class_name_client.g.dart';

@RestApi()
abstract class ClassNameClient {
  factory ClassNameClient(Dio dio, {String? baseUrl}) = _ClassNameClient;

  @GET('/')
  Future<void> getRequest();

  @POST('/')
  Future<void> postRequest();

  @PUT('/')
  Future<void> putRequest();

  @HEAD('/')
  Future<void> headRequest();

  @DELETE('/')
  Future<void> deleteRequest();

  @PATCH('/')
  Future<void> patchRequest();

  @CONNECT('/')
  Future<void> connectRequest();

  @OPTIONS('/')
  Future<void> optionsRequest();

  @TRACE('/')
  Future<void> traceRequest();
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/',
            returnType: null,
            parameters: [],
          ),
          UniversalRequest(
            name: 'postRequest',
            requestType: HttpRequestType.post,
            route: '/',
            returnType: null,
            parameters: [],
          ),
          UniversalRequest(
            name: 'putRequest',
            requestType: HttpRequestType.put,
            route: '/',
            returnType: null,
            parameters: [],
          ),
          UniversalRequest(
            name: 'headRequest',
            requestType: HttpRequestType.head,
            route: '/',
            returnType: null,
            parameters: [],
          ),
          UniversalRequest(
            name: 'deleteRequest',
            requestType: HttpRequestType.delete,
            route: '/',
            returnType: null,
            parameters: [],
          ),
          UniversalRequest(
            name: 'patchRequest',
            requestType: HttpRequestType.patch,
            route: '/',
            returnType: null,
            parameters: [],
          ),
          UniversalRequest(
            name: 'connectRequest',
            requestType: HttpRequestType.connect,
            route: '/',
            returnType: null,
            parameters: [],
          ),
          UniversalRequest(
            name: 'optionsRequest',
            requestType: HttpRequestType.options,
            route: '/',
            returnType: null,
            parameters: [],
          ),
          UniversalRequest(
            name: 'traceRequest',
            requestType: HttpRequestType.trace,
            route: '/',
            returnType: null,
            parameters: [],
          ),
        ],
      );
      const fillController = FillController(
        programmingLanguage: ProgrammingLanguage.kotlin,
      );
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface ClassNameClient {
    @GET("/")
    suspend fun getRequest()

    @POST("/")
    suspend fun postRequest()

    @PUT("/")
    suspend fun putRequest()

    @HEAD("/")
    suspend fun headRequest()

    @DELETE("/")
    suspend fun deleteRequest()

    @PATCH("/")
    suspend fun patchRequest()

    @CONNECT("/")
    suspend fun connectRequest()

    @OPTIONS("/")
    suspend fun optionsRequest()

    @TRACE("/")
    suspend fun traceRequest()
}
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('Returned type', () {
    test('dart + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/',
            returnType: null,
            parameters: [],
          ),
          UniversalRequest(
            name: 'getStringRequest',
            requestType: HttpRequestType.get,
            route: '/string',
            returnType: UniversalType(type: 'string'),
            parameters: [],
          ),
          UniversalRequest(
            name: 'getBoolRequest',
            requestType: HttpRequestType.get,
            route: '/boolean',
            returnType: UniversalType(type: 'boolean'),
            parameters: [],
          ),
        ],
      );
      const fillController = FillController();
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'class_name_client.g.dart';

@RestApi()
abstract class ClassNameClient {
  factory ClassNameClient(Dio dio, {String? baseUrl}) = _ClassNameClient;

  @GET('/')
  Future<void> getRequest();

  @GET('/string')
  Future<String> getStringRequest();

  @GET('/boolean')
  Future<bool> getBoolRequest();
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/',
            returnType: null,
            parameters: [],
          ),
          UniversalRequest(
            name: 'getStringRequest',
            requestType: HttpRequestType.get,
            route: '/string',
            returnType: UniversalType(type: 'string'),
            parameters: [],
          ),
          UniversalRequest(
            name: 'getBoolRequest',
            requestType: HttpRequestType.get,
            route: '/boolean',
            returnType: UniversalType(type: 'boolean'),
            parameters: [],
          ),
        ],
      );
      const fillController = FillController(
        programmingLanguage: ProgrammingLanguage.kotlin,
      );
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface ClassNameClient {
    @GET("/")
    suspend fun getRequest()

    @GET("/string")
    suspend fun getStringRequest(): String

    @GET("/boolean")
    suspend fun getBoolRequest(): Boolean
}
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('Array type', () {
    test('dart + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/',
            returnType: null,
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  arrayDepth: 1,
                  name: 'list1',
                ),
                name: 'list1',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.body,
                type: UniversalType(
                  type: 'string',
                  arrayDepth: 3,
                  name: 'list2',
                ),
              ),
            ],
          ),
          UniversalRequest(
            name: 'listOfList',
            requestType: HttpRequestType.get,
            route: '/list-of-list',
            returnType: UniversalType(type: 'string', arrayDepth: 2),
            parameters: [],
          ),
        ],
      );
      const fillController = FillController();
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'class_name_client.g.dart';

@RestApi()
abstract class ClassNameClient {
  factory ClassNameClient(Dio dio, {String? baseUrl}) = _ClassNameClient;

  @GET('/')
  Future<void> getRequest({
    @Query('list1') required List<String> list1,
    @Body() required List<List<List<String>>> list2,
  });

  @GET('/list-of-list')
  Future<List<List<String>>> listOfList();
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/',
            returnType: null,
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  arrayDepth: 1,
                  name: 'list1',
                ),
                name: 'list1',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.body,
                type: UniversalType(
                  type: 'string',
                  arrayDepth: 3,
                  name: 'list2',
                ),
              ),
            ],
          ),
          UniversalRequest(
            name: 'listOfList',
            requestType: HttpRequestType.get,
            route: '/list-of-list',
            returnType: UniversalType(type: 'string', arrayDepth: 2),
            parameters: [],
          ),
        ],
      );
      const fillController = FillController(
        programmingLanguage: ProgrammingLanguage.kotlin,
      );
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface ClassNameClient {
    @GET("/")
    suspend fun getRequest(
        @Query("list1") list1: List<String>,
        @Body list2: List<List<List<String>>>,
    )

    @GET("/list-of-list")
    suspend fun listOfList(): List<List<String>>
}
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('Single parameter', () {
    test('dart + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/',
            returnType: UniversalType(type: 'string'),
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(type: 'string', name: 'alex'),
                name: 'name',
              ),
            ],
          ),
        ],
      );
      const fillController = FillController();
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'class_name_client.g.dart';

@RestApi()
abstract class ClassNameClient {
  factory ClassNameClient(Dio dio, {String? baseUrl}) = _ClassNameClient;

  @GET('/')
  Future<String> getRequest({
    @Query('name') required String alex,
  });
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/',
            returnType: UniversalType(type: 'string'),
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(type: 'string', name: 'alex'),
                name: 'name',
              ),
            ],
          ),
        ],
      );
      const fillController = FillController(
        programmingLanguage: ProgrammingLanguage.kotlin,
      );
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface ClassNameClient {
    @GET("/")
    suspend fun getRequest(
        @Query("name") alex: String,
    ): String
}
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('All request types of parameter', () {
    test('dart + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/{id}',
            returnType: null,
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.header,
                type: UniversalType(type: 'string', name: 'token'),
                name: 'Authorization',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(type: 'string', name: 'alex'),
                name: 'name',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.path,
                type: UniversalType(type: 'int', name: 'id'),
                name: 'id',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.body,
                type: UniversalType(type: 'Another', name: 'another'),
              ),
            ],
          ),
        ],
      );
      const fillController = FillController();
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'class_name_client.g.dart';

@RestApi()
abstract class ClassNameClient {
  factory ClassNameClient(Dio dio, {String? baseUrl}) = _ClassNameClient;

  @GET('/{id}')
  Future<void> getRequest({
    @Header('Authorization') required String token,
    @Query('name') required String alex,
    @Path('id') required int id,
    @Body() required Another another,
  });
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/{id}',
            returnType: null,
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.header,
                type: UniversalType(type: 'string', name: 'token'),
                name: 'Authorization',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(type: 'string', name: 'alex'),
                name: 'name',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.path,
                type: UniversalType(type: 'int', name: 'id'),
                name: 'id',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.body,
                type: UniversalType(type: 'Another', name: 'another'),
              ),
            ],
          ),
        ],
      );
      const fillController = FillController(
        programmingLanguage: ProgrammingLanguage.kotlin,
      );
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface ClassNameClient {
    @GET("/{id}")
    suspend fun getRequest(
        @Header("Authorization") token: String,
        @Query("name") alex: String,
        @Path("id") id: int,
        @Body another: Another,
    )
}
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('Multipart', () {
    test('dart + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {'AnotherFile'},
        requests: [
          UniversalRequest(
            name: 'sendMultiPart',
            requestType: HttpRequestType.post,
            route: '/send',
            returnType: null,
            contentType: 'multipart/form-data',
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.header,
                type: UniversalType(type: 'string', name: 'token'),
                name: 'Authorization',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.part,
                type: UniversalType(type: 'string', name: 'alex'),
                name: 'name',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.part,
                type: UniversalType(
                  type: 'string',
                  format: 'binary',
                  name: 'file',
                ),
                name: 'file',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.part,
                type: UniversalType(type: 'file', name: 'secondFile'),
                name: 'file2',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.part,
                type: UniversalType(type: 'boolean', name: 'parsed'),
                name: 'parsed-if',
              ),
            ],
          ),
          UniversalRequest(
            name: 'singleEntity',
            requestType: HttpRequestType.post,
            route: '/single',
            returnType: UniversalType(type: 'boolean'),
            contentType: 'multipart/form-data',
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.body,
                type: UniversalType(type: 'AnotherFile', name: 'file'),
              ),
            ],
          ),
        ],
      );
      const fillController = FillController();
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/another_file.dart';

part 'class_name_client.g.dart';

@RestApi()
abstract class ClassNameClient {
  factory ClassNameClient(Dio dio, {String? baseUrl}) = _ClassNameClient;

  @MultiPart()
  @POST('/send')
  Future<void> sendMultiPart({
    @Header('Authorization') required String token,
    @Part(name: 'name') required String alex,
    @Part(name: 'file') required File file,
    @Part(name: 'file2') required File secondFile,
    @Part(name: 'parsed-if') required bool parsed,
  });

  @MultiPart()
  @POST('/single')
  Future<bool> singleEntity({
    @Body() required AnotherFile file,
  });
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {'AnotherFile'},
        requests: [
          UniversalRequest(
            name: 'sendMultiPart',
            requestType: HttpRequestType.post,
            route: '/send',
            returnType: null,
            contentType: 'multipart/form-data',
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.header,
                type: UniversalType(type: 'string', name: 'token'),
                name: 'Authorization',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.part,
                type: UniversalType(type: 'string', name: 'alex'),
                name: 'name',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.part,
                type: UniversalType(
                  type: 'string',
                  format: 'binary',
                  name: 'file',
                ),
                name: 'file',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.part,
                type: UniversalType(type: 'file', name: 'secondFile'),
                name: 'file2',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.part,
                type: UniversalType(type: 'boolean', name: 'parsed'),
                name: 'parsed-if',
              ),
            ],
          ),
          UniversalRequest(
            name: 'singleEntity',
            requestType: HttpRequestType.post,
            route: '/single',
            returnType: UniversalType(type: 'boolean'),
            contentType: 'multipart/form-data',
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.body,
                type: UniversalType(type: 'AnotherFile', name: 'file'),
              ),
            ],
          ),
        ],
      );
      const fillController = FillController(
        programmingLanguage: ProgrammingLanguage.kotlin,
      );
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface ClassNameClient {
    @MultiPart
    @POST("/send")
    suspend fun sendMultiPart(
        @Header("Authorization") token: String,
        @Part("name") alex: String,
        @Part("file") file: MultipartBody.Part,
        @Part("file2") secondFile: MultipartBody.Part,
        @Part("parsed-if") parsed: Boolean,
    )

    @MultiPart
    @POST("/single")
    suspend fun singleEntity(
        @Body file: AnotherFile,
    ): Boolean
}
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('FormUrlEncoded', () {
    test('dart + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {'Lol'},
        requests: [
          UniversalRequest(
            name: 'sendBody',
            requestType: HttpRequestType.post,
            route: '/send',
            returnType: null,
            contentType: 'application/x-www-form-urlencoded',
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.header,
                type: UniversalType(type: 'string', name: 'token'),
                name: 'Authorization',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.body,
                type: UniversalType(type: 'Lol', name: 'lol'),
              ),
            ],
          ),
        ],
      );
      const fillController = FillController();
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/lol.dart';

part 'class_name_client.g.dart';

@RestApi()
abstract class ClassNameClient {
  factory ClassNameClient(Dio dio, {String? baseUrl}) = _ClassNameClient;

  @FormUrlEncoded()
  @POST('/send')
  Future<void> sendBody({
    @Header('Authorization') required String token,
    @Body() required Lol lol,
  });
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {'Lol'},
        requests: [
          UniversalRequest(
            name: 'sendBody',
            requestType: HttpRequestType.post,
            route: '/send',
            returnType: null,
            contentType: 'application/x-www-form-urlencoded',
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.header,
                type: UniversalType(type: 'string', name: 'token'),
                name: 'Authorization',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.body,
                type: UniversalType(type: 'Lol', name: 'lol'),
              ),
            ],
          ),
        ],
      );
      const fillController = FillController(
        programmingLanguage: ProgrammingLanguage.kotlin,
      );
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface ClassNameClient {
    @FormUrlEncoded
    @POST("/send")
    suspend fun sendBody(
        @Header("Authorization") token: String,
        @Body lol: Lol,
    )
}
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('Required parameters', () {
    test('dart + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/{id}',
            returnType: UniversalType(type: 'string'),
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  arrayDepth: 1,
                  name: 'list',
                  isRequired: false,
                ),
                name: 'list',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.path,
                type: UniversalType(
                  type: 'integer',
                  name: 'id',
                  isRequired: true,
                ),
                name: 'id',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  name: 'stringType',
                  isRequired: false,
                ),
                name: 'type',
              ),
            ],
          ),
        ],
      );
      const fillController = FillController();
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'class_name_client.g.dart';

@RestApi()
abstract class ClassNameClient {
  factory ClassNameClient(Dio dio, {String? baseUrl}) = _ClassNameClient;

  @GET('/{id}')
  Future<String> getRequest({
    @Path('id') required int id,
    @Query('list') List<String>? list,
    @Query('type') String? stringType,
  });
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/{id}',
            returnType: UniversalType(type: 'string'),
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  arrayDepth: 1,
                  name: 'list',
                  isRequired: false,
                ),
                name: 'list',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.path,
                type: UniversalType(
                  type: 'integer',
                  name: 'id',
                  isRequired: true,
                ),
                name: 'id',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  name: 'stringType',
                  isRequired: false,
                ),
                name: 'type',
              ),
            ],
          ),
        ],
      );
      const fillController = FillController(
        programmingLanguage: ProgrammingLanguage.kotlin,
      );
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface ClassNameClient {
    @GET("/{id}")
    suspend fun getRequest(
        @Query("list") list: List<String>?,
        @Path("id") id: Int,
        @Query("type") stringType: String?,
    ): String
}
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('Default parameters', () {
    test('dart + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {'Unit', 'Soma'},
        requests: [
          UniversalRequest(
            name: 'sendMessage',
            requestType: HttpRequestType.post,
            route: '/send',
            returnType: null,
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.header,
                type: UniversalType(
                  type: 'string',
                  name: 'token',
                  defaultValue: 'message123',
                ),
                name: 'Authorization',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'number',
                  format: 'double',
                  name: 'age',
                  defaultValue: '17',
                ),
                name: 'age',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'boolean',
                  name: 'adult',
                  defaultValue: 'false',
                ),
                name: 'adult',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'Unit',
                  name: 'unit',
                  defaultValue: 'CELSIUS',
                  enumType: 'string',
                ),
                name: 'unit',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'Soma',
                  name: 'soma',
                  defaultValue: '1',
                  enumType: 'int',
                ),
                name: 'soma',
              ),
            ],
          ),
        ],
      );
      const fillController = FillController();
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/unit.dart';
import '../models/soma.dart';

part 'class_name_client.g.dart';

@RestApi()
abstract class ClassNameClient {
  factory ClassNameClient(Dio dio, {String? baseUrl}) = _ClassNameClient;

  @POST('/send')
  Future<void> sendMessage({
    @Header('Authorization') String token = 'message123',
    @Query('age') double age = 17,
    @Query('adult') bool adult = false,
    @Query('unit') Unit unit = Unit.celsius,
    @Query('soma') Soma soma = Soma.value1,
  });
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'sendMessage',
            requestType: HttpRequestType.post,
            route: '/send',
            returnType: null,
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.header,
                type: UniversalType(
                  type: 'string',
                  name: 'token',
                  defaultValue: 'message123',
                ),
                name: 'Authorization',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'number',
                  format: 'double',
                  name: 'age',
                  defaultValue: '17',
                ),
                name: 'age',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'boolean',
                  name: 'adult',
                  defaultValue: 'false',
                ),
                name: 'adult',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'Unit',
                  name: 'unit',
                  defaultValue: 'CELSIUS',
                  enumType: 'string',
                ),
                name: 'unit',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'Soma',
                  name: 'soma',
                  defaultValue: '1',
                  enumType: 'int',
                ),
                name: 'soma',
              ),
            ],
          ),
        ],
      );
      const fillController = FillController(
        programmingLanguage: ProgrammingLanguage.kotlin,
      );
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface ClassNameClient {
    @POST("/send")
    suspend fun sendMessage(
        @Header("Authorization") token: String = "message123",
        @Query("age") age: Double = 17,
        @Query("adult") adult: Boolean = false,
        @Query("unit") unit: Unit = Unit.CELSIUS,
        @Query("soma") soma: Soma = Soma.VALUE_1,
    )
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('Dart + retrofit nullability of request parameters', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/request',
            returnType: UniversalType(type: 'string', nullable: true),
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  arrayDepth: 4,
                  name: 'deepList',
                  isRequired: false,
                  nullable: true,
                ),
                name: 'deepArrayNullable',
              ),
            ],
          ),
          UniversalRequest(
            name: 'getRequest2',
            requestType: HttpRequestType.get,
            route: '/request2',
            returnType: UniversalType(type: 'string', nullable: false),
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  arrayDepth: 4,
                  name: 'deepList',
                  isRequired: false,
                  nullable: true,
                ),
                name: 'deepArrayNullable',
              ),
            ],
          ),
        ],
      );
      const fillController = FillController();
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'class_name_client.g.dart';

@RestApi()
abstract class ClassNameClient {
  factory ClassNameClient(Dio dio, {String? baseUrl}) = _ClassNameClient;

  @GET('/request')
  Future<String?> getRequest({
    @Query('deepArrayNullable') List<List<List<List<String>>>>? deepList,
  });

  @GET('/request2')
  Future<String> getRequest2({
    @Query('deepArrayNullable') List<List<List<List<String>>>>? deepList,
  });
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('dart + retrofit nullable parameters', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/request',
            returnType: UniversalType(type: 'string'),
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  arrayDepth: 4,
                  name: 'list1',
                  isRequired: false,
                  nullable: true,
                ),
                name: 'deepArrayNullable',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  name: 'list2',
                  isRequired: false,
                  nullable: true,
                ),
                name: 'notRequiredButNullable',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  name: 'list3',
                  isRequired: true,
                  nullable: false,
                ),
                name: 'requiredButNotNullable',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  name: 'list4',
                  isRequired: false,
                  nullable: false,
                ),
                name: 'notRequiredAndNotNullable',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  name: 'list5',
                  isRequired: true,
                  nullable: true,
                ),
                name: 'RequiredAndNullable',
              ),
            ],
          ),
        ],
      );
      const fillController = FillController();
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'class_name_client.g.dart';

@RestApi()
abstract class ClassNameClient {
  factory ClassNameClient(Dio dio, {String? baseUrl}) = _ClassNameClient;

  @GET('/request')
  Future<String> getRequest({
    @Query('requiredButNotNullable') required String list3,
    @Query('RequiredAndNullable') required String? list5,
    @Query('deepArrayNullable') List<List<List<List<String>>>>? list1,
    @Query('notRequiredButNullable') String? list2,
    @Query('notRequiredAndNotNullable') String? list4,
  });
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('Kotlin nullability of request parameters', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/request',
            returnType: UniversalType(type: 'string', nullable: true),
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  arrayDepth: 4,
                  name: 'deepList',
                  isRequired: false,
                  nullable: true,
                ),
                name: 'deepArrayNullable',
              ),
            ],
          ),
          UniversalRequest(
            name: 'getRequest2',
            requestType: HttpRequestType.get,
            route: '/request2',
            returnType: UniversalType(type: 'string', nullable: false),
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  arrayDepth: 4,
                  name: 'deepList',
                  isRequired: false,
                  nullable: true,
                ),
                name: 'deepArrayNullable',
              ),
            ],
          ),
        ],
      );
      const fillController = FillController(
        programmingLanguage: ProgrammingLanguage.kotlin,
      );
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface ClassNameClient {
    @GET("/request")
    suspend fun getRequest(
        @Query("deepArrayNullable") deepList: List<List<List<List<String>>>>?,
    ): String?

    @GET("/request2")
    suspend fun getRequest2(
        @Query("deepArrayNullable") deepList: List<List<List<List<String>>>>?,
    ): String
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin nullable parameters', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/request',
            returnType: UniversalType(type: 'string'),
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  arrayDepth: 4,
                  name: 'list1',
                  isRequired: false,
                  nullable: true,
                ),
                name: 'deepArrayNullable',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  name: 'list2',
                  isRequired: false,
                  nullable: true,
                ),
                name: 'notRequiredButNullable',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  name: 'list3',
                  isRequired: true,
                  nullable: false,
                ),
                name: 'requiredButNotNullable',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  name: 'list4',
                  isRequired: false,
                  nullable: false,
                ),
                name: 'notRequiredAndNotNullable',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  name: 'list5',
                  isRequired: true,
                  nullable: true,
                ),
                name: 'RequiredAndNullable',
              ),
            ],
          ),
        ],
      );
      const fillController = FillController(
        programmingLanguage: ProgrammingLanguage.kotlin,
      );
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface ClassNameClient {
    @GET("/request")
    suspend fun getRequest(
        @Query("deepArrayNullable") list1: List<List<List<List<String>>>>?,
        @Query("notRequiredButNullable") list2: String?,
        @Query("requiredButNotNullable") list3: String,
        @Query("notRequiredAndNotNullable") list4: String?,
        @Query("RequiredAndNullable") list5: String?,
    ): String
}
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('Description', () {
    test('dart + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {'Some'},
        requests: [
          UniversalRequest(
            name: 'some',
            requestType: HttpRequestType.get,
            route: '/some',
            description: 'Some description',
            returnType: null,
            parameters: [],
          ),
        ],
      );
      const fillController = FillController();
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/some.dart';

part 'class_name_client.g.dart';

@RestApi()
abstract class ClassNameClient {
  factory ClassNameClient(Dio dio, {String? baseUrl}) = _ClassNameClient;

  /// Some description
  @GET('/some')
  Future<void> some();
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {'Some'},
        requests: [
          UniversalRequest(
            name: 'some',
            requestType: HttpRequestType.get,
            route: '/some',
            description: 'Some description',
            returnType: null,
            parameters: [],
          ),
        ],
      );
      const fillController = FillController(
        programmingLanguage: ProgrammingLanguage.kotlin,
      );
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface ClassNameClient {
    /// Some description
    @GET("/some")
    suspend fun some()
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('Dart + retrofit nullability of request parameters', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/request',
            returnType: UniversalType(type: 'string', nullable: true),
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  arrayDepth: 4,
                  name: 'deepList',
                  isRequired: false,
                  nullable: true,
                ),
                name: 'deepArrayNullable',
              ),
            ],
          ),
          UniversalRequest(
            name: 'getRequest2',
            requestType: HttpRequestType.get,
            route: '/request2',
            returnType: UniversalType(type: 'string', nullable: false),
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  arrayDepth: 4,
                  name: 'deepList',
                  isRequired: false,
                  nullable: true,
                ),
                name: 'deepArrayNullable',
              ),
            ],
          ),
        ],
      );
      const fillController = FillController();
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'class_name_client.g.dart';

@RestApi()
abstract class ClassNameClient {
  factory ClassNameClient(Dio dio, {String? baseUrl}) = _ClassNameClient;

  @GET('/request')
  Future<String?> getRequest({
    @Query('deepArrayNullable') List<List<List<List<String>>>>? deepList,
  });

  @GET('/request2')
  Future<String> getRequest2({
    @Query('deepArrayNullable') List<List<List<List<String>>>>? deepList,
  });
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('dart + retrofit nullable parameters', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/request',
            returnType: UniversalType(type: 'string'),
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  arrayDepth: 4,
                  name: 'list1',
                  isRequired: false,
                  nullable: true,
                ),
                name: 'deepArrayNullable',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  name: 'list2',
                  isRequired: false,
                  nullable: true,
                ),
                name: 'notRequiredButNullable',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  name: 'list3',
                  isRequired: true,
                  nullable: false,
                ),
                name: 'requiredButNotNullable',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  name: 'list4',
                  isRequired: false,
                  nullable: false,
                ),
                name: 'notRequiredAndNotNullable',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  name: 'list5',
                  isRequired: true,
                  nullable: true,
                ),
                name: 'RequiredAndNullable',
              ),
            ],
          ),
        ],
      );
      const fillController = FillController();
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'class_name_client.g.dart';

@RestApi()
abstract class ClassNameClient {
  factory ClassNameClient(Dio dio, {String? baseUrl}) = _ClassNameClient;

  @GET('/request')
  Future<String> getRequest({
    @Query('requiredButNotNullable') required String list3,
    @Query('RequiredAndNullable') required String? list5,
    @Query('deepArrayNullable') List<List<List<List<String>>>>? list1,
    @Query('notRequiredButNullable') String? list2,
    @Query('notRequiredAndNotNullable') String? list4,
  });
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('Kotlin nullability of request parameters', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/request',
            returnType: UniversalType(type: 'string', nullable: true),
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  arrayDepth: 4,
                  name: 'deepList',
                  isRequired: false,
                  nullable: true,
                ),
                name: 'deepArrayNullable',
              ),
            ],
          ),
          UniversalRequest(
            name: 'getRequest2',
            requestType: HttpRequestType.get,
            route: '/request2',
            returnType: UniversalType(type: 'string', nullable: false),
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  arrayDepth: 4,
                  name: 'deepList',
                  isRequired: false,
                  nullable: true,
                ),
                name: 'deepArrayNullable',
              ),
            ],
          ),
        ],
      );
      const fillController = FillController(
        programmingLanguage: ProgrammingLanguage.kotlin,
      );
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface ClassNameClient {
    @GET("/request")
    suspend fun getRequest(
        @Query("deepArrayNullable") deepList: List<List<List<List<String>>>>?,
    ): String?

    @GET("/request2")
    suspend fun getRequest2(
        @Query("deepArrayNullable") deepList: List<List<List<List<String>>>>?,
    ): String
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin nullable parameters', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [
          UniversalRequest(
            name: 'getRequest',
            requestType: HttpRequestType.get,
            route: '/request',
            returnType: UniversalType(type: 'string'),
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  arrayDepth: 4,
                  name: 'list1',
                  isRequired: false,
                  nullable: true,
                ),
                name: 'deepArrayNullable',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  name: 'list2',
                  isRequired: false,
                  nullable: true,
                ),
                name: 'notRequiredButNullable',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  name: 'list3',
                  isRequired: true,
                  nullable: false,
                ),
                name: 'requiredButNotNullable',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  name: 'list4',
                  isRequired: false,
                  nullable: false,
                ),
                name: 'notRequiredAndNotNullable',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.query,
                type: UniversalType(
                  type: 'string',
                  name: 'list5',
                  isRequired: true,
                  nullable: true,
                ),
                name: 'RequiredAndNullable',
              ),
            ],
          ),
        ],
      );
      const fillController = FillController(
        programmingLanguage: ProgrammingLanguage.kotlin,
      );
      final filledContent = fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface ClassNameClient {
    @GET("/request")
    suspend fun getRequest(
        @Query("deepArrayNullable") list1: List<List<List<List<String>>>>?,
        @Query("notRequiredButNullable") list2: String?,
        @Query("requiredButNotNullable") list3: String,
        @Query("notRequiredAndNotNullable") list4: String?,
        @Query("RequiredAndNullable") list5: String?,
    ): String
}
''';
      expect(filledContent.contents, expectedContents);
    });
  });
}
