import 'dart:collection';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../generator/models/open_api_info.dart';
import '../generator/models/replacement_rule.dart';
import '../generator/models/universal_data_class.dart';
import '../generator/models/universal_request.dart';
import '../generator/models/universal_request_type.dart';
import '../generator/models/universal_rest_client.dart';
import '../generator/models/universal_type.dart';
import '../utils/case_utils.dart';
import '../utils/dart_keywords.dart';
import '../utils/utils.dart';
import 'parser_exception.dart';

export 'parser_exception.dart';

/// General class for parsing OpenApi files into universal models
class OpenApiParser {
  /// Accepts [fileContent] of the schema file
  /// and [isYaml] schema format or not
  OpenApiParser(
    String fileContent, {
    bool isYaml = false,
    bool enumsPrefix = false,
    bool pathMethodName = false,
    String? name,
    bool squashClients = false,
    List<ReplacementRule> replacementRules = const <ReplacementRule>[],
  })  : _pathMethodName = pathMethodName,
        _enumsPrefix = enumsPrefix,
        _name = name,
        _squashClients = squashClients,
        _replacementRules = replacementRules {
    _definitionFileContent = isYaml
        ? (loadYaml(fileContent) as YamlMap).toMap()
        : jsonDecode(fileContent) as Map<String, dynamic>;

    if (_definitionFileContent.containsKey(_openApiConst)) {
      final version = _definitionFileContent[_openApiConst].toString();
      if (version.startsWith('3.1')) {
        _version = OAS.v3_1;
        return;
      }
      if (version.startsWith('3.0')) {
        _version = OAS.v3;
        return;
      }
    }
    if (_definitionFileContent.containsKey(_swaggerConst) &&
        _definitionFileContent[_swaggerConst].toString().startsWith('2.0')) {
      _version = OAS.v2;
      return;
    }
    throw const ParserException('Unknown version of OpenAPI.');
  }

  final bool _pathMethodName;
  final bool _enumsPrefix;
  final String? _name;
  final bool _squashClients;
  final List<ReplacementRule> _replacementRules;
  late final Map<String, dynamic> _definitionFileContent;
  late final OAS _version;
  final List<UniversalComponentClass> _objectClasses = [];
  final List<UniversalEnumClass> _enumClasses = [];
  int _uniqueNameCounter = 0;

  static const _additionalPropertiesConst = 'additionalProperties';
  static const _allOfConst = 'allOf';
  static const _anyOfConst = 'anyOf';
  static const _arrayConst = 'array';
  static const _bodyConst = 'body';
  static const _componentsConst = 'components';
  static const _consumesConst = 'consumes';
  static const _contentConst = 'content';
  static const _defaultConst = 'default';
  static const _definitionsConst = 'definitions';
  static const _descriptionConst = 'description';
  static const _enumConst = 'enum';
  static const _formatConst = 'format';
  static const _formUrlEncodedConst = 'application/x-www-form-urlencoded';
  static const _inConst = 'in';
  static const _infoConst = 'info';
  static const _itemsConst = 'items';
  static const _multipartFormDataConst = 'multipart/form-data';
  static const _nameConst = 'name';
  static const _nullableConst = 'nullable';
  static const _objectConst = 'object';
  static const _oneOfConst = 'oneOf';
  static const _openApiConst = 'openapi';
  static const _operationIdConst = 'operationId';
  static const _parametersConst = 'parameters';
  static const _pathsConst = 'paths';
  static const _propertiesConst = 'properties';
  static const _refConst = r'$ref';
  static const _requestBodyConst = 'requestBody';
  static const _requiredConst = 'required';
  static const _responsesConst = 'responses';
  static const _schemaConst = 'schema';
  static const _schemasConst = 'schemas';
  static const _serversConst = 'servers';
  static const _summaryConst = 'summary';
  static const _swaggerConst = 'swagger';
  static const _tagsConst = 'tags';
  static const _titleConst = 'title';
  static const _typeConst = 'type';
  static const _valueConst = 'value';
  static const _versionConst = 'version';

  OpenApiInfo parseOpenApiInfo() {
    final info = _definitionFileContent[_infoConst];
    if (info == null || info is! Map<String, dynamic>) {
      return const OpenApiInfo();
    }

    return OpenApiInfo(
      title: info[_titleConst]?.toString(),
      summary: info[_summaryConst]?.toString(),
      description: info[_descriptionConst]?.toString(),
      version: info[_versionConst]?.toString(),
    );
  }

