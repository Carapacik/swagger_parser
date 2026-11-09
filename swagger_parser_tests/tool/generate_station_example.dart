import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';

Future<void> main() async {
  final Uri root = Platform.script.resolve('../');
  const loader = FileSchemaSourceLoader();
  final SchemaSource source = await loader.load(
    root.resolve(
      '../swagger_parser/test/fixtures/extraction/open_api_v3_2.yaml',
    ),
  );
  final GenerationResult result = await const SwaggerParserRunner().generate(
    source,
    loader: loader,
  );
  final Directory output = await Directory.fromUri(
    root.resolve('example/stations/'),
  ).create(recursive: true);
  for (final GeneratedFile file in result.files) {
    final target = File.fromUri(output.uri.resolve(file.relativePath));
    await target.parent.create(recursive: true);
    await target.writeAsString(file.content);
  }
}
