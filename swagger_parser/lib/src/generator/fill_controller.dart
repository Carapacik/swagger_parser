import '../utils/case_utils.dart';
import 'models/generated_file.dart';
import 'models/open_api_info.dart';
import 'models/programming_language.dart';
import 'models/universal_data_class.dart';
import 'models/universal_rest_client.dart';

/// Handles generating files
final class FillController {
  /// Constructor that accepts configuration parameters with default values to create files
  const FillController({
    OpenApiInfo openApiInfo = const OpenApiInfo(),
    ProgrammingLanguage programmingLanguage = ProgrammingLanguage.dart,
    String clientPostfix = 'Client',
    String rootClientName = 'RestClient',
    bool putClientsInFolder = false,
    bool freezed = false,
    bool enumsToJson = false,
    bool unknownEnumValue = true,
    bool markFilesAsGenerated = false,
    String defaultContentType = 'application/json',
  })  : _openApiInfo = openApiInfo,
        _clientPostfix = clientPostfix,
        _programmingLanguage = programmingLanguage,
        _rootClientName = rootClientName,
        _putClientsInFolder = putClientsInFolder,
        _freezed = freezed,
        _enumsToJson = enumsToJson,
        _unknownEnumValue = unknownEnumValue,
        _markFilesAsGenerated = markFilesAsGenerated,
        _defaultContentType = defaultContentType;

  final OpenApiInfo _openApiInfo;
  final ProgrammingLanguage _programmingLanguage;
  final String _rootClientName;
  final String _clientPostfix;
  final bool _freezed;
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
          freezed: _freezed,
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
}
