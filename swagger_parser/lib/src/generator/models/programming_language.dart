import 'package:collection/collection.dart';

import '../generator_exception.dart';
import '../templates/dart_enum_dto_template.dart';
import '../templates/dart_freezed_dto_template.dart';
import '../templates/dart_json_serializable_dto_template.dart';
import '../templates/dart_retrofit_client_template.dart';
import '../templates/dart_root_client_template.dart';
import '../templates/dart_typedef_template.dart';
import '../templates/kotlin_enum_dto_template.dart';
import '../templates/kotlin_moshi_dto_template.dart';
import '../templates/kotlin_retrofit_client_template.dart';
import '../templates/kotlin_typedef_template.dart';
import 'open_api_info.dart';
import 'universal_data_class.dart';
import 'universal_rest_client.dart';

/// Enumerates supported programming languages to determine templates
enum ProgrammingLanguage {
  /// Dart language
  dart('dart'),

  /// Kotlin language
  kotlin('kt');

  /// Constructor with [fileExtension] for every language
  const ProgrammingLanguage(this.fileExtension);

  /// Extension for generated files
  final String fileExtension;

  /// Used to get [ProgrammingLanguage] from config
  static ProgrammingLanguage? fromString(String? value) =>
      ProgrammingLanguage.values.firstWhereOrNull((e) => e.name == value);

  /// Determines template for generating DTOs by language
  String dtoFileContent(
    UniversalDataClass dataClass, {
    required bool freezed,
    required bool enumsToJson,
    required bool markFilesAsGenerated,
  }) {
    switch (this) {
      case dart:
        if (dataClass is UniversalEnumClass) {
          return dartEnumDtoTemplate(
            dataClass,
            freezed: freezed,
            enumsToJson: enumsToJson,
            markFileAsGenerated: markFilesAsGenerated,
          );
        } else if (dataClass is UniversalComponentClass) {
          if (dataClass.typeDef) {
            return dartTypeDefTemplate(
              dataClass,
              markFileAsGenerated: markFilesAsGenerated,
            );
          }
          if (freezed) {
            return dartFreezedDtoTemplate(
              dataClass,
              markFileAsGenerated: markFilesAsGenerated,
            );
          }
          return dartJsonSerializableDtoTemplate(
            dataClass,
            markFileAsGenerated: markFilesAsGenerated,
          );
        }
      case kotlin:
        if (dataClass is UniversalEnumClass) {
          return kotlinEnumDtoTemplate(
            dataClass,
            markFileAsGenerated: markFilesAsGenerated,
          );
        } else if (dataClass is UniversalComponentClass) {
          if (dataClass.typeDef) {
            return kotlinTypeDefTemplate(
              dataClass,
              markFileAsGenerated: markFilesAsGenerated,
            );
          }
          return kotlinMoshiDtoTemplate(
            dataClass,
            markFileAsGenerated: markFilesAsGenerated,
          );
        }
    }
    throw GeneratorException('Unknown type exception');
  }

  /// Determines template for generating Rest client by language
  String restClientFileContent(
    UniversalRestClient restClient,
    String name, {
    required bool markFilesAsGenerated,
  }) =>
      switch (this) {
        dart => dartRetrofitClientTemplate(
            restClient: restClient,
            name: name,
            markFileAsGenerated: markFilesAsGenerated,
          ),
        kotlin => kotlinRetrofitClientTemplate(
            restClient: restClient,
            name: name,
            markFileAsGenerated: markFilesAsGenerated,
          ),
      };

  /// Determines template for generating root interface for clients
  String rootClientFileContent(
    Set<String> clientsNames, {
    required OpenApiInfo openApiInfo,
    required String name,
    required String postfix,
    required bool putClientsInFolder,
    required bool markFilesAsGenerated,
  }) =>
      switch (this) {
        dart => dartRootClientTemplate(
            openApiInfo: openApiInfo,
            name: name,
            clientsNames: clientsNames,
            postfix: postfix,
            putClientsInFolder: putClientsInFolder,
            markFileAsGenerated: markFilesAsGenerated,
          ),
        kotlin => '',
      };
}
