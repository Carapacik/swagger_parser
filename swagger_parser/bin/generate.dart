import 'package:swagger_parser/src/utils/utils.dart';
import 'package:swagger_parser/swagger_parser.dart';

Future<void> main(List<String> arguments) async {
  introMessage();
  try {
    /// Run generate from YAML config
    /// If you need
    final generator = Generator.fromYamlConfig(arguments);
    generateMessage();
    await generator.generateFiles();
    successMessage();
  } on Exception catch (e) {
    exitWithError('Failed to generate files.\n$e');
  }
}
