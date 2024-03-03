import '../generator/model/programming_language.dart';
import '../parser/swagger_parser_core.dart';

/// Converts [UniversalType] to type from specified language
extension UniversalTypeX on UniversalType {
  /// Converts [UniversalType] to concrete type of certain [ProgrammingLanguage]
  String toSuitableType(ProgrammingLanguage lang) {
    if (wrappingCollections.isEmpty) {
      return _questionMark(lang);
    }
    final sb = StringBuffer();
    for (var i = 0; i < wrappingCollections.length; i++) {
      sb.write(wrappingCollections[i].collectionsString);
    }
    sb.write(_questionMark(lang));
    for (var i = 0; i < wrappingCollections.length; i++) {
      sb.write('>');
    }
    if (nullable || (!isRequired && defaultValue == null)) {
      sb.write('?');
    }
    return sb.toString();
  }

  String _questionMark(ProgrammingLanguage lang) {
    final questionMark = isRequired && !nullable ||
            wrappingCollections.isNotEmpty ||
            defaultValue != null
        ? ''
        : '?';
    switch (lang) {
      case ProgrammingLanguage.dart:
        // https://github.com/trevorwang/retrofit.dart/issues/631
        // https://github.com/Carapacik/swagger_parser/issues/110
        return type.toDartType(format) +
            (type.toDartType(format) == 'dynamic' ? '' : questionMark);
      case ProgrammingLanguage.kotlin:
        return type.toKotlinType(format) + questionMark;
    }
  }
}
