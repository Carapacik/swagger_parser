import 'package:collection/collection.dart';
import 'package:swagger_parser/src/generator/model/json_serializer.dart';
import 'package:swagger_parser/src/generator/model/programming_language.dart';
import 'package:swagger_parser/src/generator/templates/dart_import_dto_template.dart';
import 'package:swagger_parser/src/parser/model/normalized_identifier.dart';
import 'package:swagger_parser/src/parser/swagger_parser_core.dart';
import 'package:swagger_parser/src/utils/base_utils.dart';
import 'package:swagger_parser/src/utils/type_utils.dart';

String dartDartMappableDtoTemplate(
  UniversalComponentClass dataClass, {
  required bool markFileAsGenerated,
  required bool useMultipartFile,
  required bool dartMappableConvenientWhen,
  String? fallbackUnion,
}) {
  // Use fallback union only if explicitly provided
  // Auto-fallback is disabled to avoid breaking existing tests
  final effectiveFallbackUnion = fallbackUnion;
  final originalClassName = dataClass.name.toPascal;
  final discriminator = dataClass.discriminator;
  final isUndiscriminatedUnion =
      dataClass.undiscriminatedUnionVariants?.isNotEmpty ?? false;
  final isUnion = discriminator != null || isUndiscriminatedUnion;

  final className =
      isUnion ? _applySealedNaming(originalClassName) : originalClassName;
  final classNameSnake = className.toSnake;

  // For dart_mappable, treat discriminated unions with complete mapping as undiscriminated
  // to use the wrapper pattern instead of direct inheritance
  final shouldUseWrapperPattern = isUndiscriminatedUnion ||
      (discriminator != null && _isCompleteDiscriminatorMapping(discriminator));

  // For discriminated union variants that should become standalone classes for wrapper pattern
  // We detect this by checking if this is a discriminator variant (has discriminatorValue)
  // and if the discriminator value matches the class name (indicating complete mapping)
  final isDiscriminatorVariant = dataClass.discriminatorValue != null;
  final hasCompleteMapping = isDiscriminatorVariant &&
      dataClass.discriminatorValue!.propertyValue == originalClassName;

  final parent = (isDiscriminatorVariant && hasCompleteMapping)
      ? null
      : _applySealedNamingToParent(dataClass.discriminatorValue?.parentClass);

  // Check if this is a simple data class that could be used in unions
  final isSimpleDataClass = !isUnion &&
      parent == null &&
      dataClass.parameters.isNotEmpty &&
      dataClass.discriminatorValue == null;

  // Generate additional classes for undiscriminated unions or discriminated unions with complete mapping
  final additionalClasses = shouldUseWrapperPattern
      ? _generateWrapperClasses(
          dataClass, className, useMultipartFile, effectiveFallbackUnion)
      : '';

  return '''
${dartImportDtoTemplate(JsonSerializer.dartMappable)}
${dartImports(imports: _getAllImports(dataClass, isUnion: isUnion))}
part '$classNameSnake.mapper.dart';

${descriptionComment(dataClass.description)}@MappableClass(${_getMappableClassAnnotation(dataClass, className, effectiveFallbackUnion)})
${_classModifier(isUnion: isUnion)}class $className ${parent != null ? "extends $parent " : ""}with ${className}Mappable {
${_generateClassBody(dataClass, className, useMultipartFile, isUnion, dartMappableConvenientWhen, isSimpleDataClass, effectiveFallbackUnion)}
}

$additionalClasses''';
}

