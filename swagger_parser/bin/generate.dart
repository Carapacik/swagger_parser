import 'dart:io';
import 'swagger_parser.dart' as swagger_parser;

/// Used for run `dart run swagger_parser:generate`
@Deprecated('Use `dart run swagger_parser` instead')
Future<void> main(List<String> arguments) {
  stdout.writeln(
    '\nThis command is deprecated. Use `dart run swagger_parser` instead.\n',
  );
  return swagger_parser.main(arguments);
}
