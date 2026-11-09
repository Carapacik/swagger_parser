part of 'dart_model_mapper.dart';

const _multipart = 'multipart/form-data';
const _urlencoded = 'application/x-www-form-urlencoded';

bool _isJsonMedia(String media) =>
    DartHttpMedia.parse(media) == DartHttpMedia.json;

MapEntry<String?, ApiMediaType>? _selectMedia(
  Map<String?, ApiMediaType> content, {
  bool request = false,
}) {
  for (final MapEntry<String?, ApiMediaType> entry in content.entries) {
    if (entry.key == null || _isJsonMedia(entry.key!)) {
      return entry;
    }
  }
  return content.entries
      .where((entry) => !request || !(entry.key?.contains('*') ?? false))
      .firstOrNull;
}

DartTypeReference _listOf(DartTypeReference type) =>
    DartTypeReference(symbol: 'List', typeArguments: [type]);

final DartTypeReference _bytesType = _listOf(DartTypeReference(symbol: 'int'));

extension on _Mapping {
  DartTypeReference _textType(ReferenceLocation? id, _Direction direction) {
    if (id != null) {
      final _SchemaUse schema = index.use(id, const {}, direction);
      if (_customType(schema) case final type?) {
        if (type.scalarCodec!.wireType != 'String' || type.isNullable) {
          _fail(schema, 'Text payloads require a non-null string mapping.');
        }
        return type;
      }
    }
    return DartTypeReference(symbol: 'String');
  }

  DartTypeReference? _responseType(
    ApiMediaType entry,
    String media,
    String hint,
  ) {
    if (DartHttpMedia.parse(media) == DartHttpMedia.bytes ||
        DartHttpMedia.parse(media) == DartHttpMedia.multipart ||
        DartHttpMedia.parse(media) == DartHttpMedia.form) {
      return config.streamBinaryResponses &&
              DartHttpMedia.parse(media) == DartHttpMedia.bytes
          ? DartTypeReference(symbol: 'Stream', typeArguments: [_bytesType])
          : _bytesType;
    }
    if (DartHttpMedia.parse(media) == DartHttpMedia.text) {
      return _textType(entry.schema, _Direction.response);
    }
    final lines = DartHttpMedia.parse(media) == DartHttpMedia.jsonLines;
    if (lines || DartHttpMedia.parse(media) == DartHttpMedia.events) {
      final ReferenceLocation? item = entry.itemSchema;
      final ReferenceLocation? array = entry.schema;
      final _SchemaUse? schema = item != null
          ? index.use(item, const {}, _Direction.response)
          : array == null
          ? null
          : _concrete(index.use(array, const {}, _Direction.response)).items;
      return DartTypeReference(
        symbol: 'Stream',
        typeArguments: [
          if (schema == null && lines)
            _any
          else if (schema == null)
            DartTypeReference(
              symbol: 'Map',
              typeArguments: [
                DartTypeReference(symbol: 'String'),
                _any,
              ],
            )
          else
            _type(schema, '${hint}Item'),
        ],
      );
    }
    if (!_isJsonMedia(media)) {
      return null;
    }
    return entry.schema == null
        ? _any
        : _type(index.use(entry.schema!, const {}, _Direction.response), hint);
  }

  Map<String, Object?> _operationExtra(ApiOperation op) {
    final servers = <Object?>[];
    for (final JsonValue value in op.servers) {
      final server = value.value! as Map<String, Object?>;
      if (server.containsKey('url')) {
        servers.add(server);
      } else {
        final List<Object?> schemes =
            server['schemes'] as List<Object?>? ?? const [];
        final Object? host = server['host'];
        final Object base = server['basePath'] ?? '';
        for (final Object? scheme in schemes.isEmpty ? [null] : schemes) {
          servers.add({
            'url': host == null
                ? base
                : '${scheme == null ? '' : '$scheme:'}//$host$base',
          });
        }
      }
    }
    return {
      if (servers.isNotEmpty) 'openapi.servers': servers,
      if (api.security.isNotEmpty || op.security.isNotEmpty) ...{
        'openapi.security': [for (final entry in op.security) entry.value],
        'openapi.securitySchemes': {
          for (final entry in op.security)
            for (final name in (entry.value! as Map<String, Object?>).keys)
              if (api.securitySchemes[name] case final scheme?)
                name: scheme.value,
        },
      },
    };
  }