String getDiscriminatorConvenienceMethods(
  UniversalComponentClass dataClass,
  String className, [
  String? fallbackUnion,
]) {
  if (dataClass.discriminator == null) {
    return '';
  }

  final discriminatorEntries =
      dataClass.discriminator!.discriminatorValueToRefMapping.entries;

  // Build when/maybeWhen method parameters
  final whenParams = discriminatorEntries
      .map(
        (e) =>
            'required T Function(${e.value} ${e.key.toCamel}) ${e.key.toCamel},',
      )
      .toList();

  final maybeWhenParams = discriminatorEntries
      .map(
        (e) => 'T Function(${e.value} ${e.key.toCamel})? ${e.key.toCamel},',
      )
      .toList();

  final switchCases = discriminatorEntries
      .map(
        (e) => '${e.value} _ => ${e.key.toCamel}?.call(this as ${e.value}),',
      )
      .toList();

  final maybeWhenArgs = discriminatorEntries
      .map(
        (e) => '${e.key.toCamel}: ${e.key.toCamel},',
      )
      .toList();

  // Add fallback union if provided
  if (fallbackUnion != null && fallbackUnion.isNotEmpty) {
    final fallbackClassName = className + fallbackUnion.toPascal;
    whenParams.add(
        'required T Function($fallbackClassName $fallbackUnion) $fallbackUnion,');
    maybeWhenParams
        .add('T Function($fallbackClassName $fallbackUnion)? $fallbackUnion,');
    switchCases.add(
        '$fallbackClassName _ => $fallbackUnion?.call(this as $fallbackClassName),');
    maybeWhenArgs.add('$fallbackUnion: $fallbackUnion,');
  }

  return '''
  @Deprecated('Use Dart pattern matching with sealed class')
  T when<T>({
  ${whenParams.join('\n  ')}
  }) {
    return maybeWhen(
    ${maybeWhenArgs.join('\n    ')}
    )!;
  }
  @Deprecated('Use Dart pattern matching with sealed class')
  T? maybeWhen<T>({
  ${maybeWhenParams.join('\n  ')}
  }) {
    return switch (this) {
    ${switchCases.join('\n    ')}
      _ => throw Exception("Unhandled type: \${this.runtimeType}"),
    };
  }
  ''';
}

String getParameters(UniversalComponentClass dataClass) {
  // if this class has discriminated values, don't populate the discriminator field
  // in the parent class
  final parameters = dataClass.parameters
      .where((it) => it.name != dataClass.discriminator?.propertyName)
      .toList();
  if (parameters.isNotEmpty) {
    return '{\n${_parametersToString(parameters)}\n${indentation(2)}}';
  } else {
    return '';
  }
}

String getFields(
  UniversalComponentClass dataClass, {
  required bool useMultipartFile,
  bool isSimpleDataClass = false,
}) {
  // if this class has discriminated values, don't populate the discriminator field
  // in the parent class
  final parameters = dataClass.parameters
      .where((it) => it.name != dataClass.discriminator?.propertyName)
      .toList();
  if (parameters.isNotEmpty) {
    return '${_fieldsToString(parameters, useMultipartFile)}\n';
  } else {
    return '';
  }
}

String _fieldsToString(
  List<UniversalType> parameters,
  bool useMultipartFile,
) {
  final sortedByRequired = Set<UniversalType>.from(
    parameters.sorted((a, b) => a.compareTo(b)),
  );
  return sortedByRequired
      .mapIndexed(
        (i, e) =>
            '${_jsonKey(e)}${indentation(2)}final ${_renameUnionTypes(e.toSuitableType(ProgrammingLanguage.dart, useMultipartFile: useMultipartFile))} ${e.name};',
      )
      .join('\n');
}

String _parametersToString(List<UniversalType> parameters) {
  final sortedByRequired = Set<UniversalType>.from(
    parameters.sorted((a, b) => a.compareTo(b)),
  );
  return sortedByRequired
      .mapIndexed(
        (i, e) =>
            '${indentation(4)}${_required(e)}this.${e.name}${getDefaultValue(e)},',
      )
      .join('\n');
}

/// if jsonKey is different from the name
String _jsonKey(UniversalType t) {
  if (t.jsonKey == null || t.name == t.jsonKey) {
    return '';
  }
  return "${indentation(2)}@MappableField(key: '${protectJsonKey(t.jsonKey)}')\n";
}

String getDefaultValue(UniversalType t) {
  if (t.defaultValue == null) {
    return '';
  }
  return ' = ${_defaultValue(t)}';
}

