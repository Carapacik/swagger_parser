// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'url.dart';

part 'xml_http_request.freezed.dart';
part 'xml_http_request.g.dart';

@Freezed()
class XMLHttpRequest with _$XMLHttpRequest {
  const factory XMLHttpRequest({
    required URL url,
  }) = _XMLHttpRequest;

  factory XMLHttpRequest.fromJson(Map<String, Object?> json) =>
      _$XMLHttpRequestFromJson(json);
}
