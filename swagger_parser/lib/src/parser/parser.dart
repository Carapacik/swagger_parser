import 'dart:collection';
import 'dart:convert';

import 'package:collection/collection.dart';

import '../generator/models/all_of.dart';
import '../generator/models/universal_data_class.dart';
import '../generator/models/universal_request.dart';
import '../generator/models/universal_request_type.dart';
import '../generator/models/universal_rest_client.dart';
import '../generator/models/universal_type.dart';
import '../utils/case_utils.dart';
import 'parser_exception.dart';

// ignore_for_file: avoid_dynamic_calls
/// General class for parsing openApi json files into universal models
class OpenApiJsonParser {
  OpenApiJsonParser(String jsonContent) {
    _jsonContent = jsonDecode(jsonContent) as Map<String, dynamic>;

    if (_jsonContent.containsKey('openapi')) {
      final version = _jsonContent['openapi'].toString();
      if (version.startsWith('3.1')) {
        _version = OpenApiVersion.v3_1;
        return;
      }
      if (version.startsWith('3.0')) {
        _version = OpenApiVersion.v3;
        return;
      }
    }
    if (_jsonContent.containsKey('swagger') &&
        _jsonContent['swagger'].toString().startsWith('2.0')) {
      _version = OpenApiVersion.v2;
      return;
    }
    throw ParserException('Unknown version of OpenAPI.');
  }

  late final Map<String, dynamic> _jsonContent;
  late final OpenApiVersion _version;

  static const _defaultClientTag = 'client';
  static const _formatVar = 'format';
  static const _contentVar = 'content';
  static const _responsesVar = 'responses';
  static const _multipartVar = 'multipart/form-data';
  static const _typeVar = 'type';
  static const _bodyVar = 'body';
  static const _nameVar = 'name';
  static const _parametersVar = 'parameters';
  static const _schemaVar = 'schema';
  static const _requestBodyVar = 'requestBody';
  static const _inVar = 'in';
  static const _propertiesVar = 'properties';
  static const _definitionsVar = 'definitions';
  static const _requiredVar = 'required';
  static const _componentsVar = 'components';
  static const _refVar = r'$ref';
  static const _tagsVar = 'tags';
  static const _consumesVar = 'consumes';
  static const _schemasVar = 'schemas';
  static const _pathsVar = 'paths';
  static const _allOfVar = 'allOf';

