import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:swagger_parser_pages/src/worker_message.dart';
import 'package:web/web.dart' as web;

/// A browser download. Call [dispose] when its link is no longer shown.
final class const BrowserDownload(
  /// Object URL for the ZIP.
  final String url,

  /// Suggested archive filename.
  final String name,

  /// Number of generated files.
  final int count,

  /// Generation diagnostics.
  final String diagnostics,
) {
  /// Keeps the generated archive available for repeat downloads.
  this;

  /// Starts a browser download without leaving the editor.
  void save() {
    final link = web.HTMLAnchorElement()
      ..href = url
      ..download = name;
    web.document.body!.appendChild(link);
    link
      ..click()
      ..remove();
  }

  /// Releases the ZIP memory.
  void dispose() => web.URL.revokeObjectURL(url);
}

/// Owns one worker run. Each run ends on success, failure, or cancellation.
final class BrowserGeneration() {
  /// Creates a worker controller.
  this;

  web.Worker? _worker;
  Completer<BrowserDownload>? _pending;

  /// Generates a ZIP in a worker. Throws on config, schema, or worker errors.
  Future<BrowserDownload> run(
    String schema,
    String config,
    String workerUrl, {
    String? templates,
  }) async {
    cancel();
    final worker = web.Worker(workerUrl.toJS);
    final pending = Completer<BrowserDownload>();
    _worker = worker;
    _pending = pending;
    void fail(String message) {
      if (!pending.isCompleted) {
        pending.completeError(FormatException(message));
      }
    }

    worker
      ..onmessage = ((web.MessageEvent event) {
        final message = WorkerMessage.fromJS(event.data! as JSObject);
        if (message.error case final error?) {
          fail(error.toDart);
          return;
        }
        final JSUint8Array bytes = message.bytes!;
        final blob = web.Blob(
          [bytes].toJS,
          web.BlobPropertyBag(type: 'application/zip'),
        );
        pending.complete(
          BrowserDownload(
            web.URL.createObjectURL(blob),
            message.name!.toDart,
            message.count!.toDartInt,
            message.diagnostics!.toDart,
          ),
        );
      }).toJS
      ..onerror = ((web.Event event) {
        event.preventDefault();
        fail('Generation worker failed. Reload the page and try again.');
      }).toJS
      ..onmessageerror = ((web.Event event) {
        fail('Cannot read the generation result. Try again.');
      }).toJS;
    try {
      worker.postMessage(
        jsonEncode({'schema': schema, 'config': config, 'templates': templates})
            .toJS,
      );
      return await pending.future;
    } finally {
      worker.terminate();
      if (identical(_worker, worker)) {
        _worker = null;
        _pending = null;
      }
    }
  }

  /// Stops active work and releases the worker.
  void cancel() {
    _worker?.terminate();
    final Completer<BrowserDownload>? pending = _pending;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(const FormatException('Generation cancelled.'));
    }
    _worker = null;
    _pending = null;
  }
}
