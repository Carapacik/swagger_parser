import 'package:collection/collection.dart';

import '../../parser/model/normalized_identifier.dart';
import '../../parser/swagger_parser_core.dart';
import '../../utils/base_utils.dart';

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
    .mapIndexed(
      (i, e) =>
          '${i != 0 && e.description != null ? '\n\n' : '\n'}${descriptionComment(e.description, tab: '    ')}'
          '${dataClass.type != 'string' || e.jsonKey != e.name.toScreamingSnake ? '    @Json("${protectJsonKey(e.jsonKey)}")' : ''}\n    '
          '${e.name.toScreamingSnake},',
    )
    .join();
