import 'dart:js_interop';

import 'package:swagger_parser/swagger_parser.dart';

@JS('fetch')
external JSPromise<_Response> _fetch(String path);

extension type _Response(JSObject _) implements JSObject {
  external bool get ok;
  external int get status;
  external JSPromise<JSString> text();
}

final Uri _base = Uri.parse('https://fixtures.example/extraction/');
final DocumentLoader fixtureLoader = _FixtureLoader();

Future<SchemaSource> fixtureSource(String name) =>
    fixtureLoader.load(_base.resolve(name));

final class _FixtureLoader() implements DocumentLoader {
  @override
  Future<SchemaSource> load(Uri uri) async {
    final path = 'fixtures${uri.path}';
    final _Response response = await _fetch(path).toDart;
    if (!response.ok) {
      throw StateError('Cannot load $path (HTTP ${response.status}).');
    }
    return SchemaSource((await response.text().toDart).toDart, uri: uri);
  }
}
