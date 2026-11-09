part of 'dart_code_builder.dart';

cb.Library _buildResponseDecoder(DartLibraryModel model) {
  final String source = switch (model.responseDecoder) {
    'native' => _nativeResponseDecoder,
    'web' => _webResponseDecoder,
    _ =>
      '''
import 'dart:async';
import 'dart:convert' as convert;
import 'dart:typed_data';
import '${model.responseDecoderImports[0]}' if (dart.library.io) '${model.responseDecoderImports[1]}' as worker;
$_responseDecoder
''',
  };
  return cb.Library(
    (library) => library.body.add(cb.Code('$source\n$_responseCancellation')),
  );
}

const _responseCancellation = '''
void Function() _listenForCancellation(Future<Object>? cancelled, void Function(Object, StackTrace) fail) {
  // Release results and buffers when a shared cancellation token stays alive.
  void Function(Object, StackTrace)? callback = fail;
  unawaited(cancelled?.then((error) => callback?.call(error, StackTrace.current), onError: (Object error, StackTrace stack) => callback?.call(error, stack)));
  return () => callback = null;
}
''';

const _responseDecoder = '''
/// Keeps the parsed JSON for a raw Retrofit response.
final class DecodedResponse<T> {
  /// Stores the typed value and the original JSON.
  const DecodedResponse(this.value, this.json);

  /// Decoded DTO or scalar.
  final T value;

  /// JSON before DTO conversion.
  final Object? json;
}

/// Reads bytes and decodes JSON. Cancellation stops reading or worker execution.
Future<T> decodeResponse<T>(Stream<List<int>> source, T Function(Object?) convert, {Future<Object>? cancelled}) async {
  final bytes = await readResponseBytes(source, cancelled: cancelled);
  return worker.decode(bytes, convert, cancelled: cancelled);
}

/// Reads a non-JSON error body using the transport text policy.
Future<String> readResponseText(Stream<List<int>> source, {Future<Object>? cancelled}) async =>
    convert.utf8.decode(await readResponseBytes(source, cancelled: cancelled), allowMalformed: true);

/// Reads response bytes. Throws the supplied cancellation error.
Future<List<int>> readResponseBytes(Stream<List<int>> source, {Future<Object>? cancelled}) {
  final result = Completer<List<int>>();
  final bytes = BytesBuilder(copy: false);
  StreamSubscription<List<int>>? subscription;
  void fail(Object error, StackTrace stack) {
    if (result.isCompleted) return;
    result.completeError(error, stack);
    // Preserve the request error if stream cleanup also fails.
    unawaited(subscription?.cancel().catchError((Object error, StackTrace stack) {}));
  }
  subscription = source.listen((chunk) {
    if (!result.isCompleted) bytes.add(chunk);
  }, onError: fail, onDone: () {
    if (!result.isCompleted) result.complete(bytes.takeBytes());
  }, cancelOnError: true);
  final stopListening = _listenForCancellation(cancelled, fail);
  return result.future.whenComplete(stopListening);
}
''';

const _nativeResponseDecoder = '''
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

/// Decodes JSON and constructs the value in a cancellable isolate.
Future<T> decode<T>(List<int> bytes, T Function(Object?) convert, {Future<Object>? cancelled}) async {
  final result = Completer<T>();
  final port = ReceivePort();
  Isolate? worker;
  void fail(Object error, StackTrace stack) {
    if (!result.isCompleted) result.completeError(error, stack);
  }
  final subscription = port.listen((Object? message) {
    if (result.isCompleted) return;
    if (message is List<Object?> && message.first == true) {
      result.complete(message[1] as T);
    } else if (message is List<Object?> && message.first == false) {
      fail(message[1]!, StackTrace.fromString(message[2]! as String));
    } else if (message is List<Object?>) {
      fail(RemoteError(message[0]! as String, message[1]! as String), StackTrace.fromString(message[1]! as String));
    } else {
      fail(StateError('Response decoder exited without a result.'), StackTrace.current);
    }
  });
  final stopListening = _listenForCancellation(cancelled, fail);
  // Spawn separately so cancellation can complete before worker startup.
  unawaited(Isolate.spawn(_decode, (port.sendPort, TransferableTypedData.fromList([bytes is Uint8List ? bytes : Uint8List.fromList(bytes)]), convert), onError: port.sendPort, onExit: port.sendPort).then((isolate) {
    worker = isolate;
    if (result.isCompleted) isolate.kill(priority: Isolate.immediate);
  }, onError: fail));
  try {
    return await result.future;
  } finally {
    stopListening();
    worker?.kill(priority: Isolate.immediate);
    port.close();
    await subscription.cancel();
  }
}

void _decode((SendPort, TransferableTypedData, Object? Function(Object?)) message) {
  final (port, bytes, convert) = message;
  try {
    final value = convert(jsonDecode(utf8.decode(bytes.materialize().asUint8List())));
    Isolate.exit(port, [true, value]);
  } catch (error, stack) {
    Isolate.exit(port, [false, error, stack.toString()]);
  }
}
''';