/// return required if isRequired
String _required(UniversalType t) =>
    t.isRequired && t.defaultValue == null ? 'required ' : '';

/// return defaultValue if have
String _defaultValue(UniversalType t) =>
    '${t.enumType != null ? '${t.type}.${protectDefaultEnum(t.defaultValue)?.toCamel}' : protectDefaultValue(t.defaultValue, type: t.type)}';

String _classModifier({required bool isUnion}) {
  return isUnion ? 'sealed ' : '';
}

String _generateClassBody(
    UniversalComponentClass dataClass,
    String className,
    bool useMultipartFile,
    bool isUnion,
    bool dartMappableConvenientWhen,
    bool isSimpleDataClass,
    [String? fallbackUnion]) {
  if (!isUnion) {
    // Regular class generation
    return '''
${indentation(2)}const $className(${getParameters(dataClass)});
${getFields(dataClass, useMultipartFile: useMultipartFile, isSimpleDataClass: isSimpleDataClass)}
${dartMappableConvenientWhen ? getDiscriminatorConvenienceMethods(dataClass, className, fallbackUnion) : ''}
${indentation(2)}static $className fromJson(Map<String, dynamic> json) => ${className}Mapper.ensureInitialized().decodeMap<$className>(json);
''';
  }

  // Union class generation
  if (dataClass.undiscriminatedUnionVariants case final variants?
      when variants.isNotEmpty) {
    return _generateUndiscriminatedUnionBody(className, variants,
        useMultipartFile, dartMappableConvenientWhen, fallbackUnion);
  }

  // Discriminated unions with complete mapping use wrapper pattern
  // and the public extension-based deserializer
  if (dataClass.discriminator != null &&
      _isCompleteDiscriminatorMapping(dataClass.discriminator!)) {
    return '''
${indentation(2)}const $className();

${dartMappableConvenientWhen ? getDiscriminatorConvenienceMethods(dataClass, className, fallbackUnion) : ''}
${indentation(2)}static $className fromJson(Map<String, dynamic> json) {
${indentation(4)}return ${_deserializerExtensionName(className)}.tryDeserialize(json);
${indentation(2)}}
''';
  }

  // Discriminated union - already handled by existing discriminator convenience methods
  return '''
${indentation(2)}const $className();

${dartMappableConvenientWhen ? getDiscriminatorConvenienceMethods(dataClass, className, fallbackUnion) : ''}
${indentation(2)}static $className fromJson(Map<String, dynamic> json) => ${className}Mapper.ensureInitialized().decodeMap<$className>(json);
''';
}

String _generateUndiscriminatedUnionBody(
    String className,
    Map<String, Set<UniversalType>> variants,
    bool useMultipartFile,
    bool dartMappableConvenientWhen,
    [String? fallbackUnion]) {
  return '''
${indentation(2)}const $className();
${dartMappableConvenientWhen ? '\n${_generateUndiscriminatedUnionConvenienceMethods(className, variants, fallbackUnion)}' : ''}
${indentation(2)}static $className fromJson(Map<String, dynamic> json) {
${indentation(4)}return ${_deserializerExtensionName(className)}.tryDeserialize(json);
${indentation(2)}}
''';
}

String _generateUndiscriminatedUnionClasses(String className,
    Map<String, Set<UniversalType>> variants, bool useMultipartFile,
    [String? fallbackUnion]) {
  return '''
${_generateUndiscriminatedMappableExtension(className, variants, fallbackUnion)}

${_generateVariantWrappers(className, variants, useMultipartFile, fallbackUnion)}''';
}