  /// Parses rest clients from `paths` section of definition file
  /// and return list of [UniversalRestClient]
  Iterable<UniversalRestClient> parseRestClients() {
    final restClients = <UniversalRestClient>[];
    final imports = SplayTreeSet<String>();
    var isMultiPart = false;
    var isFormUrlEncoded = false;

    /// Parses return type for client query for OpenApi v3
    UniversalType? returnTypeV3(Map<String, dynamic> map) {
      final code2xxMap = _code2xxMap(map);
      if (code2xxMap == null || !code2xxMap.containsKey(_contentConst)) {
        return null;
      }
      final contentType = (code2xxMap[_contentConst] as Map<String, dynamic>)
          .entries
          .firstOrNull;
      if (contentType == null) {
        throw const ParserException(
          'Response must always have a content type.',
        );
      }
      final contentTypeValue = contentType.value as Map<String, dynamic>;
      if (contentTypeValue.isEmpty ||
          !contentTypeValue.containsKey(_schemaConst) ||
          (contentTypeValue[_schemaConst] as Map<String, dynamic>).isEmpty) {
        return null;
      }
      final typeWithImport = _findType(
        contentTypeValue[_schemaConst] as Map<String, dynamic>,
      );
      if (typeWithImport.import != null) {
        imports.add(typeWithImport.import!);
      }
      return UniversalType(
        type: typeWithImport.type.type,
        arrayDepth: typeWithImport.type.arrayDepth,
      );
    }

    /// Parses query parameters (parameters and requestBody)
    /// into universal models for OpenApi v3
    List<UniversalRequestType> parametersV3(Map<String, dynamic> map) {
      if (!map.containsKey(_parametersConst) &&
          !map.containsKey(_requestBodyConst)) {
        return [];
      }
      final types = <UniversalRequestType>[];
      if (map.containsKey(_parametersConst)) {
        for (final rawParameter in map[_parametersConst] as List<dynamic>) {
          final isRefParameter =
              (rawParameter as Map<String, dynamic>).containsKey(_refConst);
          var parameter = rawParameter;
          if (isRefParameter) {
            // find ref parameter
            final refParameterName = _formatRef(parameter);
            final isRefParameterExist =
                _definitionFileContent.containsKey(_componentsConst) &&
                    (_definitionFileContent[_componentsConst]
                            as Map<String, dynamic>)
                        .containsKey(_parametersConst) &&
                    ((_definitionFileContent[_componentsConst]
                                as Map<String, dynamic>)[_parametersConst]
                            as Map<String, dynamic>)
                        .containsKey(refParameterName);

            if (!isRefParameterExist) {
              throw ParserException(
                '${parameter[_refConst]} does not exist in schema',
              );
            }
            parameter = ((_definitionFileContent[_componentsConst]
                        as Map<String, dynamic>)[_parametersConst]
                    as Map<String, dynamic>)[refParameterName]!
                as Map<String, dynamic>;
          }
          final isRequired = parameter[_requiredConst]?.toString().toBool();
          final typeWithImport = _findType(
            parameter[_schemaConst] != null
                ? parameter[_schemaConst] as Map<String, dynamic>
                : parameter,
            name: parameter[_nameConst].toString(),
            isRequired: isRequired ?? true,
          );

          if (typeWithImport.import != null) {
            imports.add(typeWithImport.import!);
          }
          types.add(
            UniversalRequestType(
              parameterType: HttpParameterType.values.firstWhere(
                (e) => e.name == (parameter[_inConst].toString()),
              ),
              type: typeWithImport.type,
              name: parameter[_nameConst] == _bodyConst
                  ? null
                  : parameter[_nameConst].toString(),
            ),
          );
        }
      }
      if (map.containsKey(_requestBodyConst)) {
        final requestBody = map[_requestBodyConst] as Map<String, dynamic>;
        if (!requestBody.containsKey(_contentConst)) {
          throw const ParserException('Request body must always have content.');
        }
        final contentTypes = requestBody[_contentConst] as Map<String, dynamic>;
        Map<String, dynamic>? contentType;
        if (contentTypes.containsKey(_multipartFormDataConst)) {
          contentType =
              contentTypes[_multipartFormDataConst] as Map<String, dynamic>;
          isMultiPart = true;
        } else if (contentTypes.containsKey(_formUrlEncodedConst)) {
          contentType =
              contentTypes[_formUrlEncodedConst] as Map<String, dynamic>;
          isFormUrlEncoded = true;
        } else {
          final content = (requestBody[_contentConst] as Map<String, dynamic>)
              .entries
              .firstOrNull;
          contentType =
              content == null ? null : content.value as Map<String, dynamic>;
        }
        if (contentType == null) {
          throw const ParserException(
            'Response must always have a content type.',
          );
        }
        if (isMultiPart) {
          if ((contentType[_schemaConst] as Map<String, dynamic>)
              .containsKey(_refConst)) {
            final isRequired = requestBody[_requiredConst]?.toString().toBool();
            final typeWithImport = _findType(
              contentType[_schemaConst] as Map<String, dynamic>,
              isRequired: isRequired ?? true,
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
                  name: 'file',
                  description: currentType.description,
                  format: currentType.format,
                  defaultValue: currentType.defaultValue,
                  isRequired: currentType.isRequired,
                  nullable: currentType.nullable,
                  arrayDepth: currentType.arrayDepth,
                ),
              ),
            );
          }
          final schemaContentType =
              contentType[_schemaConst] as Map<String, dynamic>;
          if (schemaContentType.containsKey(_propertiesConst)) {
            for (final e
                in (schemaContentType[_propertiesConst] as Map<String, dynamic>)
                    .entries) {
              final typeWithImport = _findType(e.value as Map<String, dynamic>);
              final currentType = typeWithImport.type;
              if (typeWithImport.import != null) {
                imports.add(typeWithImport.import!);
              }
              types.add(
                UniversalRequestType(
                  parameterType: HttpParameterType.part,
                  name: e.key,
                  type: UniversalType(
                    type: currentType.type,
                    name: e.key,
                    description: currentType.description,
                    format: currentType.format,
                    defaultValue: currentType.defaultValue,
                    isRequired: currentType.isRequired,
                    nullable: currentType.nullable,
                    arrayDepth: currentType.arrayDepth,
                  ),
                ),
              );
            }
          }
        } else {
          final isRequired = requestBody[_requiredConst]?.toString().toBool();
          final typeWithImport = _findType(
            contentType[_schemaConst] as Map<String, dynamic>,
            isRequired: isRequired ?? true,
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
                name: _bodyConst,
                description: currentType.description,
                format: currentType.format,
                defaultValue: currentType.defaultValue,
                isRequired: currentType.isRequired,
                nullable: currentType.nullable,
                arrayDepth: currentType.arrayDepth,
              ),
            ),
          );
        }
      }
      return types;
    }

    /// Parses return type for client query for OpenApi v2
    UniversalType? returnTypeV2(Map<String, dynamic> map) {
      final code2xxMap = _code2xxMap(map);
      if (code2xxMap == null || !code2xxMap.containsKey(_schemaConst)) {
        return null;
      }
      final typeWithImport =
          _findType(code2xxMap[_schemaConst] as Map<String, dynamic>);
      if (typeWithImport.import != null) {
        imports.add(typeWithImport.import!);
      }
      return UniversalType(
        type: typeWithImport.type.type,
        arrayDepth: typeWithImport.type.arrayDepth,
      );
    }

    /// Parses query parameters (parameters and requestBody)
    /// into universal models for OpenApi v2
    List<UniversalRequestType> parametersV2(Map<String, dynamic> map) {
      final types = <UniversalRequestType>[];
      if (!map.containsKey(_parametersConst)) {
        return types;
      }
      if (map.containsKey(_consumesConst) &&
          (map[_consumesConst] as List<dynamic>)
              .contains(_multipartFormDataConst)) {
        isMultiPart = true;
      }
      if (map.containsKey(_consumesConst) &&
          (map[_consumesConst] as List<dynamic>)
              .contains(_formUrlEncodedConst)) {
        isFormUrlEncoded = true;
      }
      for (final rawParameter in map[_parametersConst] as List<dynamic>) {
        final isRequired =
            (rawParameter as Map<String, dynamic>)[_requiredConst]
                ?.toString()
                .toBool();

        final typeWithImport = _findType(
          rawParameter[_schemaConst] != null
              ? rawParameter[_schemaConst] as Map<String, dynamic>
              : rawParameter,
          name: rawParameter[_nameConst].toString(),
          isRequired: isRequired ?? true,
        );

        if (typeWithImport.import != null) {
          imports.add(typeWithImport.import!);
        }
        types.add(
          UniversalRequestType(
            parameterType: HttpParameterType.values.firstWhere(
              (e) => e.name == (rawParameter[_inConst].toString()),
            ),
            type: typeWithImport.type,
            name: rawParameter[_inConst] == _bodyConst
                ? null
                : rawParameter[_nameConst].toString(),
          ),
        );
      }
      return types;
    }

    if (!_definitionFileContent.containsKey(_pathsConst)) {
      return [];
    }
    (_definitionFileContent[_pathsConst] as Map<String, dynamic>)
        .forEach((path, pathValue) {
      (pathValue as Map<String, dynamic>).forEach((key, requestPath) {
        // `servers` contains List<dynamic>
        if (key == _serversConst) {
          return;
        }

        final requestPathResponses = (requestPath
            as Map<String, dynamic>)[_responsesConst] as Map<String, dynamic>;
        final returnType = _version == OAS.v2
            ? returnTypeV2(requestPathResponses)
            : returnTypeV3(requestPathResponses);
        final parameters = _version == OAS.v2
            ? parametersV2(requestPath)
            : parametersV3(requestPath);
        final requestName = _pathMethodName
            ? (key + path).toCamel
            : replaceNotEnglishLetter(
                  requestPath[_operationIdConst]?.toString(),
                )?.toCamel ??
                (key + path).toCamel;

        final summary = requestPath[_summaryConst]?.toString();
        final description = requestPath[_descriptionConst]?.toString();
        final fullDescription = switch ((summary, description)) {
          (null, null) => null,
          (_, null) => summary,
          (null, _) => description,
          (_, _) => '$summary\n\n$description',
        };

        final request = UniversalRequest(
          name: requestName,
          description: fullDescription,
          requestType: HttpRequestType.fromString(key)!,
          route: path,
          isMultiPart: isMultiPart,
          isFormUrlEncoded: isFormUrlEncoded,
          returnType: returnType,
          parameters: parameters,
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
        isFormUrlEncoded = false;
        imports.clear();
      });
    });
    return restClients;
  }

  /// Parses data classes from `components` of definition file
  /// to list of [UniversalDataClass]
  Iterable<UniversalDataClass> parseDataClasses() {
    final dataClasses = <UniversalDataClass>[];
    late final Map<String, dynamic> entities;
    if (_version == OAS.v3_1 || _version == OAS.v3) {
      if (!_definitionFileContent.containsKey(_componentsConst) ||
          !(_definitionFileContent[_componentsConst] as Map<String, dynamic>)
              .containsKey(_schemasConst)) {
        return dataClasses;
      }
      entities = (_definitionFileContent[_componentsConst]
          as Map<String, dynamic>)[_schemasConst] as Map<String, dynamic>;
    } else if (_version == OAS.v2) {
      if (!_definitionFileContent.containsKey(_definitionsConst)) {
        return dataClasses;
      }
      entities =
          _definitionFileContent[_definitionsConst] as Map<String, dynamic>;
    }
    entities.forEach((key, value) {
      var requiredParameters = <String>[];
      if ((value as Map<String, dynamic>).containsKey(_requiredConst)) {
        requiredParameters = (value[_requiredConst] as List<dynamic>)
            .map((e) => e.toString())
            .toList();
      }

      final refs = <String>[];
      final parameters = <UniversalType>[];
      final imports = SplayTreeSet<String>();

      /// Used for find properties in map
      void findParamsAndImports(Map<String, dynamic> map) {
        (map[_propertiesConst] as Map<String, dynamic>).forEach(
          (propertyName, propertyValue) {
            final typeWithImport = _findType(
              propertyValue as Map<String, dynamic>,
              name: propertyName,
              additionalName: key,
              isRequired: requiredParameters.contains(propertyName),
            );
            parameters.add(typeWithImport.type);
            if (typeWithImport.import != null) {
              imports.add(typeWithImport.import!);
            }
          },
        );
      }

      if (value.containsKey(_propertiesConst)) {
        findParamsAndImports(value);
      } else if (value.containsKey(_enumConst)) {
        final items =
            (value[_enumConst] as List).map((e) => e.toString()).toSet();
        final type = value[_typeConst].toString();
        for (final replacementRule in _replacementRules) {
          key = replacementRule.apply(key)!;
        }

        dataClasses.add(
          UniversalEnumClass(
            name: key,
            type: type,
            items: items,
            defaultValue: value[_defaultConst]?.toString(),
            description: value[_descriptionConst]?.toString(),
          ),
        );
        return;
      } else if (value.containsKey(_typeConst) ||
          value.containsKey(_refConst)) {
        final typeWithImport = _findType(
          value,
          name: key,
          isRequired: requiredParameters.contains(key),
        );
        parameters.add(typeWithImport.type);
        if (typeWithImport.import != null) {
          imports.add(typeWithImport.import!);
        }
        dataClasses.add(
          UniversalComponentClass(
            name: key,
            imports: imports,
            parameters: parameters,
            typeDef: true,
            description: value[_descriptionConst]?.toString(),
          ),
        );
        if (!value.containsKey(_allOfConst)) {
          return;
        }
      }

      if (value.containsKey(_allOfConst)) {
        for (final map in value[_allOfConst] as List) {
          if ((map as Map<String, dynamic>).containsKey(_refConst)) {
            var ref = _formatRef(map);
            for (final replacementRule in _replacementRules) {
              ref = replacementRule.apply(ref)!;
            }
            refs.add(ref);
            continue;
          }
          if (map.containsKey(_propertiesConst)) {
            findParamsAndImports(map);
          }
        }
      }

      final allOf =
          refs.isNotEmpty ? (refs: refs, properties: parameters) : null;

      for (final replacementRule in _replacementRules) {
        key = replacementRule.apply(key)!;
      }

      dataClasses.add(
        UniversalComponentClass(
          name: key,
          imports: imports,
          parameters: allOf != null ? [] : parameters,
          allOf: allOf,
          description: value[_descriptionConst]?.toString(),
        ),
      );
    });

    dataClasses.addAll(_objectClasses);
    _objectClasses.clear();

    dataClasses.addAll(_enumClasses);
    _enumClasses.clear();

    // check for `allOf`
    final allOfClasses = dataClasses
        .where((dc) => dc is UniversalComponentClass && dc.allOf != null);
    for (final allOfClass in allOfClasses) {
      if (allOfClass is! UniversalComponentClass) {
        continue;
      }
      final refs = allOfClass.allOf!.refs;
      final foundClasses = dataClasses.where((e) => refs.contains(e.name));
      for (final element in foundClasses) {
        if (element is UniversalComponentClass) {
          allOfClass.parameters.addAll(element.parameters);
          allOfClass.imports.addAll(element.imports);
        } else if (element is UniversalEnumClass) {
          allOfClass.parameters.add(
            UniversalType(type: element.name, name: element.name.toCamel),
          );
          allOfClass.imports.add(element.name);
        }
      }
      allOfClass.parameters.addAll(allOfClass.allOf!.properties);
    }
    return dataClasses;
  }

  /// Return map[2xx] if code 2xx contains in map
  Map<String, dynamic>? _code2xxMap(Map<String, dynamic> map) {
    const codes2xx = {
      '200',
      '201',
      '202',
      '203',
      '204',
      '205',
      '206',
      '207',
      '208',
      '226',
    };
    final key = map.keys.where(codes2xx.contains).firstOrNull;
    if (key == null) {
      return null;
    }
    return map[key] as Map<String, dynamic>;
  }

  /// Get tag for name
  String _getTag(Map<String, dynamic> map) => _squashClients && _name != null
      ? _name!
      : map.containsKey(_tagsConst)
          ? (map[_tagsConst] as List<dynamic>).first.toString()
          : 'client';

  /// Format `$ref` type
  String _formatRef(Map<String, dynamic> map, {bool useSchema = false}) => p
      .basename(
        useSchema
            ? (map[_schemaConst] as Map<String, dynamic>)[_refConst].toString()
            : map[_refConst].toString(),
      )
      .toPascal;

  /// Get a unique name for objects without a specific name
  String get _uniqueName {
    final name = '$_objectConst$_uniqueNameCounter'.toPascal;
    _uniqueNameCounter++;
    return name;
  }

  /// Find type of map
  ({UniversalType type, String? import}) _findType(
    Map<String, dynamic> map, {
    String? name,
    String? additionalName,
    bool isRequired = false,
    bool root = true,
  }) {
    if (map.containsKey(_typeConst) && map[_typeConst] == _arrayConst) {
      // `array`
      final arrayItems = map[_itemsConst] as Map<String, dynamic>;
      final arrayType = _findType(
        arrayItems,
        additionalName: name,
        root: false,
      );
      final arrayValueNullable = arrayItems[_nullableConst].toString().toBool();
      final type = '${arrayType.type.type}${arrayValueNullable ? '?' : ''}';
      return (
        type: UniversalType(
          type: type,
          name: (dartKeywords.contains(name) ? '$name $_valueConst' : name)
              ?.toCamel,
          description: map[_descriptionConst]?.toString(),
          format: arrayType.type.format,
          jsonKey: name,
          defaultValue: arrayType.type.defaultValue,
          isRequired: isRequired,
          nullable: map[_nullableConst].toString().toBool(),
          arrayDepth: arrayType.type.arrayDepth + 1,
        ),
        import: arrayType.import,
      );
    } else if (map.containsKey(_enumConst)) {
      // `enum`
      final variableName = name ?? _uniqueName;
      var newName = variableName;
      if (_enumsPrefix && additionalName != null) {
        newName = '$additionalName $newName'.toPascal;
      }
      for (final replacementRule in _replacementRules) {
        newName = replacementRule.apply(newName)!;
      }
      final items = (map[_enumConst] as List).map((e) => e.toString()).toSet();
      _enumClasses.add(
        UniversalEnumClass(
          name: newName,
          type: map[_typeConst].toString(),
          items: items,
          defaultValue: map[_defaultConst]?.toString(),
          description: map[_descriptionConst]?.toString(),
        ),
      );

      return (
        type: UniversalType(
          type: newName.toPascal,
          name: (dartKeywords.contains(variableName)
                  ? '$variableName $_enumConst'
                  : variableName)
              .toCamel,
          description: map[_descriptionConst]?.toString(),
          format: map.containsKey(_formatConst)
              ? map[_formatConst].toString()
              : null,
          jsonKey: name ?? _uniqueName,
          defaultValue: map[_defaultConst]?.toString(),
          isRequired: isRequired,
          enumType: map[_typeConst].toString(),
        ),
        import: newName,
      );
    } else if (map.containsKey(_typeConst) &&
            map[_typeConst] == _objectConst &&
            (map.containsKey(_propertiesConst) &&
                (map[_propertiesConst] as Map<String, dynamic>).isNotEmpty) ||
        (map.containsKey(_additionalPropertiesConst) &&
            (map[_additionalPropertiesConst] as Map<String, dynamic>)
                .isNotEmpty)) {
      // `object` or `additionalProperties`
      final newName = name ?? additionalName ?? _uniqueName;
      final typeWithImports = <({UniversalType type, String? import})>[];
      if (map.containsKey(_propertiesConst)) {
        (map[_propertiesConst] as Map<String, dynamic>).forEach((key, value) {
          typeWithImports.add(
            _findType(
              value as Map<String, dynamic>,
              name: key,
              root: false,
            ),
          );
        });
      }
      if (map.containsKey(_additionalPropertiesConst)) {
        typeWithImports.add(
          _findType(
            map[_additionalPropertiesConst] as Map<String, dynamic>,
            name: _additionalPropertiesConst,
            root: false,
          ),
        );
      }
      if (_objectClasses
          .where((oc) => oc.name == '$newName $_valueConst'.toPascal)
          .isEmpty) {
        _objectClasses.add(
          UniversalComponentClass(
            name: '$newName $_valueConst'.toPascal,
            imports: typeWithImports
                .where((e) => e.import != null)
                .map((e) => e.import!)
                .toSet(),
            parameters: typeWithImports.map((e) => e.type).toList(),
          ),
        );
      }
      return (
        type: UniversalType(
          type: '$newName $_valueConst'.toPascal,
          name: (dartKeywords.contains(newName)
                  ? '$newName $_valueConst'
                  : newName)
              .toCamel,
          description: map[_descriptionConst]?.toString(),
          format: map.containsKey(_formatConst)
              ? map[_formatConst].toString()
              : null,
          jsonKey: newName,
          defaultValue: map[_defaultConst]?.toString(),
          isRequired: isRequired,
        ),
        import: '$newName $_valueConst',
      );
    } else if (map.containsKey(_allOfConst) ||
        map.containsKey(_anyOfConst) ||
        map.containsKey(_oneOfConst)) {
      String? ofImport;
      UniversalType? ofType;

      final of = map[_allOfConst] ?? map[_anyOfConst] ?? map[_oneOfConst];
      if (of is List<dynamic>) {
        // Find type in of one-element allOf, anyOf or oneOf
        if (of.length == 1) {
          final item = of[0];
          if (item is Map<String, dynamic>) {
            (import: ofImport, type: ofType) = _findType(item);
          }
        }
        // Find nullable type in of two-element allOf, anyOf or oneOf
        else if (map.containsKey(_anyOfConst) && of.length == 2) {
          final item1 = of[0];
          final item2 = of[1];
          if (item1 is Map<String, dynamic> && item2 is Map<String, dynamic>) {
            final nullableItem = item1[_typeConst] == 'null'
                ? item2
                : item2[_typeConst] == 'null'
                    ? item1
                    : null;
            if (nullableItem != null) {
              final type = _findType(nullableItem);
              ofImport = type.import;
              ofType = type.type.copyWith(nullable: true);
            }
          }
        }
      }

      final type = ofType?.type ?? _objectConst;
      final import = ofImport;
      final defaultValue = map[_defaultConst]?.toString();

      return (
        type: UniversalType(
          type: type,
          name: (dartKeywords.contains(name) ? '$name $_valueConst' : name)
              ?.toCamel,
          description: map[_descriptionConst]?.toString(),
          format: ofType?.format,
          jsonKey: name,
          defaultValue: defaultValue,
          enumType: defaultValue != null &&
                  import != null &&
                  (ofType == null || ofType.arrayDepth == 0)
              ? type
              : null,
          isRequired: isRequired,
          arrayDepth: ofType?.arrayDepth ?? 0,
          nullable: root &&
                  map.containsKey(_nullableConst) &&
                  map[_nullableConst].toString().toBool() ||
              (ofType?.nullable ?? false),
        ),
        import: import,
      );
    } else {
      var type = map.containsKey(_typeConst)
          ? map.containsKey(_refConst) &&
                  map[_typeConst].toString() == _objectConst
              ? _formatRef(map)
              : map[_typeConst].toString()
          : map.containsKey(_refConst)
              ? _formatRef(map)
              : _objectConst;

      var import = map.containsKey(_refConst) ? _formatRef(map) : null;

      if (import != null) {
        for (final replacementRule in _replacementRules) {
          import = replacementRule.apply(import);
          type = replacementRule.apply(type)!;
        }
      }

      final defaultValue = map[_defaultConst]?.toString();

      return (
        type: UniversalType(
          type: type,
          name: (dartKeywords.contains(name) ? '$name $_valueConst' : name)
              ?.toCamel,
          description: map[_descriptionConst]?.toString(),
          format: map[_formatConst]?.toString(),
          jsonKey: name,
          defaultValue: defaultValue,
          enumType: defaultValue != null && import != null ? type : null,
          isRequired: isRequired,
          nullable: root &&
              map.containsKey(_nullableConst) &&
              map[_nullableConst].toString().toBool(),
        ),
        import: import,
      );
    }
  }
}

/// Extension used for YAML map
extension on YamlMap {
  /// Convert to Dart map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    for (final entry in entries) {
      if (entry.value is YamlMap || entry.value is Map) {
        map[entry.key.toString()] = (entry.value as YamlMap).toMap();
      } else if (entry.value is YamlList) {
        map[entry.key.toString()] = (entry.value as YamlList)
            .map<dynamic>((e) => e is YamlMap ? e.toMap() : e)
            .toList(growable: false);
      } else {
        map[entry.key.toString()] = entry.value.toString();
      }
    }
    return map;
  }
}

/// Extension used for YAML map
extension on String {
  /// used specially for YAML map
  bool toBool() => toLowerCase() == 'true';
}

/// All versions of the OpenApi Specification that this package supports
enum OAS { v3_1, v3, v2 }
