import 'dart:collection';
import 'dart:convert' show jsonDecode;

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../config/parser_config.dart';
import '../exception/open_api_parser_exception.dart';
import '../model/open_api_info.dart';
import '../model/universal_collections.dart';
import '../model/universal_data_class.dart';
import '../model/universal_request.dart';
import '../model/universal_request_type.dart';
import '../model/universal_rest_client.dart';
import '../model/universal_type.dart';
import '../utils/case_utils.dart';
import '../utils/http_utils.dart';
import '../utils/type_utils.dart';

/// General class for parsing OpenApi specification into universal models
class OpenApiParser {
  /// Creates a [OpenApiParser].
  OpenApiParser(this.config) {
    _definitionFileContent = config.isJson
        ? jsonDecode(config.fileContent) as Map<String, Object?>
        : (loadYaml(config.fileContent) as YamlMap).toMap();
    _apiInfo = _parseOpenApiInfo();
  }

  /// [ParserConfig] that [OpenApiParser] use
  final ParserConfig config;

  /// `info` section in specification
  late final OpenApiInfo _apiInfo;

  /// Specification content
  late final Map<String, dynamic> _definitionFileContent;

  final _objectClasses = <UniversalComponentClass>[];
  final _enumClasses = <UniversalEnumClass>{};
  final _usedNamesCount = <String, int>{};
  final _skipDataClasses = <String>[];

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
  static const _requestBodiesConst = 'requestBodies';
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

