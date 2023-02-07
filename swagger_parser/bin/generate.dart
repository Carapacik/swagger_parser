import 'package:swagger_parser/src/utils/utils.dart';
import 'package:swagger_parser/swagger_parser.dart';

Future<void> main(List<String> arguments) async {
  try {
    /// Run generate from YAML config
    /// If you need
    final generator = Generator.fromYamlConfig(arguments);
    await generator.generateFiles();
  } on Exception catch (e) {
    exitWithError('Failed to generate files.\n$e');
  }
}
