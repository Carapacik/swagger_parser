import 'package:swagger_parser/src/utils/utils.dart';
import 'package:swagger_parser/swagger_parser.dart';

Future<void> main(List<String> arguments) async {
  try {
    final generator = Generator(arguments);
    await generator.generateAsync();
  } on Exception catch (e) {
    exitWithError('Failed to generate files.\n$e');
  }
}