  UniversalEnumClass _getUniqueEnumClass({
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
    if (_usedNamesCount.containsKey(name)) {
      _usedNamesCount[name] = _usedNamesCount[name]! + 1;
      uniqueName = '$name${_usedNamesCount[name]}';
    } else {
      _usedNamesCount[name] = 1;
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
  OpenApiInfo _parseOpenApiInfo() {
    final schemaVersion = switch (_definitionFileContent) {
      {_openApiConst: final Object? v} when v.toString().startsWith('3.1') =>
        OAS.v3_1,
      {_openApiConst: final Object? v} when v.toString().startsWith('3.0') =>
        OAS.v3,
      {_swaggerConst: final Object? v} when v.toString().startsWith('2.0') =>
        OAS.v2,
      _ => throw const OpenApiParserException('Unknown version of OpenAPI.'),
    };
    final info = switch (_definitionFileContent) {
      {_infoConst: final Map<String, Object?> v} => v,
      _ => null,
    };
    return OpenApiInfo(
      schemaVersion: schemaVersion,
      apiVersion: info?[_versionConst]?.toString(),
      title: info?[_titleConst]?.toString(),
      summary: info?[_summaryConst]?.toString(),
      description: info?[_descriptionConst]?.toString(),
    );
  }

  /// Get saved [OpenApiInfo] from [OpenApiParser]
  OpenApiInfo get openApiInfo => _apiInfo;

  /// Parses rest clients from `paths` section of definition file
  /// and return list of [UniversalRestClient]
  List<UniversalRestClient> parseRestClients() {
    final restClients = <UniversalRestClient>[];
    final imports = SplayTreeSet<String>();
    var resultContentType = config.defaultContentType;

    /// Parses return type for client query for OpenApi v3
    UniversalType? returnTypeV3(
      Map<String, dynamic> map,
      String additionalName,
    ) {
      final code2xx = code2xxMap(map);
      if (code2xx == null || !code2xx.containsKey(_contentConst)) {
        return null;
      }
      final contentType = (code2xx[_contentConst] as Map<String, dynamic>?)
          ?.entries
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
        isRequired: config.requiredByDefault,
      );
      if (typeWithImport.import != null) {
        imports.add(typeWithImport.import!);
      }
      return UniversalType(
        type: typeWithImport.type.type,
        wrappingCollections: typeWithImport.type.wrappingCollections,
        isRequired: config.requiredByDefault,
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
              throw OpenApiParserException(
                '${parameter[_refConst]} does not exist in schema',
              );
            }
            parameter = ((_definitionFileContent[_componentsConst]
                        as Map<String, dynamic>)[_parametersConst]
                    as Map<String, dynamic>)[refParameterName]!
                as Map<String, dynamic>;
          }
          if (config.skippedParameters.contains(parameter[_nameConst])) {
            continue;
          }
          final isRequired = parameter[_requiredConst]?.toString().toBool() ??
              config.requiredByDefault;
          final typeWithImport = _findType(
            parameter[_schemaConst] != null
                ? parameter[_schemaConst] as Map<String, dynamic>
                : parameter,
            name: parameter[_nameConst].toString(),
            isRequired: isRequired,
          );

          if (typeWithImport.import != null) {
            imports.add(typeWithImport.import!);
          }
          final parameterType = HttpParameterType.values.firstWhereOrNull(
            (e) => e.name == (parameter[_inConst].toString()),
          );
          if (parameterType == null) {
            // ignore: avoid_print
            print(
              'Warning:\nparameterType ${parameter[_inConst]} not supported',
            );
          } else {
            types.add(
              UniversalRequestType(
                parameterType: parameterType,
                type: typeWithImport.type,
                description: parameter[_descriptionConst]?.toString(),
                name:
                    parameterType.isBody && parameter[_nameConst] == _bodyConst
                        ? null
                        : parameter[_nameConst].toString(),
              ),
            );
          }
        }
      }
      if (map.containsKey(_requestBodyConst)) {
        var requestBody = map[_requestBodyConst] as Map<String, dynamic>;

        final isRefBody = requestBody.containsKey(_refConst);

        if (isRefBody) {
          final refBodyName = _formatRef(requestBody);

          final isRefBodyExist = _definitionFileContent
                  .containsKey(_componentsConst) &&
              (_definitionFileContent[_componentsConst] as Map<String, dynamic>)
                  .containsKey(_requestBodiesConst) &&
              ((_definitionFileContent[_componentsConst]
                          as Map<String, dynamic>)[_requestBodiesConst]
                      as Map<String, dynamic>)
                  .containsKey(refBodyName);

          if (!isRefBodyExist) {
            throw OpenApiParserException(
              '${requestBody[_refConst]} does not exist in schema',
            );
          }
          requestBody = ((_definitionFileContent[_componentsConst]
                  as Map<String, dynamic>)[_requestBodiesConst]
              as Map<String, dynamic>)[refBodyName] as Map<String, dynamic>;
        }

        if (!requestBody.containsKey(_contentConst)) {
          throw const OpenApiParserException(
            'Request body must always have content.',
          );
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
          final content = contentTypes.containsKey(config.defaultContentType)
              ? contentTypes[config.defaultContentType]
              : contentTypes.entries.firstOrNull?.value;
          contentType =
              content == null ? null : content as Map<String, dynamic>;
        }

        if (contentType == null) {
          throw const OpenApiParserException(
            'Response must always have a content type.',
          );
        }

        if (resultContentType == _multipartFormDataConst) {
          final schemaContent =
              contentType[_schemaConst] as Map<String, dynamic>;

          final Map<String, dynamic> properties;
          final List<String> requiredParameters;

          if ((contentType[_schemaConst] as Map<String, dynamic>)
              .containsKey(_refConst)) {
            final isRequired =
                requestBody[_requiredConst]?.toString().toBool() ??
                    config.requiredByDefault;
            final typeWithImportAndComponentTypeName = _findType(
              contentType[_schemaConst] as Map<String, dynamic>,
              isRequired: isRequired,
            );

            final type = typeWithImportAndComponentTypeName.type.type;
            final componentTypeName =
                typeWithImportAndComponentTypeName.componentTypeName;

            _skipDataClasses.add(type);

            final components = _definitionFileContent[_componentsConst]
                as Map<String, dynamic>;
            final schemes = components[_schemasConst] as Map<String, dynamic>;
            final dataClass =
                schemes[componentTypeName] as Map<String, dynamic>;
            final props = dataClass[_propertiesConst] as Map<String, dynamic>;
            final required = dataClass[_requiredConst] as List<dynamic>?;

            properties = props;
            requiredParameters =
                required?.map((e) => e.toString()).toList() ?? [];
          } else {
            properties =
                schemaContent[_propertiesConst] as Map<String, dynamic>;
            requiredParameters =
                (schemaContent[_requiredConst] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [];
          }

          for (final e in properties.entries) {
            final typeWithImport = _findType(
              e.value as Map<String, dynamic>,
              isRequired: requiredParameters.contains(e.key) ||
                  config.requiredByDefault,
            );
            final currentType = typeWithImport.type;
            if (typeWithImport.import != null) {
              imports.add(typeWithImport.import!);
            }

            final (protectedName, renameDescription) = protectName(e.key);
            final decscription = (currentType.description == null &&
                    renameDescription == null)
                ? null
                : (currentType.description ?? '') + (renameDescription ?? '');

            types.add(
              UniversalRequestType(
                parameterType: HttpParameterType.part,
                name: protectedName,
                description: currentType.description,
                type: UniversalType(
                  type: currentType.type,
                  name: protectedName,
                  description: decscription,
                  format: currentType.format,
                  defaultValue: currentType.defaultValue,
                  isRequired: currentType.isRequired,
                  nullable: currentType.nullable,
                  wrappingCollections: currentType.wrappingCollections,
                ),
              ),
            );
          }
        } else {
          final isRequired = requestBody[_requiredConst]?.toString().toBool() ??
              config.requiredByDefault;
          final typeWithImport = _findType(
            contentType[_schemaConst] as Map<String, dynamic>,
            isRequired: isRequired,
          );
          final currentType = typeWithImport.type;
          if (typeWithImport.import != null) {
            imports.add(typeWithImport.import!);
          }

          types.add(
            UniversalRequestType(
              parameterType: HttpParameterType.body,
              description: currentType.description,
              type: UniversalType(
                type: currentType.type,
                name: _bodyConst,
                description: currentType.description,
                format: currentType.format,
                defaultValue: currentType.defaultValue,
                isRequired: currentType.isRequired,
                nullable: currentType.nullable,
                wrappingCollections: currentType.wrappingCollections,
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
      final code2xx = code2xxMap(map);
      if (code2xx == null || !code2xx.containsKey(_schemaConst)) {
        return null;
      }
      final typeWithImport = _findType(
        code2xx[_schemaConst] as Map<String, dynamic>? ?? {},
        additionalName: additionalName,
        isRequired: config.requiredByDefault,
      );

      if (typeWithImport.import != null) {
        imports.add(typeWithImport.import!);
      }
      return UniversalType(
        type: typeWithImport.type.type,
        wrappingCollections: typeWithImport.type.wrappingCollections,
        isRequired: config.requiredByDefault,
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
      for (final rawParameter in map[_parametersConst] as List<dynamic>) {
        final isRequired =
            (rawParameter as Map<String, dynamic>)[_requiredConst]
                    ?.toString()
                    .toBool() ??
                config.requiredByDefault;

        final isRefParameter = rawParameter.containsKey(_refConst);
        var parameter = Map<String, dynamic>.of(rawParameter);
        if (isRefParameter) {
          // find ref parameter
          final refParameterName = _formatRef(rawParameter);
          final isRefParameterExist = _definitionFileContent
                  .containsKey(_parametersConst) &&
              (_definitionFileContent[_parametersConst] as Map<String, dynamic>)
                  .containsKey(refParameterName);

          if (!isRefParameterExist) {
            throw OpenApiParserException(
              '${rawParameter[_refConst]} does not exist in schema',
            );
          }
          parameter = (_definitionFileContent[_parametersConst]
                  as Map<String, dynamic>)[refParameterName]!
              as Map<String, dynamic>;
        }

        final typeWithImport = _findType(
          rawParameter[_schemaConst] != null
              ? rawParameter[_schemaConst] as Map<String, dynamic>
              : rawParameter,
          name: rawParameter[_nameConst].toString(),
          isRequired: isRequired,
        );

        if (config.skippedParameters.contains(rawParameter[_nameConst])) {
          continue;
        }

        if (typeWithImport.import != null) {
          imports.add(typeWithImport.import!);
        }
        final parameterType = HttpParameterType.values.firstWhereOrNull(
          (e) => e.name == (parameter[_inConst].toString()),
        );
        if (parameterType == null) {
          // ignore: avoid_print
          print(
            'Warning:\nparameterType ${parameter[_inConst]} not supported',
          );
        } else {
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
        final params = _apiInfo.schemaVersion == OAS.v2
            ? parametersV2(pathValue)
            : parametersV3(pathValue);
        globalParameters.addAll(params);
      }

      pathValue.forEach((key, requestPath) {
        // `servers` contains List<dynamic>
        if (key == _serversConst ||
            key == _parametersConst ||
            key.startsWith('x-')) {
          return;
        }

        final requestPathResponses = (requestPath
            as Map<String, dynamic>)[_responsesConst] as Map<String, dynamic>;
        final additionalName = '$key${path}Response'.toPascal;
        final returnType = _apiInfo.schemaVersion == OAS.v2
            ? returnTypeV2(requestPathResponses, additionalName)
            : returnTypeV3(requestPathResponses, additionalName);
        final parameters = _apiInfo.schemaVersion == OAS.v2
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
            .join('\n\n')
            .trim();
        description = switch ((description, parametersDescription)) {
          (null, '') || ('', '') => null,
          (_, '') => description,
          (null, _) || ('', _) => parametersDescription,
          (_, _) => '$description\n\n$parametersDescription',
        };
        // End build full description

        String requestName;

        if (config.pathMethodName) {
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

        // Handle duplicate named parameters
        final protectedParameters = <UniversalRequestType>[];
        final groupedParameters = groupBy(parameters, (e) => e.type.name);
        for (final entry in groupedParameters.values) {
          if (entry.length == 1) {
            protectedParameters.add(entry.first);
          } else {
            var counter = 0;
            for (final parameter in entry) {
              final protectedParameter = UniversalRequestType(
                name: parameter.name,
                type:
                    // ignore: prefer_single_quotes
                    parameter.type.copyWith(name: "${parameter.name}$counter"),
                parameterType: parameter.parameterType,
                description: parameter.description,
              );
              protectedParameters.add(protectedParameter);
              counter++;
            }
          }
        }

        final request = UniversalRequest(
          name: requestName,
          description: description,
          requestType: HttpRequestType.fromString(key)!,
          route: path,
          contentType: resultContentType,
          returnType: returnType,
          parameters: protectedParameters,
          isDeprecated:
              requestPath[_deprecatedConst].toString().toBool() ?? false,
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
        resultContentType = config.defaultContentType;
        imports.clear();
      });
    });
    return restClients;
  }

  /// Parses data classes from `components` of definition file
  /// and return list of  [UniversalDataClass]
  List<UniversalDataClass> parseDataClasses() {
    final dataClasses = <UniversalDataClass>[];
    late final Map<String, dynamic> entities;
    if (_apiInfo.schemaVersion == OAS.v3_1 ||
        _apiInfo.schemaVersion == OAS.v3) {
      if (!_definitionFileContent.containsKey(_componentsConst) ||
          !(_definitionFileContent[_componentsConst] as Map<String, dynamic>)
              .containsKey(_schemasConst)) {
        return [...dataClasses, ..._objectClasses, ..._enumClasses];
      }
      entities = (_definitionFileContent[_componentsConst]
          as Map<String, dynamic>)[_schemasConst] as Map<String, dynamic>;
    } else if (_apiInfo.schemaVersion == OAS.v2) {
      if (!_definitionFileContent.containsKey(_definitionsConst)) {
        return [...dataClasses, ..._objectClasses, ..._enumClasses];
      }
      entities =
          _definitionFileContent[_definitionsConst] as Map<String, dynamic>;
    }
    entities.forEach((key, value) {
      if (_skipDataClasses.contains(key)) {
        return;
      }

      value as Map<String, dynamic>;

      var requiredParameters = <String>[];
      if (value case {_requiredConst: final List<dynamic> rawParameters}) {
        requiredParameters = rawParameters.map((e) => e.toString()).toList();
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
              isRequired: requiredParameters.contains(propertyName) ||
                  config.requiredByDefault,
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
        for (final replacementRule in config.replacementRules) {
          key = replacementRule.apply(key)!;
        }

        dataClasses.add(
          _getUniqueEnumClass(
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
          isRequired:
              requiredParameters.contains(key) || config.requiredByDefault,
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
            for (final replacementRule in config.replacementRules) {
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

      for (final replacementRule in config.replacementRules) {
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
            UniversalType(
              type: element.name,
              name: element.name.toCamel,
              isRequired: config.requiredByDefault,
            ),
          );
          allOfClass.imports.add(element.name);
        }
      }
      allOfClass.parameters.addAll(allOfClass.allOf!.properties);
    }

    // Rename parameters / enum members with the same name
    for (final (index, dataclass) in dataClasses.indexed) {
      if (dataclass is UniversalComponentClass) {
        final protectedParameters = <UniversalType>[];
        final groupedParameters = groupBy(dataclass.parameters, (e) => e.name);

        for (final MapEntry(value: groupParameters)
            in groupedParameters.entries) {
          if (groupParameters.length == 1) {
            protectedParameters.add(groupParameters[0]);
          } else {
            var counter = 0;
            for (final parameter in groupParameters) {
              protectedParameters
                  .add(parameter.copyWith(name: '${parameter.name}$counter'));
              counter++;
            }
          }
        }
        dataClasses[index] = UniversalComponentClass(
          name: dataclass.name,
          imports: dataclass.imports,
          allOf: dataclass.allOf,
          description: dataclass.description,
          typeDef: dataclass.typeDef,
          parameters: protectedParameters,
        );
      } else if (dataclass is UniversalEnumClass) {
        final protectedItems = <UniversalEnumItem>{};
        final groupedItems = groupBy(dataclass.items, (e) => e.name);
        for (final MapEntry(value: groupItems) in groupedItems.entries) {
          if (groupItems.length == 1) {
            protectedItems.add(groupItems.first);
          } else {
            var counter = 0;
            for (final item in groupItems) {
              protectedItems.add(
                UniversalEnumItem(
                  jsonKey: item.jsonKey,
                  name: '${item.name}$counter',
                  description: item.description,
                ),
              );
              counter++;
            }
          }
        }
        dataClasses[index] = UniversalEnumClass(
          originalName: dataclass.originalName,
          name: dataclass.name,
          type: dataclass.type,
          items: protectedItems,
          defaultValue: dataclass.defaultValue,
          description: dataclass.description,
        );
      }
    }

    return dataClasses;
  }

  /// Get tag for name
  String _getTag(Map<String, dynamic> map) =>
      config.mergeClients && config.name != null
          ? config.name!
          : map.containsKey(_tagsConst)
              ? (map[_tagsConst] as List<dynamic>).first.toString().replaceAll(
                    RegExp(r'[^\w\s]+'),
                    '',
                  )
              : 'client';

  /// Format `$ref` type
  String _formatRef(Map<String, dynamic> map, {bool useSchema = false}) =>
      p.basename(
        useSchema
            ? (map[_schemaConst] as Map<String, dynamic>)[_refConst].toString()
            : map[_refConst].toString(),
      );

  /// Find type of map
  ({UniversalType type, String? import, String? componentTypeName}) _findType(
    Map<String, dynamic> map, {
    required bool isRequired,
    bool root = true,
    String? name,
    String? additionalName,
  }) {
    // Array
    if (map.containsKey(_typeConst) && map[_typeConst] == _arrayConst) {
      final arrayItems = map[_itemsConst] as Map<String, dynamic>;
      final arrayType = _findType(
        arrayItems,
        name: name,
        additionalName: name,
        root: false,
        isRequired: config.requiredByDefault,
      );

      final (newName, description) =
          protectName(name, description: map[_descriptionConst]?.toString());

      return (
        type: UniversalType(
          type: arrayType.type.type,
          name: newName?.toCamel,
          description: description,
          format: arrayType.type.format,
          jsonKey: name,
          defaultValue:
              protectDefaultValue(arrayType.type.defaultValue, isArray: true),
          isRequired: isRequired,
          nullable: map[_nullableConst].toString().toBool() ??
              !config.requiredByDefault,
          wrappingCollections: List.of(arrayType.type.wrappingCollections)
            ..insert(0, UniversalCollections.list),
        ),
        import: arrayType.import,
        componentTypeName: null,
      );
    }
    // Map
    else if (map[_typeConst].toString() == _objectConst &&
        map.containsKey(_additionalPropertiesConst) &&
        (map[_additionalPropertiesConst] is Map<String, dynamic>)) {
      final arrayItems =
          map[_additionalPropertiesConst] as Map<String, dynamic>;
      final arrayType = _findType(
        arrayItems,
        name: name,
        additionalName: name,
        root: false,
        isRequired: config.requiredByDefault,
      );

      final (newName, description) =
          protectName(name, description: map[_descriptionConst]?.toString());

      return (
        type: UniversalType(
          type: arrayType.type.type,
          name: newName?.toCamel,
          description: description,
          format: arrayType.type.format,
          jsonKey: name,
          defaultValue:
              protectDefaultValue(arrayType.type.defaultValue, isArray: true),
          isRequired: isRequired,
          nullable: map[_nullableConst].toString().toBool() ??
              !config.requiredByDefault,
          wrappingCollections: List.of(arrayType.type.wrappingCollections)
            ..insert(0, UniversalCollections.map),
        ),
        import: arrayType.import,
        componentTypeName: null,
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
      if (config.enumsParentPrefix && additionalName != null) {
        newName = '$additionalName $newName'.toPascal;
      }

      for (final replacementRule in config.replacementRules) {
        newName = replacementRule.apply(newName)!;
      }

      final items = protectEnumItemsNames(
        (map[_enumConst] as List).map((e) => '$e'),
      );

      final enumClass = _getUniqueEnumClass(
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
        componentTypeName: null,
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

      final typeWithImports = <({UniversalType type, String? import})>[];

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
          defaultValue: protectDefaultValue(map[_defaultConst]),
          nullable: map[_nullableConst].toString().toBool() ??
              !config.requiredByDefault,
          isRequired: isRequired,
        ),
        import: newName.toPascal,
        componentTypeName: null,
      );
    }
    // Type in allOf, anyOf or oneOf
    else if (map.containsKey(_allOfConst) ||
        map.containsKey(_anyOfConst) ||
        map.containsKey(_oneOfConst)) {
      String? ofImport;
      UniversalType? ofType;
      // ignore: unused_local_variable
      String? componentTypeName;

      final of = map[_allOfConst] ?? map[_anyOfConst] ?? map[_oneOfConst];
      if (of is List<dynamic>) {
        // Find type in of one-element allOf, anyOf or oneOf
        if (of.length == 1) {
          final item = of[0];
          if (item is Map<String, dynamic>) {
            (
              import: ofImport,
              type: ofType,
              componentTypeName: componentTypeName
            ) = _findType(
              item,
              isRequired: config.requiredByDefault,
            );
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
              final type = _findType(
                nullableItem,
                isRequired: config.requiredByDefault,
              );
              ofImport = type.import;
              ofType = type.type.copyWith(nullable: true);
            }
          }
        }
        ofType = ofType?.copyWith(name: name?.toPascal);
      }

      final type = ofType?.type ?? _objectConst;

      final import = ofImport;
      final defaultValue = map[_defaultConst]?.toString();

      final enumType = defaultValue != null &&
              import != null &&
              (ofType == null || ofType.wrappingCollections.isEmpty)
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
            isArray: (ofType?.wrappingCollections.length ?? 0) > 0,
          ),
          enumType: enumType,
          isRequired: isRequired,
          wrappingCollections: ofType?.wrappingCollections ?? [],
          nullable: root &&
                  map.containsKey(_nullableConst) &&
                  (map[_nullableConst].toString().toBool() ??
                      !config.requiredByDefault) ||
              (ofType?.nullable ?? false),
        ),
        import: import,
        componentTypeName: null,
      );
    }
    // Type or ref
    else {
      String? import;
      String type;
      String? componentTypeName;
      bool usingBuiltInType = false;
      if (map.containsKey(_refConst)) {
        import = _formatRef(map);
      } else if (map.containsKey(_additionalPropertiesConst) &&
          map[_additionalPropertiesConst] is Map<String, dynamic> &&
          (map[_additionalPropertiesConst] as Map<String, dynamic>)
              .containsKey(_refConst)) {
        import =
            _formatRef(map[_additionalPropertiesConst] as Map<String, dynamic>);
      }

      if (map.containsKey(_typeConst)) {
        if (import != null && map[_typeConst].toString() == _objectConst) {
          type = import;
        } else {
          usingBuiltInType = true;
          type = map[_typeConst].toString();
        }
      } else {
        type = import ?? _objectConst;
      }

      // Handle PascalCase for type
      import = import?.toPascal;
      componentTypeName = type;
      if (!usingBuiltInType) {
        type = type.toPascal;
      }
      // Only apply replacement rules after the componentTypeName has been set
      if (import != null) {
        for (final replacementRule in config.replacementRules) {
          import = replacementRule.apply(import);
          type = replacementRule.apply(type)!;
        }
        // Append the suffix
        type = type + config.modelSuffix;
        import = import! + config.modelSuffix;
      }

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
          defaultValue:
              protectDefaultValue(defaultValue, isEnum: enumType != null),
          enumType: enumType,
          isRequired: isRequired,
          nullable: root &&
              map.containsKey(_nullableConst) &&
              (map[_nullableConst].toString().toBool() ??
                  !config.requiredByDefault),
        ),
        import: import,
        componentTypeName: componentTypeName,
      );
    }
  }
}

/// Extension used for [YamlMap]
extension on YamlMap {
  /// Convert [YamlMap] to Dart map
  Map<String, Object?> toMap() {
    final map = <String, Object?>{};
    for (final entry in entries) {
      if (entry.value is YamlMap || entry.value is Map) {
        map[entry.key.toString()] = (entry.value as YamlMap).toMap();
      } else if (entry.value is YamlList) {
        map[entry.key.toString()] = (entry.value as YamlList)
            .map<Object?>((e) => e is YamlMap ? e.toMap() : e)
            .toList(growable: false);
      } else {
        map[entry.key.toString()] = entry.value.toString();
      }
    }
    return map;
  }
}

/// Extension used for [YamlMap]
extension on String? {
  /// Used specially for [YamlMap] to covert [String] value to [bool]
  bool? toBool() => this == null ? null : this!.toLowerCase() == 'true';
}
