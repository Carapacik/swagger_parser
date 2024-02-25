import 'package:path/path.dart' as p;
import 'package:swagger_parser/src/parser/swagger_parser_core.dart';
import 'package:swagger_parser/src/utils/file_utils.dart';
import 'package:test/test.dart';

void main() {
  group('Paths check', () {
    test('basic paths check 2.0', () async {
      final schemaPath =
          p.join('test', 'parser', 'schemes', 'basic_requests.2.0.json');
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(ParserConfig(schemaContent, isJson: true));
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
              returnType: UniversalType(
                type: 'string',
                isRequired: true,
              ),
              contentType: 'text/json',
              parameters: [
                UniversalRequestType(
                  parameterType: HttpParameterType.body,
                  type: UniversalType(
                    type: 'RegisterUserDto',
                    name: 'body',
                    jsonKey: 'body',
                    isRequired: true,
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
              returnType: UniversalType(
                type: 'UserInfoDto',
                isRequired: true,
              ),
              parameters: [
                UniversalRequestType(
                  name: 'tags',
                  type: UniversalType(
                    type: 'string',
                    name: 'tags',
                    description: 'tags to filter by',
                    jsonKey: 'tags',
                    arrayDepth: 1,
                    isRequired: true,
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
              contentType: 'multipart/form-data',
              parameters: [
                UniversalRequestType(
                  name: 'avatar',
                  type: UniversalType(
                    type: 'file',
                    name: 'avatar',
                    jsonKey: 'avatar',
                    isRequired: true,
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
                    isRequired: true,
                  ),
                  parameterType: HttpParameterType.path,
                ),
              ],
            ),
          ],
        ),
      ];
      for (var i = 0; i < actualRestClients.length; i++) {
        expect(actualRestClients[i], expectedRestClients[i]);
      }
    });

    test('basic paths check 3.0', () async {
      final schemaPath =
          p.join('test', 'parser', 'schemes', 'basic_requests.3.0.json');
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(ParserConfig(schemaContent, isJson: true));
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
              returnType: UniversalType(
                type: 'string',
                isRequired: false,
              ),
              parameters: [
                UniversalRequestType(
                  parameterType: HttpParameterType.body,
                  type: UniversalType(
                    type: 'RegisterUserDto',
                    name: 'body',
                    jsonKey: 'body',
                    isRequired: true,
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
              returnType: UniversalType(
                type: 'UserInfoDto',
                isRequired: true,
              ),
              parameters: [
                UniversalRequestType(
                  name: 'limit',
                  type: UniversalType(
                    type: 'integer',
                    name: 'limit',
                    format: 'int32',
                    jsonKey: 'limit',
                    isRequired: true,
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
                    isRequired: true,
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
              contentType: 'multipart/form-data',
              parameters: [
                UniversalRequestType(
                  name: 'id',
                  type: UniversalType(
                    type: 'integer',
                    name: 'id',
                    format: 'int32',
                    jsonKey: 'id',
                    isRequired: true,
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
