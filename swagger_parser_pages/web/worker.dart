import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:swagger_parser_pages/src/editor_config.dart';
import 'package:swagger_parser_pages/src/editor_services.dart';
import 'package:swagger_parser_pages/src/generation_archive.dart';
import 'package:swagger_parser_pages/src/worker_message.dart';
import 'package:web/web.dart';

@JS('self')
external DedicatedWorkerGlobalScope get _scope;

/// Generates and compresses files outside the UI thread.
void main() {
  _scope.onmessage = ((MessageEvent event) {
    unawaited(_generate(event));
  }).toJS;
}

Future<void> _generate(MessageEvent event) async {
  try {
    final input =
        jsonDecode((event.data! as JSString).toDart) as Map<String, dynamic>;
    final GenerationArchive result = await EditorServices().generate(
      input['schema'] as String,
      EditorConfig.parse(input['config'] as String),
      templates: input['templates'] as String?,
    );
    _scope.postMessage(
      WorkerMessage(
        bytes: result.bytes.toJS,
        name: result.name.toJS,
        count: result.fileCount.toJS,
        diagnostics: result.diagnostics.join('\n').toJS,
      ),
    );
  } on Object catch (error) {
    final String message = switch (error) {
      GenerationException(:final message, :final diagnostics) => [
        message,
        ...diagnostics.map(formatDiagnostic),
      ].join('\n'),
      _ => error.toString(),
    };
    _scope.postMessage(WorkerMessage(error: message.toJS));
  }
}
