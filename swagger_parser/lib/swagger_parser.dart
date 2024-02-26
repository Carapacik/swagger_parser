/// Provides generation functions that generates REST clients and data classes from OpenApi definition file
/// [swagger_parser](https://pub.dev/packages/swagger_parser)
library swagger_parser;

export 'src/generator/config/generator_config.dart';
export 'src/generator/generator/fill_controller.dart';
export 'src/generator/generator/generator.dart';
export 'src/generator/generator/generator_processor.dart';
export 'src/generator/model/generated_file.dart';
export 'src/generator/model/json_serializer.dart';
export 'src/generator/model/programming_language.dart';
export 'src/parser/model/replacement_rule.dart';
export 'src/parser/swagger_parser_core.dart';
