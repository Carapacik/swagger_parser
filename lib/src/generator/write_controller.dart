import 'dart:io';

import 'package:swagger_parser/src/generator/models/programming_lang.dart';
import 'package:swagger_parser/src/generator/models/universal_data_class.dart';
import 'package:swagger_parser/src/generator/models/universal_rest_client.dart';
import 'package:swagger_parser/src/utils/case_utils.dart';
import 'package:swagger_parser/src/utils/file_utils.dart';

/// Handles generating files
class WriteController {
  const WriteController(
    this._outputDirectory,
    this._programmingLanguage, {
    bool freezed = false,
  }) : _freezed = freezed;

  final String _outputDirectory;
  final ProgrammingLanguage _programmingLanguage;
  final bool _freezed;

  /// Generates DTO classes from [UniversalDataClass] models
  Future<void> generateDto(UniversalDataClass dataClass) async => createDtoFile(
        _outputDirectory,
        '${_programmingLanguage == ProgrammingLanguage.dart ? dataClass.name.toSnake : dataClass.name.toPascal}'
        '.${_programmingLanguage.fileExtension}',
        _programmingLanguage.dtoFileContent(dataClass, freezed: _freezed),
      );

  /// Generates Rest clients from [UniversalRestClient] models
  Future<File> generateRestClient(UniversalRestClient restClient) async {
    if (_programmingLanguage == ProgrammingLanguage.dart) {
      return createRestClientFile(
        _outputDirectory,
        restClient.name.toSnake,
        _programmingLanguage.restClientFileContent(restClient),
        'rest_client.${_programmingLanguage.fileExtension}',
      );
    }
    return createRestClientFile(
      _outputDirectory,
      'clients',
      _programmingLanguage.restClientFileContent(restClient),
      '${restClient.name.toPascal}Client.${_programmingLanguage.fileExtension}',
    );
  }
}
