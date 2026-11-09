import 'package:swagger_parser/src/extraction/api_definition.dart';

/// Names used when mapping HTTP operations to Dart.
extension DartOperationNaming on ApiOperation {
  /// Returns the declared ID or a method-and-path fallback before collision checks.
  String get dartMethodNameCandidate {
    if (operationId case final id?) {
      return id;
    }
    return dartPathMethodNameCandidate;
  }

  /// Uses the HTTP method and mounted path before name checks.
  String get dartPathMethodNameCandidate {
    final name = StringBuffer(method.toLowerCase());
    var afterParameter = false;
    for (final String segment in path.split('/')) {
      for (final RegExpMatch part in _routeParts.allMatches(segment)) {
        final String? parameter = part.group(1);
        if (parameter != null) {
          name.write(afterParameter ? 'And' : 'By');
        }
        final String token = parameter ?? part[0]!;
        for (final RegExpMatch word in _words.allMatches(token)) {
          final String token = word[0]!;
          final String value = token == token.toUpperCase()
              ? token.toLowerCase()
              : token;
          name.write('${value[0].toUpperCase()}${value.substring(1)}');
        }
        afterParameter = parameter != null;
      }
    }
    return name.toString();
  }
}

final _routeParts = RegExp(r'\{([^{}]+)\}|[^{}]+');
final _words = RegExp('[A-Za-z0-9]+');
