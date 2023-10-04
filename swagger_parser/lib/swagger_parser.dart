/// Provides generation functions that generates REST clients and data classes from OpenApi definition file
/// [swagger_parser](https://pub.dev/packages/swagger_parser)
library swagger_parser;

export 'src/generator/fill_controller.dart';
export 'src/generator/generator.dart';
export 'src/generator/models/generated_file.dart';
export 'src/generator/models/programming_language.dart';
export 'src/generator/models/replacement_rule.dart';
export 'src/generator/models/universal_data_class.dart';
export 'src/generator/models/universal_rest_client.dart';
export 'src/parser/parser.dart';
