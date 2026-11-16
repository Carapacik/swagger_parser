part of 'dart_code_builder.dart';

Iterable<String> _mediaTypes(DartClientOperation op) => op.variants.isEmpty
    ? [op.mediaType]
    : op.variants.values.where((v) => v.type != null).map((v) => v.mediaType);

bool _readsStream(DartClientOperation op) =>
    _mediaTypes(op).any((m) => DartHttpMedia.parse(m) != DartHttpMedia.json);

bool _returnsStream(DartClientOperation op) =>
    op.response.symbol == 'Stream' ||
    op.variants.values.any((v) => v.type?.symbol == 'Stream');

bool _hasEvents(DartClientOperation op) =>
    _mediaTypes(op).any((m) => DartHttpMedia.parse(m) == DartHttpMedia.events);

bool _jsonMedia(String? media) =>
    DartHttpMedia.parse(media) == DartHttpMedia.json;

bool _rawResponse(String media) => switch (DartHttpMedia.parse(media)) {
  DartHttpMedia.bytes || DartHttpMedia.form || DartHttpMedia.multipart => true,
  _ => false,
};

String? _partMedia(DartFormField field) {
  if (field.contentType != null) {
    return field.contentType;
  }
  if (field.file) {
    return null;
  }
  final DartTypeReference type = field.type.symbol == 'List'
      ? field.type.typeArguments.single
      : field.type;
  return _bodyModels(type).isNotEmpty ||
          type.symbol == 'Map' ||
          type.scalarCodec?.wireType == 'Map<String, Object?>'
      ? 'application/json'
      : null;
}

bool _usesConvert(DartClientOperation op, {bool background = false}) {
  final DartClientBody? body = op.body;
  return op.parameters.any((p) => _jsonMedia(p.contentType)) ||
      (_readsStream(op) &&
          _mediaTypes(
            op,
          ).any((m) => !_rawResponse(m) && (!background || !_jsonMedia(m)))) ||
      (body != null &&
          (_jsonMedia(body.mediaType) ||
              body.fields.any((f) => !f.file && _jsonMedia(_partMedia(f)))));
}

String _readPayload(
  _JsonBuilder json,
  DartTypeReference type,
  String media,
  bool streamed,
  String stream, {
  String? decoder,
  String? cancelled,
}) {
  if (DartHttpMedia.parse(media) == DartHttpMedia.events) {
    final DartTypeReference item = type.typeArguments.single;
    final events = '_readEvents($stream)';
    if (item.symbol == 'Map' && item.typeArguments.last.symbol == 'Object') {
      return events;
    }
    // A string item selects the data field. Object items describe the parsed event.
    if (item.symbol == 'DateTime' || item.scalarCodec?.wireType == 'String') {
      return "$events.map((event) => ${json._decode(item, "event['data']")})";
    }
    if (item.symbol == 'String') {
      return "$events.map((event) => event['data']! as String)";
    }
    final value = json.objectTypes.contains(item.symbol)
        ? 'event'
        : 'event as Object?';
    final String read = json.objectTypes.contains(item.symbol)
        ? "${json.qualified.contains(item.symbol) ? 'models.' : ''}${item.symbol}.fromJson(event)"
        : json._decode(item, value);
    return '$events.map((event) => $read)';
  }
  if (DartHttpMedia.parse(media) == DartHttpMedia.jsonLines) {
    final DartTypeReference item = type.typeArguments.single;
    final String read = json._decode(item, 'value');
    return 'const convert.LineSplitter().bind(convert.utf8.decoder.bind($stream)).map((line) { final Object? value = convert.jsonDecode(line); return $read; })';
  }
  if (_rawResponse(media)) {
    if (type.symbol == 'Stream') {
      return stream;
    }
    return 'await $stream.expand((chunk) => chunk).toList()';
  }
  final text = 'convert.utf8.decoder.bind($stream).join()';
  if (DartHttpMedia.parse(media) == DartHttpMedia.text) {
    return type.scalarCodec == null
        ? 'await $text'
        : json._decode(type, '(await $text)');
  }
  if (decoder != null) {
    return 'await _decoding.decodeResponse($stream, $decoder, cancelled: $cancelled)';
  }
  if (streamed) {
    return 'await $text.then((text) {final Object? value = convert.jsonDecode(text); return ${json._decode(type, 'value')};})';
  }
  return json._decode(type, 'response.data');
}

