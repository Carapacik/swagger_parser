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
      final schemaFilePath =
          p.join('test', 'parser', 'schemas', 'basic_requests.2.0.json');
      final configFile = schemaFile(schemaFilePath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(schemaContent);
      final actualDataClass = parser.parseRestClients().toList();
      const expectedDataClass = [
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
                  ),
                  parameterType: HttpParameterType.path,
                ),
              ],
            ),
          ],
        ),
      ];
      for (var i = 0; i < actualDataClass.length; i++) {
        expect(actualDataClass.last, expectedDataClass.last);
      }
    });

    test('basic paths check 3.0', () async {
      final schemaFilePath =
          p.join('test', 'parser', 'schemas', 'basic_requests.3.0.json');
      final configFile = schemaFile(schemaFilePath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(schemaContent);
      final actualDataClass = parser.parseRestClients().toList();
      const expectedDataClass = [
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
      for (var i = 0; i < actualDataClass.length; i++) {
        expect(actualDataClass.last, expectedDataClass.last);
      }
    });
  });
}
