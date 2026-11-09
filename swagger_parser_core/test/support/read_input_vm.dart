import 'dart:io';
import 'dart:isolate';

final Future<Uri?> _library = Isolate.resolvePackageUri(
  Uri.parse('package:swagger_parser_core/swagger_parser_core.dart'),
);

Future<String> readInput(String name) => _library.then((library) {
  if (library == null) {
    throw StateError('Cannot locate swagger_parser_core.');
  }
  return File.fromUri(library.resolve('../test/fixtures/$name')).readAsString();
});
