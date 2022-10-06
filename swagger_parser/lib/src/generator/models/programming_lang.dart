import 'package:collection/collection.dart';

import '../templates/dart_freezed_dto_template.dart';
import '../templates/dart_json_serializable_dto_template.dart';
import '../templates/dart_retrofit_client_template.dart';
import '../templates/kotlin_moshi_dto_template.dart';
import '../templates/kotlin_retrofit_client_template.dart';
import 'universal_data_class.dart';
import 'universal_rest_client.dart';

/// Enumerates supported programming languages to determine templates
enum ProgrammingLanguage {
  dart('dart'),
  kotlin('kt');

  const ProgrammingLanguage(this.fileExtension);

  /// Extension for generated files
  final String fileExtension;

  /// Used to get [ProgrammingLanguage] from config
  static ProgrammingLanguage? fromString(String? value) =>
      ProgrammingLanguage.values.firstWhereOrNull((e) => e.name == value);

  /// Determines template for generating DTOs by language
  String dtoFileContent(UniversalDataClass dataClass, {bool freezed = false}) {
    switch (this) {
      case ProgrammingLanguage.dart:
        return freezed
            ? dartFreezedDtoTemplate(dataClass)
            : dartJsonSerializableDtoTemplate(dataClass);
      case ProgrammingLanguage.kotlin:
        return kotlinMoshiDtoTemplate(dataClass);
    }
  }

  /// Determines template for generating Rest client by language
  String restClientFileContent(
    UniversalRestClient restClient,
    String? postfix,
  ) {
    switch (this) {
      case ProgrammingLanguage.dart:
        return dartRetrofitClientTemplate(
          restClient: restClient,
          postfix: postfix,
        );
      case ProgrammingLanguage.kotlin:
        return kotlinRetrofitClientTemplate(
          restClient: restClient,
          postfix: postfix,
        );
    }
  }
}
