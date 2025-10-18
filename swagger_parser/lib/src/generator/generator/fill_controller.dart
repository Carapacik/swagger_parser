import 'package:swagger_parser/src/generator/config/generator_config.dart';
import 'package:swagger_parser/src/generator/model/generated_file.dart';
import 'package:swagger_parser/src/generator/model/json_serializer.dart';
import 'package:swagger_parser/src/generator/model/programming_language.dart';
import 'package:swagger_parser/src/parser/model/normalized_identifier.dart';
import 'package:swagger_parser/src/parser/swagger_parser_core.dart';
import 'package:swagger_parser/src/utils/base_utils.dart';

/// Handles generating files
final class FillController {
  /// Constructor that accepts configuration parameters with default values to create files
  const FillController({
    required this.config,
    this.info = const OpenApiInfo(schemaVersion: OAS.v3_1),
  });

  /// Api info
  final OpenApiInfo info;

  /// Config
  final GeneratorConfig config;

  /// Return [GeneratedFile] generated from given [UniversalDataClass]
  GeneratedFile fillDtoContent(UniversalDataClass dataClass) => GeneratedFile(
        name:
            'models/${_resolveDtoFileBaseName(dataClass)}.${config.language.fileExtension}',
        content: config.language.dtoFileContent(
          dataClass,
          jsonSerializer: config.jsonSerializer,
          enumsToJson: config.enumsToJson,
          unknownEnumValue: config.unknownEnumValue,
          markFilesAsGenerated: config.markFilesAsGenerated,
          generateValidator: config.generateValidator,
          useFreezed3: config.useFreezed3,
          useMultipartFile: config.useMultipartFile,
          dartMappableConvenientWhen: config.dartMappableConvenientWhen,
          includeIfNull: config.includeIfNull,
          fallbackUnion: config.fallbackUnion,
        ),
      );

  String _resolveDtoFileBaseName(UniversalDataClass dataClass) {
    if (config.language != ProgrammingLanguage.dart) {
      return dataClass.name.toPascal;
    }

    var baseName = dataClass.name;

    if (config.jsonSerializer != JsonSerializer.freezed &&
        dataClass is UniversalComponentClass) {
      final isUnion = dataClass.discriminator != null ||
          (dataClass.undiscriminatedUnionVariants?.isNotEmpty ?? false);
      if (isUnion) {
        baseName = _applySealedNaming(baseName);
      }
    }

    return baseName.toSnake;
  }

  String _applySealedNaming(String name) {
    const unionSuffix = 'Union';
    const sealedSuffix = 'Sealed';

    if (name.endsWith(sealedSuffix)) {
      return name;
    }

    if (name.endsWith(unionSuffix)) {
      return '${name.substring(0, name.length - unionSuffix.length)}$sealedSuffix';
    }

    return name;
  }

  /// Return [GeneratedFile] generated from given [UniversalRestClient]
  GeneratedFile fillRestClientContent(UniversalRestClient restClient) {
    final postfix = config.clientPostfix ?? 'Client';
    final fileName = config.language == ProgrammingLanguage.dart
        ? '${restClient.name}_$postfix'.toSnake
        : restClient.name.toPascal + postfix.toPascal;
    final folderName =
        config.putClientsInFolder ? 'clients' : restClient.name.toSnake;

    return GeneratedFile(
      name: '$folderName/$fileName.${config.language.fileExtension}',
      content: config.language.restClientFileContent(
        restClient,
        restClient.name.toPascal + postfix.toPascal,
        markFilesAsGenerated: config.markFilesAsGenerated,
        defaultContentType: config.defaultContentType,
        extrasParameterByDefault: config.extrasParameterByDefault,
        dioOptionsParameterByDefault: config.dioOptionsParameterByDefault,
        originalHttpResponse: config.originalHttpResponse,
        useMultipartFile: config.useMultipartFile,
        fileName: fileName,
      ),
    );
  }

  /// Return [GeneratedFile] root client generated from given clients
  GeneratedFile fillRootClient(Iterable<UniversalRestClient> clients) {
    final rootClientName = config.rootClientName ?? 'RestClient';
    final postfix = config.clientPostfix ?? 'Client';
    final clientsNames = clients.map((c) => c.name.toPascal).toSet();
    // Create a map from Pascal names to snake names
    final clientsNameMap = <String, String>{
      for (final client in clients) client.name.toPascal: client.name.toSnake
    };

    return GeneratedFile(
      name: '${rootClientName.toSnake}.${config.language.fileExtension}',
      content: config.language.rootClientFileContent(
        clientsNames,
        openApiInfo: info,
        name: rootClientName,
        postfix: postfix.toPascal,
        putClientsInFolder: config.putClientsInFolder,
        markFilesAsGenerated: config.markFilesAsGenerated,
        clientsNameMap: clientsNameMap,
      ),
    );
  }

  /// Return [GeneratedFile] with all exports from all files
  GeneratedFile fillExportFile({
    required List<GeneratedFile> restClients,
    required List<GeneratedFile> dataClasses,
    required GeneratedFile? rootClient,
  }) {
    return GeneratedFile(
      name: 'export.${config.language.fileExtension}',
      content: config.language.exportFileContent(
        restClients: restClients,
        dataClasses: dataClasses,
        rootClient: rootClient,
      ),
    );
  }

  GeneratedFile fillMergedOutputs(List<GeneratedFile> outputs) {
    final dartImports = <String>{};
    final packageImports = <String>{};
    final lines = <String>[];
    for (final output in outputs) {
      for (final line in output.content.split('\n')) {
        if (line == '') {
          if (lines.isNotEmpty && lines.last != '') {
            lines.add('');
          }
        } else if (line.startsWith('import')) {
          if (config.language == ProgrammingLanguage.kotlin) {
            // Keep all imports in Kotlin
            packageImports.add(line);
          } else {
            // Separate Dart and package imports in Dart and ignore local imports
            if (line.startsWith("import 'package:")) {
              packageImports.add(line);
            } else if (line.startsWith("import 'dart:")) {
              dartImports.add(line);
            }
          }
        } else if (config.language == ProgrammingLanguage.dart &&
            line.startsWith('part ')) {
          // ignore part lines in Dart
        } else {
          lines.add(line);
        }
      }
    }
    final buffer =
        StringBuffer(generatedFileComment(language: config.language));

    if (dartImports.isNotEmpty) {
      for (final import in dartImports.toList()..sort()) {
        buffer.writeln(import);
      }
      buffer.writeln();
    }

    if (packageImports.isNotEmpty) {
      for (final import in packageImports.toList()..sort()) {
        buffer.writeln(import);
      }
      buffer.writeln();
    }

    buffer
      ..writeln(
          "part '${config.name}.freezed.${config.language.fileExtension}';")
      ..writeln("part '${config.name}.g.${config.language.fileExtension}';")
      ..writeln();

    for (final line in lines) {
      buffer.writeln(line);
    }
    return GeneratedFile(
      name: '${config.name}.${config.language.fileExtension}',
      content: buffer.toString(),
    );
  }

  List<GeneratedFile> addGeneratedFileComments(List<GeneratedFile> files) {
    final comment = generatedFileComment(language: config.language);
    return files
        .map((file) =>
            GeneratedFile(name: file.name, content: '$comment${file.content}'))
        .toList();
  }
}