cb.Method _readEvents() => cb.Method(
  (m) => m
    ..name = '_readEvents'
    ..static = true
    ..modifier = cb.MethodModifier.asyncStar
    ..returns = cb.refer('Stream<Map<String, Object?>>')
    ..requiredParameters.add(
      cb.Parameter(
        (p) => p
          ..name = 'bytes'
          ..type = cb.refer('Stream<List<int>>'),
      ),
    )
    ..body = const cb.Code(r'''
final lines = const convert.LineSplitter().bind(const convert.Utf8Decoder(allowMalformed: true).bind(bytes));
final data = <String>[];
String? id;
int? retry;
String? event;
await for (final line in lines) {
  if (line.isEmpty) {
    if (data.isNotEmpty) {
      yield {'data': data.join('\n'), 'event': event == null || event.isEmpty ? 'message' : event, if (id != null) 'id': id, if (retry != null) 'retry': retry};
    }
    data.clear();
    event = null;
    continue;
  }
  final colon = line.indexOf(':');
  final key = colon < 0 ? line : line.substring(0, colon);
  var value = colon < 0 ? '' : line.substring(colon + 1);
  if (value.startsWith(' ')) value = value.substring(1);
  switch (key) {
    case 'data': data.add(value);
    case 'event': event = value;
    case 'id': if (!value.contains('\u0000')) id = value;
    case 'retry': if (RegExp(r'^\d+$').hasMatch(value)) retry = int.tryParse(value) ?? retry;
  }
}
'''),
);

DartTypeReference _formNonNull(DartTypeReference type) => DartTypeReference(
  symbol: type.symbol,
  importUrl: type.importUrl,
  scalarCodec: type.scalarCodec,
  typeArguments: type.typeArguments,
  isMetadataEnum: type.isMetadataEnum,
);

String _multipartField(
  DartFormField field,
  String Function(
    String value,
    DartTypeReference type, {
    required bool jsonNull,
  })
  emit,
) {
  final code = StringBuffer();
  final String name = field.name;
  final bool many = field.type.symbol == 'List' && field.separator == null;
  final bool nullable = !field.required || field.type.isNullable;
  final bool json = _jsonMedia(field.contentType);
  if (nullable) {
    if (json) {
      code.write(
        'if ($name == null) {${emit(name, field.type, jsonNull: true)}} else {',
      );
    } else {
      code.write('if ($name != null) {');
    }
  }
  if (many) {
    code.write('for (final item in $name) {');
    final DartTypeReference type = field.type.typeArguments.single;
    if (type.isNullable) {
      if (json) {
        code.write(
          'if (item == null) {${emit('item', type, jsonNull: true)}} else {',
        );
      } else {
        code.write('if (item != null) {');
      }
    }
    code.write(emit('item', _formNonNull(type), jsonNull: false));
    if (type.isNullable) {
      code.write('}');
    }
    code.write('}');
  } else if (field.type.symbol == 'List' &&
      field.type.typeArguments.single.isNullable &&
      !json) {
    final type = DartTypeReference(
      symbol: 'List',
      typeArguments: [_formNonNull(field.type.typeArguments.single)],
    );
    code.write(emit('$name.nonNulls.toList()', type, jsonNull: false));
  } else {
    code.write(emit(name, _formNonNull(field.type), jsonNull: false));
  }
  if (nullable) {
    code.write('}');
  }
  return code.toString();
}

