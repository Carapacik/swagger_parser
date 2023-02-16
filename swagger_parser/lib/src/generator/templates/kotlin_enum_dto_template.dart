import '../../utils/case_utils.dart';
import '../models/universal_enum_class.dart';

/// Provides template for generating kotlin enum DTO
String kotlinEnumDtoTemplate(UniversalEnumClass dataClass) {
  return '''
import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
enum class ${dataClass.name.toPascal} {${_parameters(dataClass)}
}
''';
}

String _parameters(UniversalEnumClass dataClass) => dataClass.items
    .map(
      (e) =>
          '${dataClass.type != 'string' || _valuePrefixForEnumItems(dataClass.type, e) != e ? '\n    @Json("$e")' : ''}\n    '
          '${_valuePrefixForEnumItems(dataClass.type, e)},',
    )
    .join();

String _valuePrefixForEnumItems(String type, String item) =>
    (type != 'string' ? 'VALUE_$item' : item).toSnake.toUpperCase();
