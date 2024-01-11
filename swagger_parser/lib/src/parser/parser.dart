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
import '../utils/type_utils.dart';
import 'parser_exception.dart';

export 'parser_exception.dart';

/// General class for parsing OpenApi files into universal models
class OpenApiParser {
  /// Accepts [fileContent] of the schema file
  /// and [isYaml] schema format or not
  OpenApiParser(
    String fileContent, {
    String? name,
    bool isYaml = false,
    bool enumsPrefix = false,
    bool pathMethodName = false,
    bool squashClients = false,
    bool originalHttpResponse = false,
    String defaultContentType = 'application/json',
    List<ReplacementRule> replacementRules = const <ReplacementRule>[],
    List<String> skipParameters = const <String>[],
  })  : _name = name,
        _pathMethodName = pathMethodName,
        _enumsPrefix = enumsPrefix,
        _squashClients = squashClients,
        _originalHttpResponse = originalHttpResponse,
        _defaultContentType = defaultContentType,
        _replacementRules = replacementRules,
        _skipParameters = skipParameters {
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
  final bool _originalHttpResponse;
  final String _defaultContentType;
  final List<ReplacementRule> _replacementRules;
  final List<String> _skipParameters;
  late final Map<String, dynamic> _definitionFileContent;
  late final OAS _version;
  final List<UniversalComponentClass> _objectClasses = [];
  final Set<UniversalEnumClass> _enumClasses = {};

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
  static const _deprecatedConst = 'deprecated';
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
  static const _versionConst = 'version';
  final usedNamesCount = <String, int>{};

  UniversalEnumClass getUniqueEnumClass({
    required final String name,
    required final Set<UniversalEnumItem> items,
    required final String type,
    required final String? defaultValue,
    required final String? description,
  }) {
    // Search _enumClasses for an enum with the same name and values
    final enumClass = _enumClasses.firstWhereOrNull(
      (e) =>
          e.originalName == name &&
          const DeepCollectionEquality().equals(e.items, items),
    );

    if (enumClass != null) {
      return enumClass;
    }

    String uniqueName;
    if (usedNamesCount.containsKey(name)) {
      usedNamesCount[name] = usedNamesCount[name]! + 1;
      uniqueName = '$name${usedNamesCount[name]}';
    } else {
      usedNamesCount[name] = 1;
      uniqueName = name;
    }

    return UniversalEnumClass(
      originalName: name,
      name: uniqueName.toPascal,
      type: type,
      items: items,
      defaultValue: defaultValue,
      description: description,
    );
  }

  /// Parse OpenApi parameters into [OpenApiInfo]
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
    var resultContentType = _defaultContentType;

    /// Parses return type for client query for OpenApi v3
    UniversalType? returnTypeV3(
      Map<String, dynamic> map,
      String additionalName,
    ) {
      final code2xxMap = _code2xxMap(map);
      if (code2xxMap == null || !code2xxMap.containsKey(_contentConst)) {
        return null;
      }
      final contentType = (code2xxMap[_contentConst] as Map<String, dynamic>)
          .entries
          .firstOrNull;
      if (contentType == null) {
        return null;
      }
      final contentTypeValue = contentType.value as Map<String, dynamic>;
      if (contentTypeValue.isEmpty ||
          !contentTypeValue.containsKey(_schemaConst) ||
          (contentTypeValue[_schemaConst] as Map<String, dynamic>).isEmpty) {
        return null;
      }
      final typeWithImport = _findType(
        contentTypeValue[_schemaConst] as Map<String, dynamic>,
        additionalName: additionalName,
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
          if (_skipParameters.contains(parameter[_nameConst])) {
            continue;
          }
          final isRequired = parameter[_requiredConst]?.toString().toBool();
          final typeWithImport = _findType(
            parameter[_schemaConst] != null
                ? parameter[_schemaConst] as Map<String, dynamic>
                : parameter,
            name: parameter[_nameConst].toString(),
            isRequired: isRequired ?? false,
          );

          if (typeWithImport.import != null) {
            imports.add(typeWithImport.import!);
          }
          final parameterType = HttpParameterType.values.firstWhere(
            (e) => e.name == (parameter[_inConst].toString()),
          );
          types.add(
            UniversalRequestType(
              parameterType: parameterType,
              type: typeWithImport.type,
              description: parameter[_descriptionConst]?.toString(),
              name: parameterType.isBody && parameter[_nameConst] == _bodyConst
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
          resultContentType = _multipartFormDataConst;
        } else if (contentTypes.containsKey(_formUrlEncodedConst)) {
          contentType =
              contentTypes[_formUrlEncodedConst] as Map<String, dynamic>;
          resultContentType = _formUrlEncodedConst;
        } else {
          final content = contentTypes.containsKey(_defaultContentType)
              ? contentTypes[_defaultContentType]
              : contentTypes.entries.firstOrNull?.value;
          contentType =
              content == null ? null : content as Map<String, dynamic>;
        }

        if (contentType == null) {
          throw const ParserException(
            'Response must always have a content type.',
          );
        }

        if (resultContentType == _multipartFormDataConst) {
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
                description: requestBody[_descriptionConst]?.toString(),
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
          final schemaContent =
              contentType[_schemaConst] as Map<String, dynamic>;
          if (schemaContent.containsKey(_propertiesConst)) {
            for (final e
                in (schemaContent[_propertiesConst] as Map<String, dynamic>)
                    .entries) {
              final typeWithImport = _findType(
                e.value as Map<String, dynamic>,
              );
              final currentType = typeWithImport.type;
              if (typeWithImport.import != null) {
                imports.add(typeWithImport.import!);
              }
              types.add(
                UniversalRequestType(
                  parameterType: HttpParameterType.part,
                  name: e.key,
                  description: requestBody[_descriptionConst]?.toString(),
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
              description: requestBody[_descriptionConst]?.toString(),
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
    UniversalType? returnTypeV2(
      Map<String, dynamic> map,
      String additionalName,
    ) {
      final code2xxMap = _code2xxMap(map);
      if (code2xxMap == null || !code2xxMap.containsKey(_schemaConst)) {
        return null;
      }
      final typeWithImport = _findType(
        code2xxMap[_schemaConst] as Map<String, dynamic>,
        additionalName: additionalName,
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
    /// into universal models for OpenApi v2
    List<UniversalRequestType> parametersV2(Map<String, dynamic> map) {
      final types = <UniversalRequestType>[];
      if (!map.containsKey(_parametersConst)) {
        return types;
      }

      if (map.containsKey(_consumesConst) &&
          map[_consumesConst] is List<dynamic>) {
        final consumes = map[_consumesConst] as List<dynamic>;
        if (consumes.contains(_multipartFormDataConst)) {
          resultContentType = _multipartFormDataConst;
        } else if (consumes.contains(_formUrlEncodedConst)) {
          resultContentType = _formUrlEncodedConst;
        } else if (consumes.isNotEmpty && consumes.first != null) {
          resultContentType = consumes.first as String;
        }
      }
      for (final parameter in map[_parametersConst] as List<dynamic>) {
        final isRequired = (parameter as Map<String, dynamic>)[_requiredConst]
            ?.toString()
            .toBool();

        final typeWithImport = _findType(
          parameter[_schemaConst] != null
              ? parameter[_schemaConst] as Map<String, dynamic>
              : parameter,
          name: parameter[_nameConst].toString(),
          isRequired: isRequired ?? false,
        );

        if (_skipParameters.contains(parameter[_nameConst])) {
          continue;
        }

        if (typeWithImport.import != null) {
          imports.add(typeWithImport.import!);
        }
        final parameterType = HttpParameterType.values.firstWhere(
          (e) => e.name == (parameter[_inConst].toString()),
        );
        types.add(
          UniversalRequestType(
            parameterType: parameterType,
            type: typeWithImport.type,
            description: parameter[_descriptionConst]?.toString(),
            name: parameterType.isBody && parameter[_nameConst] == _bodyConst
                ? null
                : parameter[_nameConst].toString(),
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
      final pathValueMap = pathValue as Map<String, dynamic>;

      // global parameters are defined at the path level (i.e. /users/{id})
      final globalParameters = <UniversalRequestType>[];

      if (pathValueMap.containsKey(_parametersConst)) {
        final params = _version == OAS.v2
            ? parametersV2(pathValue)
            : parametersV3(pathValue);
        globalParameters.addAll(params);
      }

      pathValue.forEach((key, requestPath) {
        // `servers` contains List<dynamic>
        if (key == _serversConst || key == _parametersConst) {
          return;
        }

        final requestPathResponses = (requestPath
            as Map<String, dynamic>)[_responsesConst] as Map<String, dynamic>;
        final additionalName = '$key${path}Response'.toPascal;
        final returnType = _version == OAS.v2
            ? returnTypeV2(requestPathResponses, additionalName)
            : returnTypeV3(requestPathResponses, additionalName);
        final parameters = _version == OAS.v2
            ? parametersV2(requestPath)
            : parametersV3(requestPath);

        // Add global parameters that have not been overridden by local parameters
        // defined at the request level.
        parameters.addAll(
          globalParameters.where(
            (e) =>
                parameters.every((p) => p.name != e.name && p.type != e.type),
          ),
        );

        // Build full description
        final summary = requestPath[_summaryConst]?.toString().trim();
        var description = requestPath[_descriptionConst]?.toString().trim();
        description = switch ((summary, description)) {
          (null, null) || ('', '') => null,
          (_, null) || (_, '') => summary,
          (null, _) || ('', _) => description,
          (_, _) => '$summary\n\n$description',
        };
        final parametersDescription = parameters
            .where((e) => e.description != null)
            .map((e) => '[${e.name?.toCamel ?? 'body'}] - ${e.description}')
            .join('\n')
            .trim();
        description = switch ((description, parametersDescription)) {
          (null, '') || ('', '') => null,
          (_, '') => description,
          (null, _) || ('', _) => parametersDescription,
          (_, _) => '$description\n\n$parametersDescription',
        };

        String requestName;

        if (_pathMethodName) {
          requestName = (key + path).toCamel;
        } else {
          final operationIdName =
              requestPath[_operationIdConst]?.toString().toCamel;
          final (_, nameDescription) = protectName(operationIdName);
          if (nameDescription != null) {
            description = '$description\n\n$nameDescription';
            requestName = (key + path).toCamel;
          } else {
            requestName = operationIdName ?? (key + path).toCamel;
          }
        }

        final request = UniversalRequest(
          name: requestName,
          description: description,
          requestType: HttpRequestType.fromString(key)!,
          route: path,
          contentType: resultContentType,
          isOriginalHttpResponse: _originalHttpResponse,
          returnType: returnType,
          parameters: parameters,
          isDeprecated: requestPath[_deprecatedConst].toString().toBool(),
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
        resultContentType = _defaultContentType;
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
      void findParametersAndImports(Map<String, dynamic> map) {
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
        findParametersAndImports(value);
      } else if (value.containsKey(_enumConst)) {
        final items = protectEnumItemsNames(
          (value[_enumConst] as List).map((e) => '$e'),
        );
        final type = value[_typeConst].toString();
        for (final replacementRule in _replacementRules) {
          key = replacementRule.apply(key)!;
        }

        dataClasses.add(
          getUniqueEnumClass(
            name: key,
            items: items,
            type: type,
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
        for (final map in value[_allOfConst] as List<dynamic>) {
          if ((map as Map<String, dynamic>).containsKey(_refConst)) {
            var ref = _formatRef(map);
            for (final replacementRule in _replacementRules) {
              ref = replacementRule.apply(ref)!;
            }
            refs.add(ref);
            continue;
          }
          if (map.containsKey(_propertiesConst)) {
            findParametersAndImports(map);
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
          ? (map[_tagsConst] as List<dynamic>)
              .first
              .toString()
              .replaceAll(RegExp(r'[^\w\s]+'), '') // Remove special characters
          : 'client';

  /// Format `$ref` type
  String _formatRef(Map<String, dynamic> map, {bool useSchema = false}) =>
      p.basename(
        useSchema
            ? (map[_schemaConst] as Map<String, dynamic>)[_refConst].toString()
            : map[_refConst].toString(),
      );

  /// Find type of map
  ({UniversalType type, String? import}) _findType(
    Map<String, dynamic> map, {
    String? name,
    String? additionalName,
    bool isRequired = false,
    bool root = true,
  }) {
    // Array
    if (map.containsKey(_typeConst) && map[_typeConst] == _arrayConst) {
      final arrayItems = map[_itemsConst] as Map<String, dynamic>;
      final arrayType = _findType(
        arrayItems,
        name: name,
        additionalName: name,
        root: false,
      );
      final arrayValueNullable = arrayItems[_nullableConst].toString().toBool();
      final type = '${arrayType.type.type}${arrayValueNullable ? '?' : ''}';

      final (newName, description) =
          protectName(name, description: map[_descriptionConst]?.toString());

      return (
        type: UniversalType(
          type: type,
          name: newName?.toCamel,
          description: description,
          format: arrayType.type.format,
          jsonKey: name,
          defaultValue:
              protectDefaultValue(arrayType.type.defaultValue, isArray: true),
          isRequired: isRequired,
          nullable: map[_nullableConst].toString().toBool(),
          arrayDepth: arrayType.type.arrayDepth + 1,
        ),
        import: arrayType.import,
      );
    }
    // Enum
    else if (map.containsKey(_enumConst)) {
      // ignore: unnecessary_null_checks
      final (variableName!, description) = protectName(
        name,
        isEnum: true,
        uniqueIfNull: true,
        description: map[_descriptionConst]?.toString(),
      );

      var newName = variableName;
      if (_enumsPrefix && additionalName != null) {
        newName = '$additionalName $newName'.toPascal;
      }

      for (final replacementRule in _replacementRules) {
        newName = replacementRule.apply(newName)!;
      }

      final items = protectEnumItemsNames(
        (map[_enumConst] as List).map((e) => '$e'),
      );

      final enumClass = getUniqueEnumClass(
        name: newName,
        items: items,
        type: map[_typeConst].toString(),
        defaultValue: protectDefaultValue(map[_defaultConst], isEnum: true),
        description: description,
      );

      _enumClasses.add(enumClass);

      return (
        type: UniversalType(
          type: enumClass.name,
          name: variableName.toCamel,
          description: description,
          format: map[_formatConst]?.toString(),
          jsonKey: name,
          defaultValue: protectDefaultValue(map[_defaultConst]),
          isRequired: isRequired,
          enumType: map[_typeConst]?.toString(),
        ),
        import: enumClass.name,
      );
    }
    //  Object or additionalProperties
    else if (map.containsKey(_typeConst) &&
            map[_typeConst] == _objectConst &&
            (map.containsKey(_propertiesConst) &&
                (map[_propertiesConst] is Map<String, dynamic>) &&
                (map[_propertiesConst] as Map<String, dynamic>).isNotEmpty) ||
        (map.containsKey(_additionalPropertiesConst) &&
            (map[_additionalPropertiesConst] is Map<String, dynamic>) &&
            (map[_additionalPropertiesConst] as Map<String, dynamic>)
                .isNotEmpty &&
            !(map[_additionalPropertiesConst] as Map<String, dynamic>)
                .containsKey(_refConst))) {
      // false positive result
      // ignore: unnecessary_null_checks
      final (newName!, description) = protectName(
        name ?? additionalName,
        uniqueIfNull: true,
        description: map[_descriptionConst]?.toString(),
      );

      var requiredParameters = <String>[];
      if (map.containsKey(_requiredConst)) {
        requiredParameters =
            (map[_requiredConst] as List).map((e) => '$e').toList();
      }

      final typeWithImports = <({UniversalType type, String? import})>[];

      // To detect is this entity is map or not
      final mapType = map[_typeConst].toString() == _objectConst &&
              map.containsKey(_additionalPropertiesConst) &&
              (map[_additionalPropertiesConst] is Map<String, dynamic>) &&
              !(map[_additionalPropertiesConst] as Map<String, dynamic>)
                  .containsKey(r'$ref')
          ? 'string'
          : null;
      if (map.containsKey(_propertiesConst)) {
        (map[_propertiesConst] as Map<String, dynamic>).forEach((key, value) {
          typeWithImports.add(
            _findType(
              value as Map<String, dynamic>,
              name: key,
              root: false,
              isRequired: requiredParameters.contains(key),
            ),
          );
        });
      }
      if (map.containsKey(_additionalPropertiesConst) &&
          map[_additionalPropertiesConst] is Map<String, dynamic>) {
        typeWithImports.add(
          _findType(
            map[_additionalPropertiesConst] as Map<String, dynamic>,
            name: _additionalPropertiesConst,
            root: false,
          ),
        );
      }

      // Interception of objectClass creation when Map construction is expected
      if (typeWithImports.length == 1 && typeWithImports[0].import == null) {
        return (
          type: UniversalType(
            type: map[_typeConst] as String,
            name: newName.toCamel,
            description: description,
            format: map.containsKey(_formatConst)
                ? map[_formatConst].toString()
                : null,
            jsonKey: newName,
            mapType: mapType,
            defaultValue: protectDefaultValue(map[_defaultConst]),
            nullable: map[_nullableConst].toString().toBool(),
            isRequired: isRequired,
          ),
          import: null,
        );
      }

      if (_objectClasses.where((oc) => oc.name == newName.toPascal).isEmpty) {
        _objectClasses.add(
          UniversalComponentClass(
            name: newName.toPascal,
            imports:
                typeWithImports.map((e) => e.import).whereNotNull().toSet(),
            parameters: typeWithImports.map((e) => e.type).toList(),
          ),
        );
      }

      return (
        type: UniversalType(
          type: newName.toPascal,
          name: newName.toCamel,
          description: description,
          format: map.containsKey(_formatConst)
              ? map[_formatConst].toString()
              : null,
          jsonKey: newName,
          mapType: mapType,
          defaultValue: protectDefaultValue(map[_defaultConst]),
          nullable: map[_nullableConst].toString().toBool(),
          isRequired: isRequired,
        ),
        import: newName.toPascal,
      );
    }
    // Type in allOf, anyOf or oneOf
    else if (map.containsKey(_allOfConst) ||
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
        // Find nullable type in of two-element anyOf
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

      final enumType = defaultValue != null &&
              import != null &&
              (ofType == null || ofType.arrayDepth == 0)
          ? type
          : null;
      final (newName, description) =
          protectName(name, description: map[_descriptionConst]?.toString());

      return (
        type: UniversalType(
          type: type,
          name: newName?.toCamel,
          description: description,
          format: ofType?.format,
          jsonKey: name,
          defaultValue: protectDefaultValue(
            defaultValue,
            isEnum: enumType != null,
            isArray: (ofType?.arrayDepth ?? 0) > 0,
          ),
          enumType: enumType,
          isRequired: isRequired,
          arrayDepth: ofType?.arrayDepth ?? 0,
          nullable: root &&
                  map.containsKey(_nullableConst) &&
                  map[_nullableConst].toString().toBool() ||
              (ofType?.nullable ?? false),
        ),
        import: import,
      );
    }
    // Type or ref
    else {
      String? import;
      String type;
      if (map.containsKey(_refConst)) {
        import = _formatRef(map).toPascal;
      } else if (map.containsKey(_additionalPropertiesConst) &&
          map[_additionalPropertiesConst] is Map<String, dynamic> &&
          (map[_additionalPropertiesConst] as Map<String, dynamic>)
              .containsKey(_refConst)) {
        import =
            _formatRef(map[_additionalPropertiesConst] as Map<String, dynamic>)
                .toPascal;
      }

      if (map.containsKey(_typeConst)) {
        type = import != null && map[_typeConst].toString() == _objectConst
            ? import
            : map[_typeConst].toString();
      } else {
        type = import ?? _objectConst;
      }
      if (import != null) {
        for (final replacementRule in _replacementRules) {
          import = replacementRule.apply(import);
          type = replacementRule.apply(type)!;
        }
      }

      // To detect is this entity is map or not
      final mapType = map[_typeConst].toString() == _objectConst &&
              map.containsKey(_additionalPropertiesConst) &&
              (map[_additionalPropertiesConst] is Map<String, dynamic>)
          ? 'string'
          : null;
      final defaultValue = map[_defaultConst]?.toString();
      final (newName, description) =
          protectName(name, description: map[_descriptionConst]?.toString());

      final enumType = defaultValue != null && import != null ? type : null;

      return (
        type: UniversalType(
          type: type,
          name: newName?.toCamel,
          description: description,
          format: map[_formatConst]?.toString(),
          jsonKey: name,
          mapType: mapType,
          defaultValue:
              protectDefaultValue(defaultValue, isEnum: enumType != null),
          enumType: enumType,
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
enum OAS {
  /// 3.1.x
  v3_1,

  /// 3.0.x
  v3,

  /// 2.0
  v2;

  /// Constructor for OpenApi Specification
  const OAS();
}