String _generateUndiscriminatedUnionConvenienceMethods(
    String className, Map<String, Set<UniversalType>> variants,
    [String? fallbackUnion]) {
  final whenCases = variants.entries
      .map(
        (e) =>
            '${indentation(4)}required T Function($className${e.key.toPascal} ${e.key.toCamel}) ${e.key.toCamel},',
      )
      .toList();

  final maybeWhenCases = variants.entries
      .map(
        (e) =>
            '${indentation(4)}T Function($className${e.key.toPascal} ${e.key.toCamel})? ${e.key.toCamel},',
      )
      .toList();

  final switchCases = variants.entries
      .map(
        (e) =>
            '${indentation(6)}$className${e.key.toPascal} _ => ${e.key.toCamel}?.call(this as $className${e.key.toPascal}),',
      )
      .toList();

  final maybeWhenArgs = variants.entries
      .map(
        (e) => '${indentation(6)}${e.key.toCamel}: ${e.key.toCamel},',
      )
      .toList();

  // Add fallback case if provided
  if (fallbackUnion != null && fallbackUnion.isNotEmpty) {
    whenCases.add(
        '${indentation(4)}required T Function($className${fallbackUnion.toPascal} ${fallbackUnion.toCamel}) ${fallbackUnion.toCamel},');
    maybeWhenCases.add(
        '${indentation(4)}T Function($className${fallbackUnion.toPascal} ${fallbackUnion.toCamel})? ${fallbackUnion.toCamel},');
    switchCases.add(
        '${indentation(6)}$className${fallbackUnion.toPascal} _ => ${fallbackUnion.toCamel}?.call(this as $className${fallbackUnion.toPascal}),');
    maybeWhenArgs.add(
        '${indentation(6)}${fallbackUnion.toCamel}: ${fallbackUnion.toCamel},');
  }

  return '''
${indentation(2)}@Deprecated('Use Dart pattern matching with sealed class')
${indentation(2)}T when<T>({
${whenCases.join('\n')}
${indentation(2)}}) {
${indentation(4)}return maybeWhen(
${maybeWhenArgs.join('\n')}
${indentation(4)})!;
${indentation(2)}}

${indentation(2)}@Deprecated('Use Dart pattern matching with sealed class')
${indentation(2)}T? maybeWhen<T>({
${maybeWhenCases.join('\n')}
${indentation(2)}}) {
${indentation(4)}return switch (this) {
${switchCases.join('\n')}
${indentation(6)}_ => throw Exception("Unhandled type: \${this.runtimeType}"),
${indentation(4)}};
${indentation(2)}}
''';
}

String _generateUndiscriminatedMappableExtension(
    String className, Map<String, Set<UniversalType>> variants,
    [String? fallbackUnion]) {
  final tryBlocks = variants.keys
      .map(
        (variantName) => '''
${indentation(4)}try {
${indentation(6)}return $className${variantName.toPascal}Mapper.ensureInitialized().decodeMap<$className${variantName.toPascal}>(json);
${indentation(4)}} catch (_) {}''',
      )
      .join('\n');

  final fallbackBlock = (fallbackUnion != null && fallbackUnion.isNotEmpty)
      ? '''
${indentation(4)}// Try fallback variant before throwing exception
${indentation(4)}try {
${indentation(6)}return $className${fallbackUnion.toPascal}Mapper.ensureInitialized().decodeMap<$className${fallbackUnion.toPascal}>(json);
${indentation(4)}} catch (_) {}'''
      : '';

  return '''
extension ${_deserializerExtensionName(className)} on $className {
${indentation(2)}static $className tryDeserialize(Map<String, dynamic> json) {
$tryBlocks
$fallbackBlock

${indentation(4)}throw FormatException('Could not determine the correct type for $className from: \$json');
${indentation(2)}}
}''';
}