  DartClientBody? _httpBody(
    ApiOperation op,
    ApiRequestBody body,
    Set<String> arguments,
  ) {
    final MapEntry<String?, ApiMediaType>? selected = body.formFields.isEmpty
        ? _selectMedia(body.content, request: true)
        : body.content.entries
              .where(
                (entry) =>
                    entry.key == null ||
                    DartHttpMedia.parse(entry.key) == DartHttpMedia.multipart ||
                    DartHttpMedia.parse(entry.key) == DartHttpMedia.form,
              )
              .firstOrNull;
    if (selected == null) {
      return null;
    }
    final String media =
        selected.key ??
        (body.formFields.isEmpty
            ? 'application/json'
            : body.formFields.any(
                (p) =>
                    p.schema != null &&
                    index
                        .use(p.schema!, const {}, _Direction.request)
                        .types
                        .contains('file'),
              )
            ? _multipart
            : _urlencoded);
    final ApiMediaType entry = selected.value;
    final ReferenceLocation? id = entry.schema;
    final hint = '${_operationNameCandidate(op)}Request';
    final DartHttpMedia codec = DartHttpMedia.parse(media);
    if (codec != DartHttpMedia.multipart && codec != DartHttpMedia.form) {
      final DartTypeReference type = codec == DartHttpMedia.bytes
          ? _bytesType
          : codec == DartHttpMedia.text
          ? _textType(id, _Direction.request)
          : codec == DartHttpMedia.events || codec == DartHttpMedia.jsonLines
          ? DartTypeReference(symbol: 'String')
          : id == null
          ? _any
          : _type(index.use(id, const {}, _Direction.request), hint);
      return DartClientBody(
        type: type,
        documentation: DartDocumentation(
          description: config.generateDocs ? body.description : null,
        ),
        mediaType: media,
        isRequired: body.isRequired,
        isObjectDto: _objectDto(type),
      );
    }

    final fields = <DartFormField>[];
    void add(
      String key,
      _SchemaUse schema, {
      required bool required,
      String? collectionFormat,
      DartDocumentation? documentation,
    }) {
      final _SchemaUse member = _concrete(schema);
      final _SchemaUse? item = member.items;
      final _SchemaUse target = item == null ? member : _concrete(item);
      final String path = key.replaceAll('~', '~0').replaceAll('/', '~1');
      final ApiEncoding? encoding = entry.encodings['/encoding/$path'];
      final Map<String, Object?> settings =
          encoding?.definition.value as Map<String, Object?>? ?? const {};
      final contentType = settings['contentType'] as String?;
      final bool chooseType =
          contentType != null &&
          (contentType.contains(',') || contentType.contains('*'));
      final bool binary =
          target.types.contains('file') ||
          target.fields['format'] == 'binary' ||
          target.fields['contentMediaType'] == 'application/octet-stream';
      final bool file =
          codec == DartHttpMedia.multipart &&
          (binary || chooseType || (encoding?.headers.isNotEmpty ?? false));
      final DartTypeReference type = file
          ? DartTypeReference(
              symbol: 'MultipartFile',
              isNullable: _nullable(item ?? schema),
            )
          : _wireType(_type(schema, '${hint}_$key'));
      final DartTypeReference element = type.symbol == 'List'
          ? type.typeArguments.single
          : type;
      final DartTypeReference wire = _unwrappedParameterType(element);
      final bool scalarModel =
          (enums.any((e) => e.name == element.symbol) ||
              values.any((v) => v.name == element.symbol)) &&
          (_dartScalars.containsValue(wire.symbol) ||
              enums.any((e) => e.name == wire.symbol));
      final String? separator = switch ((
        collectionFormat,
        settings['style'],
        settings['explode'],
      )) {
        ('ssv', _, _) || (_, 'spaceDelimited', _) => ' ',
        ('pipes', _, _) || (_, 'pipeDelimited', _) => '|',
        ('tsv', _, _) => '\t',
        ('csv', _, _) || (_, _, false) => ',',
        _ => null,
      };
      fields.add((
        documentation: documentation ?? _schemaDocumentation(schema),
        name: _identifier(key, arguments),
        key: key,
        type: file && item != null
            ? DartTypeReference(
                symbol: 'List',
                typeArguments: [type],
                isNullable: _nullable(schema),
              )
            : type,
        required: required,
        contentType: chooseType
            ? null
            : contentType ?? (scalarModel ? 'text/plain' : null),
        file: file,
        separator: file ? null : separator,
        defaultValue: _argumentDefault(schema, required: required || file),
      ));
    }

    if (body.formFields.isNotEmpty) {
      for (final ApiParameter field in body.formFields) {
        if (field.schema == null) {
          return null;
        }
        add(
          field.name,
          index.use(field.schema!, const {}, _Direction.request),
          required: field.isRequired,
          collectionFormat: field.serialization.collectionFormat,
          documentation: _parameterDocumentation(field),
        );
      }
    } else if (id != null) {
      final _SchemaUse schema = _concrete(
        index.use(id, const {}, _Direction.request),
      );
      final Set<String>? types = _conjunctiveTypes(schema);
      if (codec == DartHttpMedia.form &&
          types != null &&
          !types.contains('object')) {
        return null;
      }
      if (schema.types.contains('object') ||
          schema.properties.isNotEmpty ||
          schema.allOf.isNotEmpty) {
        final _ObjectShape shape = _shape(schema);
        for (final MapEntry<String, _SchemaUse> field
            in shape.properties.entries) {
          add(
            field.key,
            field.value,
            required: shape.required.contains(field.key),
          );
        }
      }
    }
    // Keep the complete body optional when its schema has required fields.
    final bool raw =
        fields.isEmpty ||
        (body.formFields.isEmpty &&
            !body.isRequired &&
            fields.any((f) => f.required)) ||
        entry.encodings.keys.any(
          (key) => !RegExp(r'^/encoding/[^/]+$').hasMatch(key),
        );
    return DartClientBody(
      documentation: DartDocumentation(
        description: config.generateDocs ? body.description : null,
      ),
      type: codec == DartHttpMedia.multipart
          ? DartTypeReference(
              symbol: config.httpClient == HttpClientBackend.http
                  ? 'MultipartRequest'
                  : 'FormData',
            )
          : DartTypeReference(
              symbol: 'Map',
              typeArguments: [
                DartTypeReference(symbol: 'String'),
                _any,
              ],
            ),
      fields: raw ? const [] : fields,
      mediaType: media,
      isRequired: body.isRequired,
      isObjectDto: false,
    );
  }
}
