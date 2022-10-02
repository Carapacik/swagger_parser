import 'package:swagger_parser/src/generator/models/universal_data_class.dart';
import 'package:swagger_parser/src/generator/models/universal_rest_client.dart';
import 'package:swagger_parser/src/generator/templates/dart_dto_template.dart';
import 'package:swagger_parser/src/generator/templates/dart_retrofit_client_template.dart';
import 'package:swagger_parser/src/generator/templates/freezed_dto_template.dart';
import 'package:swagger_parser/src/generator/templates/kotlin_moshi_dto_template.dart';
import 'package:swagger_parser/src/generator/templates/kotlin_retrofit_client_template.dart';

/// Enumerates supported programming languages to determine templates
enum ProgrammingLanguage {
  dart('dart'),
  kotlin('kt');

  const ProgrammingLanguage(this.fileExtension);

  final String fileExtension;

  /// Determines template for generating DTOs by language
  String dtoFileContent(UniversalDataClass dataClass, {bool freezed = false}) {
    switch (this) {
      case ProgrammingLanguage.dart:
        if (freezed) {
          return freezedDtoTemplate(dataClass: dataClass);
        } else {
          return dartJsonSerializableDtoTemplate(dataClass: dataClass);
        }
      case ProgrammingLanguage.kotlin:
        return kotlinMoshiDtoTemplate(dataClass: dataClass);
    }
  }

  /// Determines template for generating Rest client by language
  String restClientFileContent(UniversalRestClient restClient) {
    switch (this) {
      case ProgrammingLanguage.dart:
        return dartRetrofitClientTemplate(restClient: restClient);
      case ProgrammingLanguage.kotlin:
        return kotlinRetrofitClientTemplate(restClient: restClient);
    }
  }
}