const _webResponseDecoder = '''
import 'dart:async';
import 'dart:convert';

/// Decodes inline on web. A synchronous decode cannot be interrupted.
Future<T> decode<T>(List<int> bytes, T Function(Object?) convert, {Future<Object>? cancelled}) async {
  final result = Completer<T>();
  void fail(Object error, StackTrace stack) {
    if (!result.isCompleted) result.completeError(error, stack);
  }
  final stopListening = _listenForCancellation(cancelled, fail);
  scheduleMicrotask(() {
    if (result.isCompleted) return;
    try {
      result.complete(convert(jsonDecode(utf8.decode(bytes))));
    } catch (error, stack) {
      fail(error, stack);
    }
  });
  return result.future.whenComplete(stopListening);
}
''';

bool _hasBufferedJson(DartClientOperation op) => op.variants.isEmpty
    ? op.response.symbol != 'void' && _jsonMedia(op.mediaType)
    : op.variants.values.any((v) => v.type != null && _jsonMedia(v.mediaType));

Iterable<cb.Method> _responseConverters(
  DartClientOperation op,
  Set<String> qualified, {
  bool preserveJson = false,
}) sync* {
  final json = _JsonBuilder(
    op.objectTypes.isNotEmpty
        ? op.objectTypes
        : {
            if (op.objectResponse) op.response.symbol,
            for (final v in op.variants.values)
              if (v.objectPayload) v.type!.symbol,
          },
    const {},
    matchIntegers: false,
    qualified: qualified,
  );
  final types = <String, DartTypeReference>{
    if (op.variants.isEmpty && _jsonMedia(op.mediaType))
      '_decode${op.name}': op.response,
    for (final entry in op.variants.entries)
      if (entry.value.type != null && _jsonMedia(entry.value.mediaType))
        '_decode${op.name}_${entry.key}': entry.value.type!,
  };
  for (final MapEntry<String, DartTypeReference> entry in types.entries) {
    yield cb.Method(
      (m) => m
        ..name = entry.key
        ..static = true
        ..returns = _buildType(
          preserveJson
              ? DartTypeReference(
                  symbol: '_decoding.DecodedResponse',
                  typeArguments: [entry.value],
                )
              : entry.value,
          qualified: qualified,
        )
        ..requiredParameters.add(
          cb.Parameter(
            (p) => p
              ..name = 'value'
              ..type = cb.refer('Object?'),
          ),
        )
        ..lambda = true
        ..body = cb.Code(
          preserveJson
              ? '_decoding.DecodedResponse(${json._decode(entry.value, 'value')}, value)'
              : json._decode(entry.value, 'value'),
        ),
    );
  }
}

const _backgroundResponseError = '''
Object? _responseJson(Object? value) => value;

Future<Response<Object?>> _decodeResponseError(Object error, StackTrace stack, CancelToken? cancelToken) async {
  if (error is DioException && error.type != DioExceptionType.cancel) {
    final response = error.response;
    if (response?.data case final ResponseBody body) {
      final media = response!.headers.value('content-type')?.split(';').first.trim().toLowerCase();
      try {
        response.data = media == 'application/json' || (media?.endsWith('+json') ?? false)
            ? await _decoding.decodeResponse(body.stream, _responseJson, cancelled: cancelToken?.whenCancel)
            : await _decoding.readResponseText(body.stream, cancelled: cancelToken?.whenCancel);
      } catch (decodeError, decodeStack) {
        if (decodeError is DioException && decodeError.type == DioExceptionType.cancel) rethrow;
        throw DioException(requestOptions: error.requestOptions, response: response, type: DioExceptionType.unknown, error: decodeError, stackTrace: decodeStack);
      }
    }
  }
  Error.throwWithStackTrace(error, stack);
}
''';
