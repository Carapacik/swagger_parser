import 'dart:convert';
import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run example/parse_file.dart <schema.json|schema.yaml>',
    );
    exitCode = 64;
    return;
  }
  final SchemaSource source = await const FileSchemaSourceLoader().loadPath(
    args.single,
  );
  final OpenApiDocument document = const OpenApiParser().parse(source);
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(document.toJson()));
}
