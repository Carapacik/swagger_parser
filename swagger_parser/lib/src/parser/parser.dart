// ignore_for_file: avoid_dynamic_calls
import 'dart:collection';
import 'dart:convert';

import 'package:collection/collection.dart';
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

/// General class for parsing OpenApi json files into universal models
class OpenApiParser {
  OpenApiParser(String fileContent, {bool isYaml = false}) {
    _jsonContent = isYaml
        ? (loadYaml(fileContent) as YamlMap).toMap()
        : jsonDecode(fileContent) as Map<String, dynamic>;

    if (_jsonContent.containsKey(_openApiVar)) {
      final version = _jsonContent[_openApiVar].toString();
      if (version.startsWith('3.1')) {
        _version = OpenApiVersion.v3_1;
        return;
      }
      if (version.startsWith('3.0')) {
        _version = OpenApiVersion.v3;
        return;
      }
    }
    if (_jsonContent.containsKey(_swaggerVar) &&
        _jsonContent[_swaggerVar].toString().startsWith('2.0')) {
      _version = OpenApiVersion.v2;
      return;
    }
    throw const ParserException('Unknown version of OpenAPI.');
  }

  late final Map<String, dynamic> _jsonContent;
  late final OpenApiVersion _version;

  final List<UniversalComponentClass> objectClasses =
      <UniversalComponentClass>[];

  static const _allOfVar = 'allOf';
  static const _anyOfVar = 'anyOf';
  static const _arrayVar = 'array';
  static const _bodyVar = 'body';
  static const _code200Var = '200';
  static const _componentsVar = 'components';
  static const _consumesVar = 'consumes';
  static const _contentVar = 'content';
  static const _defaultClientTag = 'client';
  static const _defaultVar = 'default';
  static const _definitionsVar = 'definitions';
  static const _enumVar = 'enum';
  static const _formatVar = 'format';
  static const _inVar = 'in';
  static const _itemsVar = 'items';
  static const _multipartVar = 'multipart/form-data';
  static const _nameVar = 'name';
  static const _objectVar = 'object';
  static const _oneOfVar = 'oneOf';
  static const _openApiVar = 'openapi';
  static const _parametersVar = 'parameters';
  static const _pathsVar = 'paths';
  static const _propertiesVar = 'properties';
  static const _refVar = r'$ref';
  static const _requestBodyVar = 'requestBody';
  static const _requiredVar = 'required';
  static const _responsesVar = 'responses';
  static const _schemaVar = 'schema';
  static const _schemasVar = 'schemas';
  static const _swaggerVar = 'swagger';
  static const _tagsVar = 'tags';
  static const _typeVar = 'type';
  static const _valueVar = 'value';

