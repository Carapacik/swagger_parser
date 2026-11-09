import 'package:swagger_parser_core/src/model/open_api_version.dart';

/// Effective wire settings for a request parameter.
final class const ParameterSerialization._({
  /// Swagger 2.0 array format, such as `csv` or `multi`.
  final String? collectionFormat,

  /// OpenAPI 3.x serialization style, such as `form` or `simple`.
  final String? style,

  /// Whether to expand the value. An omitted `deepObject` setting stays null.
  final bool? explode,
}) {
  /// Reads a Parameter Object in [family] without changing it.
  ///
  /// Pass the parameter's JSON fields or the resolved reference target.
  /// Use a resolved definition to include settings from a reference.
  factory effective(OpenApiFamily family, Map<String, Object?> parameter) {
    if (parameter.containsKey(r'$ref')) {
      return const ParameterSerialization._();
    }
    if (family == OpenApiFamily.swaggerV2) {
      if (parameter['in'] == 'body' || parameter['type'] != 'array') {
        return const ParameterSerialization._();
      }
      return ParameterSerialization._(
        collectionFormat: parameter['collectionFormat'] as String? ?? 'csv',
      );
    }
    if (!parameter.containsKey('schema') ||
        parameter.containsKey('content') ||
        parameter['in'] == 'querystring') {
      return const ParameterSerialization._();
    }
    final String? style =
        parameter['style'] as String? ??
        switch (parameter['in']) {
          'query' || 'cookie' => 'form',
          'path' || 'header' => 'simple',
          _ => null,
        };
    final bool? explode =
        parameter['explode'] as bool? ??
        switch (style) {
          null || 'deepObject' => null,
          'form' => true,
          'cookie' => family == OpenApiFamily.v32,
          _ => false,
        };
    return ParameterSerialization._(style: style, explode: explode);
  }

  /// Returns the applicable fields using their specification names.
  Map<String, Object?> toJson() => {
    'collectionFormat': ?collectionFormat,
    'style': ?style,
    'explode': ?explode,
  };
}
