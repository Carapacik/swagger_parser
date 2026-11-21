import 'dart:async';

import 'package:swagger_parser_core/src/diagnostics/diagnostic.dart';

final _warningKey = Object();

/// Receives recoverable errors in the current parse scope.
void Function(Diagnostic)? get parseWarningHandler {
  final Object? handler = Zone.current[_warningKey];
  return handler is void Function(Diagnostic) ? handler : null;
}

/// Runs [read] with a handler for recoverable input errors.
/// A null [onWarning] selects strict parsing. Concurrent calls are independent.
T withParseWarnings<T>(
  void Function(Diagnostic)? onWarning,
  T Function() read,
) {
  if (onWarning == parseWarningHandler) {
    return read();
  }
  return runZoned(read, zoneValues: {_warningKey: onWarning ?? false});
}
