import 'package:collection/collection.dart';

import '../../parser/model/normalized_identifier.dart';
import '../../parser/swagger_parser_core.dart';
import '../../utils/base_utils.dart';
import '../../utils/type_utils.dart';
import '../model/programming_language.dart';

/// Provides template for generating dart DTO using JSON serializable
String dartJsonSerializableDtoTemplate(
  UniversalComponentClass dataClass, {
  required bool markFileAsGenerated,
  required bool useMultipartFile,
}) {
  final className = dataClass.name.toPascal;
  
  // Check if this is a union type
  final isUnion = dataClass.discriminator != null || 
                  (dataClass.undiscriminatedUnionVariants?.isNotEmpty ?? false);
  
  if (isUnion) {
    return _generateUnionTemplate(dataClass, className);
  }
  
  return '''
${ioImport(dataClass.parameters, useMultipartFile: useMultipartFile)}import 'package:json_annotation/json_annotation.dart';
${dartImports(imports: dataClass.imports)}
part '${dataClass.name.toSnake}.g.dart';

${descriptionComment(dataClass.description)}@JsonSerializable()
class $className {
  const $className(${dataClass.parameters.isNotEmpty ? '{' : ''}${_parametersInConstructor(dataClass.parameters)}${dataClass.parameters.isNotEmpty ? '\n  }' : ''});
  
  factory $className.fromJson(Map<String, Object?> json) => _\$${className}FromJson(json);
  ${_parametersInClass(dataClass.parameters, useMultipartFile)}${dataClass.parameters.isNotEmpty ? '\n' : ''}
  Map<String, Object?> toJson() => _\$${className}ToJson(this);
}
''';
}

String _generateUnionTemplate(UniversalComponentClass dataClass, String className) {
  // Generate list of possible variants for documentation
  final variants = <String>[];
  
  if (dataClass.discriminator != null) {
    variants.addAll(dataClass.discriminator!.discriminatorValueToRefMapping.values);
  }
  
  if (dataClass.undiscriminatedUnionVariants != null) {
    variants.addAll(dataClass.undiscriminatedUnionVariants!.keys);
  }
  
  final variantsList = variants.isNotEmpty 
    ? variants.join(', ')
    : 'multiple possible types';
  
  final discriminatorComment = dataClass.discriminator != null 
    ? "\n  /// Check the '${dataClass.discriminator!.propertyName}' field to determine which variant."
    : '\n  /// Use try-catch or manual inspection to determine the actual type.';
  
  return '''
import 'package:json_annotation/json_annotation.dart';
${dartImports(imports: dataClass.imports)}
part '${dataClass.name.toSnake}.g.dart';

${descriptionComment(dataClass.description)}@JsonSerializable()
class $className {
  const $className(this.data);
  
  /// Raw JSON data for union type.
  /// This can be one of: $variantsList$discriminatorComment
  final Map<String, dynamic> data;
  
  factory $className.fromJson(Map<String, dynamic> json) => $className(json);
  
  Map<String, dynamic> toJson() => data;
}
''';
}

String _parametersInClass(
        Set<UniversalType> parameters, bool useMultipartFile,) =>
    parameters
        .mapIndexed(
          (i, e) =>
              '\n${i != 0 && (e.description?.isNotEmpty ?? false) ? '\n' : ''}${descriptionComment(e.description, tab: '  ')}'
              '${_jsonKey(e)}  final ${e.toSuitableType(ProgrammingLanguage.dart, useMultipartFile: useMultipartFile)} ${e.name};',
        )
        .join();

String _parametersInConstructor(Set<UniversalType> parameters) {
  final sortedByRequired = Set<UniversalType>.from(
    parameters.sorted((a, b) => a.compareTo(b)),
  );
  return sortedByRequired
      .map((e) => '\n    ${_required(e)}this.${e.name}${_defaultValue(e)},')
      .join();
}

/// if jsonKey is different from the name
String _jsonKey(UniversalType t) {
  if (t.jsonKey == null || t.name == t.jsonKey) {
    return '';
  }
  return "  @JsonKey(name: '${protectJsonKey(t.jsonKey)}')\n";
}

/// return required if isRequired
String _required(UniversalType t) =>
    t.isRequired && t.defaultValue == null ? 'required ' : '';

/// return defaultValue if have
String _defaultValue(UniversalType t) => t.defaultValue != null
    ? ' = '
        '${t.wrappingCollections.isNotEmpty ? 'const ' : ''}'
        '${t.enumType != null ? '${t.type}.${protectDefaultEnum(t.defaultValue)?.toCamel}' : protectDefaultValue(t.defaultValue, type: t.type)}'
    : '';
