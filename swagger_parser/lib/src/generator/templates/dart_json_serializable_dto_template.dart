import 'package:collection/collection.dart';
import 'package:swagger_parser/src/generator/model/programming_language.dart';
import 'package:swagger_parser/src/parser/model/normalized_identifier.dart';
import 'package:swagger_parser/src/parser/swagger_parser_core.dart';
import 'package:swagger_parser/src/utils/base_utils.dart';
import 'package:swagger_parser/src/utils/type_utils.dart';

/// Provides template for generating dart DTO using JSON serializable
String dartJsonSerializableDtoTemplate(
  UniversalComponentClass dataClass, {
  required bool markFileAsGenerated,
  required bool useMultipartFile,
  required bool includeIfNull,
  String? fallbackUnion,
}) {
  final originalClassName = dataClass.name.toPascal;

  // Check if this is a union type
  final isUnion = dataClass.discriminator != null ||
      (dataClass.undiscriminatedUnionVariants?.isNotEmpty ?? false);

  final className =
      isUnion ? _applySealedNaming(originalClassName) : originalClassName;
  final classNameSnake = className.toSnake;

  if (isUnion) {
    return _generateUnionTemplate(
        dataClass, className, useMultipartFile, includeIfNull, fallbackUnion);
  }

  return '''
${ioImport(dataClass.parameters, useMultipartFile: useMultipartFile)}import 'package:json_annotation/json_annotation.dart';
${dartImports(imports: _filterUnionImportsForNonUnion(dataClass))}
part '$classNameSnake.g.dart';

${descriptionComment(dataClass.description)}@JsonSerializable()
class $className {
  const $className(${dataClass.parameters.isNotEmpty ? '{' : ''}${_parametersInConstructor(dataClass.parameters, includeIfNull)}${dataClass.parameters.isNotEmpty ? '\n  }' : ''});
  
  factory $className.fromJson(Map<String, Object?> json) => _\$${className}FromJson(json);
  ${_parametersInClass(dataClass.parameters, useMultipartFile, includeIfNull)}${dataClass.parameters.isNotEmpty ? '\n' : ''}
  Map<String, Object?> toJson() => _\$${className}ToJson(this);
}
''';
}

String _generateUnionTemplate(
    UniversalComponentClass dataClass,
    String className,
    bool useMultipartFile,
    bool includeIfNull,
    String? fallbackUnion) {
  // Check if this is a discriminated union
  if (dataClass.discriminator != null) {
    return _generateDiscriminatedUnionTemplate(
        dataClass, className, useMultipartFile, includeIfNull, fallbackUnion);
  }

  // Handle undiscriminated unions
  if (dataClass.undiscriminatedUnionVariants?.isNotEmpty ?? false) {
    return _generateUndiscriminatedUnionTemplate(
        dataClass, className, useMultipartFile, includeIfNull, fallbackUnion);
  }

  // Fallback to simple map wrapper for unknown union types
  return _generateSimpleMapWrapper(dataClass, className);
}

String _generateDiscriminatedUnionTemplate(
  UniversalComponentClass dataClass,
  String className,
  bool useMultipartFile,
  bool includeIfNull,
  String? fallbackUnion,
) {
  final discriminator = dataClass.discriminator!;

  // Generate sealed base class
  final baseClass = '''
@JsonSerializable(createFactory: false)
sealed class $className {
  const $className();
  
  factory $className.fromJson(Map<String, dynamic> json) =>
      ${_deserializerExtensionName(className)}.tryDeserialize(json);
  
  Map<String, dynamic> toJson();
}''';

  // Generate wrapper classes first (they are referenced by the extension)
  final wrappers = _generateDiscriminatedWrapperClasses(
      className, discriminator, useMultipartFile, includeIfNull, fallbackUnion);

  // Generate public extension-based deserializer
  final deserializerExtension =
      _generateDiscriminatorExtension(className, discriminator, fallbackUnion);

  return '''
import 'package:json_annotation/json_annotation.dart';
${dartImports(imports: _importsForDiscriminatedUnion(dataClass, fallbackUnion))}

part '${className.toSnake}.g.dart';

${descriptionComment(dataClass.description)}$baseClass

$deserializerExtension

$wrappers
''';
}

