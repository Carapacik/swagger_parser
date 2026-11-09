part of 'dart_code_builder.dart';

bool _httpUsesQuery(DartClientOperation op) =>
    op.body?.mediaType == 'application/x-www-form-urlencoded' ||
    op.parameters.any(
      (p) =>
          p.contentType == 'application/x-www-form-urlencoded' ||
          p.location == DartClientParameterLocation.query && !p.allowReserved,
    );

bool _httpUsesConvert(DartClientOperation op, {bool background = false}) =>
    (!background &&
        (op.variants.isEmpty
            ? op.response.symbol != 'void' && _jsonMedia(op.mediaType)
            : op.variants.values.any(
                (v) => v.type != null && _jsonMedia(v.mediaType),
              ))) ||
    (op.body != null &&
        const {
          DartHttpMedia.form,
          DartHttpMedia.events,
          DartHttpMedia.jsonLines,
          DartHttpMedia.text,
        }.contains(DartHttpMedia.parse(op.body!.mediaType)));

String _separator(DartQueryListFormat format) => switch (format) {
  DartQueryListFormat.csv => ',',
  DartQueryListFormat.pipes => '|',
  DartQueryListFormat.ssv => ' ',
  DartQueryListFormat.tsv => '\t',
  DartQueryListFormat.multi => ',',
};

String _httpList(String name, DartQueryListFormat format) =>
    format == DartQueryListFormat.multi
    ? name
    : '$name.join(${_literal(_separator(format))})';

void _httpConstructor(cb.ClassBuilder client) {
  for (final (name, type) in [
    ('_transport', 'http.Client'),
    ('baseUrl', 'Uri'),
    (
      'prepareRequest',
      'void Function(http.BaseRequest, Map<String, Object?>)?',
    ),
  ]) {
    client.fields.add(
      cb.Field(
        (f) => f
          ..name = name
          ..modifier = cb.FieldModifier.final$
          ..type = cb.refer(type),
      ),
    );
  }
  client.constructors.add(
    cb.Constructor(
      (c) => c
        ..requiredParameters.add(
          cb.Parameter(
            (p) => p
              ..name = '_transport'
              ..toThis = true,
          ),
        )
        ..optionalParameters.addAll([
          for (final name in ['baseUrl', 'prepareRequest'])
            cb.Parameter(
              (p) => p
                ..name = name
                ..named = true
                ..required = name == 'baseUrl'
                ..toThis = true,
            ),
        ]),
    ),
  );
}

cb.Method _httpQuery() => cb.Method(
  (m) => m
    ..name = '_httpQuery'
    ..static = true
    ..returns = cb.refer('String')
    ..requiredParameters.add(
      cb.Parameter(
        (p) => p
          ..name = 'fields'
          ..type = cb.refer('Map<String, Object?>'),
      ),
    )
    ..body = const cb.Code(r'''
final entries = <String>[];
void add(String key, Object? value) {
  if (value is Iterable) {
    for (final item in value) { add(key, item); }
  } else if (value is Map) {
    for (final entry in value.entries) { add('$key[${entry.key}]', entry.value); }
  } else {
    entries.add(Uri.encodeQueryComponent(key) + '=' + Uri.encodeQueryComponent(value?.toString() ?? ''));
  }
}
fields.forEach(add);
return entries.join('&');
'''),
);

void _sendHttpRequest(
  StringBuffer code,
  DartClientOperation op,
  String path,
  String query,
  List<String> headers,
  String? accepted, {
  bool originalHttpResponse = false,
}) {
  code
    ..write(
      r"final _base = baseUrl.toString().replaceFirst(RegExp(r'/+$'), '');",
    )
    ..write('var _url = Uri.parse(_base + ($path));');
  if (query.isNotEmpty) {
    code.write(
      "final _query = _httpQuery($query); if (_query.isNotEmpty) { _url = _url.replace(query: [_url.query, _query].where((s) => s.isNotEmpty).join('&')); }",
    );
  }
  final abort =
      ', abortTrigger: ${_returnsStream(op) ? '_abortTrigger' : 'abortTrigger'}';
  final args = '${_literal(op.method)}, _url$abort';
  final DartClientBody? body = op.body;
  if (body != null &&
      DartHttpMedia.parse(body.mediaType) == DartHttpMedia.multipart) {
    _httpMultipart(code, body, args);
  } else {
    code.write('final request = http.AbortableRequest($args);');
    if (body != null) {
      _httpBodyBytes(code, body);
    }
  }
  if (body != null &&
      DartHttpMedia.parse(body.mediaType) != DartHttpMedia.multipart) {
    headers.add("'Content-Type': ${_literal(body.mediaType)}");
  }
  code
    ..write(
      "request.headers.addAll(<String, Object?>{...?options?.headers, ${headers.join(',')}}.map((key, value) => MapEntry(key, value.toString())));",
    )
    ..write(
      'if (options?.followRedirects case final value?) request.followRedirects = value; '
      'if (options?.maxRedirects case final value?) request.maxRedirects = value; '
      'prepareRequest?.call(request, extra);',
    )
    ..write(
      'final response = await _transport.send(request); final _status = response.statusCode;',
    );
  final String valid = accepted ?? '_status >= 200 && _status < 300';
  code.write(
    "if (!($valid)) { await response.stream.listen(null).cancel(); throw http.ClientException('HTTP \$_status', _url); }",
  );
  if (op.response.symbol == 'void' && !originalHttpResponse) {
    code.write('await response.stream.drain<void>();');
  }
}

