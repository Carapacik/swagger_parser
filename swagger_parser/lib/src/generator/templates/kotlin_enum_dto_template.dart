import 'package:collection/collection.dart';

import '../../utils/case_utils.dart';
import '../../utils/utils.dart';
import '../models/universal_data_class.dart';

/// Provides template for generating kotlin enum DTO
String kotlinEnumDtoTemplate(
  UniversalEnumClass dataClass, {
  required bool markFileAsGenerated,
}) {
  return '''
${generatedFileComment(markFileAsGenerated: markFileAsGenerated, ignoreLints: false)}import com.squareup.moshi.Json
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
          '${dataClass.type != 'string' || e.jsonKey != e.name.toScreamingSnake ? '    @Json("${e.jsonKey}")' : ''}\n    '
          '${e.name.toScreamingSnake},',
    )
    .join();
