import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run example/generate_dto.dart <schema>');
    exitCode = 64;
    return;
  }
  const loader = FileSchemaSourceLoader();
  final SchemaSource source = await loader.loadPath(args.single);
  final GenerationResult result = await const SwaggerParserRunner().generate(
    source,
    loader: loader,
  );
  for (final GeneratedFile file in result.files.where(
    (f) => f.relativePath.split('/').contains('models'),
  )) {
    stdout.write(file.content);
  }
}
