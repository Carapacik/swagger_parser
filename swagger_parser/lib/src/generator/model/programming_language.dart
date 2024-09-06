import '../../parser/swagger_parser_core.dart';
import '../model/generated_file.dart';
import '../model/json_serializer.dart';
import '../templates/dart_dart_mappable_dto_template.dart';
import '../templates/dart_enum_dto_template.dart';
import '../templates/dart_export_file_template.dart';
import '../templates/dart_freezed_dto_template.dart';
import '../templates/dart_json_serializable_dto_template.dart';
import '../templates/dart_retrofit_client_template.dart';
import '../templates/dart_root_client_template.dart';
import '../templates/dart_typedef_template.dart';
import '../templates/kotlin_enum_dto_template.dart';
import '../templates/kotlin_moshi_dto_template.dart';
import '../templates/kotlin_retrofit_client_template.dart';
import '../templates/kotlin_typedef_template.dart';

/// Enumerates supported programming languages to determine templates
enum ProgrammingLanguage {
  /// Dart language
  dart('dart'),

  /// Kotlin language
  kotlin('kt');

  /// Constructor with [fileExtension] for every language
  const ProgrammingLanguage(this.fileExtension);

  /// Returns [ProgrammingLanguage] from string
  factory ProgrammingLanguage.fromString(String value) =>
      ProgrammingLanguage.values.firstWhere(
        (e) => e.name == value,
        orElse: () => throw ArgumentError(
          "'$value' must be contained in ${ProgrammingLanguage.values.map((e) => e.name)}",
        ),
      );

  /// Extension for generated files
  final String fileExtension;

  /// Determines template for generating DTOs by language
  String dtoFileContent(
    UniversalDataClass dataClass, {
    required JsonSerializer jsonSerializer,
    required bool enumsToJson,
    required bool unknownEnumValue,
    required bool markFilesAsGenerated,
  }) {
    switch (this) {
      case dart:
        if (dataClass is UniversalEnumClass) {
          return dartEnumDtoTemplate(
            dataClass,
            jsonSerializer: jsonSerializer,
            enumsToJson: enumsToJson,
            unknownEnumValue: unknownEnumValue,
            markFileAsGenerated: markFilesAsGenerated,
          );
        } else if (dataClass is UniversalComponentClass) {
          if (dataClass.typeDef) {
            return dartTypeDefTemplate(
              dataClass,
              markFileAsGenerated: markFilesAsGenerated,
            );
          }

          switch (jsonSerializer) {
            case JsonSerializer.freezed:
              return dartFreezedDtoTemplate(
                dataClass,
                markFileAsGenerated: markFilesAsGenerated,
              );
            case JsonSerializer.jsonSerializable:
              return dartJsonSerializableDtoTemplate(
                dataClass,
                markFileAsGenerated: markFilesAsGenerated,
              );
            case JsonSerializer.dartMappable:
              return dartDartMappableDtoTemplate(
                dataClass,
                markFileAsGenerated: markFilesAsGenerated,
              );
          }
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
    throw ArgumentError('Unknown type exception');
  }

  /// Determines template for generating Rest client by language
  String restClientFileContent(
    UniversalRestClient restClient,
    String name, {
    required bool markFilesAsGenerated,
    required String defaultContentType,
    bool extrasParameterByDefault = false,
    bool dioOptionsParameterByDefault = false,
    bool originalHttpResponse = false,
  }) =>
      switch (this) {
        dart => dartRetrofitClientTemplate(
            restClient: restClient,
            name: name,
            markFileAsGenerated: markFilesAsGenerated,
            defaultContentType: defaultContentType,
            extrasParameterByDefault: extrasParameterByDefault,
            dioOptionsParameterByDefault: dioOptionsParameterByDefault,
            originalHttpResponse: originalHttpResponse,
          ),
        kotlin => kotlinRetrofitClientTemplate(
            restClient: restClient,
            name: name,
            markFileAsGenerated: markFilesAsGenerated,
          ),
      };

  /// Determines template for generating root client for clients
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

  /// Export file by language
  String exportFileContent({
    required bool markFileAsGenerated,
    required List<GeneratedFile> restClients,
    required List<GeneratedFile> dataClasses,
    required GeneratedFile? rootClient,
  }) =>
      switch (this) {
        dart => dartExportFileTemplate(
            markFileAsGenerated: markFileAsGenerated,
            restClients: restClients,
            dataClasses: dataClasses,
            rootClient: rootClient,
          ),
        kotlin => '',
      };
}