  /// Parses rest clients from 'paths' section of json file into universal models
  Iterable<UniversalRestClient> parseRestClients() {
    final restClients = <UniversalRestClient>[];
    final imports = SplayTreeSet<String>();
    var isMultiPart = false;

    /// Parses return type for client query for OpenApi v3
    UniversalType? returnTypeV3(Map<String, dynamic> map) {
      if (!map.containsKey(_code200Var) ||
          !(map[_code200Var] as Map<String, dynamic>)
              .containsKey(_contentVar)) {
        return null;
      }
      final contentType =
          (map[_code200Var][_contentVar] as Map<String, dynamic>)
              .entries
              .firstOrNull;
      if (contentType == null) {
        throw const ParserException(
          'Response must always have a content type.',
        );
      }
      final contentTypeValue = contentType.value as Map<String, dynamic>;
      if (contentTypeValue.isEmpty ||
          !contentTypeValue.containsKey(_schemasVar) ||
          (contentTypeValue[_schemaVar] as Map<String, dynamic>).isEmpty) {
        return null;
      }
      final typeWithImport = _findType(
        contentType.value[_schemaVar] as Map<String, dynamic>,
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
      if (!map.containsKey(_parametersVar) &&
          !map.containsKey(_requestBodyVar)) {
        return [];
      }
      final types = <UniversalRequestType>[];
      if (map.containsKey(_parametersVar)) {
        for (final rawParameter in map[_parametersVar] as List<dynamic>) {
          final isRequired =
              (rawParameter as Map<String, dynamic>)[_requiredVar] as bool?;
          final typeWithImport = _findType(
            rawParameter[_schemaVar] as Map<String, dynamic>,
            name: rawParameter[_nameVar].toString(),
            isRequired: isRequired ?? true,
            allOfObject: (rawParameter[_schemaVar] as Map<String, dynamic>)
                .containsKey(_allOfVar),
          );
          if (typeWithImport.import != null) {
            imports.add(typeWithImport.import!);
          }
          types.add(
            UniversalRequestType(
              parameterType: HttpParameterType.values.firstWhere(
                (e) => e.name == (rawParameter[_inVar].toString()),
              ),
              type: typeWithImport.type,
              name: _checkForBody(rawParameter)
                  ? null
                  : rawParameter[_nameVar].toString(),
            ),
          );
        }
      }
      if (map.containsKey(_requestBodyVar)) {
        if (!(map[_requestBodyVar] as Map<String, dynamic>)
            .containsKey(_contentVar)) {
          throw const ParserException('Request body must always have content.');
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
          throw const ParserException(
            'Response must always have a content type.',
          );
        }
        if (isMultiPart) {
          if ((contentType[_schemaVar] as Map<String, dynamic>)
              .containsKey(_refVar)) {
            final isRequired = map[_requestBodyVar][_requiredVar] as bool?;
            final typeWithImport = _findType(
              contentType[_schemaVar] as Map<String, dynamic>,
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
                  arrayDepth: currentType.arrayDepth,
                  name: 'file',
                  defaultValue: currentType.defaultValue,
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
                  type: UniversalType(
                    type: currentType.type,
                    arrayDepth: currentType.arrayDepth,
                    name: e.key,
                    defaultValue: currentType.defaultValue,
                    isRequired: currentType.isRequired,
                    format: currentType.format,
                  ),
                  name: e.key,
                ),
              );
            }
          }
        } else {
          final isRequired =
              map[_requestBodyVar][_requiredVar]?.toString().toBool();
          final typeWithImport = _findType(
            contentType[_schemaVar] as Map<String, dynamic>,
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
                name: _bodyVar,
                type: currentType.type,
                arrayDepth: currentType.arrayDepth,
                defaultValue: currentType.defaultValue,
                isRequired: currentType.isRequired,
                format: currentType.format,
              ),
            ),
          );
        }
      }
      return types;
    }

    /// Parses return type for client query for OpenApi v2
    UniversalType? returnTypeV2(Map<String, dynamic> map) {
      if (!map.containsKey(_code200Var) ||
          !(map[_code200Var] as Map<String, dynamic>).containsKey(_schemaVar)) {
        return null;
      }
      final typeWithImport =
          _findType(map[_code200Var][_schemaVar] as Map<String, dynamic>);
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
      if (!map.containsKey(_parametersVar)) {
        return types;
      }
      if (map.containsKey(_consumesVar) &&
          (map[_consumesVar] as List<dynamic>).contains(_multipartVar)) {
        isMultiPart = true;
      }
      for (final rawParameter in map[_parametersVar] as List<dynamic>) {
        final isRequired =
            (rawParameter as Map<String, dynamic>)[_requiredVar] as bool?;
        final typeWithImport = _findType(
          rawParameter,
          name: rawParameter[_nameVar].toString(),
          isRequired: isRequired ?? true,
          useSchema: true,
        );
        if (typeWithImport.import != null) {
          imports.add(typeWithImport.import!);
        }
        types.add(
          UniversalRequestType(
            parameterType: HttpParameterType.values
                .firstWhere((e) => e.name == (rawParameter[_inVar].toString())),
            type: typeWithImport.type,
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
        final returnType = _version == OpenApiVersion.v2
            ? returnTypeV2(requestPath[_responsesVar] as Map<String, dynamic>)
            : returnTypeV3(requestPath[_responsesVar] as Map<String, dynamic>);
        final parameters = _version == OpenApiVersion.v2
            ? parametersV2(requestPath as Map<String, dynamic>)
            : parametersV3(requestPath as Map<String, dynamic>);
        final request = UniversalRequest(
          name: (key + path).toCamel,
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

  /// Parses data classes from 'components' of json file to universal models
  Iterable<UniversalDataClass> parseDataClasses() {
    final dataClasses = <UniversalDataClass>[];
    late final Map<String, dynamic> entities;
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

      if (value.containsKey(_propertiesVar)) {
        findParamsAndImports(value);
      } else if (value.containsKey(_enumVar)) {
        final items =
            (value[_enumVar] as List).map((e) => e.toString()).toSet();
        dataClasses.add(
          UniversalEnumClass(
            name: key,
            items: items,
            type: value[_typeVar].toString(),
            defaultValue: _defaultValueCheck(value),
          ),
        );
        return;
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
        UniversalComponentClass(
          name: key,
          imports: imports,
          parameters: allOf != null ? [] : parameters,
          allOf: allOf,
        ),
      );
    });

    dataClasses.addAll(objectClasses);

    // check for 'allOf'
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

  String _getTag(Map<String, dynamic> map) => map.containsKey(_tagsVar)
      ? (map[_tagsVar] as List<dynamic>).first.toString()
      : _defaultClientTag;

  bool _checkForBody(Map<String, dynamic> map) => map[_nameVar] == _bodyVar;

  String _formatRef(String ref) => ref.split('/').last.toPascal;

  String? _defaultValueCheck(Map<String, dynamic> map) =>
      map.containsKey(_defaultVar) ? map[_defaultVar].toString() : null;

  TypeWithImport _findType(
    Map<String, dynamic> map, {
    String? name,
    bool isRequired = true,
    bool useSchema = false,
    bool allOfObject = false,
    String? arrayName,
  }) {
    if (map.containsKey(_typeVar) && map[_typeVar] == _arrayVar) {
      final arrayType =
          _findType(map[_itemsVar] as Map<String, dynamic>, arrayName: name);
      return TypeWithImport(
        type: UniversalType(
          type: arrayType.type.type,
          format: arrayType.type.format,
          name: (dartKeywords.contains(name) ? '$name $_valueVar' : name)
              ?.toCamel,
          jsonKey: name,
          defaultValue: arrayType.type.defaultValue,
          isRequired: isRequired,
          arrayDepth: arrayType.type.arrayDepth + 1,
        ),
        import: arrayType.import,
      );
    } else if (map.containsKey(_typeVar) &&
        map[_typeVar] == _objectVar &&
        map.containsKey(_propertiesVar) &&
        (map[_propertiesVar] as Map<String, dynamic>).isNotEmpty) {
      final newName = arrayName ?? name ?? '';
      final typeWithImports = <TypeWithImport>[];
      (map[_propertiesVar] as Map<String, dynamic>).forEach((key, value) {
        typeWithImports
            .add(_findType(value as Map<String, dynamic>, name: key));
      });
      if (objectClasses
          .where((element) => element.name == '$newName $_valueVar'.toPascal)
          .isEmpty) {
        objectClasses.add(
          UniversalComponentClass(
            name: '$newName $_valueVar'.toPascal,
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
          type: '$newName $_valueVar'.toPascal,
          format:
              map.containsKey(_formatVar) ? map[_formatVar].toString() : null,
          name:
              (dartKeywords.contains(newName) ? '$newName $_valueVar' : newName)
                  .toCamel,
          jsonKey: newName,
          defaultValue: _defaultValueCheck(map),
          isRequired: isRequired,
        ),
        import: '$newName $_valueVar',
      );
    }
    final type = map.containsKey(_typeVar)
        ? map[_typeVar].toString()
        : map.containsKey(_anyOfVar) ||
                map.containsKey(_oneOfVar) ||
                allOfObject
            ? _objectVar
            : _formatRef(
                useSchema
                    ? map[_schemaVar][_refVar].toString()
                    : map[_refVar].toString(),
              );
    final import = map.containsKey(_typeVar) ||
            map.containsKey(_anyOfVar) ||
            map.containsKey(_oneOfVar) ||
            allOfObject
        ? null
        : _formatRef(
            useSchema
                ? map[_schemaVar][_refVar].toString()
                : map[_refVar].toString(),
          );
    return TypeWithImport(
      type: UniversalType(
        type: type,
        format: map.containsKey(_formatVar) ? map[_formatVar].toString() : null,
        name:
            (dartKeywords.contains(name) ? '$name $_valueVar' : name)?.toCamel,
        jsonKey: name,
        defaultValue: _defaultValueCheck(map),
        isRequired: isRequired,
      ),
      import: import,
    );
  }
}

/// Class that contains Certain [type] and imports associated with it
/// [import] are created when $ref is found while determining type
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
        print(entry.value);
      } else {
        map[entry.key.toString()] = entry.value.toString();
      }
    }
    return map;
  }
}

extension _StringToBoolX on String {
  bool toBool() => toLowerCase() == 'true';
}

/// All versions of the OpenApi that this package supports
enum OpenApiVersion { v3_1, v3, v2 }
