import 'dart:collection';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../generator/models/all_of.dart';
import '../generator/models/universal_component_class.dart';
import '../generator/models/universal_data_class.dart';
import '../generator/models/universal_enum_class.dart';
import '../generator/models/universal_request.dart';
import '../generator/models/universal_request_type.dart';
import '../generator/models/universal_rest_client.dart';
import '../generator/models/universal_type.dart';
import '../utils/case_utils.dart';
import '../utils/dart_keywords.dart';
import 'parser_exception.dart';

/// General class for parsing OpenApi files into universal models
class OpenApiParser {
  /// Accepts [fileContent] of the schema file
  /// and [isYaml] schema format or not
  OpenApiParser(String fileContent, {bool isYaml = false}) {
    _definitionFileContent = isYaml
        ? (loadYaml(fileContent) as YamlMap).toMap()
        : jsonDecode(fileContent) as Map<String, dynamic>;

    if (_definitionFileContent.containsKey(_openApiConst)) {
      final version = _definitionFileContent[_openApiConst].toString();
      if (version.startsWith('3.1')) {
        _version = OpenApiVersion.v3_1;
        return;
      }
      if (version.startsWith('3.0')) {
        _version = OpenApiVersion.v3;
        return;
      }
    }
    if (_definitionFileContent.containsKey(_swaggerConst) &&
        _definitionFileContent[_swaggerConst].toString().startsWith('2.0')) {
      _version = OpenApiVersion.v2;
      return;
    }
    throw const ParserException('Unknown version of OpenAPI.');
  }

  late final Map<String, dynamic> _definitionFileContent;
  late final OpenApiVersion _version;
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
  static const _inConst = 'in';
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
  static const _swaggerConst = 'swagger';
  static const _tagsConst = 'tags';
  static const _typeConst = 'type';
  static const _valueConst = 'value';

