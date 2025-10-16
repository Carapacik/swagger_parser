import 'package:swagger_parser/src/generator/model/json_serializer.dart';

String dartImportDtoTemplate(JsonSerializer jsonSerializer) {
  switch (jsonSerializer) {
    case JsonSerializer.freezed:
      return "import 'package:freezed_annotation/freezed_annotation.dart';";
    case JsonSerializer.jsonSerializable:
      return "import 'package:json_annotation/json_annotation.dart';";
    case JsonSerializer.dartMappable:
      return "import 'package:dart_mappable/dart_mappable.dart';";
  }
}
