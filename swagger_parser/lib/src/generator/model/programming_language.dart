import 'package:swagger_parser/src/generator/model/generated_file.dart';
import 'package:swagger_parser/src/generator/model/json_serializer.dart';
import 'package:swagger_parser/src/generator/templates/dart_dart_mappable_dto_template.dart';
import 'package:swagger_parser/src/generator/templates/dart_enum_dto_template.dart';
import 'package:swagger_parser/src/generator/templates/dart_export_file_template.dart';
import 'package:swagger_parser/src/generator/templates/dart_freezed_dto_template.dart';
import 'package:swagger_parser/src/generator/templates/dart_json_serializable_dto_template.dart';
import 'package:swagger_parser/src/generator/templates/dart_retrofit_client_template.dart';
import 'package:swagger_parser/src/generator/templates/dart_root_client_template.dart';
import 'package:swagger_parser/src/generator/templates/dart_typedef_template.dart';
import 'package:swagger_parser/src/generator/templates/kotlin_enum_dto_template.dart';
import 'package:swagger_parser/src/generator/templates/kotlin_moshi_dto_template.dart';
import 'package:swagger_parser/src/generator/templates/kotlin_retrofit_client_template.dart';
import 'package:swagger_parser/src/generator/templates/kotlin_typedef_template.dart';
import 'package:swagger_parser/src/parser/swagger_parser_core.dart';

/// Enumerates supported programming languages to determine templates
enum ProgrammingLanguage {
  /// Dart language
  dart('dart'),

  /// Kotlin language
  kotlin('kt');

  /// Constructor with [fileExtension] for every language
  const ProgrammingLanguage(this.fileExtension);

  /// Returns [ProgrammingLanguage] from string
  factory ProgrammingLanguage.fromString(
    String value,
  ) =>
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
    required bool generateValidator,
    required bool useFreezed3,
    required bool useMultipartFile,
    required bool dartMappableConvenientWhen,
    required bool includeIfNull,
    String? fallbackUnion,
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
            return dartTypeDefTemplate(dataClass,
                useMultipartFile: useMultipartFile);
          }
          return switch (jsonSerializer) {
            JsonSerializer.freezed => dartFreezedDtoTemplate(
                dataClass,
                generateValidator: generateValidator,
                isV3: useFreezed3,
                useMultipartFile: useMultipartFile,
                includeIfNull: includeIfNull,
                fallbackUnion: fallbackUnion,
              ),
            JsonSerializer.jsonSerializable => dartJsonSerializableDtoTemplate(
                dataClass,
                markFileAsGenerated: markFilesAsGenerated,
                useMultipartFile: useMultipartFile,
                includeIfNull: includeIfNull,
                fallbackUnion: fallbackUnion,
              ),
            JsonSerializer.dartMappable => dartDartMappableDtoTemplate(
                dataClass,
                markFileAsGenerated: markFilesAsGenerated,
                useMultipartFile: useMultipartFile,
                fallbackUnion: fallbackUnion,
                dartMappableConvenientWhen: dartMappableConvenientWhen,
              ),
          };
        }
      case kotlin:
        if (dataClass is UniversalEnumClass) {
          return kotlinEnumDtoTemplate(dataClass);
        } else if (dataClass is UniversalComponentClass) {
          if (dataClass.typeDef) {
            return kotlinTypeDefTemplate(dataClass);
          }
          return kotlinMoshiDtoTemplate(dataClass);
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
    required bool useMultipartFile,
    bool extrasParameterByDefault = false,
    bool dioOptionsParameterByDefault = false,
    bool originalHttpResponse = false,
    String? fileName,
  }) =>
      switch (this) {
        dart => dartRetrofitClientTemplate(
            restClient: restClient,
            name: name,
            defaultContentType: defaultContentType,
            extrasParameterByDefault: extrasParameterByDefault,
            dioOptionsParameterByDefault: dioOptionsParameterByDefault,
            originalHttpResponse: originalHttpResponse,
            useMultipartFile: useMultipartFile,
            fileName: fileName,
          ),
        kotlin =>
          kotlinRetrofitClientTemplate(restClient: restClient, name: name),
      };

  /// Determines template for generating root client for clients
  String rootClientFileContent(
    Set<String> clientsNames, {
    required OpenApiInfo openApiInfo,
    required String name,
    required String postfix,
    required bool putClientsInFolder,
    required bool markFilesAsGenerated,
    Map<String, String>? clientsNameMap,
  }) =>
      switch (this) {
        dart => dartRootClientTemplate(
            openApiInfo: openApiInfo,
            name: name,
            clientsNames: clientsNames,
            postfix: postfix,
            putClientsInFolder: putClientsInFolder,
            markFileAsGenerated: markFilesAsGenerated,
            clientsNameMap: clientsNameMap,
          ),
        kotlin => '',
      };

  /// Export file by language
  String exportFileContent({
    required List<GeneratedFile> restClients,
    required List<GeneratedFile> dataClasses,
    required GeneratedFile? rootClient,
  }) =>
      switch (this) {
        dart => dartExportFileTemplate(
            restClients: restClients,
            dataClasses: dataClasses,
            rootClient: rootClient,
          ),
        kotlin => '',
      };
}
