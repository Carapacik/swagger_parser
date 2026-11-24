import 'package:swagger_parser_core/src/model/open_api_version.dart';

/// Returns the JSON Schema violation for one parameter flag, if present.
String? parameterFlagError(
  String key,
  Map<String, Object?> fields,
  OpenApiFamily family, {
  required bool header,
}) {
  if (!fields.containsKey(key)) {
    return null;
  }
  final Object? location = header ? 'header' : fields['in'];
  if (key == 'allowReserved' && fields.containsKey('content')) {
    return 'allowReserved requires schema.';
  }
  if (family != OpenApiFamily.v30 && location != 'query') {
    if (key == 'allowEmptyValue' || family == OpenApiFamily.v31) {
      return '$key requires a query parameter.';
    }
    if (location != 'path' &&
        !(location == 'cookie' && (fields['style'] ?? 'form') == 'form')) {
      return 'allowReserved requires a percent-encoded style.';
    }
  }
  return fields[key] is bool ? null : 'Expected a boolean.';
}
