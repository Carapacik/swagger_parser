import 'dart:io';

import 'package:swagger_parser_core/swagger_parser_core.dart';

/// Origin-bound headers for schema retrieval. No credentials are set by default.
final class const SchemaDownloadConfig({
  /// Credential records. Child lists replace inherited records.
  final List<SchemaDownloadCredential> credentials = const [],
}) {
  /// Creates retrieval settings. Values are resolved before each matching request.
  this;

  /// Selects exact-origin headers. Missing or invalid selected values fail.
  Map<String, String> headersFor(Uri uri, Map<String, String> environment) {
    final SchemaDownloadCredential? rule = credentials
        .where((rule) => rule.origin.origin == uri.origin)
        .firstOrNull;
    if (rule == null) {
      return const {};
    }
    return {
      for (final entry in rule.headers.entries)
        entry.key: entry.value.resolve(environment),
    };
  }

  /// Removes configured header values and URL userinfo from diagnostics.
  String redact(String text, {Map<String, String>? environment}) {
    final Map<String, String> values = environment ?? Platform.environment;
    final secrets = <String>{};
    for (final SchemaDownloadCredential rule in credentials) {
      for (final MapEntry<String, SchemaDownloadHeader> entry
          in rule.headers.entries) {
        final String? value = entry.value.value ?? values[entry.value.env];
        if (value == null || value.isEmpty) {
          continue;
        }
        secrets.add(value);
        if (entry.key.toLowerCase() == 'authorization') {
          final int space = value.indexOf(' ');
          if (space >= 0 && space < value.length - 1) {
            secrets.add(value.substring(space + 1));
          }
        }
      }
    }
    var result = text;
    for (final String secret
        in secrets.toList()..sort((a, b) => b.length.compareTo(a.length))) {
      result = result
          .replaceAll(secret, '[redacted]')
          .replaceAll(Uri.encodeComponent(secret), '[redacted]');
    }
    return result.replaceAllMapped(
      RegExp(r'(https?://)[^\s/@]+@', caseSensitive: false),
      (match) => '${match[1]}[redacted]@',
    );
  }
}

/// Headers for one normalized HTTP(S) origin.
final class const SchemaDownloadCredential(
  /// Origin without a path, query, fragment, or userinfo.
  final Uri origin,

  /// Headers keyed by lowercase HTTP field name.
  final Map<String, SchemaDownloadHeader> headers,
) {
  /// Creates one credential record.
  this;
}

/// A literal header or a reference to an environment variable.
final class const SchemaDownloadHeader({
  /// Literal value. Mutually exclusive with [env].
  final String? value,

  /// Environment variable name. Stores the complete header value.
  final String? env,
}) {
  /// Creates a header value.
  this;

  /// Resolves a selected header. Throws on missing, empty, or invalid values.
  String resolve(Map<String, String> environment) {
    final String? resolved = value ?? environment[env];
    if (resolved == null || resolved.trim().isEmpty) {
      throw OpenApiException(
        'Missing schema credential environment variable: $env.',
      );
    }
    if (!isValidValue(resolved)) {
      throw const OpenApiException('Invalid schema credential header value.');
    }
    return resolved;
  }

  /// Accepts non-empty HTTP values without line breaks or control characters.
  static bool isValidValue(String value) =>
      value.trim().isNotEmpty &&
      value.codeUnits.every((c) => (c >= 32 || c == 9) && c != 127 && c <= 255);
}
