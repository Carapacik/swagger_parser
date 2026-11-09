import 'dart:isolate';

import 'package:swagger_parser/swagger_parser.dart';

const fixtureLoader = FileSchemaSourceLoader();
final Future<Uri?> _library = Isolate.resolvePackageUri(
  Uri.parse('package:swagger_parser/swagger_parser.dart'),
);

Future<SchemaSource> fixtureSource(String name) => _library.then(
  (library) =>
      fixtureLoader.load(library!.resolve('../test/fixtures/extraction/$name')),
);
