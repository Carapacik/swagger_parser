import 'package:path/path.dart' as p;
import 'package:swagger_parser/src/generator/models/universal_request.dart';
import 'package:swagger_parser/src/generator/models/universal_request_type.dart';
import 'package:swagger_parser/src/generator/models/universal_rest_client.dart';
import 'package:swagger_parser/src/generator/models/universal_type.dart';
import 'package:swagger_parser/src/parser/parser.dart';
import 'package:swagger_parser/src/utils/file_utils.dart';
import 'package:test/test.dart';

void main() {
  group('Paths check', () {
    test('basic paths check 2.0', () async {
      final schemaPath =
          p.join('test', 'parser', 'schemas', 'basic_requests.2.0.json');
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(schemaContent);
      final actualRestClients = parser.parseRestClients().toList();
      const expectedRestClients = [
        UniversalRestClient(
          name: 'Auth',
          imports: {'RegisterUserDto'},
          requests: [
            UniversalRequest(
              name: 'postApiAuthRegister',
              requestType: HttpRequestType.post,
              route: '/api/Auth/register',
              returnType: UniversalType(type: 'string'),
              parameters: [
                UniversalRequestType(
                  parameterType: HttpParameterType.body,
                  type: UniversalType(
                    type: 'RegisterUserDto',
                    name: 'body',
                    jsonKey: 'body',
                    isRequired: false,
                  ),
                ),
              ],
            ),
          ],
        ),
        UniversalRestClient(
          name: 'User',
          imports: {'UserInfoDto'},
          requests: [
            UniversalRequest(
              name: 'getApiUserInfo',
              requestType: HttpRequestType.get,
              route: '/api/User/info',
              returnType: UniversalType(type: 'UserInfoDto'),
              parameters: [
                UniversalRequestType(
                  name: 'tags',
                  type: UniversalType(
                    type: 'string',
                    name: 'tags',
                    description: 'tags to filter by',
                    jsonKey: 'tags',
                    arrayDepth: 1,
                    isRequired: false,
                  ),
                  parameterType: HttpParameterType.query,
                ),
                UniversalRequestType(
                  name: 'limit',
                  type: UniversalType(
                    type: 'integer',
                    name: 'limit',
                    description: 'maximum number of results to return',
                    format: 'int32',
                    jsonKey: 'limit',
                    isRequired: false,
                  ),
                  parameterType: HttpParameterType.query,
                ),
              ],
            ),
            UniversalRequest(
              name: 'patchApiUserIdAvatar',
              requestType: HttpRequestType.patch,
              route: '/api/User/{id}/avatar',
              returnType: null,
              isMultiPart: true,
              parameters: [
                UniversalRequestType(
                  name: 'avatar',
                  type: UniversalType(
                    type: 'file',
                    name: 'avatar',
                    jsonKey: 'avatar',
                    isRequired: false,
                  ),
                  parameterType: HttpParameterType.formData,
                ),
                UniversalRequestType(
                  name: 'id',
                  type: UniversalType(
                    type: 'integer',
                    name: 'id',
                    format: 'int32',
                    jsonKey: 'id',
                    isRequired: false,
                  ),
                  parameterType: HttpParameterType.path,
                ),
              ],
            ),
          ],
        ),
      ];
      for (var i = 0; i < actualRestClients.length; i++) {
        expect(actualRestClients.last, expectedRestClients.last);
      }
    });

    test('basic paths check 3.0', () async {
      final schemaPath =
          p.join('test', 'parser', 'schemas', 'basic_requests.3.0.json');
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(schemaContent);
      final actualRestClients = parser.parseRestClients().toList();
      const expectedRestClients = [
        UniversalRestClient(
          name: 'Auth',
          imports: {'RegisterUserDto'},
          requests: [
            UniversalRequest(
              name: 'postApiAuthRegister',
              requestType: HttpRequestType.post,
              route: '/api/Auth/register',
              returnType: UniversalType(type: 'string'),
              parameters: [
                UniversalRequestType(
                  parameterType: HttpParameterType.body,
                  type: UniversalType(
                    type: 'RegisterUserDto',
                    name: 'body',
                    jsonKey: 'body',
                    isRequired: false,
                  ),
                ),
              ],
            ),
          ],
        ),
        UniversalRestClient(
          name: 'User',
          imports: {'UserInfoDto'},
          requests: [
            UniversalRequest(
              name: 'getApiUserInfo',
              requestType: HttpRequestType.get,
              route: '/api/User/info',
              returnType: UniversalType(type: 'UserInfoDto'),
              parameters: [
                UniversalRequestType(
                  name: 'limit',
                  type: UniversalType(
                    type: 'integer',
                    name: 'limit',
                    format: 'int32',
                    jsonKey: 'limit',
                    isRequired: false,
                  ),
                  parameterType: HttpParameterType.query,
                ),
                UniversalRequestType(
                  name: 'tags',
                  type: UniversalType(
                    type: 'string',
                    name: 'tags',
                    jsonKey: 'tags',
                    arrayDepth: 1,
                    isRequired: false,
                  ),
                  parameterType: HttpParameterType.query,
                ),
              ],
            ),
            UniversalRequest(
              name: 'patchApiUserIdAvatar',
              requestType: HttpRequestType.patch,
              route: '/api/User/{id}/avatar',
              returnType: null,
              isMultiPart: true,
              parameters: [
                UniversalRequestType(
                  name: 'id',
                  type: UniversalType(
                    type: 'integer',
                    name: 'id',
                    format: 'int32',
                    jsonKey: 'id',
                    isRequired: false,
                  ),
                  parameterType: HttpParameterType.path,
                ),
                UniversalRequestType(
                  name: 'avatar',
                  type: UniversalType(
                    type: 'file',
                    name: 'avatar',
                    isRequired: false,
                  ),
                  parameterType: HttpParameterType.part,
                ),
              ],
            ),
          ],
        ),
      ];
      for (var i = 0; i < actualRestClients.length; i++) {
        expect(actualRestClients.last, expectedRestClients.last);
      }
    });
  });
}