  /// Parses rest clients from "paths" section of json file into universal models
  Iterable<UniversalRestClient> parseRestClients() {
    final restClients = <UniversalRestClient>[];
    final imports = SplayTreeSet<String>();
    var isMultiPart = false;

    /// Parses return type for client Query for openApi v3
    UniversalType? returnTypeV3(Map<String, dynamic> map) {
      if (!map.containsKey('200') ||
          !(map['200'] as Map<String, dynamic>).containsKey(_contentVar)) {
        return null;
      }
      final contentType =
          (map['200'][_contentVar] as Map<String, dynamic>).entries.firstOrNull;
      if (contentType == null) {
        throw ParserException('Response must always have a content type');
      }
      // When content/{content type} exists but empty
      if ((contentType.value as Map<String, dynamic>).isEmpty) {
        return null;
      }
      final parameter = _arrayWithDepth(
        contentType.value[_schemaVar] as Map<String, dynamic>,
      );
      if (parameter.import != null) {
        imports.add(parameter.import!);
      }
      return UniversalType(
        type: parameter.type.type,
        arrayDepth: parameter.type.arrayDepth,
      );
    }

    /// Parses query parameters (parameters and requestBody)
    /// into universal models for openApi v3
    List<UniversalRequestType> parametersV3(Map<String, dynamic> map) {
      if (!map.containsKey(_parametersVar) &&
          !map.containsKey(_requestBodyVar)) {
        return [];
      }
      final types = <UniversalRequestType>[];
      if (map.containsKey(_parametersVar)) {
        for (final rawParameter in map[_parametersVar] as List<dynamic>) {
          types.add(
            UniversalRequestType(
              parameterType: HttpParameterType.values.firstWhere(
                (e) => e.name == (rawParameter[_inVar].toString()),
              ),
              type: _arrayWithDepth(
                rawParameter[_schemaVar] as Map<String, dynamic>,
                name: rawParameter[_nameVar].toString(),
              ).type,
              name: _checkForBody(rawParameter as Map<String, dynamic>)
                  ? null
                  : rawParameter[_nameVar].toString(),
            ),
          );
        }
      }
      if (map.containsKey(_requestBodyVar)) {
        if (!(map[_requestBodyVar] as Map<String, dynamic>)
            .containsKey(_contentVar)) {
          throw ParserException('requestBody must always have content');
        }
        final contentTypes =
            map[_requestBodyVar][_contentVar] as Map<String, dynamic>;
        Map<String, dynamic>? contentType;
        if (contentTypes.containsKey(_multipartVar)) {
          contentType = map[_requestBodyVar][_contentVar][_multipartVar]
              as Map<String, dynamic>;
          isMultiPart = true;
        } else {
          final content =
              (map[_requestBodyVar][_contentVar] as Map<String, dynamic>)
                  .entries
                  .firstOrNull;
          contentType =
              content == null ? null : content.value as Map<String, dynamic>;
        }
        if (contentType == null) {
          throw ParserException('Response must always have a content type');
        }
        if (isMultiPart) {
          if ((contentType[_schemaVar] as Map<String, dynamic>)
              .containsKey(_refVar)) {
            final typeWithImport = _arrayWithDepth(
              contentType[_schemaVar] as Map<String, dynamic>,
            );
            final currentType = typeWithImport.type;
            if (typeWithImport.import != null) {
              imports.add(typeWithImport.import!);
            }
            types.add(
              UniversalRequestType(
                parameterType: HttpParameterType.part,
                type: UniversalType(
                  type: currentType.type,
                  arrayDepth: currentType.arrayDepth,
                  name: 'file',
                  isRequired: currentType.isRequired,
                  format: currentType.format,
                ),
              ),
            );
          }
          if ((contentType[_schemaVar] as Map<String, dynamic>)
              .containsKey(_propertiesVar)) {
            for (final e in (contentType[_schemaVar][_propertiesVar]
                    as Map<String, dynamic>)
                .entries) {
              final typeWithImport = _arrayWithDepth(
                e.value as Map<String, dynamic>,
              );
              final currentType = typeWithImport.type;
              if (typeWithImport.import != null) {
                imports.add(typeWithImport.import!);
              }
              types.add(
                UniversalRequestType(
                  parameterType: HttpParameterType.part,
                  type: UniversalType(
                    type: currentType.type,
                    arrayDepth: currentType.arrayDepth,
                    name: e.key,
                    isRequired: currentType.isRequired,
                    format: currentType.format,
                  ),
                  name: e.key,
                ),
              );
            }
          }
        } else {
          final typeWithImport = _arrayWithDepth(
            contentType[_schemaVar] as Map<String, dynamic>,
          );
          final currentType = typeWithImport.type;
          if (typeWithImport.import != null) {
            imports.add(typeWithImport.import!);
          }
          types.add(
            UniversalRequestType(
              parameterType: HttpParameterType.body,
              type: UniversalType(
                type: currentType.type,
                arrayDepth: currentType.arrayDepth,
                name: _bodyVar,
                isRequired: currentType.isRequired,
                format: currentType.format,
              ),
            ),
          );
        }
      }
      return types;
    }

    /// Parses return type for client query for openApi v2
    UniversalType? returnTypeV2(Map<String, dynamic> map) {
      if (!map.containsKey('200') ||
          !(map['200'] as Map<String, dynamic>).containsKey(_schemaVar)) {
        return null;
      }
      final parameter = _arrayWithDepth(
        map['200'][_schemaVar] as Map<String, dynamic>,
      );
      if (parameter.import != null) {
        imports.add(parameter.import!);
      }
      return UniversalType(
        type: parameter.type.type,
        arrayDepth: parameter.type.arrayDepth,
      );
    }

    /// Parses query parameters (parameters and requestBody)
    /// into universal models for openApi v2
    List<UniversalRequestType> parametersV2(Map<String, dynamic> map) {
      final types = <UniversalRequestType>[];
      if (!map.containsKey(_parametersVar)) {
        return types;
      }
      if (map.containsKey(_consumesVar) &&
          (map[_consumesVar] as List<dynamic>).contains(_multipartVar)) {
        isMultiPart = true;
      }
      for (final rawParameter in map[_parametersVar] as List<dynamic>) {
        types.add(
          UniversalRequestType(
            parameterType: HttpParameterType.values
                .firstWhere((e) => e.name == (rawParameter[_inVar].toString())),
            type: _arrayWithDepth(
              rawParameter as Map<String, dynamic>,
              name: rawParameter[_nameVar].toString(),
            ).type,
            name: _checkForBody(rawParameter)
                ? null
                : rawParameter[_nameVar].toString(),
          ),
        );
      }
      return types;
    }

    (_jsonContent[_pathsVar] as Map<String, dynamic>)
        .forEach((path, pathValue) {
      (pathValue as Map<String, dynamic>).forEach((key, requestPath) {
        final request = UniversalRequest(
          isMultiPart: isMultiPart,
          name: (key + path).toCamel,
          requestType: HttpRequestType.fromString(key)!,
          route: path,
          returnType:
              (_version == OpenApiVersion.v3_1 || _version == OpenApiVersion.v3)
                  ? returnTypeV3(
                      requestPath[_responsesVar] as Map<String, dynamic>,
                    )
                  : returnTypeV2(
                      requestPath[_responsesVar] as Map<String, dynamic>,
                    ),
          parameters:
              (_version == OpenApiVersion.v3_1 || _version == OpenApiVersion.v3)
                  ? parametersV3(requestPath as Map<String, dynamic>)
                  : parametersV2(requestPath as Map<String, dynamic>),
        );
        final currentTag = _getTag(requestPath);
        final sameTagIndex =
            restClients.indexWhere((e) => e.name == currentTag);
        if (sameTagIndex == -1) {
          restClients.add(
            UniversalRestClient(
              name: currentTag,
              requests: [request],
              imports: SplayTreeSet<String>.of(imports),
            ),
          );
        } else {
          restClients[sameTagIndex].requests.add(request);
          restClients[sameTagIndex].imports.addAll(imports);
        }
        isMultiPart = false;
        imports.clear();
      });
    });
    return restClients;
  }

