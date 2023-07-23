import '../utils/case_utils.dart';
import 'models/generated_file.dart';
import 'models/programming_lang.dart';
import 'models/universal_data_class.dart';
import 'models/universal_rest_client.dart';

/// Handles generating files
class FillController {
  const FillController({
    ProgrammingLanguage programmingLanguage = ProgrammingLanguage.dart,
    String clientPostfix = 'Client',
    bool squishClients = false,
    bool freezed = false,
    bool includeToJsonInEnums = false,
  })  : _clientPostfix = clientPostfix,
        _programmingLanguage = programmingLanguage,
        _squishClients = squishClients,
        _freezed = freezed,
        _includeToJsonInEnums = includeToJsonInEnums;

  final ProgrammingLanguage _programmingLanguage;
  final String _clientPostfix;
  final bool _freezed;
  final bool _squishClients;
  final bool _includeToJsonInEnums;

  /// Return [GeneratedFile] generated from given [UniversalDataClass]
  GeneratedFile fillDtoContent(UniversalDataClass dataClass) => GeneratedFile(
        name: 'shared_models/'
            '${_programmingLanguage == ProgrammingLanguage.dart ? dataClass.name.toSnake : dataClass.name.toPascal}'
            '.${_programmingLanguage.fileExtension}',
        contents: _programmingLanguage.dtoFileContent(
          dataClass,
          freezed: _freezed,
          includeToJsonInEnums: _includeToJsonInEnums,
        ),
      );

  /// Return [GeneratedFile] generated from given [UniversalRestClient]
  GeneratedFile fillRestClientContent(UniversalRestClient restClient) {
    final fileName = _programmingLanguage == ProgrammingLanguage.dart
        ? '${restClient.name}_$_clientPostfix'.toSnake
        : restClient.name.toPascal + _clientPostfix.toPascal;
    final folderName = _squishClients ? 'clients' : restClient.name.toSnake;
    return GeneratedFile(
      name: '$folderName/$fileName.${_programmingLanguage.fileExtension}',
      contents: _programmingLanguage.restClientFileContent(
        restClient,
        restClient.name.toPascal + _clientPostfix.toPascal,
      ),
    );
  }

  GeneratedFile fillRootInterface(Iterable<UniversalRestClient> clients) {
    final clientsNames = clients.map((c) => c.name.toPascal).toSet();
    return GeneratedFile(
      name: 'rest_client.${_programmingLanguage.fileExtension}',
      contents: _programmingLanguage.rootInterfaceFileContent(
        clientsNames,
        postfix: _clientPostfix.toPascal,
        squishClients: _squishClients,
      ),
    );
  }
}
