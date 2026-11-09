import 'dart:js_interop';

@JS('fetch')
external JSPromise<_Response> _fetch(String url);

extension type _Response(JSObject _) implements JSObject {
  external bool get ok;
  external int get status;
  external JSPromise<JSString> text();
}

Future<String> readInput(String name) async {
  final _Response response = await _fetch('fixtures/$name').toDart;
  if (!response.ok) {
    throw StateError('Cannot load $name (HTTP ${response.status}).');
  }
  return (await response.text().toDart).toDart;
}
