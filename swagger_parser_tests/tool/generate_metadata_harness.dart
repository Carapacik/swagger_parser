import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';

Future<void> main(List<String> args) async {
  final DtoSerializer serializer = DtoSerializer.values.byName(
    args.isEmpty ? 'freezed' : args.single,
  );
  final SchemaSource source = await const FileSchemaSourceLoader().loadPath(
    'test/fixtures/enum_metadata/openapi3_1.yaml',
  );
  final result = await const SwaggerParserRunner().generate(
    source,
    config: GenerationConfig(
      serializer: serializer,
      unknownEnumValues: UnknownValueMode.reject,
    ),
  );
  for (final file in result.files.where(
    (file) => file.relativePath.startsWith('models/'),
  )) {
    final target = File(
      'lib/enhanced_enum_${serializer.name}/${file.relativePath}',
    );
    await target.parent.create(recursive: true);
    await target.writeAsString(file.content);
    stdout.writeln(target.path);
  }
}