void _httpBodyBytes(StringBuffer code, DartClientBody body) {
  final DartHttpMedia media = DartHttpMedia.parse(body.mediaType);
  if (body.fields.isNotEmpty) {
    final fields = <String>[];
    for (final DartFormField field in body.fields) {
      final String wire = _encode(
        field.required ? field.type : _formNonNull(field.type),
        field.name,
      );
      final value = field.separator != null
          ? '$wire.join(${_literal(field.separator)})'
          : _jsonMedia(_partMedia(field))
          ? 'convert.jsonEncode($wire)'
          : wire;
      fields.add(
        "${field.required ? '' : 'if (${field.name} != null) '}${_literal(field.key)}: $value",
      );
    }
    code.write(
      "request.bodyBytes = convert.utf8.encode(_httpQuery({${fields.join(',')}}));",
    );
    return;
  }
  final String expression = switch (media) {
    DartHttpMedia.bytes => 'body',
    DartHttpMedia.form => 'convert.utf8.encode(_httpQuery(body))',
    DartHttpMedia.json =>
      "convert.utf8.encode(${_jsonArgument(body.type, 'body')})",
    _ => 'convert.utf8.encode(${_bodyWire(body.type, 'body')})',
  };
  if (!body.isRequired) {
    final condition = body.type.symbol == 'Null'
        ? 'sendNullBody'
        : body.allowsAbsentAndNull
        ? 'body != null || sendNullBody'
        : 'body != null';
    code.write('if ($condition) {request.bodyBytes = $expression;}');
  } else {
    code.write('request.bodyBytes = $expression;');
  }
}

void _httpMultipart(StringBuffer code, DartClientBody body, String args) {
  final bool mayBeAbsent =
      !body.isRequired && !body.fields.any((f) => _jsonMedia(f.contentType));
  if (mayBeAbsent) {
    final String hasParts = body.fields.isEmpty
        ? 'body != null'
        : body.fields.map((f) => '${f.name} != null').join(' || ');
    code.write('final http.BaseRequest request; if ($hasParts) {');
  }
  code.write('final _multi = http.AbortableMultipartRequest($args);');
  if (body.fields.isEmpty) {
    code.write(
      '_multi.fields.addAll(body.fields); _multi.files.addAll(body.files);',
    );
  }
  for (final DartFormField f in body.fields) {
    final bool many = f.type.symbol == 'List' && f.separator == null;
    final String key = _literal(f.key);
    final String? media = _partMedia(f);
    code.write(
      _multipartField(f, (item, type, {required jsonNull}) {
        if (f.file && !jsonNull) {
          final contentType = media == null
              ? '$item.contentType'
              : 'http.MediaType.parse(${_literal(media)})';
          return '_multi.files.add(http.MultipartFile($key, $item.finalize(), $item.length, filename: $item.filename, contentType: $contentType));';
        }
        final String wire = jsonNull ? 'null' : _encode(type, item);
        final value = _jsonMedia(media)
            ? 'convert.jsonEncode($wire)'
            : f.separator != null
            ? '$wire.join(${_literal(f.separator)})'
            : '$wire.toString()';
        if (media != null || many) {
          final arg = media == null
              ? ''
              : ', contentType: http.MediaType.parse(${_literal(media)})';
          return '_multi.files.add(http.MultipartFile.fromString($key, $value$arg));';
        }
        return '_multi.fields[$key] = $value;';
      }),
    );
  }
  code.write(
    mayBeAbsent
        ? 'request = _multi; } else {request = http.AbortableRequest($args);}'
        : 'final request = _multi;',
  );
}

const _httpRequestOptions = '''
/// Settings for one HTTP request.
final class HttpRequestOptions {
  /// Creates request settings. Null values keep transport defaults.
  const HttpRequestOptions({
    this.headers = const {},
    this.followRedirects,
    this.maxRedirects,
  });

  /// Extra headers. Schema headers take priority.
  final Map<String, String> headers;

  /// Whether to follow redirects. Browser support depends on the client.
  final bool? followRedirects;

  /// Maximum redirects. Browser support depends on the client.
  final int? maxRedirects;
}
''';

const _httpResponse = '''
/// A decoded payload and its transport response.
final class HttpResponse<T> {
  /// Keeps the payload and response metadata.
  const HttpResponse(this.data, this.response);

  /// The decoded payload.
  final T data;

  /// A buffered Response or a StreamedResponse for a streaming payload.
  /// Read streaming content through data. The source stream has one listener.
  final http.BaseResponse response;
}
''';