String _requestData(StringBuffer code, DartClientBody body, bool optionalNull) {
  final String media = body.mediaType;
  if (body.fields.isNotEmpty) {
    final multi = DartHttpMedia.parse(media) == DartHttpMedia.multipart;
    code.write(
      multi
          ? 'final formData = FormData();'
          : 'final formData = <String, Object?>{};',
    );
    for (final DartFormField field in body.fields) {
      final String name = field.name;
      final String key = _literal(field.key);
      final array = field.type.symbol == 'List';
      final String? partMedia = _partMedia(field);
      if (multi) {
        code.write(
          _multipartField(field, (item, type, {required jsonNull}) {
            if (field.file && !jsonNull) {
              final value = partMedia == null
                  ? item
                  : 'MultipartFile.fromStream(() => $item.clone().finalize(), $item.length, filename: $item.filename, headers: $item.headers, contentType: DioMediaType.parse(${_literal(partMedia)}))';
              return 'formData.files.add(MapEntry($key, $value));';
            }
            final String wire = jsonNull ? 'null' : _encode(type, item);
            final value = _jsonMedia(partMedia)
                ? 'convert.jsonEncode($wire)'
                : array && field.separator != null
                ? '$wire.join(${_literal(field.separator)})'
                : '$wire.toString()';
            if (partMedia == null) {
              return 'formData.fields.add(MapEntry($key, $value));';
            }
            return 'formData.files.add(MapEntry($key, MultipartFile.fromString($value, contentType: DioMediaType.parse(${_literal(partMedia)}))));';
          }),
        );
      } else {
        if (!field.required) {
          code.write('if ($name != null) {');
        }
        final String wire = _encode(
          field.required ? field.type : _formNonNull(field.type),
          name,
        );
        final value = _jsonMedia(partMedia)
            ? 'convert.jsonEncode($wire)'
            : array && field.separator != null
            ? '$wire.join(${_literal(field.separator)})'
            : wire;
        code.write('formData[$key] = $value;');
        if (!field.required) {
          code.write('}');
        }
      }
    }
    if (body.isRequired) {
      return ', data: formData';
    }
    return multi
        ? ', data: formData.fields.isEmpty && formData.files.isEmpty ? null : formData'
        : ', data: formData.isEmpty ? null : formData';
  }
  if (DartHttpMedia.parse(media) == DartHttpMedia.bytes) {
    return ", data: ${body.isRequired ? '' : 'body == null ? null : '}Uint8List.fromList(body)";
  }
  if (!_jsonMedia(media)) {
    return ', data: ${body.isRequired ? '' : 'body == null ? null : '}${_bodyWire(body.type, 'body')}';
  }
  final String omit = switch (body) {
    _ when body.isRequired => '',
    _ when body.type.symbol == 'Null' => '!sendNullBody ? null : ',
    _ when optionalNull => 'body == null && !sendNullBody ? null : ',
    _ => 'body == null ? null : ',
  };
  return ', data: $omit${_jsonArgument(body.type, 'body')}';
}

String _jsonArgument(DartTypeReference type, String name) {
  if (_hasScalarCodec(type)) {
    return 'convert.jsonEncode(${_encode(type, name)})';
  }
  bool containsDateTime(DartTypeReference t) =>
      t.symbol == 'DateTime' || t.typeArguments.any(containsDateTime);
  if (!containsDateTime(type)) {
    return 'convert.jsonEncode($name)';
  }
  return 'convert.jsonEncode($name, toEncodable: (value) => (value as DateTime).toUtc().toIso8601String())';
}

String _cookieArgument(DartClientParameter p) {
  final guard = p.isRequired ? '' : 'if (${p.name} != null) ';
  final String key = _literal('${Uri.encodeComponent(p.wireName)}=');
  String encoded(String value) => p.rawCookie
      ? '_cookieValue($value.toString())'
      : p.allowReserved
      ? "_reserved($value.toString(), ${_literal(r":/?@!$&'()*+=")})"
      : 'Uri.encodeComponent($value.toString())';
  if (p.type.symbol == 'List') {
    final String item = encoded(
      _parameterWire(p.type.typeArguments.single, 'item'),
    );
    return p.explode
        ? '${guard}for (final item in ${p.name}) $key + $item'
        : "$guard$key + ${p.name}.map((item) => $item).join(',')";
  }
  if (p.objectShape != null) {
    final entries =
        '_flatObject(${_literal(p.wireName)}, ${_objectJson(p)}).entries';
    final String name = encoded('e.key');
    final String value = encoded('e.value');
    return p.explode
        ? "${guard}for (final e in $entries) if (e.value != null) $name + '=' + $value"
        : "$guard$key + [for (final e in $entries) if (e.value != null) ...[$name, $value]].join(',')";
  }
  final String scalar = p.scalarCodec ? '(${_encode(p.type, p.name)})' : p.name;
  return '$guard$key + ${encoded(scalar)}';
}

