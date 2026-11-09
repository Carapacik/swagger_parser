import 'dart:js_interop';

/// Structured worker output. ZIP bytes do not pass through JSON encoding.
@JS()
extension type WorkerMessage.fromJS(JSObject _) implements JSObject {
  /// Creates a worker response.
  external factory({
    JSUint8Array? bytes,
    JSString? name,
    JSNumber? count,
    JSString? diagnostics,
    JSString? error,
  });

  /// ZIP bytes on success.
  external JSUint8Array? get bytes;

  /// Download name on success.
  external JSString? get name;

  /// Generated file count on success.
  external JSNumber? get count;

  /// Diagnostic text on success.
  external JSString? get diagnostics;

  /// Error text on failure.
  external JSString? get error;
}
