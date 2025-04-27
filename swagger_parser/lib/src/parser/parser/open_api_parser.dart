import 'dart:collection';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../config/parser_config.dart';
import '../corrector/open_api_corrector.dart';
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
    _definitionFileContent = OpenApiCorrector(config).correct();
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
  final _objectNamesCount = <String, int>{};

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
  static const _discriminatorConst = 'discriminator';
  static const _enumConst = 'enum';
  static const _enumNamesConst = 'x-enumNames';
  static const _formatConst = 'format';
  static const _formUrlEncodedConst = 'application/x-www-form-urlencoded';
  static const _inConst = 'in';
  static const _infoConst = 'info';
  static const _itemsConst = 'items';
  static const _mappingConst = 'mapping';
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
  static const _propertyNameConst = 'propertyName';
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
  static const _xNullableConst = 'x-nullable';

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
        // Return type is most often required in any case
        isRequired: true,
      );
      if (typeWithImport.import != null) {
        imports.add(typeWithImport.import!);
      }

      // List<dynamic> is not supported by Retrofit, use dynamic instead
      if (typeWithImport.type.type == _objectConst) {
        return typeWithImport.type.copyWith(wrappingCollections: const []);
      }

      return typeWithImport.type;
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
          final isRequired =
              parameter[_requiredConst]?.toString().toBool() ?? false;
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

          if ((contentType[_schemaConst] as Map<String, dynamic>).containsKey(
            _refConst,
          )) {
            final isRequired =
                requestBody[_requiredConst]?.toString().toBool() ?? false;
            final typeWithImport = _findType(
              contentType[_schemaConst] as Map<String, dynamic>,
              isRequired: isRequired,
            );

            final type = typeWithImport.type.type;

            _skipDataClasses.add(type);

            final components = _definitionFileContent[_componentsConst]
                as Map<String, dynamic>;
            final schemes = components[_schemasConst] as Map<String, dynamic>;
            final dataClass = schemes[type] as Map<String, dynamic>;
            final props = dataClass[_propertiesConst] as Map<String, dynamic>;
            final required = dataClass[_requiredConst] as List<dynamic>?;

            properties = props;
            requiredParameters =
                required?.map((e) => e.toString()).toList() ?? [];
          } else {
            if (schemaContent[_propertiesConst] is Map<String, dynamic>) {
              properties =
                  schemaContent[_propertiesConst] as Map<String, dynamic>;
            } else {
              properties = {};
            }
            requiredParameters =
                (schemaContent[_requiredConst] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [];
          }

          for (final propName in properties.keys) {
            final propValue = properties[propName] as Map<String, dynamic>;
            final isRequired = requiredParameters.contains(propName);
            final typeWithImport = _findType(propValue, isRequired: isRequired);
            final currentType = typeWithImport.type;
            if (typeWithImport.import != null) {
              imports.add(typeWithImport.import!);
            }
            types.add(
              UniversalRequestType(
                parameterType: HttpParameterType.part,
                name: propName,
                description: currentType.description,
                type: UniversalType(
                  type: currentType.type,
                  name: propName,
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
        } else {
          final isRequired =
              requestBody[_requiredConst]?.toString().toBool() ?? false;
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
        // Return type is most often required in any case
        isRequired: true,
      );
      if (typeWithImport.import != null) {
        imports.add(typeWithImport.import!);
      }

      final type = typeWithImport.type;
      return UniversalType(
        type: type.type,
        wrappingCollections:
            // List<dynamic> is not supported by Retrofit, use dynamic instead
            type.type == _objectConst ? const [] : type.wrappingCollections,
        isRequired: typeWithImport.type.isRequired,
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
                false;

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
          print('Warning:\nparameterType ${parameter[_inConst]} not supported');
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
    (_definitionFileContent[_pathsConst] as Map<String, dynamic>).forEach((
      path,
      pathValue,
    ) {
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

        final request = UniversalRequest(
          name: requestName,
          description: description,
          requestType: HttpRequestType.fromString(key)!,
          route: path,
          contentType: resultContentType,
          returnType: returnType,
          parameters: parameters,
          isDeprecated:
              requestPath[_deprecatedConst].toString().toBool() ?? false,
        );
        final currentTag = _getTag(requestPath);
        final sameTagIndex = restClients.indexWhere(
          (e) => e.name == currentTag,
        );
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

  /// Used to find properties in map
  (List<UniversalType>, Set<String>) _findParametersAndImports(
    Map<String, dynamic> map, {
    String? additionalName,
  }) {
    final parameters = <UniversalType>[];
    final imports = <String>{};

    var requiredParameters = <String>[];
    if (map case {_requiredConst: final List<dynamic> rawParameters}) {
      requiredParameters = rawParameters.map((e) => e.toString()).toList();
    }

    if (map case {_propertiesConst: final Map<String, dynamic> props}) {
      for (final propertyName in props.keys) {
        final propertyValue = props[propertyName] as Map<String, dynamic>;
        var isNullable = propertyValue[_nullableConst].toString().toBool();
        // OpenAPI 2.0 nullable value
        isNullable =
            isNullable ?? propertyValue[_xNullableConst].toString().toBool();

        isNullable = isNullable ??
            switch (propertyValue) {
              {_anyOfConst: final List<dynamic> anyOf} => anyOf.any(
                  (e) => e is Map<String, dynamic> && e['type'] == 'null',
                ),
              {_oneOfConst: final List<dynamic> oneOf} => oneOf.any(
                  (e) => e is Map<String, dynamic> && e['type'] == 'null',
                ),
              {_allOfConst: final List<dynamic> allOf} => allOf.any(
                  (e) => e is Map<String, dynamic> && e['type'] == 'null',
                ),
              _ => false,
            };

        final isRequired = requiredParameters.contains(propertyName);
        final typeWithImport = _findType(
          propertyValue,
          name: propertyName,
          additionalName: additionalName,
          isRequired: (_apiInfo.schemaVersion == OAS.v2 && !config.useXNullable)
              ? isRequired
              : isRequired || !isNullable,
        );

        var validation = propertyValue;
        final anyOf = propertyValue[_anyOfConst];
        if (anyOf != null && anyOf is List<dynamic> && anyOf.length == 2) {
          final first = anyOf.first as Map<String, dynamic>;
          final last = anyOf.last as Map<String, dynamic>;
          if (last['type'] == 'null') {
            validation = first;
          }
        }

        final max = double.tryParse(validation['maximum'].toString());
        final min = double.tryParse(validation['minimum'].toString());
        final maxLength = int.tryParse(validation['maxLength'].toString());
        final minLength = int.tryParse(validation['minLength'].toString());
        final maxItems = int.tryParse(validation['maxItems'].toString());
        final minItems = int.tryParse(validation['minItems'].toString());
        final patternString = validation['pattern'].toString();
        final pattern = patternString == 'null' ? null : patternString;
        final uniqueItems = validation['uniqueItems'].toString().toBool();

        final typeWithValidationParams = typeWithImport.type.copyWith(
          min: min,
          max: max,
          minLength: minLength,
          maxLength: maxLength,
          maxItems: maxItems,
          minItems: minItems,
          pattern: pattern,
          uniqueItems: uniqueItems,
        );

        parameters.add(typeWithValidationParams);
        if (typeWithImport.import != null) {
          imports.add(typeWithImport.import!);
        }
      }
    }

    return (parameters, imports);
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

      final refs = <String>[];
      final parameters = <UniversalType>[];
      final imports = SplayTreeSet<String>();

      /// Used for find properties in map
      void localFindParametersAndImports(Map<String, dynamic> map) {
        final (findParameters, findImports) = _findParametersAndImports(
          map,
          additionalName: key,
        );
        parameters.addAll(findParameters);
        imports.addAll(findImports);
      }

      if (value.containsKey(_propertiesConst)) {
        localFindParametersAndImports(value);
      } else if (value.containsKey(_enumConst)) {
        final Set<UniversalEnumItem> items;
        final values = (value[_enumConst] as List).map((e) => '$e');
        if (value.containsKey(_enumNamesConst)) {
          final names = (value[_enumNamesConst] as List).map((e) => '$e');
          items = protectEnumItemsNamesAndValues(names, values);
        } else {
          items = protectEnumItemsNames(values);
        }
        final type = value[_typeConst].toString();

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
          // typeDef is always non-nullable
          isRequired: true,
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
        return;
      }

      if (value.containsKey(_allOfConst)) {
        for (final map in value[_allOfConst] as List<dynamic>) {
          if ((map as Map<String, dynamic>).containsKey(_refConst)) {
            final ref = _formatRef(map);

            refs.add(ref);
            continue;
          }
          if (map.containsKey(_propertiesConst)) {
            localFindParametersAndImports(map);
          }
        }
      }

      final allOf =
          refs.isNotEmpty ? (refs: refs, properties: parameters) : null;

      final discriminator = _parseDiscriminatorInfo(value);
      dataClasses.add(
        UniversalComponentClass(
          name: key,
          imports: imports,
          parameters: allOf != null ? [] : parameters,
          allOf: allOf,
          description: value[_descriptionConst]?.toString(),
          discriminator: discriminator,
        ),
      );
    });

    dataClasses.addAll(_objectClasses);
    _objectClasses.clear();
    dataClasses.addAll(_enumClasses);
    _enumClasses.clear();

    // check for `allOf`
    final allOfClasses = dataClasses.where(
      (dc) => dc is UniversalComponentClass && dc.allOf != null,
    );
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
              isRequired: false,
            ),
          );
          allOfClass.imports.add(element.name);
        }
      }
      allOfClass.parameters.addAll(allOfClass.allOf!.properties);
    }

    // check for discriminated oneOf
    final discriminatedOneOfClasses = dataClasses.where(
      (dc) => dc is UniversalComponentClass && dc.discriminator != null,
    );
    for (final discriminatedOneOfClass in discriminatedOneOfClasses) {
      if (discriminatedOneOfClass is! UniversalComponentClass) {
        continue;
      }
      final discriminator = discriminatedOneOfClass.discriminator!;
      // for each ref, we lookup the matching dataclass and add its properties to the discriminator mapping, its imports are added to the discriminatedOneOfClass's imports
      for (final ref in discriminator.discriminatorValueToRefMapping.values) {
        final refedClassIndex = dataClasses.indexWhere((dc) => dc.name == ref);
        final refedClass = dataClasses[refedClassIndex];
        if (refedClass is! UniversalComponentClass) {
          continue;
        }
        discriminator.refProperties[ref] = refedClass.parameters;
        discriminatedOneOfClass.imports.addAll(refedClass.imports);
        discriminatedOneOfClass.imports.add(refedClass.import);

        dataClasses[refedClassIndex] = refedClass.copyWith(
          imports: {
            ...refedClass.imports,
            discriminatedOneOfClass.import,
          }.sortedBy((it) => it).toSet(),
          discriminatorValue: (
            propertyValue: discriminatedOneOfClass
                .discriminator!.discriminatorValueToRefMapping.entries
                .firstWhere((it) => it.value == ref)
                .key,
            parentClass: discriminatedOneOfClass.name,
          ),
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
  ({UniversalType type, String? import}) _findType(
    Map<String, dynamic> map, {
    required bool isRequired,
    bool root = true,
    String? name,
    String? additionalName,
  }) {
    // Array
    if (map.containsKey(_typeConst) && map[_typeConst] == _arrayConst) {
      final arrayItems = map[_itemsConst] as Map<String, dynamic>;
      final (:type, :import) = _findType(
        arrayItems,
        name: name,
        additionalName: additionalName,
        root: false,
        isRequired: isRequired,
      );

      final (newName, description) = protectName(
        name,
        description: map[_descriptionConst]?.toString(),
      );

      final nullable =
          map[_nullableConst].toString().toBool() ?? (root && !isRequired);

      return (
        type: UniversalType(
          type: type.type,
          name: newName?.toCamel,
          description: description,
          format: type.format,
          jsonKey: name,
          defaultValue: protectDefaultValue(type.defaultValue, isArray: true),
          isRequired: type.isRequired,
          nullable: type.nullable,
          wrappingCollections: [
            if (nullable)
              UniversalCollections.nullableList
            else
              UniversalCollections.list,
            ...type.wrappingCollections,
          ],
        ),
        import: import,
      );
    }
    // Map
    else if (map.containsKey(_additionalPropertiesConst) &&
        map[_typeConst].toString() == _objectConst &&
        (map[_additionalPropertiesConst] is Map<String, dynamic>)) {
      final mapItem = map[_additionalPropertiesConst] as Map<String, dynamic>;
      final (:type, :import) = _findType(
        mapItem,
        name: name,
        additionalName: name,
        root: false,
        isRequired: isRequired,
      );

      final (newName, description) = protectName(
        name,
        description: map[_descriptionConst]?.toString(),
      );

      final nullable =
          map[_nullableConst].toString().toBool() ?? (root && !isRequired);
      return (
        type: UniversalType(
          type: type.type,
          name: newName?.toCamel,
          description: description,
          format: type.format,
          jsonKey: name,
          defaultValue: protectDefaultValue(type.defaultValue, isArray: true),
          isRequired: type.isRequired,
          nullable: type.nullable,
          wrappingCollections: [
            if (nullable)
              UniversalCollections.nullableMap
            else
              UniversalCollections.map,
            ...type.wrappingCollections,
          ],
        ),
        import: import,
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

      final Set<UniversalEnumItem> items;
      final values = (map[_enumConst] as List).map((e) => '$e');
      if (map.containsKey(_enumNamesConst)) {
        final names = (map[_enumNamesConst] as List).map((e) => '$e');
        items = protectEnumItemsNamesAndValues(names, values);
      } else {
        items = protectEnumItemsNames(values);
      }

      final enumClass = _getUniqueEnumClass(
        name: newName,
        items: items,
        type: map[_typeConst].toString(),
        defaultValue: protectDefaultValue(map[_defaultConst], isEnum: true),
        description: description,
      );

      _enumClasses.add(enumClass);

      final type = map[_typeConst];
      final nullable = type is List && type.any((e) => e.toString() == 'null');

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
          nullable: nullable,
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
        !map.containsKey(_typeConst) &&
            (map.containsKey(_additionalPropertiesConst) &&
                (map[_additionalPropertiesConst] is Map<String, dynamic>) &&
                (map[_additionalPropertiesConst] as Map<String, dynamic>)
                    .isNotEmpty &&
                !(map[_additionalPropertiesConst] as Map<String, dynamic>)
                    .containsKey(_refConst))) {
      final originalName = name ?? additionalName;
      // false positive result
      // ignore: unnecessary_null_checks
      final (newName!, description) = protectName(
        originalName,
        uniqueIfNull: true,
        description: map[_descriptionConst]?.toString(),
      );

      final (parameters, imports) = _findParametersAndImports(map);

      var type = newName.toPascal;

      for (final replacementRule in config.replacementRules) {
        type = replacementRule.apply(type)!;
      }

      // Check for duplicate type names
      if (_objectNamesCount.containsKey(type)) {
        _objectNamesCount[type] = _objectNamesCount[type]! + 1;
        type = '$type${_objectNamesCount[type]}';
        stdout.writeln('Found duplicate object name: $type');
      } else {
        _objectNamesCount[type] = 1;
      }

      if (_objectClasses.where((oc) => oc.name == type).isEmpty) {
        _objectClasses.add(
          UniversalComponentClass(
            name: type,
            imports: imports,
            parameters: parameters,
          ),
        );
      }

      return (
        type: UniversalType(
          type: type,
          name: newName.toCamel,
          description: description,
          format: map.containsKey(_formatConst)
              ? map[_formatConst].toString()
              : null,
          jsonKey: originalName,
          defaultValue: protectDefaultValue(map[_defaultConst]),
          nullable:
              map[_nullableConst].toString().toBool() ?? (root && !isRequired),
          isRequired: isRequired,
        ),
        import: type,
      );
    }
    // Type in allOf, anyOf or oneOf
    else if (map.containsKey(_allOfConst) ||
        map.containsKey(_anyOfConst) ||
        map.containsKey(_oneOfConst) ||
        map[_typeConst] is List) {
      String? ofImport;
      UniversalType? ofType;
      final ofList = map[_allOfConst] ??
          map[_anyOfConst] ??
          map[_oneOfConst] ??
          (map[_typeConst] as List<dynamic>)
              .map((e) => <String, dynamic>{_typeConst: e.toString()})
              .toList();

      UniversalType makeNullable(UniversalType type) {
        if (type.wrappingCollections.isEmpty) {
          return type.copyWith(nullable: true);
        } else {
          final first = type.wrappingCollections.first;
          final wrappingCollections = [...type.wrappingCollections]..first =
                switch (first) {
              UniversalCollections.list => UniversalCollections.nullableList,
              UniversalCollections.map => UniversalCollections.nullableMap,
              _ => first,
            };
          return type.copyWith(
            wrappingCollections: wrappingCollections,
          );
        }
      }

      if (ofList is List<dynamic>) {
        // Handle first the special case of oneOf with discriminator which should be handled as sealed class
        if (map.containsKey(_oneOfConst) &&
            map.containsKey(_discriminatorConst) &&
            (map[_discriminatorConst] as Map<String, dynamic>).containsKey(
              _propertyNameConst,
            ) &&
            (map[_discriminatorConst] as Map<String, dynamic>).containsKey(
              _mappingConst,
            )) {
          final discriminator = _parseDiscriminatorInfo(map);

          // Create a base union class for the discriminated types
          final baseClassName =
              '${additionalName ?? ''} ${name ?? ''} Union'.toPascal;
          final (newName, description) = protectName(
            baseClassName,
            uniqueIfNull: true,
            description: map[_descriptionConst]?.toString(),
          );

          // Create a sealed class to represent the discriminated union
          _objectClasses.add(
            UniversalComponentClass(
              name: newName!.toPascal,
              imports: SplayTreeSet<String>(),
              parameters: [
                UniversalType(
                  type: 'String',
                  name: discriminator?.propertyName,
                  isRequired: true,
                ),
              ],
              discriminator: discriminator,
            ),
          );

          ofType = UniversalType(
            type: newName.toPascal,
            isRequired: isRequired,
          );
          ofImport = newName.toPascal;
        }

        // If there is only one item, we directly return the type inside the xOf
        else if (ofList.length == 1) {
          final item = ofList[0];
          if (item is Map<String, dynamic>) {
            (import: ofImport, type: ofType) = _findType(
              item,
              root: false,
              isRequired: false,
            );
          }
        }
        // Find n-element anyOf/allOf
        else if (ofList.length > 1) {
          final nullItems = ofList
              .where(
                (item) =>
                    item is Map<String, dynamic> &&
                    (item[_typeConst]?.toString() == 'null' ||
                        (item.containsKey(_nullableConst) &&
                            (item[_nullableConst]?.toString().toBool() ??
                                false))),
              )
              .whereType<Map<String, dynamic>>()
              .toList();
          final otherItems = ofList
              .where(
                (item) =>
                    item is Map<String, dynamic> && !nullItems.contains(item),
              )
              .whereType<Map<String, dynamic>>()
              .toList();

          // If there is only one item in otherItems, it probably means the type is the same or
          // the type is used as a nullable here
          if (otherItems.length == 1) {
            final optionalItem = otherItems[0];
            // Add to support this:
            // anyOf:
            //   - type: array
            //   - type: null
            // items:
            //   type: string
            final nMap = {...map}
              ..remove(_anyOfConst)
              ..remove(_allOfConst)
              ..remove(_oneOfConst)
              ..remove(_typeConst);

            optionalItem.addAll(nMap);

            final (:type, :import) = _findType(
              optionalItem,
              root: root,
              isRequired: false,
            );
            ofType = type;
            ofImport = import;
          }
          // If there is more than one item, there is a union of types which dart might not natively support
          else if (otherItems.length > 1) {
            // It is possible that more cases have to be handled like
            // types:
            //   - null
            //   - number
            //   - string
            // In theory this is not very type safe but it COULD be handled through a union type
            // This is left as an indication for future contributors who may want to handle this case

            // If we try to handle an allOf, the goal is to obtain a single type that is the union of all the types in otherItems
            // At this point, we only explored a part of the schema so if the item is a ref, we won't be able to fully resolve the type
            // What we should do is create a new type that is a composition of all the object types in otherItems
            // Then we collect the refs and properties and store them in the UniversalComponentClass to be processed when we are done parsing the data classes.
            if (map.containsKey(_allOfConst)) {
              final refs = <String>[];
              final parameters = <UniversalType>[];
              final imports = SplayTreeSet<String>();

              for (final item in otherItems) {
                if (item.containsKey(_refConst)) {
                  // Get referenced schema
                  final ref = _formatRef(item);
                  // Add to list of refs to be processed
                  refs.add(ref);
                  imports.add(ref);
                } else if (item.containsKey(_propertiesConst)) {
                  final (foundParameters, foundImports) =
                      _findParametersAndImports(
                    item,
                    additionalName: name,
                  );
                  parameters.addAll(foundParameters);
                  imports.addAll(foundImports);
                }
              }

              final baseClassName =
                  '${additionalName ?? ''} ${name ?? ''}'.toPascal;
              final (newName, description) = protectName(
                baseClassName,
                uniqueIfNull: true,
                description: map[_descriptionConst]?.toString(),
              );

              // Create a class to represent the allOf composition
              _objectClasses.add(
                UniversalComponentClass(
                  name: newName!.toPascal,
                  imports: imports,
                  // This is a workaround as the linter is rightfully complaining
                  // because we give a litteral that should be a const but can't
                  // because it is modified later when the data classes are created
                  // This should be addressed in the future.
                  // ignore: prefer_const_literals_to_create_immutables
                  parameters: [],
                  allOf: (refs: refs, properties: parameters),
                  description: description,
                ),
              );

              ofType = UniversalType(
                type: newName.toPascal,
                isRequired: isRequired,
              );

              ofImport = newName.toPascal;
            }
          }

          // If the ofList contains the "null" type, it is a nullable type
          if (ofType != null && nullItems.isNotEmpty) {
            ofType = makeNullable(ofType);
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
      final (newName, description) = protectName(
        name,
        description: map[_descriptionConst]?.toString(),
      );

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
          nullable: (ofType?.nullable ?? false) ||
              (map[_nullableConst].toString().toBool() ?? false) ||
              (root && !isRequired),
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
          (map[_additionalPropertiesConst] as Map<String, dynamic>).containsKey(
            _refConst,
          )) {
        import = _formatRef(
          map[_additionalPropertiesConst] as Map<String, dynamic>,
        ).toPascal;
      }

      if (map.containsKey(_typeConst)) {
        type = import != null && map[_typeConst].toString() == _objectConst
            ? import
            : map[_typeConst].toString();
      } else {
        type = import ?? _objectConst;
      }
      if (import != null) {
        type = type.toPascal;
      }

      final defaultValue = map[_defaultConst]?.toString();
      final (newName, description) = protectName(
        name,
        description: map[_descriptionConst]?.toString(),
      );

      final enumType = defaultValue != null && import != null ? type : null;

      return (
        type: UniversalType(
          type: type,
          name: newName?.toCamel,
          description: description,
          format: map[_formatConst]?.toString(),
          jsonKey: name,
          defaultValue: protectDefaultValue(
            defaultValue,
            isEnum: enumType != null,
          ),
          enumType: enumType,
          isRequired: isRequired,
          nullable:
              map[_nullableConst].toString().toBool() ?? (root && !isRequired),
        ),
        import: import,
      );
    }
  }

  Discriminator? _parseDiscriminatorInfo(Map<String, dynamic> map) {
    if (!map.containsKey(_oneOfConst)) {
      return null;
    }
    final discriminator = map[_discriminatorConst] as Map<String, dynamic>;
    final propertyName = discriminator[_propertyNameConst] as String;
    final refMapping = discriminator[_mappingConst] as Map<String, dynamic>;

    // Cleanup the refMapping to contain only the class name
    final cleanedRefMapping = <String, String>{};
    for (final key in refMapping.keys) {
      final refMap = <String, dynamic>{_refConst: refMapping[key]};
      cleanedRefMapping[key] = _formatRef(refMap);
    }
    return (
      propertyName: propertyName,
      discriminatorValueToRefMapping: cleanedRefMapping,
      // This property is populated by the parser after all the data classes are created
      refProperties: <String, List<UniversalType>>{},
    );
  }
}

/// Extension used for [YamlMap]
extension on String? {
  /// Used specially for [YamlMap] to covert [String] value to [bool]
  bool? toBool() =>
      this == null || this == 'null' ? null : this!.toLowerCase() == 'true';
}