cb.Method _cancelStream() => cb.Method(
  (m) => m
    ..name = '_cancelStream'
    ..static = true
    ..types.add(cb.refer('T'))
    ..returns = cb.refer('Stream<T>')
    ..requiredParameters.addAll([
      cb.Parameter(
        (p) => p
          ..name = 'source'
          ..type = cb.refer('Stream<T>'),
      ),
      cb.Parameter(
        (p) => p
          ..name = 'cancel'
          ..type = cb.refer('void Function()'),
      ),
    ])
    ..body = const cb.Code('''
return Stream<T>.multi((output) {
    final subscription = source.listen(output.addSync, onError: output.addErrorSync, onDone: output.closeSync);
    output.onPause = subscription.pause;
    output.onResume = subscription.resume;
    output.onCancel = () {
      cancel();
      return subscription.cancel();
    };
  });'''),
);

cb.Method _reservedEncoder() => cb.Method(
  (m) => m
    ..name = '_reserved'
    ..static = true
    ..returns = cb.refer('String')
    ..requiredParameters.addAll([
      for (final name in ['value', 'allowed'])
        cb.Parameter(
          (p) => p
            ..name = name
            ..type = cb.refer('String'),
        ),
    ])
    ..body = const cb.Code("""
return value.replaceAllMapped(RegExp(r'%[0-9A-Fa-f]{2}|.', unicode: true, dotAll: true), (match) {
  final char = match[0]!;
  return char.length == 3 && char.startsWith('%') || allowed.contains(char)
      ? char : Uri.encodeComponent(char);
});
"""),
);

cb.Method _reservedPath() => cb.Method(
  (m) => m
    ..name = '_reservedPath'
    ..static = true
    ..returns = cb.refer('String')
    ..requiredParameters.add(
      cb.Parameter(
        (p) => p
          ..name = 'value'
          ..type = cb.refer('String'),
      ),
    )
    ..lambda = true
    ..body = cb.Code("_reserved(value, ${_literal(r":@!$&'()*+,;=")})"),
);

String _reservedQueryArgument(DartClientParameter p) {
  final String allowed = _literal(r":/?@!$'()*,;");
  String encode(String value) => '_reserved($value.toString(), $allowed)';
  final String key = _literal('${Uri.encodeComponent(p.wireName)}=');
  final String name = p.name;
  if (p.objectShape != null) {
    final fields =
        '_flatObject(${_literal(p.wireName)}, ${_objectJson(p)}).entries';
    if (p.queryObjectShape != null) {
      final String prefix = _literal('${Uri.encodeComponent(p.wireName)}%5B');
      return "[for (final e in $fields) $prefix + Uri.encodeComponent(e.key) + '%5D=' + (e.value == null ? '' : ${encode('e.value')} )]";
    }
    if (p.explode) {
      return "[for (final e in $fields) if (e.value != null) Uri.encodeComponent(e.key) + '=' + ${encode('e.value')}]";
    }
    final String sep = switch (p.queryListFormat) {
      DartQueryListFormat.ssv => '%20',
      DartQueryListFormat.pipes => '%7C',
      _ => ',',
    };
    return "[if ($fields.any((e) => e.value != null)) $key + [for (final e in $fields) if (e.value != null) ...[Uri.encodeComponent(e.key), ${encode('e.value')}]].join('$sep')]";
  }
  if (p.type.symbol == 'List') {
    if (p.queryListFormat == DartQueryListFormat.multi) {
      return '[for (final item in $name) $key + ${encode(_parameterWire(p.type.typeArguments.single, 'item'))}]';
    }
    final String sep = switch (p.queryListFormat) {
      DartQueryListFormat.ssv => '%20',
      DartQueryListFormat.pipes => '%7C',
      DartQueryListFormat.tsv => '%09',
      _ => ',',
    };
    return "[if ($name.isNotEmpty) $key + $name.map((item) => ${encode(_parameterWire(p.type.typeArguments.single, 'item'))}).join('$sep')]";
  }
  return '[$key + ${encode(p.scalarCodec ? '(${_encode(p.type, name)})' : name)}]';
}
