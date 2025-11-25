import 'package:collection/collection.dart';
import 'package:swagger_parser/src/generator/model/programming_language.dart';
import 'package:swagger_parser/src/parser/model/normalized_identifier.dart';
import 'package:swagger_parser/src/parser/swagger_parser_core.dart';
import 'package:swagger_parser/src/utils/base_utils.dart';
import 'package:swagger_parser/src/utils/type_utils.dart';

/// Provides template for generating dart DTO using freezed
String dartFreezedDtoTemplate(
  UniversalComponentClass dataClass, {
  required bool useMultipartFile,
  required bool includeIfNull,
  bool generateValidator = false,
  bool isV3 = false,
  String? fallbackUnion,
}) {
  final className = dataClass.name.toPascal;
  final discriminator = dataClass.discriminator;
  final isUndiscriminatedUnion =
      dataClass.undiscriminatedUnionVariants?.isNotEmpty ?? false;
  final isUnion = discriminator != null || isUndiscriminatedUnion;
  return '''
${ioImport(dataClass.parameters, useMultipartFile: useMultipartFile)}import 'package:freezed_annotation/freezed_annotation.dart';
${isUndiscriminatedUnion ? "import 'package:json_annotation/json_annotation.dart';\n" : ''}${dartImports(imports: _filterUnionImportsForFreezed(dataClass))}
part '${dataClass.name.toSnake}.freezed.dart';
part '${dataClass.name.toSnake}.g.dart';

${descriptionComment(dataClass.description)}@Freezed(${[
    if (discriminator != null) "unionKey: '${discriminator.propertyName}'",
    if (discriminator != null &&
        fallbackUnion != null &&
        fallbackUnion.isNotEmpty)
      "fallbackUnion: '$fallbackUnion'",
  ].join(', ')})
${_classModifier(isUnion: isUnion, isV3: isV3)}class $className with _\$$className {
${_factories(dataClass, className, useMultipartFile, includeIfNull, fallbackUnion, isUnion: isUnion)}
${_jsonFactories(className, dataClass.undiscriminatedUnionVariants)}
${generateValidator ? dataClass.parameters.map(_validationString).nonNulls.join() : ''}}
${generateValidator ? _validateMethod(className, dataClass.parameters) : ''}''';
}

String _classModifier({required bool isUnion, required bool isV3}) {
  return switch ((isUnion, isV3)) {
    (true, _) => 'sealed ',
    (false, true) => 'abstract ',
    _ => '',
  };
}

String _validateMethod(String className, Set<UniversalType> types) {
  final bodyBuffer = StringBuffer();

  for (final type in types) {
    final staticName = '$className.${type.name}';
    final nullCheckCondition = type.nullable ? '${type.name} != null &&' : '';
    final typeName = type.nullable ? '${type.name}!' : type.name;

    if (type.min != null) {
      bodyBuffer
        ..write('try {\n')
        ..write('  if ($nullCheckCondition $typeName < ${staticName}Min) {\n')
        ..write('    return false;\n')
        ..write('  }\n')
        ..write('} catch (e) {\n')
        ..write('  return false;\n')
        ..write('}\n');
    }

    if (type.max != null) {
      bodyBuffer
        ..write('try {\n')
        ..write('  if ($nullCheckCondition $typeName > ${staticName}Max) {\n')
        ..write('    return false;\n')
        ..write('  }\n')
        ..write('} catch (e) {\n')
        ..write('  return false;\n')
        ..write('}\n');
    }

    if (type.minItems != null) {
      bodyBuffer
        ..write('try {\n')
        ..write(
          '  if ($nullCheckCondition $typeName.length < ${staticName}MinItems) {\n',
        )
        ..write('    return false;\n')
        ..write('  }\n')
        ..write('} catch (e) {\n')
        ..write('  return false;\n')
        ..write('}\n');
    }

    if (type.maxItems != null) {
      bodyBuffer
        ..write('try {\n')
        ..write(
          '  if ($nullCheckCondition $typeName.length > ${staticName}MaxItems) {\n',
        )
        ..write('    return false;\n')
        ..write('  }\n')
        ..write('} catch (e) {\n')
        ..write('  return false;\n')
        ..write('}\n');
    }

    if (type.minLength != null) {
      bodyBuffer
        ..write('try {\n')
        ..write(
          '  if ($nullCheckCondition $typeName.length < ${staticName}MinLength) {\n',
        )
        ..write('    return false;\n')
        ..write('  }\n')
        ..write('} catch (e) {\n')
        ..write('  return false;\n')
        ..write('}\n');
    }

    if (type.maxLength != null) {
      bodyBuffer
        ..write('try {\n')
        ..write(
          '  if ($nullCheckCondition $typeName.length > ${staticName}MaxLength) {\n',
        )
        ..write('    return false;\n')
        ..write('  }\n')
        ..write('} catch (e) {\n')
        ..write('  return false;\n')
        ..write('}\n');
    }

    if (type.pattern != null) {
      bodyBuffer
        ..write('try {\n')
        ..write(
          '  if ($nullCheckCondition !RegExp(${staticName}Pattern).hasMatch($typeName)) {\n',
        )
        ..write('    return false;\n')
        ..write('  }\n')
        ..write('} catch (e) {\n')
        ..write('  return false;\n')
        ..write('}\n');
    }

    if (type.uniqueItems != null) {
      bodyBuffer
        ..write('try {\n')
        ..write(
          '  if ($nullCheckCondition ${staticName}UniqueItems && $typeName.toSet().length != $typeName.length) {\n',
        )
        ..write('    return false;\n')
        ..write('  }\n')
        ..write('} catch (e) {\n')
        ..write('  return false;\n')
        ..write('}\n');
    }
  }

  if (bodyBuffer.isEmpty) {
    return '';
  }

  final funcBuffer = StringBuffer()
    ..write('extension ${className}ValidationX on $className {\n')
    ..write('bool validate() {\n')
    ..write(bodyBuffer)
    ..write('  return true;\n}\n')
    ..write('}\n');

  return funcBuffer.toString();
}