String _generateUndiscriminatedUnionTemplate(UniversalComponentClass dataClass,
    String className, bool useMultipartFile, bool includeIfNull,
    [String? fallbackUnion]) {
  final variants = dataClass.undiscriminatedUnionVariants!;

  // Generate sealed base class
  final baseClass = '''
@JsonSerializable(createFactory: false)
sealed class $className {
  const $className();
  
  factory $className.fromJson(Map<String, dynamic> json) =>
      ${_deserializerExtensionName(className)}.tryDeserialize(json);
  
  Map<String, dynamic> toJson();
}''';

  // Generate wrapper classes first (they are referenced by the extension)
  final wrappers = _generateUndiscriminatedWrapperClasses(
      className, variants, useMultipartFile, includeIfNull, fallbackUnion);

  // Generate extension-based tryDeserialize helper for external usage
  final helperExtension =
      _generateUndiscriminatedExtension(className, variants, fallbackUnion);

  return '''
import 'package:json_annotation/json_annotation.dart';
${dartImports(imports: _importsForUndiscriminatedUnion(dataClass))}

part '${className.toSnake}.g.dart';

${descriptionComment(dataClass.description)}$baseClass

$helperExtension

$wrappers
''';
}

String _generateSimpleMapWrapper(
    UniversalComponentClass dataClass, String className) {
  // Generate list of possible variants for documentation
  final variants = <String>[];

  if (dataClass.discriminator != null) {
    variants
        .addAll(dataClass.discriminator!.discriminatorValueToRefMapping.values);
  }

  if (dataClass.undiscriminatedUnionVariants != null) {
    variants.addAll(dataClass.undiscriminatedUnionVariants!.keys);
  }

  final variantsList =
      variants.isNotEmpty ? variants.join(', ') : 'multiple possible types';

  final discriminatorComment = dataClass.discriminator != null
      ? "\n  /// Check the '${dataClass.discriminator!.propertyName}' field to determine which variant."
      : '\n  /// Use try-catch or manual inspection to determine the actual type.';

  return '''
import 'package:json_annotation/json_annotation.dart';
${dartImports(imports: _filterUnionImports(dataClass))}
part '${className.toSnake}.g.dart';

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

String _generateDiscriminatorExtension(
    String className, Discriminator discriminator, String? fallbackUnion) {
  final discriminatorKey = discriminator.propertyName;
  final variants = discriminator.discriminatorValueToRefMapping;

  // Build default mapping literal: { WrapperType: 'DiscriminatorValue', ... }
  final mappingEntries = variants.entries.map((entry) {
    final variantName = entry.value;
    final discriminatorValue = entry.key;
    final wrapperClassName = '$className${variantName.toPascal}';
    return "      $wrapperClassName: '$discriminatorValue',";
  }).join('\n');

  // Build switch cases using guarded mapping
  final switchCases = variants.entries.map((entry) {
    final variantName = entry.value;
    final wrapperClassName = '$className${variantName.toPascal}';
    return '''      _ when value == effective[$wrapperClassName] => $wrapperClassName.fromJson(json),''';
  }).join('\n');

  final fallbackCase = (fallbackUnion != null && fallbackUnion.isNotEmpty)
      ? '      _ => $className${fallbackUnion.toPascal}.fromJson(json),'
      : "      _ => throw FormatException('Unknown discriminator value \"\${json[key]}\" for $className'),";

  return '''
extension ${_deserializerExtensionName(className)} on $className {
  static $className tryDeserialize(
    Map<String, dynamic> json, {
    String key = '$discriminatorKey',
    Map<Type, Object?>? mapping,
  }) {
    final mappingFallback = const <Type, Object?>{
$mappingEntries
    };
    final value = json[key];
    final effective = mapping ?? mappingFallback;
    return switch (value) {
$switchCases
$fallbackCase
    };
  }
}''';
}

String _generateUndiscriminatedExtension(
    String className, Map<String, Set<UniversalType>> variants,
    [String? fallbackUnion]) {
  // For undiscriminated, we have no fixed key; allow override (default to '')
  // and simply try each wrapper via switch with pattern on a user-provided key
  // If key is empty, just try-catch sequentially but keep API consistent.

  // Build sequential try-catch body (Dart switch cannot elegantly express try order)
  final tryBlocks = variants.keys.map((variantName) {
    final wrapperClassName = '$className${variantName.toPascal}';
    return '''
${' ' * 4}try {
${' ' * 6}return $wrapperClassName.fromJson(json);
${' ' * 4}} catch (_) {}''';
  }).join('\n');

  final fallbackTry = (fallbackUnion != null && fallbackUnion.isNotEmpty)
      ? '''
${' ' * 4}try {
${' ' * 6}return $className${fallbackUnion.toPascal}.fromJson(json);
${' ' * 4}} catch (_) {}'''
      : '';

  return '''
extension ${_deserializerExtensionName(className)} on $className {
  static $className tryDeserialize(Map<String, dynamic> json) {
$tryBlocks
$fallbackTry

    throw FormatException('Could not determine the correct type for $className from: \$json');
  }
}''';
}

String _generateDiscriminatedWrapperClasses(
    String className,
    Discriminator discriminator,
    bool useMultipartFile,
    bool includeIfNull,
    String? fallbackUnion) {
  final wrappers =
      discriminator.discriminatorValueToRefMapping.entries.map((entry) {
    final variantName = entry.value;
    final wrapperClassName = '$className${variantName.toPascal}';
    final properties =
        discriminator.refProperties[variantName] ?? <UniversalType>{};

    // Generate direct properties
    final directProperties = properties
        .map((prop) =>
            '  @override\n  final ${_renameUnionTypes(prop.toSuitableType(ProgrammingLanguage.dart, useMultipartFile: useMultipartFile))} ${prop.name};')
        .join('\n');

    // Generate constructor parameters
    final constructorParams =
        properties.map((prop) => '    required this.${prop.name},').join('\n');

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

String _generateUndiscriminatedWrapperClasses(
  String className,
  Map<String, Set<UniversalType>> variants,
  bool useMultipartFile,
  bool includeIfNull, [
  String? fallbackUnion,
]) {
  final wrappers = variants.entries.map((entry) {
    final variantName = entry.key;
    final properties = entry.value;
    final wrapperClassName = '$className${variantName.toPascal}';

    // Generate direct properties
    final directProperties = properties
        .map((prop) =>
            '  @override\n  final ${_renameUnionTypes(prop.toSuitableType(ProgrammingLanguage.dart, useMultipartFile: useMultipartFile))} ${prop.name};')
        .join('\n');

    // Generate constructor parameters
    final constructorParams =
        properties.map((prop) => '    required this.${prop.name},').join('\n');

    // Inline synthesized variants (variantX) should not implement any interface
    final isInline = variantName.toLowerCase().startsWith('variant');
    final implementsClause = isInline ? '' : ' implements $variantName';

    return '''
@JsonSerializable()
class $wrapperClassName extends $className$implementsClause {
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

  final fallbackWrapper = _generateFallbackWrapper(className, fallbackUnion);
  return wrappers + fallbackWrapper;
}

String _generateFallbackWrapper(String className, String? fallbackUnion) {
  if (fallbackUnion == null || fallbackUnion.isEmpty) {
    return '';
  }

  final fallbackClassName = '$className${fallbackUnion.toPascal}';

  return '''

@JsonSerializable(createFactory: false)
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
  Set<UniversalType> parameters,
  bool useMultipartFile,
  bool includeIfNull,
) =>
    parameters
        .mapIndexed(
          (i, e) =>
              '\n${i != 0 && (e.description?.isNotEmpty ?? false) ? '\n' : ''}${descriptionComment(e.description, tab: '  ')}'
              '${_jsonKey(e, includeIfNull)}  final ${_renameUnionTypes(e.toSuitableType(ProgrammingLanguage.dart, useMultipartFile: useMultipartFile))} ${e.name};',
        )
        .join();

String _parametersInConstructor(
    Set<UniversalType> parameters, bool includeIfNull) {
  final sortedByRequired = Set<UniversalType>.from(
    parameters.sorted((a, b) => a.compareTo(b)),
  );
  return sortedByRequired
      .map((e) => '\n    ${_required(e)}this.${e.name}${_defaultValue(e)},')
      .join();
}

/// if jsonKey is different from the name
String _jsonKey(UniversalType t, bool includeIfNull) {
  final buffer = StringBuffer();

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
    buffer.write(
        "  @JsonKey(${jsonKeyParams.entries.map((e) => '${e.key}: ${e.value}').join(',')})\n");
  }

  return buffer.toString();
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

/// Filters imports for json_serializable union files
///
/// We MUST include interface model imports (e.g., `Cat`, `Dog`, `Human`) so
/// that `implements <Interface>` resolves. Only exclude imports that are
/// union files themselves to avoid circular dependencies.
Set<String> _filterUnionImports(UniversalComponentClass dataClass) {
  final filteredImports = <String>{};

  for (final import in dataClass.imports) {
    // Exclude union files to avoid circular dependencies
    final shouldSkip = import.toLowerCase().contains('union');

    if (!shouldSkip) {
      filteredImports.add(import);
    }
  }

  return filteredImports.map(_applySealedNamingToImport).toSet();
}

/// Imports for discriminated unions: include variant interface classes and their enums.
/// The parser already put both variant interfaces (e.g., `Cat`, `Dog`) and their
/// enum dependencies (e.g., `CatType`) into `imports`. We only need to exclude
/// union files themselves.
Set<String> _importsForDiscriminatedUnion(
    UniversalComponentClass dataClass, String? fallbackUnion) {
  // Rely on parser-provided imports; only filter out union files
  return _filterUnionImports(dataClass);
}

/// Imports for undiscriminated unions: include referenced interfaces and inline
/// synthesized variant classes. Exclude only union files.
Set<String> _importsForUndiscriminatedUnion(UniversalComponentClass dataClass) {
  final imports = <String>{}..addAll(_filterUnionImports(dataClass));
  final variants = dataClass.undiscriminatedUnionVariants;
  if (variants != null && variants.isNotEmpty) {
    for (final variantName in variants.keys) {
      // Only add imports for referenced components; skip inline variants (variantX)
      final lower = variantName.toLowerCase();
      final isUnion = lower.contains('union');
      final isInline = lower.startsWith('variant');
      final isSelf = variantName == dataClass.name;
      if (!isUnion && !isInline && !isSelf) {
        imports.add(variantName);
      }
    }
  }
  return imports.map(_applySealedNamingToImport).toSet();
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
    final shouldSkip =
        shouldFilterUnionImports && import.toLowerCase().contains('union');

    if (!shouldSkip) {
      filteredImports.add(import);
    }
  }

  return filteredImports.map(_applySealedNamingToImport).toSet();
}

const _unionSuffix = 'Union';
const _snakeUnionSuffix = '_union';

String _applySealedNaming(String name) {
  if (name.endsWith('Sealed')) {
    return name;
  }
  if (name.endsWith(_unionSuffix)) {
    return '${name.substring(0, name.length - _unionSuffix.length)}Sealed';
  }
  return name;
}

String _applySealedNamingToImport(String import) {
  if (import.endsWith(_unionSuffix)) {
    return _applySealedNaming(import);
  }
  if (import.endsWith(_snakeUnionSuffix)) {
    return '${import.substring(0, import.length - _snakeUnionSuffix.length)}_sealed';
  }
  return import;
}

String _renameUnionTypes(String type) => type.replaceAllMapped(
      RegExp(r'([A-Z][A-Za-z0-9_]*)Union\b'),
      (match) => '${match.group(1)}Sealed',
    );

String _deserializerExtensionName(String className) =>
    className.endsWith('Sealed')
        ? '${className}Deserializer'
        : '${className}SealedDeserializer';
