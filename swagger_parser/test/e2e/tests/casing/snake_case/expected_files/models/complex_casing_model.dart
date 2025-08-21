// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'complex_casing_model.freezed.dart';
part 'complex_casing_model.g.dart';

@Freezed()
class ComplexCasingModel with _$ComplexCasingModel {
  const factory ComplexCasingModel({
    @JsonKey(name: 'is_not_on_blocklist') required String isNotOnBlocklist,
    @JsonKey(name: 'http_method') required String httpMethod,
    @JsonKey(name: 'xml_data') required String xmlData,
    @JsonKey(name: 'api_key') required String apiKey,
    @JsonKey(name: 'sql_db_connection') required String sqlDbConnection,
    @JsonKey(name: 'html_parser') required String htmlParser,
    @JsonKey(name: 'user_id_123') required String userId123,
    @JsonKey(name: 'http2_protocol') required String http2Protocol,
    @JsonKey(name: 'oauth2_token') required String oauth2Token,
    @JsonKey(name: 'v1_api_endpoint') required String v1ApiEndpoint,
    @JsonKey(name: 'html5_parser') required String html5Parser,
    @JsonKey(name: 'xml2json_converter') required String xml2jsonConverter,
    @JsonKey(name: 'api_2_v3_endpoint') required String api2V3Endpoint,
    @JsonKey(name: 'https_connection') required String httpsConnection,
    @JsonKey(name: 'xml_http_request') required String xmlHttpRequest,
    @JsonKey(name: 'sql_db_connection_2') required String sqlDbConnection2,
    @JsonKey(name: 'json_api_response') required String jsonApiResponse,
    @JsonKey(name: 'jwt_auth_token') required String jwtAuthToken,
    @JsonKey(name: 'a_b_c') required String aBC,
    @JsonKey(name: 'x_y_z') required String xYZ,
    @JsonKey(name: 'io_operation') required String ioOperation,
    @JsonKey(name: 'ui_component') required String uiComponent,
    @JsonKey(name: 'id_field') required String idField,
    @JsonKey(name: 'uuid_v4_generator') required String uuidV4Generator,
    @JsonKey(name: 'css_html5_renderer') required String cssHtml5Renderer,
    @JsonKey(name: 'api_v2_https_endpoint') required String apiV2HttpsEndpoint,
    @JsonKey(name: 'oauth2_jwt_token') required String oauth2JwtToken,
    @JsonKey(name: 'xml2json_v3_parser') required String xml2jsonV3Parser,
  }) = _ComplexCasingModel;

  factory ComplexCasingModel.fromJson(Map<String, Object?> json) =>
      _$ComplexCasingModelFromJson(json);
}
