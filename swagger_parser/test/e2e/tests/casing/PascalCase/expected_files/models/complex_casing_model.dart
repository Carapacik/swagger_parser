// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'complex_casing_model.freezed.dart';
part 'complex_casing_model.g.dart';

@Freezed()
class ComplexCasingModel with _$ComplexCasingModel {
  const factory ComplexCasingModel({
    @JsonKey(name: 'IsNotOnBlocklist') required String isNotOnBlocklist,
    @JsonKey(name: 'HttpMethod') required String httpMethod,
    @JsonKey(name: 'XmlData') required String xmlData,
    @JsonKey(name: 'ApiKey') required String apiKey,
    @JsonKey(name: 'SqlDbConnection') required String sqlDbConnection,
    @JsonKey(name: 'HtmlParser') required String htmlParser,
    @JsonKey(name: 'UserId123') required String userId123,
    @JsonKey(name: 'Http2Protocol') required String http2Protocol,
    @JsonKey(name: 'Oauth2Token') required String oauth2Token,
    @JsonKey(name: 'V1ApiEndpoint') required String v1ApiEndpoint,
    @JsonKey(name: 'Html5Parser') required String html5Parser,
    @JsonKey(name: 'Xml2jsonConverter') required String xml2jsonConverter,
    @JsonKey(name: 'Api2V3Endpoint') required String api2V3Endpoint,
    @JsonKey(name: 'HttpsConnection') required String httpsConnection,
    @JsonKey(name: 'XmlHttpRequest') required String xmlHttpRequest,
    @JsonKey(name: 'SqlDbConnection2') required String sqlDbConnection2,
    @JsonKey(name: 'JsonApiResponse') required String jsonApiResponse,
    @JsonKey(name: 'JwtAuthToken') required String jwtAuthToken,
    @JsonKey(name: 'ABC') required String abc,
    @JsonKey(name: 'XYZ') required String xyz,
    @JsonKey(name: 'IoOperation') required String ioOperation,
    @JsonKey(name: 'UiComponent') required String uiComponent,
    @JsonKey(name: 'IdField') required String idField,
    @JsonKey(name: 'UuidV4Generator') required String uuidV4Generator,
    @JsonKey(name: 'CssHtml5Renderer') required String cssHtml5Renderer,
    @JsonKey(name: 'ApiV2HttpsEndpoint') required String apiV2HttpsEndpoint,
    @JsonKey(name: 'Oauth2JwtToken') required String oauth2JwtToken,
    @JsonKey(name: 'Xml2jsonV3Parser') required String xml2jsonV3Parser,
  }) = _ComplexCasingModel;

  factory ComplexCasingModel.fromJson(Map<String, Object?> json) =>
      _$ComplexCasingModelFromJson(json);
}
