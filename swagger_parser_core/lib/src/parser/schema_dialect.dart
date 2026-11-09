import 'package:swagger_parser_core/src/model/open_api_version.dart';
import 'package:swagger_parser_core/src/model/v3_1/open_api_v3_1_objects.dart';
import 'package:swagger_parser_core/src/model/v3_2/open_api_v3_2_objects.dart';

/// Schema keyword sets supported by parsing and reference resolution.
enum SchemaDialect() {
  /// JSON Schema 2020-12 with the family's OpenAPI vocabulary.
  openApi,

  /// JSON Schema 2020-12 keywords.
  draft202012,

  /// An opaque schema from another dialect.
  unknown;

  /// Identifies [uri] in the context of its OpenAPI [family].
  static SchemaDialect identify(String uri, OpenApiFamily family) {
    final String id = uri.endsWith('#')
        ? uri.substring(0, uri.length - 1)
        : uri;
    if (id == OpenApiV31Schema.draft202012) {
      return draft202012;
    }
    return switch ((family, id)) {
      (
        OpenApiFamily.v31,
        OpenApiV31Schema.oasDialect ||
            'https://spec.openapis.org/oas/3.1/dialect/2024-11-10',
      ) ||
      (
        OpenApiFamily.v32,
        OpenApiV32Schema.oasDialect ||
            'https://spec.openapis.org/oas/3.2/dialect/2025-09-17',
      ) => openApi,
      _ => unknown,
    };
  }
}