String _factories(UniversalComponentClass dataClass, String className,
    bool useMultipartFile, bool includeIfNull, String? fallbackUnion,
    {required bool isUnion}) {
  if (!isUnion) {
    return '''
  const factory $className(${dataClass.parameters.isNotEmpty ? '{' : ''}${_parametersToString(dataClass.parameters, useMultipartFile, includeIfNull)}${dataClass.parameters.isNotEmpty ? '\n  }' : ''}) = _$className;''';
  }

  if (dataClass.undiscriminatedUnionVariants case final variants?
      when variants.isNotEmpty) {
    return _createFactoriesForUndiscriminatedUnion(
      className,
      variants,
      useMultipartFile,
      includeIfNull,
    );
  }

  final factories = <String>[];
  for (final discriminatorValue
      in dataClass.discriminator!.discriminatorValueToRefMapping.keys) {
    final (protectedName, _) = protectName(discriminatorValue, isMethod: true);
    final factoryName = protectedName!.toCamel;
    final discriminatorRef = dataClass
        .discriminator!.discriminatorValueToRefMapping[discriminatorValue]!;
    final factoryParameters =
        dataClass.discriminator!.refProperties[discriminatorRef]!;
    final unionItemClassName = className + discriminatorValue.toPascal;

    factories.add('''
  @FreezedUnionValue('$discriminatorValue')
  const factory $className.$factoryName(${factoryParameters.isNotEmpty ? '{' : ''}${_parametersToString(factoryParameters, useMultipartFile, includeIfNull)}${factoryParameters.isNotEmpty ? '\n  }' : ''}) = $unionItemClassName;
''');
  }

  if (fallbackUnion != null && fallbackUnion.isNotEmpty) {
    final (protectedFallbackName, _) =
        protectName(fallbackUnion, isMethod: true);
    final fallbackFactoryName = protectedFallbackName!.toCamel;
    final unionItemClassName = className + fallbackUnion.toPascal;
    factories.add('''
  const factory $className.$fallbackFactoryName() = $unionItemClassName;
''');
  }

  return factories.join('\n');
}

String _createFactoriesForUndiscriminatedUnion(
    String className,
    Map<String, Set<UniversalType>> variants,
    bool useMultipartFile,
    bool includeIfNull) {
  final factories = <String>[];
  for (final MapEntry(key: variantName, value: factoryParameters)
      in variants.entries) {
    final (protectedName, _) = protectName(variantName, isMethod: true);
    final factoryName = protectedName!.toCamel;
    final unionItemClassName = className + variantName.toPascal;
    factories.add('''
  @JsonSerializable()
  const factory $className.$factoryName(${factoryParameters.isNotEmpty ? '{' : ''}${_parametersToString(factoryParameters, useMultipartFile, includeIfNull)}${factoryParameters.isNotEmpty ? '\n  }' : ''}) = $unionItemClassName;
  ''');
  }
  return factories.join('\n');
}

String _jsonFactories(String className,
    Map<String, Set<UniversalType>>? undiscriminatedUnionVariants) {
  if (undiscriminatedUnionVariants case final unionVariants?
      when unionVariants.isNotEmpty) {
    return '${_fromJsonUndiscriminatedUnion(className)}\n'
        '${_toJsonUndiscriminatedUnion(className, unionVariants)}';
  }

  return '  \n  factory $className.fromJson(Map<String, Object?> json) => _\$${className}FromJson(json);';
}

String _fromJsonUndiscriminatedUnion(String className) => '''

  factory $className.fromJson(Map<String, Object?> json) =>
      // TODO: Deserialization must be implemented by the user, because the OpenAPI specification did not provide a discriminator.
      // Use _\$\$$className<UnionName>ImplFromJson(json) to deserialize the union <UnionName>.
      throw UnimplementedError();
''';

