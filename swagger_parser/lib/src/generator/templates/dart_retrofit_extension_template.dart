import 'package:collection/collection.dart';

import '../../utils/case_utils.dart';
import '../../utils/type_utils.dart';
import '../../utils/utils.dart';
import '../models/programming_language.dart';
import '../models/universal_request.dart';
import '../models/universal_request_type.dart';
import '../models/universal_rest_client.dart';
import '../models/universal_type.dart';

/// Provides template for generating dart Retrofit client
String dartRetrofitExtensionTemplate({
  required String name,
  required bool markFileAsGenerated,
}) {
  final sb = StringBuffer(
    '''
extension Iso8061SerializableDateTime on DateTime {
  String toJson() => toIso8601String();
}
''',
  );
  return sb.toString();
}