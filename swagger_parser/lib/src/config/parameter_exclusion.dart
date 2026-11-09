import 'package:swagger_parser/src/config/operation_filter_config.dart';

/// Excludes an effective HTTP parameter by its wire identity.
final class const ParameterExclusion({
  /// Original name. Header names match without case.
  required final String name,

  /// Parameter location: query, header, cookie, or querystring.
  required final String location,

  /// Mounted path globs. An empty list matches all paths.
  final List<String> paths = const [],

  /// Case-sensitive HTTP methods. An empty list matches all methods.
  final List<String> methods = const [],
}) {
  /// Sets the wire identity and optional operation selectors.
  this;

  /// Reports invalid selectors. Path parameters cannot be excluded.
  String? get validationError {
    if (name.trim().isEmpty) {
      return 'Parameter exclusions require a wire name.';
    }
    if (location == 'path') {
      return 'Path parameters cannot be excluded.';
    }
    if (!const {
      'query',
      'header',
      'cookie',
      'querystring',
    }.contains(location)) {
      return 'Invalid parameter exclusion location: $location.';
    }
    if (paths.any((path) => !OperationFilterConfig.isValidPathPattern(path))) {
      return 'Invalid parameter exclusion path pattern.';
    }
    if (methods.any(
      (method) => !RegExp(r"^[!#$%&'*+.^_`|~0-9A-Za-z-]+$").hasMatch(method),
    )) {
      return 'Expected HTTP method tokens in parameter exclusions.';
    }
    return null;
  }
}
