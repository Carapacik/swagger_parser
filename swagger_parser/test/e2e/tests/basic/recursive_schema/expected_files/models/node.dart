// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'node.dart';

part 'node.freezed.dart';
part 'node.g.dart';

@Freezed()
class Node with _$Node {
  const factory Node({
    int? id,
    List<Node>? children,
  }) = _Node;

  factory Node.fromJson(Map<String, Object?> json) => _$NodeFromJson(json);
}
