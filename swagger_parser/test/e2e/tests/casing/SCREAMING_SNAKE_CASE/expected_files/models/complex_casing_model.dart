// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'complex_casing_model.freezed.dart';
part 'complex_casing_model.g.dart';

@Freezed()
class ComplexCasingModel with _$ComplexCasingModel {
  const factory ComplexCasingModel({
    @JsonKey(name: 'IS_NOT_ON_BLOCKLIST') required String isNotOnBlocklist,
    @JsonKey(name: 'HTTP_METHOD') required String httpMethod,
    @JsonKey(name: 'XML_DATA') required String xmlData,
    @JsonKey(name: 'API_KEY') required String apiKey,
    @JsonKey(name: 'SQL_DB_CONNECTION') required String sqlDbConnection,
    @JsonKey(name: 'HTML_PARSER') required String htmlParser,
    @JsonKey(name: 'USER_ID_123') required String userId123,
    @JsonKey(name: 'HTTP2_PROTOCOL') required String http2Protocol,
    @JsonKey(name: 'OAUTH2_TOKEN') required String oauth2Token,
    @JsonKey(name: 'V1_API_ENDPOINT') required String v1ApiEndpoint,
    @JsonKey(name: 'HTML5_PARSER') required String html5Parser,
    @JsonKey(name: 'XML2JSON_CONVERTER') required String xml2jsonConverter,
    @JsonKey(name: 'API_2_V3_ENDPOINT') required String api2V3Endpoint,
    @JsonKey(name: 'HTTPS_CONNECTION') required String httpsConnection,
    @JsonKey(name: 'XML_HTTP_REQUEST') required String xmlHttpRequest,
    @JsonKey(name: 'SQL_DB_CONNECTION_2') required String sqlDbConnection2,
    @JsonKey(name: 'JSON_API_RESPONSE') required String jsonApiResponse,
    @JsonKey(name: 'JWT_AUTH_TOKEN') required String jwtAuthToken,
    @JsonKey(name: 'A_B_C') required String aBC,
    @JsonKey(name: 'X_Y_Z') required String xYZ,
    @JsonKey(name: 'IO_OPERATION') required String ioOperation,
    @JsonKey(name: 'UI_COMPONENT') required String uiComponent,
    @JsonKey(name: 'ID_FIELD') required String idField,
    @JsonKey(name: 'UUID_V4_GENERATOR') required String uuidV4Generator,
    @JsonKey(name: 'CSS_HTML5_RENDERER') required String cssHtml5Renderer,
    @JsonKey(name: 'API_V2_HTTPS_ENDPOINT') required String apiV2HttpsEndpoint,
    @JsonKey(name: 'OAUTH2_JWT_TOKEN') required String oauth2JwtToken,
    @JsonKey(name: 'XML2JSON_V3_PARSER') required String xml2jsonV3Parser,
  }) = _ComplexCasingModel;

  factory ComplexCasingModel.fromJson(Map<String, Object?> json) =>
      _$ComplexCasingModelFromJson(json);
}
