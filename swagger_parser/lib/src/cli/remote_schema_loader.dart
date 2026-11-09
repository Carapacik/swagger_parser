import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:swagger_parser/src/cli/schema_download_config.dart';
import 'package:swagger_parser/swagger_parser.dart';

/// Fetches remote schemas and preserves their retrieval URIs.
final class RemoteSchemaLoader({
  /// Origin-bound request headers.
  final SchemaDownloadConfig config = const SchemaDownloadConfig(),

  /// Allows local references when the entry source is a local file.
  final bool allowFiles = false,

  /// Environment values. Defaults to the process environment.
  Map<String, String>? environment,

  /// HTTP transport. Closed by [close]. Defaults to a new client.
  HttpClient? client,
}) implements DocumentLoader {
  /// Opens a client with a 30-second timeout. Allows at most five redirects.
  this {
    _client.connectionTimeout = _timeout;
  }

  static const _timeout = Duration(seconds: 30);
  final HttpClient _client = client ?? HttpClient();
  final Map<String, String> _environment = environment ?? Platform.environment;

  /// Removes configured credentials from diagnostic text.
  String redact(String text) => config.redact(text, environment: _environment);

  /// Saves the entry document in the working directory.
  Future<SchemaSource> download(
    Uri uri, {
    String? configFile,
    String? inputId,
    Iterable<String> protectedPaths = const [],
  }) async {
    final (SchemaSource source, Uint8List bytes) = await _fetch(uri);
    final Uri actual = source.uri!;
    final String leaf = actual.pathSegments.lastOrNull ?? '';
    final String ext = p.extension(leaf).toLowerCase();
    final fallback =
        'openapi.${source.format == SchemaFormat.json ? 'json' : 'yaml'}';
    final filename =
        const {'.yaml', '.yml', '.json'}.contains(ext) &&
            !leaf.startsWith('.') &&
            !RegExp(r'[<>:"/\\|?*\x00-\x1f]').hasMatch(leaf) &&
            !RegExp(
              r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])\.',
              caseSensitive: false,
            ).hasMatch(leaf)
        ? leaf
        : fallback;
    final prefix = inputId == null ? '' : '${inputId}_';
    bool reserved(String name) =>
        const {
          'pubspec.yaml',
          'swagger_parser.yaml',
        }.contains(name.toLowerCase()) ||
        protectedPaths.any(
          (path) =>
              p.absolute(name).toLowerCase() ==
              p.normalize(p.absolute(path)).toLowerCase(),
        ) ||
        configFile != null &&
            p.absolute(name).toLowerCase() ==
                p.normalize(configFile).toLowerCase();
    final proposed = '$prefix$filename';
    final name = reserved(proposed) ? '$prefix$fallback' : proposed;
    if (reserved(name)) {
      throw FileSystemException(
        'Download would replace the active config',
        name,
      );
    }
    final Directory stage = await Directory.current.createTemp(
      '.swagger_parser-download-',
    );
    try {
      final file = File(p.join(stage.path, name));
      await file.writeAsBytes(bytes);
      await file.rename(p.absolute(name));
    } finally {
      await stage.delete(recursive: true);
    }
    stdout.writeln(redact('Downloaded $name.'));
    return source;
  }

  @override
  Future<SchemaSource> load(Uri uri) async {
    if (allowFiles && uri.scheme == 'file') {
      return await const FileSchemaSourceLoader().load(uri);
    }
    return (await _fetch(uri)).$1;
  }

  void _validateUri(Uri uri) {
    if (!{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw OpenApiException(
        'Expected an HTTP(S) reference without userinfo.',
        sourceUri: uri.replace(userInfo: ''),
      );
    }
  }

  Future<(SchemaSource, Uint8List)> _fetch(Uri uri) async {
    Uri actual = uri.removeFragment();
    _validateUri(actual);
    try {
      for (var redirects = 0; ; redirects++) {
        final Map<String, String> headers = config.headersFor(
          actual,
          _environment,
        );
        final HttpClientRequest request = await _client
            .getUrl(actual)
            .timeout(_timeout);
        request.followRedirects = false;
        headers.forEach(request.headers.set);
        final HttpClientResponse response = await request.close().timeout(
          _timeout,
        );
        if (const {301, 302, 303, 307, 308}.contains(response.statusCode)) {
          final String? location = response.headers.value(
            HttpHeaders.locationHeader,
          );
          await response.drain<void>().timeout(_timeout);
          if (location == null || location.isEmpty) {
            throw OpenApiException(
              'Redirect has no Location header.',
              sourceUri: actual,
            );
          }
          if (redirects == 5) {
            throw OpenApiException(
              'Schema redirect limit exceeded.',
              sourceUri: actual,
            );
          }
          final Uri next;
          try {
            next = actual.resolve(location).removeFragment();
          } on FormatException {
            throw OpenApiException(
              'Invalid schema redirect URI.',
              sourceUri: actual,
            );
          }
          _validateUri(next);
          if (actual.scheme == 'https' && next.scheme == 'http') {
            throw OpenApiException(
              'HTTPS-to-HTTP schema redirects are not allowed.',
              sourceUri: actual,
            );
          }
          actual = next;
          continue;
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          await response.drain<void>().timeout(_timeout);
          throw OpenApiException(
            'HTTP ${response.statusCode}.',
            sourceUri: actual,
          );
        }
        final bytes = BytesBuilder(copy: false);
        await response.timeout(_timeout).forEach(bytes.add);
        final Uint8List data = bytes.takeBytes();
        final decoded = SchemaSource.fromBytes(data, uri: actual);
        final SchemaFormat format = switch (p.url
            .extension(actual.path)
            .toLowerCase()) {
          '.json' => SchemaFormat.json,
          '.yaml' || '.yml' => SchemaFormat.yaml,
          _ => _detectFormat(decoded.content),
        };
        return (
          SchemaSource(decoded.content, uri: actual, format: format),
          data,
        );
      }
    } on IOException catch (error) {
      throw OpenApiException(
        'Schema download failed: ${redact(error.toString())}',
        sourceUri: actual,
      );
    } on TimeoutException {
      throw OpenApiException('Schema download timed out.', sourceUri: actual);
    }
  }

  /// Closes open connections.
  void close() => _client.close(force: true);
}

SchemaFormat _detectFormat(String content) {
  try {
    jsonDecode(content);
    return SchemaFormat.json;
  } on FormatException {
    return SchemaFormat.yaml;
  }
}
