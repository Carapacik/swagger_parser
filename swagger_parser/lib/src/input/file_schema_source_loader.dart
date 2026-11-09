import 'package:swagger_parser/src/input/file_source_stub.dart'
    if (dart.library.io) 'package:swagger_parser/src/input/file_source_io.dart'
    as platform;
import 'package:swagger_parser_core/swagger_parser_core.dart';

/// Loads a local file as UTF-8 schema text on Dart I/O platforms.
final class const FileSchemaSourceLoader() implements DocumentLoader {
  /// Creates a loader for local file URIs.
  this;

  /// Reads a local file and uses its absolute URI for diagnostics.
  Future<SchemaSource> loadPath(String path) => load(platform.fileUri(path));

  @override
  Future<SchemaSource> load(Uri uri) async {
    if (uri.scheme != 'file') {
      throw ArgumentError.value(uri, 'uri', 'Expected a file URI');
    }
    final String path = uri.path.toLowerCase();
    final SchemaFormat format = path.endsWith('.json')
        ? SchemaFormat.json
        : path.endsWith('.yaml') || path.endsWith('.yml')
        ? SchemaFormat.yaml
        : SchemaFormat.auto;
    return SchemaSource.fromBytes(
      await platform.readFile(uri),
      format: format,
      uri: uri,
    );
  }
}
