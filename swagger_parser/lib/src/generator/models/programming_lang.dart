import 'package:collection/collection.dart';

import '../templates/dart_enum_dto_template.dart';
import '../templates/dart_freezed_dto_template.dart';
import '../templates/dart_json_serializable_dto_template.dart';
import '../templates/dart_retrofit_client_template.dart';
import '../templates/dart_root_interface_template.dart';
import '../templates/dart_typedef_template.dart';
import '../templates/kotlin_enum_dto_template.dart';
import '../templates/kotlin_moshi_dto_template.dart';
import '../templates/kotlin_retrofit_client_template.dart';
import '../templates/kotlin_typedef_template.dart';
import 'universal_component_class.dart';
import 'universal_data_class.dart';
import 'universal_enum_class.dart';
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
    bool freezed = false,
    bool enumsToJson = false,
  }) {
    switch (this) {
      case ProgrammingLanguage.dart:
        if (dataClass is UniversalEnumClass) {
          return dartEnumDtoTemplate(
            dataClass,
            freezed: freezed,
            enumsToJson: enumsToJson,
          );
        } else if (dataClass is UniversalComponentClass) {
          if (dataClass.typeDef) {
            return dartTypeDefTemplate(dataClass);
          }
          if (freezed) {
            return dartFreezedDtoTemplate(dataClass);
          }
          return dartJsonSerializableDtoTemplate(dataClass);
        }
        throw Exception('Unknown type exception');
      case ProgrammingLanguage.kotlin:
        if (dataClass is UniversalEnumClass) {
          return kotlinEnumDtoTemplate(dataClass);
        } else if (dataClass is UniversalComponentClass) {
          if (dataClass.typeDef) {
            return kotlinTypeDefTemplate(dataClass);
          }
          return kotlinMoshiDtoTemplate(dataClass);
        }
        throw Exception('Unknown type exception');
    }
  }

  /// Determines template for generating Rest client by language
  String restClientFileContent(UniversalRestClient restClient, String name) {
    switch (this) {
      case ProgrammingLanguage.dart:
        return dartRetrofitClientTemplate(
          restClient: restClient,
          name: name,
        );
      case ProgrammingLanguage.kotlin:
        return kotlinRetrofitClientTemplate(
          restClient: restClient,
          name: name,
        );
    }
  }

  /// Determines template for generating root interface for clients
  String rootInterfaceFileContent(
    Set<String> clientsNames, {
    String postfix = 'Client',
    bool squishClients = false,
  }) {
    switch (this) {
      case ProgrammingLanguage.dart:
        return dartRootInterfaceTemplate(
          clientsNames: clientsNames,
          postfix: postfix,
          squishClients: squishClients,
        );
      case ProgrammingLanguage.kotlin:
        return '';
    }
  }
}
