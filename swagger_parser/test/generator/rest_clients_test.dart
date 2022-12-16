import 'package:swagger_parser/src/generator/fill_controller.dart';
import 'package:swagger_parser/src/generator/models/programming_lang.dart';
import 'package:swagger_parser/src/generator/models/universal_request.dart';
import 'package:swagger_parser/src/generator/models/universal_request_type.dart';
import 'package:swagger_parser/src/generator/models/universal_rest_client.dart';
import 'package:swagger_parser/src/generator/models/universal_type.dart';
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

  group('Client postfix', () {
    test('dart + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {},
        requests: [],
      );
      const fillController =
          FillController(squishClients: true, clientPostfix: 'Api');
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'class_name.g.dart';

@RestApi()
abstract class ClassNameApi {
  factory ClassNameApi(Dio dio, {required String baseUrl}) = _ClassNameApi;
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
        clientPostfix: 'Api',
      );
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface ClassNameApi {}
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
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../shared_models/camel_class.dart';
import '../shared_models/snake_class.dart';
import '../shared_models/kebab_class.dart';
import '../shared_models/pascal_class.dart';
import '../shared_models/space_class.dart';

part 'rest_client.g.dart';

@RestApi()
abstract class Client {
  factory Client(Dio dio, {required String baseUrl}) = _Client;
}
''';
      expect(filledContent.contents, expectedContents);
    });

    // Imports in Kotlin are not supported yet. You can always add PR
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
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'rest_client.g.dart';

@RestApi()
abstract class Client {
  factory Client(Dio dio, {required String baseUrl}) = _Client;

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
      const fillController =
          FillController(programmingLanguage: ProgrammingLanguage.kotlin);
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface Client {
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
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'rest_client.g.dart';

@RestApi()
abstract class Client {
  factory Client(Dio dio, {required String baseUrl}) = _Client;

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
      const fillController =
          FillController(programmingLanguage: ProgrammingLanguage.kotlin);
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface Client {
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
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'rest_client.g.dart';

@RestApi()
abstract class Client {
  factory Client(Dio dio, {required String baseUrl}) = _Client;

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
      const fillController =
          FillController(programmingLanguage: ProgrammingLanguage.kotlin);
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface Client {
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
                type:
                    UniversalType(type: 'string', arrayDepth: 1, name: 'list1'),
                name: 'list1',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.body,
                type:
                    UniversalType(type: 'string', arrayDepth: 3, name: 'list2'),
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
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'rest_client.g.dart';

@RestApi()
abstract class Client {
  factory Client(Dio dio, {required String baseUrl}) = _Client;

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
                type:
                    UniversalType(type: 'string', arrayDepth: 1, name: 'list1'),
                name: 'list1',
              ),
              UniversalRequestType(
                parameterType: HttpParameterType.body,
                type:
                    UniversalType(type: 'string', arrayDepth: 3, name: 'list2'),
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
      const fillController =
          FillController(programmingLanguage: ProgrammingLanguage.kotlin);
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface Client {
    @GET("/")
    suspend fun getRequest(
        @Query("list1") list1: List<String>,
        @Body list2: List<List<List<String>>>
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
            returnType: null,
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
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'rest_client.g.dart';

@RestApi()
abstract class Client {
  factory Client(Dio dio, {required String baseUrl}) = _Client;

  @GET('/')
  Future<void> getRequest({
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
            returnType: null,
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
      const fillController =
          FillController(programmingLanguage: ProgrammingLanguage.kotlin);
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface Client {
    @GET("/")
    suspend fun getRequest(
        @Query("name") alex: String
    )
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
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'rest_client.g.dart';

@RestApi()
abstract class Client {
  factory Client(Dio dio, {required String baseUrl}) = _Client;

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
      const fillController =
          FillController(programmingLanguage: ProgrammingLanguage.kotlin);
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface Client {
    @GET("/{id}")
    suspend fun getRequest(
        @Header("Authorization") token: String,
        @Query("name") alex: String,
        @Path("id") id: int,
        @Body another: Another
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
            isMultiPart: true,
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
            isMultiPart: true,
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.path,
                type: UniversalType(type: 'AnotherFile', name: 'file'),
              ),
            ],
          ),
        ],
      );
      const fillController = FillController();
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../shared_models/another_file.dart';

part 'rest_client.g.dart';

@RestApi()
abstract class Client {
  factory Client(Dio dio, {required String baseUrl}) = _Client;

  @MultiPart()
  @POST('/send')
  Future<void> sendMultiPart({
    @Header('Authorization') required String token,
    @Part(name: 'name') required String alex,
    @Part(name: 'file') required List<MultipartFile> file,
    @Part(name: 'file2') required List<MultipartFile> secondFile,
    @Part(name: 'parsed-if') required bool parsed,
  });

  @MultiPart()
  @POST('/single')
  Future<bool> singleEntity({
    @Path() required AnotherFile file,
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
            name: 'sendMultiPart',
            requestType: HttpRequestType.post,
            route: '/send',
            returnType: null,
            isMultiPart: true,
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
        ],
      );
      const fillController =
          FillController(programmingLanguage: ProgrammingLanguage.kotlin);
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import retrofit2.http.*

interface Client {
    @MultiPart
    @POST("/send")
    suspend fun sendMultiPart(
        @Header("Authorization") token: String,
        @Part("name") alex: String,
        @Part("file") file: MultipartBody.Part,
        @Part("file2") secondFile: MultipartBody.Part,
        @Part("parsed-if") parsed: Boolean
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
            route: '/',
            returnType: null,
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
                parameterType: HttpParameterType.body,
                type: UniversalType(
                  type: 'string',
                  name: 'stringType',
                  isRequired: false,
                ),
              ),
            ],
          ),
        ],
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

  @GET('/')
  Future<void> getRequest({
    @Query('list') List<String>? list,
    @Body() String? stringType,
  });
}
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('Default parameters', () {
    test('dart + retrofit', () async {
      const restClient = UniversalRestClient(
        name: 'ClassName',
        imports: {'AnotherFile'},
        requests: [
          UniversalRequest(
            name: 'sendGagaga',
            requestType: HttpRequestType.post,
            route: '/send',
            returnType: null,
            parameters: [
              UniversalRequestType(
                parameterType: HttpParameterType.header,
                type: UniversalType(
                  type: 'string',
                  name: 'token',
                  defaultValue: 'gagaga123',
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
            ],
          ),
        ],
      );
      const fillController = FillController();
      final filledContent =
          await fillController.fillRestClientContent(restClient);
      const expectedContents = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../shared_models/another_file.dart';

part 'rest_client.g.dart';

@RestApi()
abstract class Client {
  factory Client(Dio dio, {required String baseUrl}) = _Client;

  @POST('/send')
  Future<void> sendGagaga({
    @Header('Authorization') String token = 'gagaga123',
    @Query('age') double age = 17,
    @Query('adult') bool adult = false,
  });
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + retrofit', () async {
      // Default values in Kotlin are not supported yet. You can always add PR
    });
  });
}
