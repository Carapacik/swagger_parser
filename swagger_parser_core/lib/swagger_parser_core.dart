/// Typed Swagger 2.0, OpenAPI 3.0, 3.1, and 3.2 documents.
///
/// Use `OpenApiParser` to parse JSON or YAML from a `SchemaSource`.
library;

export 'src/config/normalize_config.dart';
export 'src/config/parse_config.dart';
export 'src/diagnostics/diagnostic.dart';
export 'src/exceptions/open_api_exception.dart';
export 'src/model/json_value.dart';
export 'src/model/open_api_document.dart';
export 'src/model/open_api_version.dart';
export 'src/model/parameter_serialization.dart';
export 'src/model/v2/swagger_v2_objects.dart';
export 'src/model/v3_0/open_api_v3_0_objects.dart';
export 'src/model/v3_1/open_api_v3_1_objects.dart';
export 'src/model/v3_2/open_api_v3_2_objects.dart';
export 'src/parser/open_api_parser.dart';
export 'src/parser/schema_dialect.dart';
export 'src/references/open_api_reference_resolver.dart';
export 'src/source/schema_source.dart';
export 'src/source/source_location.dart';
export 'src/transformation/open_api_normalizer.dart';
export 'src/traversal/document_node.dart';
export 'src/traversal/located_node.dart';
export 'src/validation/open_api_validator.dart';