String _toJsonUndiscriminatedUnion(
  String className,
  Map<String, Set<UniversalType>> undiscriminatedUnionVariants,
) {
  final cases = {
    for (final variant in undiscriminatedUnionVariants.keys)
      '        $className${variant.toPascal}() => _\$\$$className${variant.toPascal}ImplToJson(this),'
  };

  return '''
  Map<String, Object?> toJson() => switch (this) {
${cases.join('\n')}
      };''';
}

String? _validationString(UniversalType type) {
  final sb = StringBuffer();
  if (type.min != null) {
    final numType = type.type == 'integer' ? int : double;
    final min = numType == int ? type.min?.toInt() : type.min;
    sb.write('  static const $numType ${type.name}Min = $min;\n');
  }

  if (type.max != null) {
    final numType = type.type == 'integer' ? int : double;
    final max = numType == int ? type.max?.toInt() : type.max;
    sb.write('  static const $numType ${type.name}Max = $max;\n');
  }

  if (type.minItems != null) {
    sb.write('  static const int ${type.name}MinItems = ${type.minItems};\n');
  }

  if (type.maxItems != null) {
    sb.write('  static const int ${type.name}MaxItems = ${type.maxItems};\n');
  }

  if (type.minLength != null) {
    sb.write('  static const int ${type.name}MinLength = ${type.minLength};\n');
  }

  if (type.maxLength != null) {
    sb.write('  static const int ${type.name}MaxLength = ${type.maxLength};\n');
  }

  if (type.pattern != null) {
    sb.write(
      '  static const String ${type.name}Pattern = r"${type.pattern}";\n',
    );
  }

  if (type.uniqueItems != null) {
    sb.write(
      '  static const bool ${type.name}UniqueItems = ${type.uniqueItems};\n',
    );
  }

  return sb.isEmpty ? null : sb.toString();
}

String _parametersToString(
    Set<UniversalType> parameters, bool useMultipartFile, bool includeIfNull) {
  final sortedByRequired = Set<UniversalType>.from(
    parameters.sorted((a, b) => a.compareTo(b)),
  );
  return sortedByRequired
      .mapIndexed(
        (i, e) =>
            '\n${i != 0 && (e.description?.isNotEmpty ?? false) ? '\n' : ''}${descriptionComment(e.description, tab: '    ')}'
            '${_jsonKey(e, includeIfNull)}    ${_required(e)}'
            '${e.toSuitableType(ProgrammingLanguage.dart, useMultipartFile: useMultipartFile)} ${e.name},',
      )
      .join();
}

String _jsonKey(UniversalType t, bool includeIfNull) {
  final sb = StringBuffer();
  final jsonKeyParams = <String, String?>{};

  if (includeIfNull) {
    if (t.isRequired && (t.nullable || t.referencedNullable)) {
      jsonKeyParams['includeIfNull'] = 'true';
    } else if (!t.isRequired && (t.nullable || t.referencedNullable)) {
      jsonKeyParams['includeIfNull'] = 'false';
    }
  }

  if (t.jsonKey != null && t.name != t.jsonKey) {
    jsonKeyParams['name'] = "'${protectJsonKey(t.jsonKey)}'";
  }

  if (jsonKeyParams.isNotEmpty) {
    sb.write(
        "    @JsonKey(${jsonKeyParams.entries.map((e) => '${e.key}: ${e.value}').join(',')})\n");
  }

  if (t.defaultValue != null) {
    sb.write('    @Default(${_defaultValue(t)})\n');
  }

  if (t.deprecated) {
    sb.write("    @Deprecated('This is marked as deprecated')\n");
  }

  return sb.toString();
}

/// return required if isRequired
String _required(UniversalType t) =>
    t.isRequired && t.defaultValue == null ? 'required ' : '';

/// return defaultValue if have
String _defaultValue(UniversalType t) =>
    '${t.enumType != null ? '${t.type}.${protectDefaultEnum(t.defaultValue)?.toCamel}' : protectDefaultValue(t.defaultValue, type: t.type)}';

/// Filters out union imports for freezed classes to avoid circular dependencies
Set<String> _filterUnionImportsForFreezed(UniversalComponentClass dataClass) {
  final filteredImports = <String>{};

  // If this class has a discriminatorValue, it means it's part of a union and
  // shouldn't import the union file (to avoid circular dependencies)
  final shouldFilterUnionImports = dataClass.discriminatorValue != null;

  for (final import in dataClass.imports) {
    // If this is a model that's part of a union, skip union imports
    // Otherwise, allow all imports (including union imports for classes that use unions)
    final shouldSkip =
        shouldFilterUnionImports && import.toLowerCase().contains('union');

    if (!shouldSkip) {
      filteredImports.add(import);
    }
  }

  return filteredImports;
}