String _generateDiscriminatorHelper(
    String className, Discriminator discriminator,
    [String? fallbackUnion]) {
  final discriminatorKey = discriminator.propertyName;
  final discriminatorMappings = discriminator.discriminatorValueToRefMapping;

  // Build default mapping literal: { WrapperType: 'DiscriminatorValue', ... }
  final mappingEntries = discriminatorMappings.entries.map((entry) {
    final variantName = entry.value;
    final discriminatorValue = entry.key;
    final wrapperClassName = '$className${variantName.toPascal}';
    return "${indentation(6)}$wrapperClassName: '$discriminatorValue',";
  }).join('\n');

  // Build switch cases using guarded mapping
  final switchCases = discriminatorMappings.entries.map((entry) {
    final variantName = entry.value;
    final wrapperClassName = '$className${variantName.toPascal}';
    return '''${indentation(6)}_ when value == effective[$wrapperClassName] => ${wrapperClassName}Mapper.ensureInitialized().decodeMap<$wrapperClassName>(json),''';
  }).join('\n');

  final fallbackCase = (fallbackUnion != null && fallbackUnion.isNotEmpty)
      ? '${indentation(6)}_ => $className${fallbackUnion.toPascal}Mapper.ensureInitialized().decodeMap<$className${fallbackUnion.toPascal}>(json),'
      : "${indentation(6)}_ => throw FormatException('Unknown discriminator value \"\${json[key]}\" for $className'),";

  return '''
extension ${_deserializerExtensionName(className)} on $className {
${indentation(2)}static $className tryDeserialize(
${indentation(2)}  Map<String, dynamic> json, {
${indentation(2)}  String key = '$discriminatorKey',
${indentation(2)}  Map<Type, Object?>? mapping,
${indentation(2)}}) {
${indentation(4)}final mappingFallback = const <Type, Object?>{
$mappingEntries
${indentation(4)}};
${indentation(4)}final value = json[key];
${indentation(4)}final effective = mapping ?? mappingFallback;
${indentation(4)}return switch (value) {
$switchCases
$fallbackCase
${indentation(4)}};
${indentation(2)}}
}''';
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

String? _applySealedNamingToParent(String? parent) =>
    parent == null ? null : _applySealedNaming(parent);

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

String _generateVariantWrappers(String className,
    Map<String, Set<UniversalType>> variants, bool useMultipartFile,
    [String? fallbackUnion]) {
  final regularWrappers = variants.entries.map((entry) {
    final variantName = entry.key;
    final properties = entry.value;
    final wrapperClassName = '$className${variantName.toPascal}';
    final originalClassName = variantName.toPascal;

    // Generate direct properties instead of delegating getters
    final directProperties = properties
        .map(
          (prop) =>
              '${indentation(2)}@override\n${indentation(2)}final ${_renameUnionTypes(prop.toSuitableType(ProgrammingLanguage.dart, useMultipartFile: useMultipartFile))} ${prop.name};',
        )
        .join('\n');

    // Generate constructor parameters
    final constructorParams = properties
        .map(
          (prop) => '${indentation(4)}required this.${prop.name},',
        )
        .join('\n');

    // Inline synthesized variants (variantX) should not implement any interface
    final isInline = variantName.toLowerCase().startsWith('variant');
    final implementsClause = isInline ? '' : ' implements $originalClassName';

    return '''
@MappableClass()
class $wrapperClassName extends $className with ${wrapperClassName}Mappable$implementsClause {
$directProperties

${indentation(2)}const $wrapperClassName({
$constructorParams
${indentation(2)}});
}
''';
  }).join('\n');

  // Generate fallback wrapper if fallbackUnion is provided
  final fallbackWrapper = (fallbackUnion != null && fallbackUnion.isNotEmpty)
      ? '''
@MappableClass()
class $className${fallbackUnion.toPascal} extends $className with $className${fallbackUnion.toPascal}Mappable {
${indentation(2)}final Map<String, dynamic> _json;

${indentation(2)}const $className${fallbackUnion.toPascal}(this._json);

${indentation(2)}/// Access raw JSON data for unknown union variant
${indentation(2)}Map<String, dynamic> get json => _json;

${indentation(2)}static $className${fallbackUnion.toPascal} fromJson(Map<String, dynamic> json) =>
${indentation(6)}$className${fallbackUnion.toPascal}(json);
}
'''
      : '';

  return regularWrappers + fallbackWrapper;
}

String _getMappableClassAnnotation(UniversalComponentClass dataClass,
    String className, String? fallbackUnion) {
  // For discriminated unions with complete mapping, use wrapper pattern
  if (dataClass.discriminator != null &&
      _isCompleteDiscriminatorMapping(dataClass.discriminator!)) {
    final subClasses = dataClass
        .discriminator!.discriminatorValueToRefMapping.values
        .map((variantName) => '$className${variantName.toPascal}')
        .toList();
    if (fallbackUnion != null && fallbackUnion.isNotEmpty) {
      subClasses.add('$className${fallbackUnion.toPascal}');
    }
    final formattedSubClasses =
        subClasses.map((sc) => '${indentation(2)}$sc').join(',\n');
    return [
      "discriminatorKey: '${dataClass.discriminator!.propertyName}'",
      'includeSubClasses: [\n$formattedSubClasses\n]',
    ].join(', ');
  }

  // Original discriminated union logic (for incomplete mappings)
  if (dataClass.discriminator != null) {
    final subClasses =
        dataClass.discriminator!.discriminatorValueToRefMapping.values.toList();
    if (fallbackUnion != null && fallbackUnion.isNotEmpty) {
      subClasses.add('$className${fallbackUnion.toPascal}');
    }
    return [
      "discriminatorKey: '${dataClass.discriminator!.propertyName}'",
      'includeSubClasses: [${subClasses.join(', ')}]',
    ].join(', ');
  }
  // For discriminated union variants that use wrapper pattern, don't include discriminatorValue
  if (dataClass.discriminatorValue != null) {
    // Check if this is a complete mapping case (discriminator value matches class name)
    final isCompleteMapping =
        dataClass.discriminatorValue!.propertyValue == className;
    if (!isCompleteMapping) {
      return "discriminatorValue: '${dataClass.discriminatorValue!.propertyValue}'";
    }
  }
  // Check for undiscriminated unions
  if (dataClass.undiscriminatedUnionVariants?.isNotEmpty ?? false) {
    final subClasses = dataClass.undiscriminatedUnionVariants!.keys
        .map((variantName) => '$className${variantName.toPascal}')
        .toList();
    if (fallbackUnion != null && fallbackUnion.isNotEmpty) {
      subClasses.add('$className${fallbackUnion.toPascal}');
    }
    return 'includeSubClasses: [${subClasses.join(', ')}]';
  }
  return '';
}

Set<String> _getAllImports(
  UniversalComponentClass dataClass, {
  required bool isUnion,
}) {
  final imports = Set<String>.from(dataClass.imports);

  // For undiscriminated unions, add imports for referenced variant classes only
  // Skip synthesized inline variants like variant2, variant4
  if (dataClass.undiscriminatedUnionVariants?.isNotEmpty ?? false) {
    for (final variantName in dataClass.undiscriminatedUnionVariants!.keys) {
      final lower = variantName.toLowerCase();
      final isInline = lower.startsWith('variant');
      final isSelf = variantName == dataClass.name;
      if (!isInline && !isSelf) {
        imports.add(variantName);
      }
    }
  }

  // For discriminated unions with complete mapping, also add imports
  if (dataClass.discriminator != null &&
      _isCompleteDiscriminatorMapping(dataClass.discriminator!)) {
    imports
        .addAll(dataClass.discriminator!.discriminatorValueToRefMapping.values);
  }

  // Filter out circular imports: if this is a simple model class (not a union),
  // exclude any imports that would reference union classes that contain this model
  final isUnion = dataClass.discriminator != null ||
      (dataClass.undiscriminatedUnionVariants?.isNotEmpty ?? false);

  if (!isUnion) {
    // Remove imports that would create circular dependencies
    // Only remove union imports that aren't actually used by this class

    // Get all the types used by this class parameters
    final usedTypes = dataClass.parameters.map((p) => p.type).toSet();

    imports.removeWhere((import) {
      final isUnionImport = import.toLowerCase().contains('union');
      final isUsedByClass = usedTypes.contains(import) ||
          usedTypes.any((type) => type.contains(import));

      // Remove union imports that aren't used by this class
      return isUnionImport && !isUsedByClass;
    });
  }

  return imports.map(_applySealedNamingToImport).toSet();
}

bool _isCompleteDiscriminatorMapping(Discriminator discriminator) {
  // A discriminator mapping is considered "complete" if it has explicit mappings
  // for all variants (as opposed to implicit mappings)
  return discriminator.discriminatorValueToRefMapping.isNotEmpty;
}

String _generateWrapperClasses(UniversalComponentClass dataClass,
    String className, bool useMultipartFile, String? fallbackUnion) {
  // Handle undiscriminated unions
  if (dataClass.undiscriminatedUnionVariants?.isNotEmpty ?? false) {
    return _generateUndiscriminatedUnionClasses(
        className,
        dataClass.undiscriminatedUnionVariants!,
        useMultipartFile,
        fallbackUnion);
  }

  // Handle discriminated unions with complete mapping using wrapper pattern
  if (dataClass.discriminator != null &&
      _isCompleteDiscriminatorMapping(dataClass.discriminator!)) {
    final wrappers = _generateDiscriminatedWrapperClasses(
        dataClass, className, useMultipartFile, fallbackUnion);
    return wrappers;
  }

  return '';
}

String _generateDiscriminatedWrapperClasses(UniversalComponentClass dataClass,
    String className, bool useMultipartFile, String? fallbackUnion) {
  final discriminator = dataClass.discriminator!;
  final wrappers = <String>[];

  // Generate wrapper classes for each discriminator variant
  for (final entry in discriminator.discriminatorValueToRefMapping.entries) {
    final discriminatorValue = entry.key; // e.g., "Cat"
    final variantName = entry.value; // e.g., "Cat"
    final wrapperClassName =
        '$className${variantName.toPascal}'; // e.g., "FamilyMembersUnionCat"

    // Get the variant class properties from the discriminator's refProperties
    final variantProperties =
        discriminator.refProperties[variantName] ?? <UniversalType>[];

    // Include all properties (including discriminator property)
    final filteredProperties = variantProperties;

    // Generate direct properties instead of delegating getters
    final directProperties = filteredProperties
        .map(
          (prop) =>
              '${indentation(2)}@override\n${indentation(2)}final ${_renameUnionTypes(prop.toSuitableType(ProgrammingLanguage.dart, useMultipartFile: useMultipartFile))} ${prop.name};',
        )
        .join('\n');

    // Generate constructor parameters
    final constructorParams = filteredProperties
        .map(
          (prop) => '${indentation(4)}required this.${prop.name},',
        )
        .join('\n');

    wrappers.add('''
@MappableClass(discriminatorValue: '$discriminatorValue')
class $wrapperClassName extends $className with ${wrapperClassName}Mappable implements $variantName {
$directProperties

${indentation(2)}const $wrapperClassName({
$constructorParams
${indentation(2)}});
}''');
  }

  // Add fallback wrapper if specified
  if (fallbackUnion != null && fallbackUnion.isNotEmpty) {
    wrappers.add('''
@MappableClass(discriminatorValue: MappableClass.useAsDefault)
class $className${fallbackUnion.toPascal} extends $className with $className${fallbackUnion.toPascal}Mappable {
${indentation(2)}final Map<String, dynamic> _json;

${indentation(2)}const $className${fallbackUnion.toPascal}(this._json);

${indentation(2)}/// Access raw JSON data for unknown union variant
${indentation(2)}Map<String, dynamic> get json => _json;

${indentation(2)}static $className${fallbackUnion.toPascal} fromJson(Map<String, dynamic> json) =>
${indentation(6)}$className${fallbackUnion.toPascal}(json);
}''');
  }

  // Generate discriminator helper class for proper deserialization
  final helper =
      _generateDiscriminatorHelper(className, discriminator, fallbackUnion);

  return '''
$helper

${wrappers.join('\n')}''';
}
