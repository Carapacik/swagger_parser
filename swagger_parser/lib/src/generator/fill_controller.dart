import '../utils/case_utils.dart';
import 'models/generated_file.dart';
import 'models/json_serializer.dart';
import 'models/open_api_info.dart';
import 'models/programming_language.dart';
import 'models/universal_data_class.dart';
import 'models/universal_rest_client.dart';

/// Handles generating files
final class FillController {
  /// Constructor that accepts configuration parameters with default values to create files
  const FillController({
    OpenApiInfo openApiInfo = const OpenApiInfo(schemaVersion: OAS.v3_1),
    ProgrammingLanguage programmingLanguage = ProgrammingLanguage.dart,
    String clientPostfix = 'Client',
    String rootClientName = 'RestClient',
    String exportFileName = 'export',
    bool putClientsInFolder = false,
    JsonSerializer jsonSerializer = JsonSerializer.jsonSerializable,
    bool enumsToJson = false,
    bool unknownEnumValue = true,
    bool markFilesAsGenerated = false,
    String defaultContentType = 'application/json',
  })  : _openApiInfo = openApiInfo,
        _programmingLanguage = programmingLanguage,
        _clientPostfix = clientPostfix,
        _rootClientName = rootClientName,
        _exportFileName = exportFileName,
        _putClientsInFolder = putClientsInFolder,
        _jsonSerializer = jsonSerializer,
        _enumsToJson = enumsToJson,
        _unknownEnumValue = unknownEnumValue,
        _markFilesAsGenerated = markFilesAsGenerated,
        _defaultContentType = defaultContentType;

  final OpenApiInfo _openApiInfo;
  final ProgrammingLanguage _programmingLanguage;
  final String _clientPostfix;
  final String _rootClientName;
  final String _exportFileName;
  final JsonSerializer _jsonSerializer;
  final bool _putClientsInFolder;
  final bool _enumsToJson;
  final bool _unknownEnumValue;
  final bool _markFilesAsGenerated;
  final String _defaultContentType;

  /// Return [GeneratedFile] generated from given [UniversalDataClass]
  GeneratedFile fillDtoContent(UniversalDataClass dataClass) => GeneratedFile(
        name: 'models/'
            '${_programmingLanguage == ProgrammingLanguage.dart ? dataClass.name.toSnake : dataClass.name.toPascal}'
            '.${_programmingLanguage.fileExtension}',
        contents: _programmingLanguage.dtoFileContent(
          dataClass,
          jsonSerializer: _jsonSerializer,
          enumsToJson: _enumsToJson,
          unknownEnumValue: _unknownEnumValue,
          markFilesAsGenerated: _markFilesAsGenerated,
        ),
      );

  /// Return [GeneratedFile] generated from given [UniversalRestClient]
  GeneratedFile fillRestClientContent(UniversalRestClient restClient) {
    final fileName = _programmingLanguage == ProgrammingLanguage.dart
        ? '${restClient.name}_$_clientPostfix'.toSnake
        : restClient.name.toPascal + _clientPostfix.toPascal;
    final folderName =
        _putClientsInFolder ? 'clients' : restClient.name.toSnake;

    return GeneratedFile(
      name: '$folderName/$fileName.${_programmingLanguage.fileExtension}',
      contents: _programmingLanguage.restClientFileContent(
        restClient,
        restClient.name.toPascal + _clientPostfix.toPascal,
        markFilesAsGenerated: _markFilesAsGenerated,
        defaultContentType: _defaultContentType,
      ),
    );
  }

  /// Return [GeneratedFile] root client generated from given clients
  GeneratedFile fillRootClient(Iterable<UniversalRestClient> clients) {
    final clientsNames = clients.map((c) => c.name.toPascal).toSet();
    return GeneratedFile(
      name: '${_rootClientName.toSnake}.${_programmingLanguage.fileExtension}',
      contents: _programmingLanguage.rootClientFileContent(
        clientsNames,
        openApiInfo: _openApiInfo,
        name: _rootClientName,
        postfix: _clientPostfix.toPascal,
        putClientsInFolder: _putClientsInFolder,
        markFilesAsGenerated: _markFilesAsGenerated,
      ),
    );
  }

  /// Return [GeneratedFile] with all exports from all files
  GeneratedFile fillExportFile({
    required List<GeneratedFile> restClients,
    required List<GeneratedFile> dataClasses,
    GeneratedFile? rootClient,
  }) =>
      GeneratedFile(
        name: '$_exportFileName.${_programmingLanguage.fileExtension}',
        contents: _programmingLanguage.exportFileContent(
          restClients: restClients,
          dataClasses: dataClasses,
          rootClient: rootClient,
          markFileAsGenerated: _markFilesAsGenerated,
        ),
      );
}
