import '../utils/case_utils.dart';
import 'models/generated_file.dart';
import 'models/programming_lang.dart';
import 'models/universal_data_class.dart';
import 'models/universal_rest_client.dart';

/// Handles generating files
class FillController {
  const FillController({
    String clientPostfix = 'Client',
    ProgrammingLanguage programmingLanguage = ProgrammingLanguage.dart,
    bool squishClients = false,
    bool freezed = false,
  })  : _clientPostfix = clientPostfix,
        _programmingLanguage = programmingLanguage,
        _squishClients = squishClients,
        _freezed = freezed;

  final ProgrammingLanguage _programmingLanguage;
  final String _clientPostfix;
  final bool _freezed;
  final bool _squishClients;

  /// Return [GeneratedFile] generated from given [UniversalDataClass]
  Future<GeneratedFile> fillDtoContent(UniversalDataClass dataClass) async =>
      GeneratedFile(
        name: 'shared_models/'
            '${_programmingLanguage == ProgrammingLanguage.dart ? dataClass.name.toSnake : dataClass.name.toPascal}'
            '.${_programmingLanguage.fileExtension}',
        contents:
            _programmingLanguage.dtoFileContent(dataClass, freezed: _freezed),
      );

  /// Return [GeneratedFile] generated from given [UniversalRestClient]
  Future<GeneratedFile> fillRestClientContent(
    UniversalRestClient restClient,
  ) async {
    final fileName = _programmingLanguage == ProgrammingLanguage.dart
        ? _squishClients
            ? (restClient.name + _clientPostfix).toSnake
            : 'rest_client'
        : _squishClients
            ? restClient.name.toPascal + _clientPostfix
            : 'RestClient';
    final folderName =
        _squishClients ? 'clients/' : '${restClient.name.toSnake}/';
    return GeneratedFile(
      name: '$folderName$fileName.${_programmingLanguage.fileExtension}',
      contents: _programmingLanguage.restClientFileContent(
        restClient,
        _squishClients ? _clientPostfix : null,
      ),
    );
  }
}
