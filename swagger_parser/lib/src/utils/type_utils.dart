import 'package:swagger_parser/src/generator/model/programming_language.dart';
import 'package:swagger_parser/src/parser/swagger_parser_core.dart';

final _fileTypeRegExp = RegExp(r'\bFile\b');

/// Converts [UniversalType] to type from specified language
extension UniversalTypeX on UniversalType {
  bool needsIoImport({required bool useMultipartFile}) =>
      _fileTypeRegExp.hasMatch(toSuitableType(ProgrammingLanguage.dart,
          useMultipartFile: useMultipartFile));

  /// Converts [UniversalType] to concrete type of certain [ProgrammingLanguage]
  String toSuitableType(
    ProgrammingLanguage lang, {
    required bool useMultipartFile,
  }) {
    final sb = StringBuffer();

    // Append all collection prefixes, e.g., "List<"
    for (final collection in wrappingCollections) {
      sb.write(collection.collectionPrefix);
    }

    // Get the base type string (e.g., "int", "String", "MyClass").
    // IMPORTANT: This assumes that `type.toDartType(format)` and `type.toKotlinType(format)`
    // return the plain base type name WITHOUT any '?' characters.
    // Nullability is handled by the logic below.
    String baseTypeName;
    switch (lang) {
      case ProgrammingLanguage.dart:
        baseTypeName =
            type.toDartType(format: format, useMultipartFile: useMultipartFile);
      case ProgrammingLanguage.kotlin:
        baseTypeName = type.toKotlinType(format);
    }
    sb.write(baseTypeName);

    // Determine if a '?' should be appended to the baseTypeName.
    var addQuestionMarkToBaseTypeName = false;

    if (wrappingCollections.isNotEmpty) {
      // If it's a collection, the item's nullability is determined by the
      // 'itemIsNullable' property of the innermost collection.
      if (wrappingCollections.last.itemIsNullable) {
        addQuestionMarkToBaseTypeName = true;
      }
    } else {
      // If it's not a collection, the type's nullability is determined by
      // UniversalType.nullable and whether it has a default value.
      if (nullable || referencedNullable) {
        addQuestionMarkToBaseTypeName = true;
      }
    }

    if (addQuestionMarkToBaseTypeName) {
      // Special case for Dart: 'dynamic?' is not valid, it's just 'dynamic'.
      // For other types in Dart, or any type in Kotlin, append '?'.
      if (!(lang == ProgrammingLanguage.dart && baseTypeName == 'dynamic')) {
        sb.write('?');
      }
    }

    // Append closing brackets and nullability suffix for the collections themselves.
    // Iterates in reverse to close generics from innermost to outermost.
    for (final collection in wrappingCollections.reversed) {
      sb
        ..write('>') // Closing generic bracket
        ..write(collection
            .collectionSuffixQuestionMark); // '?' for the collection itself
    }

    return sb.toString();
  }
}
