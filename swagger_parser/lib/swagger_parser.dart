/// Parses OpenAPI sources and generates Dart libraries.
///
/// Use `FileSchemaSourceLoader` to read a local file on Dart I/O platforms.
/// Use `SchemaSource` for text or bytes on the VM and web.
library;

export 'package:swagger_parser_core/swagger_parser_core.dart';

export 'src/config/generation_config.dart';
export 'src/config/naming_config.dart';
export 'src/config/operation_filter_config.dart';
export 'src/config/parameter_exclusion.dart';
export 'src/config/pipeline_config.dart';
export 'src/config/type_mapping.dart';
export 'src/dart/dart_code_builder.dart';
export 'src/dart/dart_generation_model.dart';
export 'src/dart/dart_model_mapper.dart';
export 'src/dart/dart_operation_name.dart';
export 'src/extraction/api_definition.dart';
export 'src/extraction/api_definition_extractor.dart';
export 'src/generation/dart_generator.dart';
export 'src/generation/generation_exception.dart';
export 'src/input/file_schema_source_loader.dart';
export 'src/output/generated_file.dart';
export 'src/output/generation_result.dart';
export 'src/planning/dart_output_planner.dart';
export 'src/planning/generation_plan.dart';
export 'src/rendering/dart_source_renderer.dart';
export 'src/runner/swagger_parser_runner.dart';
