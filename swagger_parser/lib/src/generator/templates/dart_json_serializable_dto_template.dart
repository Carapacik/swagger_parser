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
  String? fallbackUnion,
}) {
  final className = dataClass.name.toPascal;
  
  // Check if this is a union type
  final isUnion = dataClass.discriminator != null || 
                  (dataClass.undiscriminatedUnionVariants?.isNotEmpty ?? false);
  
  if (isUnion) {
    return _generateUnionTemplate(dataClass, className, useMultipartFile, fallbackUnion);
  }
  
  return '''
${ioImport(dataClass.parameters, useMultipartFile: useMultipartFile)}import 'package:json_annotation/json_annotation.dart';
${dartImports(imports: _filterUnionImportsForNonUnion(dataClass))}
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

String _generateUnionTemplate(UniversalComponentClass dataClass, String className, bool useMultipartFile, String? fallbackUnion) {
  // Check if this is a discriminated union
  if (dataClass.discriminator != null) {
    return _generateDiscriminatedUnionTemplate(dataClass, className, useMultipartFile, fallbackUnion);
  }
  
  // Handle undiscriminated unions
  if (dataClass.undiscriminatedUnionVariants?.isNotEmpty ?? false) {
    return _generateUndiscriminatedUnionTemplate(dataClass, className, useMultipartFile);
  }
  
  // Fallback to simple map wrapper for unknown union types
  return _generateSimpleMapWrapper(dataClass, className);
}

String _generateDiscriminatedUnionTemplate(UniversalComponentClass dataClass, String className, bool useMultipartFile, String? fallbackUnion) {
  final discriminator = dataClass.discriminator!;
  final discriminatorKey = discriminator.propertyName;
  final variants = discriminator.discriminatorValueToRefMapping;
  
  // Generate sealed base class
  final baseClass = '''
@JsonSerializable(createFactory: false)
sealed class $className {
  const $className();
  
  static $className fromJson(Map<String, dynamic> json) {
    return _${className}Helper._tryDeserialize(json);
  }
  
  Map<String, dynamic> toJson();
}''';

  // Generate discriminator helper
  final helper = _generateDiscriminatorHelper(className, discriminator, fallbackUnion);
  
  // Generate wrapper classes
  final wrappers = _generateDiscriminatedWrapperClasses(className, discriminator, useMultipartFile, fallbackUnion);
  
  return '''
import 'package:json_annotation/json_annotation.dart';
${dartImports(imports: _filterUnionImports(dataClass))}

part '${dataClass.name.toSnake}.g.dart';

${descriptionComment(dataClass.description)}$baseClass

$helper

$wrappers
''';
}

String _generateUndiscriminatedUnionTemplate(UniversalComponentClass dataClass, String className, bool useMultipartFile) {
  final variants = dataClass.undiscriminatedUnionVariants!;
  
  // Generate sealed base class
  final baseClass = '''
@JsonSerializable(createFactory: false)
sealed class $className {
  const $className();
  
  static $className fromJson(Map<String, dynamic> json) {
    return _${className}Helper._tryDeserialize(json);
  }
  
  Map<String, dynamic> toJson();
}''';

  // Generate try-catch helper
  final helper = _generateUndiscriminatedHelper(className, variants);
  
  // Generate wrapper classes
  final wrappers = _generateUndiscriminatedWrapperClasses(className, variants, useMultipartFile);
  
  return '''
import 'package:json_annotation/json_annotation.dart';
${dartImports(imports: _filterUnionImports(dataClass))}

part '${dataClass.name.toSnake}.g.dart';

${descriptionComment(dataClass.description)}$baseClass

$helper

$wrappers
''';
}

String _generateSimpleMapWrapper(UniversalComponentClass dataClass, String className) {
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
${dartImports(imports: _filterUnionImports(dataClass))}
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

String _generateDiscriminatorHelper(String className, Discriminator discriminator, String? fallbackUnion) {
  final discriminatorKey = discriminator.propertyName;
  final variants = discriminator.discriminatorValueToRefMapping;
  
  // Generate if-else chain
  final conditions = variants.entries.map((entry) {
    final discriminatorValue = entry.key;
    final variantName = entry.value;
    final wrapperClassName = '$className${variantName.toPascal}';
    
    return '''    if (json['$discriminatorKey'] == '$discriminatorValue') {
      return $wrapperClassName.fromJson(json);
    }''';
  }).toList();
  
  final ifElseChain = conditions.join(' else ');
  
  // Generate fallback handling
  final fallbackHandling = fallbackUnion != null && fallbackUnion.isNotEmpty
      ? 'return $className${fallbackUnion.toPascal}.fromJson(json);'
      : 'throw FormatException(\'Unknown discriminator value "\${json[\'$discriminatorKey\']}" for $className\');';
  
  return '''
class _${className}Helper {
  static $className _tryDeserialize(Map<String, dynamic> json) {
$ifElseChain else {
      $fallbackHandling
    }
  }
}''';
}

String _generateUndiscriminatedHelper(String className, Map<String, Set<UniversalType>> variants) {
  // Generate try-catch blocks
  final tryBlocks = variants.keys.map((variantName) {
    final wrapperClassName = '$className${variantName.toPascal}';
    return '''    try {
      return $wrapperClassName.fromJson(json);
    } catch (_) {}''';
  }).join('\n');
  
  return '''
class _${className}Helper {
  static $className _tryDeserialize(Map<String, dynamic> json) {
$tryBlocks

    throw FormatException('Could not determine the correct type for $className from: \$json');
  }
}''';
}

String _generateDiscriminatedWrapperClasses(String className, Discriminator discriminator, bool useMultipartFile, String? fallbackUnion) {
  final wrappers = discriminator.discriminatorValueToRefMapping.entries.map((entry) {
    final discriminatorValue = entry.key;
    final variantName = entry.value;
    final wrapperClassName = '$className${variantName.toPascal}';
    final properties = discriminator.refProperties[variantName] ?? <UniversalType>{};
    
    // Generate direct properties
    final directProperties = properties.map((prop) => 
      '  @override\n  final ${prop.toSuitableType(ProgrammingLanguage.dart, useMultipartFile: useMultipartFile)} ${prop.name};'
    ).join('\n');
    
    // Generate constructor parameters
    final constructorParams = properties.map((prop) => 
      '    required this.${prop.name},'
    ).join('\n');
    
    return '''
@JsonSerializable()
class $wrapperClassName extends $className implements $variantName {
$directProperties

  const $wrapperClassName({
$constructorParams
  });
  
  factory $wrapperClassName.fromJson(Map<String, dynamic> json) =>
      _\$${wrapperClassName}FromJson(json);
      
  @override
  Map<String, dynamic> toJson() => _\$${wrapperClassName}ToJson(this);
}''';
  }).join('\n');
  
  // Add fallback wrapper class if configured
  final fallbackWrapper = _generateFallbackWrapper(className, fallbackUnion);
  
  return wrappers + fallbackWrapper;
}

String _generateUndiscriminatedWrapperClasses(String className, Map<String, Set<UniversalType>> variants, bool useMultipartFile) {
  return variants.entries.map((entry) {
    final variantName = entry.key;
    final properties = entry.value;
    final wrapperClassName = '$className${variantName.toPascal}';
    
    // Generate direct properties
    final directProperties = properties.map((prop) => 
      '  @override\n  final ${prop.toSuitableType(ProgrammingLanguage.dart, useMultipartFile: useMultipartFile)} ${prop.name};'
    ).join('\n');
    
    // Generate constructor parameters
    final constructorParams = properties.map((prop) => 
      '    required this.${prop.name},'
    ).join('\n');
    
    return '''
@JsonSerializable()
class $wrapperClassName extends $className implements $variantName {
$directProperties

  const $wrapperClassName({
$constructorParams
  });
  
  factory $wrapperClassName.fromJson(Map<String, dynamic> json) =>
      _\$${wrapperClassName}FromJson(json);
      
  @override
  Map<String, dynamic> toJson() => _\$${wrapperClassName}ToJson(this);
}''';
  }).join('\n');
}

String _generateFallbackWrapper(String className, String? fallbackUnion) {
  if (fallbackUnion == null || fallbackUnion.isEmpty) {
    return '';
  }
  
  final fallbackClassName = '$className${fallbackUnion.toPascal}';
  
  return '''

@JsonSerializable()
class $fallbackClassName extends $className {
  final Map<String, dynamic> _json;
  
  const $fallbackClassName(this._json);
  
  /// Access raw JSON data for unknown union variant
  Map<String, dynamic> get json => _json;
  
  factory $fallbackClassName.fromJson(Map<String, dynamic> json) => 
      $fallbackClassName(json);
      
  @override
  Map<String, dynamic> toJson() => _json;
}''';
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

/// Filters out union imports for json_serializable since they're not needed
Set<String> _filterUnionImports(UniversalComponentClass dataClass) {
  final filteredImports = <String>{};
  
  // Get list of interface names that wrapper classes implement
  final interfaceNames = <String>{};
  
  // For discriminated unions
  if (dataClass.discriminator != null) {
    interfaceNames.addAll(dataClass.discriminator!.discriminatorValueToRefMapping.values);
  }
  
  // For undiscriminated unions
  if (dataClass.undiscriminatedUnionVariants != null) {
    interfaceNames.addAll(dataClass.undiscriminatedUnionVariants!.keys);
  }
  
  for (final import in dataClass.imports) {
    // Skip imports for interface classes that wrapper classes implement
    // Also skip any import that contains 'Union' - these are union types
    final shouldSkip = interfaceNames.contains(import) || import.toLowerCase().contains('union');
    
    if (!shouldSkip) {
      filteredImports.add(import);
    }
  }
  
  return filteredImports;
}

/// Filters out union imports for regular (non-union) classes
Set<String> _filterUnionImportsForNonUnion(UniversalComponentClass dataClass) {
  final filteredImports = <String>{};
  
  // If this class has a discriminatorValue, it means it's part of a union and 
  // shouldn't import the union file (to avoid circular dependencies)
  final shouldFilterUnionImports = dataClass.discriminatorValue != null;
  
  for (final import in dataClass.imports) {
    // If this is a model that's part of a union, skip union imports
    // Otherwise, allow all imports (including union imports for classes that use unions)
    final shouldSkip = shouldFilterUnionImports && import.toLowerCase().contains('union');
    
    if (!shouldSkip) {
      filteredImports.add(import);
    }
  }
  
  return filteredImports;
}
