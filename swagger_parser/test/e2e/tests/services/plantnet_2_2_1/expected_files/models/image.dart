// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'date.dart';
import 'url.dart';

part 'image.freezed.dart';
part 'image.g.dart';

@Freezed()
class Image with _$Image {
  const factory Image({
    String? organ,
    String? author,
    String? license,
    Date? date,
    String? citation,
    Url? url,
  }) = _Image;

  factory Image.fromJson(Map<String, Object?> json) => _$ImageFromJson(json);
}
