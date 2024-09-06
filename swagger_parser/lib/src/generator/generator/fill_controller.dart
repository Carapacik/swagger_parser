import '../../parser/swagger_parser_core.dart';
import '../../parser/utils/case_utils.dart';
import '../config/generator_config.dart';
import '../model/generated_file.dart';
import '../model/programming_language.dart';

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
        name: 'models/'
            '${config.language == ProgrammingLanguage.dart ? dataClass.name.toSnake : dataClass.name.toPascal}'
            '.${config.language.fileExtension}',
        content: config.language.dtoFileContent(
          dataClass,
          jsonSerializer: config.jsonSerializer,
          enumsToJson: config.enumsToJson,
          unknownEnumValue: config.unknownEnumValue,
          markFilesAsGenerated: config.markFilesAsGenerated,
        ),
      );

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
      ),
    );
  }

  /// Return [GeneratedFile] root client generated from given clients
  GeneratedFile fillRootClient(Iterable<UniversalRestClient> clients) {
    final rootClientName = config.rootClientName ?? 'RestClient';
    final postfix = config.clientPostfix ?? 'Client';
    final clientsNames = clients.map((c) => c.name.toPascal).toSet();

    return GeneratedFile(
      name: '${rootClientName.toSnake}.${config.language.fileExtension}',
      content: config.language.rootClientFileContent(
        clientsNames,
        openApiInfo: info,
        name: rootClientName,
        postfix: postfix.toPascal,
        putClientsInFolder: config.putClientsInFolder,
        markFilesAsGenerated: config.markFilesAsGenerated,
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
        markFileAsGenerated: config.markFilesAsGenerated,
      ),
    );
  }
}