  /// Parses rest clients from `paths` section of definition file
  /// and return list of [UniversalRestClient]
  Iterable<UniversalRestClient> parseRestClients() {
    final restClients = <UniversalRestClient>[];
    final imports = SplayTreeSet<String>();
    var isMultiPart = false;

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
          final isRequired =
              (rawParameter as Map<String, dynamic>)[_requiredConst]
                  ?.toString()
                  .toBool();
          final typeWithImport = _findType(
            rawParameter[_schemaConst] as Map<String, dynamic>,
            name: rawParameter[_nameConst].toString(),
            isRequired: isRequired ?? true,
            allOfObject: (rawParameter[_schemaConst] as Map<String, dynamic>)
                .containsKey(_allOfConst),
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
              name: rawParameter[_nameConst] == _bodyConst
                  ? null
                  : rawParameter[_nameConst].toString(),
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
      for (final rawParameter in map[_parametersConst] as List<dynamic>) {
        final isRequired =
            (rawParameter as Map<String, dynamic>)[_requiredConst]
                ?.toString()
                .toBool();
        final typeWithImport = _findType(
          rawParameter,
          name: rawParameter[_nameConst].toString(),
          isRequired: isRequired ?? true,
          useSchema: true,
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
            name: rawParameter[_nameConst] == _bodyConst
                ? null
                : rawParameter[_nameConst].toString(),
          ),
        );
      }
      return types;
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
        final returnType = _version == OpenApiVersion.v2
            ? returnTypeV2(requestPathResponses)
            : returnTypeV3(requestPathResponses);
        final parameters = _version == OpenApiVersion.v2
            ? parametersV2(requestPath)
            : parametersV3(requestPath);
        final requestName =
            requestPath[_operationIdConst]?.toString().toCamel ??
                (key + path).toCamel;

        final request = UniversalRequest(
          name: requestName,
          requestType: HttpRequestType.fromString(key)!,
          route: path,
          isMultiPart: isMultiPart,
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
    if (_version == OpenApiVersion.v3_1 || _version == OpenApiVersion.v3) {
      if (!_definitionFileContent.containsKey(_componentsConst) ||
          !(_definitionFileContent[_componentsConst] as Map<String, dynamic>)
              .containsKey(_schemasConst)) {
        return dataClasses;
      }
      entities = (_definitionFileContent[_componentsConst]
          as Map<String, dynamic>)[_schemasConst] as Map<String, dynamic>;
    } else if (_version == OpenApiVersion.v2) {
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

      void findParamsAndImports(Map<String, dynamic> map) {
        (map[_propertiesConst] as Map<String, dynamic>).forEach(
          (propertyName, propertyValue) {
            final typeWithImport = _findType(
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

      if (value.containsKey(_propertiesConst)) {
        findParamsAndImports(value);
      } else if (value.containsKey(_enumConst)) {
        final items =
            (value[_enumConst] as List).map((e) => e.toString()).toSet();
        dataClasses.add(
          UniversalEnumClass(
            name: key,
            type: value[_typeConst].toString(),
            items: items,
            defaultValue: value[_defaultConst]?.toString(),
            description: value[_descriptionConst]?.toString(),
          ),
        );
        return;
      } else if (value.containsKey(_allOfConst)) {
        for (final map in value[_allOfConst] as List) {
          if ((map as Map<String, dynamic>).containsKey(_refConst)) {
            refs.add(_formatRef(map));
            continue;
          }
          if (map.containsKey(_propertiesConst)) {
            findParamsAndImports(map);
          }
        }
      } else if (value.containsKey(_typeConst) ||
          value.containsKey(_refConst)) {
        final typeWithImport = _findType(
          value,
          name: key,
          isRequired:
              requiredParameters.contains(key) || requiredParameters.isEmpty,
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

      final allOf =
          refs.isNotEmpty ? AllOf(refs: refs, properties: parameters) : null;
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
      '226'
    };
    final key = map.keys.where(codes2xx.contains).firstOrNull;
    if (key == null) {
      return null;
    }
    return map[key] as Map<String, dynamic>;
  }

  /// Get tag for name
  String _getTag(Map<String, dynamic> map) => map.containsKey(_tagsConst)
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
  TypeWithImport _findType(
    Map<String, dynamic> map, {
    String? name,
    String? arrayName,
    bool isRequired = true,
    bool useSchema = false,
    bool allOfObject = false,
    bool root = true,
  }) {
    if (map.containsKey(_typeConst) && map[_typeConst] == _arrayConst) {
      // `array`
      final arrayType = _findType(
        map[_itemsConst] as Map<String, dynamic>,
        arrayName: name,
        root: false,
      );
      return TypeWithImport(
        type: UniversalType(
          type: arrayType.type.type,
          name: (dartKeywords.contains(name) ? '$name $_valueConst' : name)
              ?.toCamel,
          description: map[_descriptionConst]?.toString(),
          format: arrayType.type.format,
          jsonKey: name,
          defaultValue: arrayType.type.defaultValue,
          isRequired: isRequired,
          nullable: map[_nullableConst] == true,
          arrayDepth: arrayType.type.arrayDepth + 1,
        ),
        import: arrayType.import,
      );
    } else if (map.containsKey(_enumConst)) {
      // `enum`
      final newName = name ?? _uniqueName;
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
      return TypeWithImport(
        type: UniversalType(
          type: newName.toPascal,
          name: (dartKeywords.contains(newName)
                  ? '$newName $_enumConst'
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
      final newName = arrayName ?? name ?? _uniqueName;
      final typeWithImports = <TypeWithImport>[];
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
      return TypeWithImport(
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
    } else {
      final type = map.containsKey(_typeConst)
          ? map.containsKey(_refConst) &&
                  map[_typeConst].toString() == _objectConst
              ? _formatRef(map)
              : map[_typeConst].toString()
          : map.containsKey(_anyOfConst) ||
                  map.containsKey(_oneOfConst) ||
                  allOfObject
              ? _objectConst
              : map.containsKey(_refConst)
                  ? _formatRef(map)
                  : _objectConst;
      final import = map.containsKey(_typeConst) ||
              map.containsKey(_anyOfConst) ||
              map.containsKey(_oneOfConst) ||
              allOfObject
          ? null
          : map.containsKey(_refConst)
              ? _formatRef(map)
              : null;
      return TypeWithImport(
        type: UniversalType(
          type: type,
          name: (dartKeywords.contains(name) ? '$name $_valueConst' : name)
              ?.toCamel,
          description: map[_descriptionConst]?.toString(),
          format: map[_formatConst]?.toString(),
          jsonKey: name,
          defaultValue: map[_defaultConst]?.toString(),
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

/// Class that contains certain [type] and imports associated with it
/// [import] are created when `$ref` is found while determining type
class TypeWithImport {
  const TypeWithImport({required this.type, this.import});

  /// Type
  final UniversalType type;

  /// Import for type, if you need a separate class
  final String? import;
}

extension _YamlMapX on YamlMap {
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

extension _StringToBoolX on String {
  /// used specially for yaml map
  bool toBool() => toLowerCase() == 'true';
}

/// All versions of the OpenApi that this package supports
enum OpenApiVersion { v3_1, v3, v2 }