  /// Parses data classes from "components" of json file to universal models
  Iterable<UniversalDataClass> parseDataClasses() {
    final dataClasses = <UniversalDataClass>[];
    late Map<String, dynamic> entities;
    if (_version == OpenApiVersion.v3_1 || _version == OpenApiVersion.v3) {
      if (!_jsonContent.containsKey(_componentsVar) ||
          !(_jsonContent[_componentsVar] as Map<String, dynamic>)
              .containsKey(_schemasVar)) {
        return dataClasses;
      }
      entities =
          _jsonContent[_componentsVar][_schemasVar] as Map<String, dynamic>;
    } else if (_version == OpenApiVersion.v2) {
      if (!_jsonContent.containsKey(_definitionsVar)) {
        return dataClasses;
      }
      entities = _jsonContent[_definitionsVar] as Map<String, dynamic>;
    }

    entities.forEach((key, value) {
      var requiredParameters = <String>[];
      if ((value as Map<String, dynamic>).containsKey(_requiredVar)) {
        requiredParameters = (value[_requiredVar] as List<dynamic>)
            .map((e) => e.toString())
            .toList();
      }

      final refs = <String>[];
      final parameters = <UniversalType>[];
      final imports = SplayTreeSet<String>();

      void findParamsAndImports(Map<String, dynamic> map) {
        (map[_propertiesVar] as Map<String, dynamic>).forEach(
          (propertyName, propertyValue) {
            final typeWithImport = _arrayWithDepth(
              propertyValue as Map<String, dynamic>,
              name: propertyName,
              isRequired: requiredParameters.contains(propertyName) ||
                  requiredParameters.isEmpty,
            );
            parameters.add(typeWithImport.type);
            if (typeWithImport.import != null) {
              imports.add(typeWithImport.import!);
            }
          },
        );
      }

      if (value.containsKey(_propertiesVar)) {
        findParamsAndImports(value);
      } else if (value.containsKey(_allOfVar)) {
        for (final element in value[_allOfVar] as List) {
          if ((element as Map<String, dynamic>).containsKey(_refVar)) {
            refs.add(_formatRef(element[_refVar].toString()));
            continue;
          }
          if (element.containsKey(_propertiesVar)) {
            findParamsAndImports(element);
          }
        }
      }

      final allOf =
          refs.isNotEmpty ? AllOf(refs: refs, properties: parameters) : null;
      dataClasses.add(
        UniversalDataClass(
          name: key,
          imports: imports,
          parameters: allOf != null ? [] : parameters,
          allOf: allOf,
        ),
      );
    });
    // allOf check
    final allOfClasses = dataClasses.where((element) => element.allOf != null);
    for (final allOfClass in allOfClasses) {
      final refs = allOfClass.allOf!.refs;
      final foundClasses =
          dataClasses.where((element) => refs.contains(element.name)).toList();
      for (final element in foundClasses) {
        allOfClass.parameters.addAll(element.parameters);
        allOfClass.imports.addAll(element.imports);
      }
      allOfClass.parameters.addAll(allOfClass.allOf!.properties);
    }

    return dataClasses;
  }

  String _getTag(Map<String, dynamic> map) => map.containsKey(_tagsVar)
      ? (map[_tagsVar] as List<dynamic>).first.toString()
      : _defaultClientTag;

  bool _checkForBody(Map<String, dynamic> map) => map[_nameVar] == _bodyVar;

  String _formatRef(String ref) => ref.split('/').last.toPascal;

  TypeWithImport _arrayWithDepth(
    Map<String, dynamic> map, {
    String? name,
    bool isRequired = true,
  }) {
    if (map.containsKey(_typeVar) && map[_typeVar] == 'array') {
      final arrayType = _arrayWithDepth(map['items'] as Map<String, dynamic>);
      return TypeWithImport(
        type: UniversalType(
          name: name?.toCamel,
          jsonKey: name,
          type: arrayType.type.type,
          arrayDepth: arrayType.type.arrayDepth + 1,
          format: arrayType.type.format,
          isRequired: isRequired,
        ),
        import: arrayType.import,
      );
    }
    return TypeWithImport(
      type: UniversalType(
        name: name?.toCamel,
        jsonKey: name,
        format: map.containsKey(_formatVar) ? map[_formatVar].toString() : null,
        type: map.containsKey(_typeVar)
            ? map[_typeVar].toString()
            : _formatRef(map[_refVar].toString()),
        isRequired: isRequired,
      ),
      import:
          map.containsKey(_refVar) ? _formatRef(map[_refVar].toString()) : null,
    );
  }
}

/// Class that contains Certain type and imports associated with it
/// Imports are created when $ref is found while determining type
class TypeWithImport {
  TypeWithImport({required this.type, this.import});

  UniversalType type;
  String? import;
}

enum OpenApiVersion { v3_1, v3, v2 }
