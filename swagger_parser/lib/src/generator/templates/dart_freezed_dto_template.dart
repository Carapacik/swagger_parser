import 'package:collection/collection.dart';

import '../../parser/swagger_parser_core.dart';
import '../../parser/utils/case_utils.dart';
import '../../utils/base_utils.dart';
import '../../utils/type_utils.dart';
import '../model/programming_language.dart';

/// Provides template for generating dart DTO using freezed
String dartFreezedDtoTemplate(
  UniversalComponentClass dataClass, {
  required bool markFileAsGenerated,
}) {
  final className = dataClass.name.toPascal;
  return '''
${generatedFileComment(
    markFileAsGenerated: markFileAsGenerated,
  )}${ioImport(dataClass)}import 'package:freezed_annotation/freezed_annotation.dart';
${dartImports(imports: dataClass.imports)}
part '${dataClass.name.toSnake}.freezed.dart';
part '${dataClass.name.toSnake}.g.dart';

${descriptionComment(dataClass.description)}@Freezed()
class $className with _\$$className {
  const factory $className(${dataClass.parameters.isNotEmpty ? '{' : ''}${_parametersToString(
    dataClass.parameters,
  )}${dataClass.parameters.isNotEmpty ? '\n  }' : ''}) = _$className;
  \n  factory $className.fromJson(Map<String, Object?> json) => _\$${className}FromJson(json);
${dataClass.parameters.map(_validationString).nonNulls.join()}}
${_validateMethod(className, dataClass.parameters)}''';
}

String _validateMethod(String className, List<UniversalType> types) {
  final bodyBuffer = StringBuffer();

  for (final type in types) {
    if (type.min != null) {
      bodyBuffer
        ..write('try {\n')
        ..write('  if (${type.name} < ${type.name}Min) {\n')
        ..write('    return false;\n')
        ..write('  }\n')
        ..write('} catch (e) {\n')
        ..write('  return false;\n')
        ..write('}\n');
    }

    if (type.max != null) {
      bodyBuffer
        ..write('try {\n')
        ..write('  if (${type.name} > ${type.name}Max) {\n')
        ..write('    return false;\n')
        ..write('  }\n')
        ..write('} catch (e) {\n')
        ..write('  return false;\n')
        ..write('}\n');
    }

    if (type.minItems != null) {
      bodyBuffer
        ..write('try {\n')
        ..write('  if (${type.name}.length < ${type.name}MinItems) {\n')
        ..write('    return false;\n')
        ..write('  }\n')
        ..write('} catch (e) {\n')
        ..write('  return false;\n')
        ..write('}\n');
    }

    if (type.maxItems != null) {
      bodyBuffer
        ..write('try {\n')
        ..write('  if (${type.name}.length > ${type.name}MaxItems) {\n')
        ..write('    return false;\n')
        ..write('  }\n')
        ..write('} catch (e) {\n')
        ..write('  return false;\n')
        ..write('}\n');
    }

    if (type.minLength != null) {
      bodyBuffer
        ..write('try {\n')
        ..write('  if (${type.name}.length < ${type.name}MinLength) {\n')
        ..write('    return false;\n')
        ..write('  }\n')
        ..write('} catch (e) {\n')
        ..write('  return false;\n')
        ..write('}\n');
    }

    if (type.maxLength != null) {
      bodyBuffer
        ..write('try {\n')
        ..write('  if (${type.name}.length > ${type.name}MaxLength) {\n')
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
            '  if (!RegExp(${type.name}Pattern).hasMatch(${type.name})) {\n')
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
            '  if (${type.name}UniqueItems && ${type.name}.toSet().length != ${type.name}.length) {\n')
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

String? _validationString(UniversalType type) {
  final sb = StringBuffer();
  if (type.min != null) {
    sb.write('  static const double ${type.name}Min = ${type.min};\n');
  }

  if (type.max != null) {
    sb.write('  static const double ${type.name}Max = ${type.max};\n');
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
        '  static const String ${type.name}Pattern = r"${type.pattern}";\n');
  }

  if (type.uniqueItems != null) {
    sb.write(
        '  static const bool ${type.name}UniqueItems = ${type.uniqueItems};\n');
  }

  return sb.isEmpty ? null : sb.toString();
}

String _parametersToString(List<UniversalType> parameters) {
  final sortedByRequired =
      List<UniversalType>.from(parameters.sorted((a, b) => a.compareTo(b)));
  return sortedByRequired
      .mapIndexed(
        (i, e) =>
            '\n${i != 0 && (e.description?.isNotEmpty ?? false) ? '\n' : ''}${descriptionComment(e.description, tab: '    ')}'
            '${_jsonKey(e)}    ${_required(e)}'
            '${e.toSuitableType(ProgrammingLanguage.dart)} ${e.name},',
      )
      .join();
}

String _jsonKey(UniversalType t) {
  final sb = StringBuffer();
  if ((t.jsonKey == null || t.name == t.jsonKey) && t.defaultValue == null) {
    return '';
  }
  if (t.jsonKey != null && t.name != t.jsonKey) {
    sb.write("    @JsonKey(name: '${protectJsonKey(t.jsonKey)}')\n");
  }
  if (t.defaultValue != null) {
    sb.write('    @Default(${_defaultValue(t)})\n');
  }

  return sb.toString();
}

/// return required if isRequired
String _required(UniversalType t) =>
    t.isRequired && t.defaultValue == null ? 'required ' : '';

/// return defaultValue if have
String _defaultValue(UniversalType t) =>
    '${t.enumType != null ? '${t.type}.${protectDefaultEnum(t.defaultValue)?.toCamel}' : protectDefaultValue(
        t.defaultValue,
        type: t.type,
      )}';
