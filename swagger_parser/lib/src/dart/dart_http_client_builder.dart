part of 'dart_code_builder.dart';

void _buildHttpClient(
  cb.LibraryBuilder library,
  DartLibraryModel model,
  HttpClientBackend backend, {
  bool bodyPositional = false,
  bool originalHttpResponse = false,
  bool decodeResponsesInBackground = false,
}) {
  final packageHttp = backend == HttpClientBackend.http;
  bool background(DartClientOperation op) =>
      decodeResponsesInBackground && _hasBufferedJson(op);
  if (model.operations.any(background)) {
    if (!packageHttp) {
      library.body.add(const cb.Code(_backgroundResponseError));
    }
    library.directives.add(
      cb.Directive.import(
        p.posix.relative(
          model.responseDecoderPath,
          from: p.posix.dirname(model.relativePath),
        ),
        as: '_decoding',
      ),
    );
  }
  String? metadata(DartClientOperation op) => model.attachOperationMetadata
      ? '_apiMetadata.${model.clientMetadataName}.${op.name}'
      : null;
  if (model.attachOperationMetadata) {
    library.directives.add(
      cb.Directive.import(
        p.posix.relative(
          model.clientMetadataPath!,
          from: p.posix.dirname(model.relativePath),
        ),
        as: '_apiMetadata',
      ),
    );
  }
  final bool hasHeader = model.operations.any(
    (op) => op.parameters.any(
      (p) => p.location == DartClientParameterLocation.header,
    ),
  );
  final Set<DartClientOperation> routes = backend != HttpClientBackend.retrofit
      ? const {}
      : model.operations
            .where(
              (op) => _usesRetrofit(op, model.clientName, hasHeader: hasHeader),
            )
            .toSet();
  final String part = model.relativePath
      .split('/')
      .last
      .replaceFirst(RegExp(r'\.dart$'), '.g.dart');
  final Set<String> models = {
    for (final op in routes) ...[
      if (op.response.symbol != 'void') op.response.symbol,
      if (op.body case final body? when body.fields.isEmpty) body.type.symbol,
      for (final p in op.parameters) ..._bodyModels(p.type),
    ],
  };
  final Set<String> defaultDependencies = {
    for (final op in model.operations) ...[
      for (final p in op.parameters) ...?p.defaultValue?.dependencies,
      for (final f in op.body?.fields ?? <DartFormField>[])
        ...?f.defaultValue?.dependencies,
    ],
  };
  final Set<String> qualified = {
    ...defaultDependencies.where(model.modelPaths.containsKey),
    for (final op in model.operations) ...[
      if (op.variants.isEmpty && op.response.symbol != 'void')
        ..._bodyModels(op.response),
      for (final variant in op.variants.values)
        if (variant.type case final type?) ..._bodyModels(type),
      if (op.body case final body?) ...[
        ..._bodyModels(body.type),
        for (final field in body.fields) ..._bodyModels(field.type),
      ],
      for (final p in op.parameters) ..._bodyModels(p.type),
    ],
  }..removeAll(models);
  final Set<String> constantModels = defaultDependencies
      .where(model.modelPaths.containsKey)
      .toSet();
  models.addAll(constantModels);
  qualified.removeAll(constantModels);
  final List<DartClientOperation> direct = model.operations;
  final Iterable<DartClientParameter> arguments = routes.expand(
    (op) => op.parameters,
  );
  final Iterable<DartClientParameter> parameters = direct
      .where((op) => !routes.contains(op))
      .expand((op) => op.parameters);
  final bool hasFormObjects = parameters.any((p) => p.isFormQueryObject);
  final bool packsObjects = parameters.any(
    (p) => p.isFormQueryObject && !p.allowReserved,
  );
  final bool usesListParam =
      packsObjects ||
      parameters.any(
        (p) =>
            p.location == DartClientParameterLocation.query &&
            !p.allowReserved &&
            p.contentType == null &&
            p.type.symbol == 'List' &&
            p.queryListFormat != DartQueryListFormat.tsv,
      );
  final bool encodesForm = parameters.any(
    (p) => p.contentType == 'application/x-www-form-urlencoded',
  );
  final Iterable<DartClientBody> multipart = model.operations
      .map((op) => op.body)
      .nonNulls
      .where(
        (b) => DartHttpMedia.parse(b.mediaType) == DartHttpMedia.multipart,
      );
  final Iterable<DartFormField> parts = multipart.expand((b) => b.fields);
  library.directives.addAll([
    if (!packageHttp &&
        direct.any(
          (op) =>
              op.body != null &&
              DartHttpMedia.parse(op.body!.mediaType) == DartHttpMedia.bytes,
        ))
      cb.Directive.import('dart:typed_data', show: const ['Uint8List']),
    if (direct.any((op) => _usesConvert(op, background: background(op))) ||
        packageHttp &&
            direct.any(
              (op) => _httpUsesConvert(op, background: background(op)),
            ))
      cb.Directive.import('dart:convert', as: 'convert'),
    if (packageHttp && originalHttpResponse)
      cb.Directive.import(
        p.posix.relative(
          model.httpResponsePath,
          from: p.posix.dirname(model.relativePath),
        ),
      ),
    if (backend == HttpClientBackend.retrofit && originalHttpResponse)
      cb.Directive.import(
        'package:retrofit/retrofit.dart',
        show: const ['HttpResponse'],
      ),
    if (packageHttp) ...[
      cb.Directive.import('package:http/http.dart', as: 'http'),
      cb.Directive.import(
        p.posix.relative(
          model.httpRequestOptionsPath,
          from: p.posix.dirname(model.relativePath),
        ),
      ),
      if (parts.any((f) => f.file) || multipart.any((b) => b.fields.isEmpty))
        cb.Directive.import(
          'package:http/http.dart',
          show: [
            if (parts.any((f) => f.file)) 'MultipartFile',
            if (multipart.any((b) => b.fields.isEmpty)) 'MultipartRequest',
          ],
        ),
      if (direct.any(_returnsStream))
        cb.Directive.import('dart:async', show: const ['Completer']),
    ] else
      cb.Directive.import(
        'package:dio/dio.dart',
        show: [
          'Dio',
          'Options',
          'ResponseType',
          if (direct.any(_readsStream) || direct.any(background))
            'ResponseBody',
          'CancelToken',
          if (originalHttpResponse && backend == HttpClientBackend.dio ||
              direct.any(background))
            'Response',
          if (direct.any(background)) ...['DioException', 'DioExceptionType'],
          if (multipart.isNotEmpty) 'FormData',
          if (parts.any((f) => f.file || _partMedia(f) != null))
            'MultipartFile',
          if (parts.any((f) => _partMedia(f) != null)) 'DioMediaType',
          if (routes.isNotEmpty) 'RequestOptions',
          if (usesListParam) 'ListParam',
          if (usesListParam || encodesForm) 'ListFormat',
          if (encodesForm) 'Transformer',
        ],
      ),
    if (routes.isNotEmpty)
      cb.Directive.import(
        'package:retrofit/retrofit.dart',
        show: [
          'RestApi',
          'Extras',
          'CancelRequest',
          ...routes.map((op) => op.method).toSet(),
          'ParseErrorLogger',
          if (routes.any((op) => op.body?.fields.isEmpty ?? false)) ...[
            'Body',
            'Headers',
          ],
          if (routes.any(
            (op) => op.body?.mediaType == 'multipart/form-data',
          )) ...[
            'MultiPart',
            'Part',
          ],
          if (routes.any(
            (op) => op.body?.mediaType == 'application/x-www-form-urlencoded',
          )) ...[
            'FormUrlEncoded',
            'Field',
          ],
          if (arguments.any((p) => p.isPath)) 'Path',
          if (arguments.any(
            (p) => p.location == DartClientParameterLocation.query,
          ))
            'Query',
          if (arguments.any(
            (p) => p.location == DartClientParameterLocation.header,
          ))
            'Header',
        ],
      ),
    ..._modelImports(model, models),
    ..._modelImports(model, qualified, prefix: 'models'),
    if (model.resultFile case final file?) ...[
      cb.Directive.import(file),
      cb.Directive.export(file),
    ],
    if (routes.isNotEmpty) cb.Directive.part(part),
  ]);
  library.body.add(
    cb.Class((c) {
      c.name = model.clientName;
      if (packageHttp) {
        _httpConstructor(c);
        if (direct.any(_httpUsesQuery)) {
          c.methods.add(_httpQuery());
        }
      }
      if (encodesForm && !packageHttp) {
        c.methods.add(
          cb.Method(
            (m) => m
              ..name = '_encodedForm'
              ..static = true
              ..returns = cb.refer('String')
              ..requiredParameters.add(
                cb.Parameter(
                  (p) => p
                    ..name = 'value'
                    ..type = _jsonValue,
                ),
              )
              ..lambda = true
              ..body = const cb.Code(
                'Transformer.urlEncodeMap(value as Map<String, Object?>, ListFormat.multi)',
              ),
          ),
        );
      }
      final Iterable<DartClientParameter> reserved = direct
          .expand((op) => op.parameters)
          .where((p) => p.allowReserved);
      if (reserved.isNotEmpty) {
        c.methods.add(_reservedEncoder());
      }
      if (reserved.any((p) => p.isPath)) {
        c.methods.add(_reservedPath());
      }
      if (direct.any((op) => op.parameters.any((p) => p.rawCookie))) {
        c.methods.add(
          cb.Method(
            (m) => m
              ..name = '_cookieValue'
              ..static = true
              ..returns = cb.refer('String')
              ..requiredParameters.add(
                cb.Parameter(
                  (p) => p
                    ..name = 'value'
                    ..type = cb.refer('String'),
                ),
              )
              ..body = const cb.Code(
                '''if (value.codeUnits.any((c) => c < 0x21 || c > 0x7e || const {34, 44, 59, 92}.contains(c))) throw ArgumentError('Expected a cookie-safe value.'); return value;''',
              ),
          ),
        );
      }
      if (direct.any(_hasEvents)) {
        c.methods.add(_readEvents());
      }
      if (direct.any(_returnsStream)) {
        c.methods.add(_cancelStream());
      }
      final Iterable<DartClientParameter> objectParameters = direct
          .expand((op) => op.parameters)
          .where((p) => p.objectShape != null);
      final bool formatsObjects = objectParameters.any(
        (p) => p.isPath || p.location == DartClientParameterLocation.header,
      );
      if (objectParameters.any(
            (p) => p.location == DartClientParameterLocation.cookie,
          ) ||
          objectParameters.any((p) => p.allowReserved) ||
          formatsObjects ||
          hasFormObjects ||
          objectParameters.any(
            (p) => p.objectShape == DartParameterObjectShape.open,
          )) {
        c.methods.add(_flatObject());
      }
      if (packsObjects) {
        c.methods.add(_addQueryObject(packageHttp: packageHttp));
      }
      if (formatsObjects) {
        c.methods.add(_formatObject());
      }
      if (direct.isNotEmpty && !packageHttp) {
        c.fields.add(
          cb.Field(
            (f) => f
              ..name = '_transport'
              ..modifier = cb.FieldModifier.final$
              ..type = cb.refer('Dio'),
          ),
        );
        c.constructors.add(
          cb.Constructor(
            (ctor) => ctor
              ..name = routes.isEmpty ? null : '_'
              ..requiredParameters.add(
                cb.Parameter(
                  (p) => p
                    ..name = '_transport'
                    ..toThis = true,
                ),
              ),
          ),
        );
      }
      if (routes.isNotEmpty) {
        c.abstract = true;
        c.annotations.add(
          cb.refer('RestApi').call([], {
            'headers': cb.literalMap({'Accept': 'application/json'}),
          }),
        );
        c.constructors.add(
          cb.Constructor((ctor) {
            ctor.factory = true;
            ctor.requiredParameters.add(
              cb.Parameter(
                (p) => p
                  ..name = 'dio'
                  ..type = cb.refer('Dio'),
              ),
            );
            ctor
              ..lambda = true
              ..body = cb.Code('_${model.clientName}WithOptions(dio)');
          }),
        );
      }
      for (final DartClientOperation op in model.operations) {
        if (background(op)) {
          c.methods.addAll(
            _responseConverters(
              op,
              qualified,
              preserveJson:
                  originalHttpResponse &&
                  backend == HttpClientBackend.retrofit &&
                  op.variants.isEmpty,
            ),
          );
        }
        final cb.Method method = _withBodyPosition(
          routes.contains(op)
              ? _retrofitMethod(op, originalHttpResponse: originalHttpResponse)
              : _directMethod(
                  op,
                  qualified,
                  decodeInBackground: background(op),
                  operationMetadata: metadata(op),
                  packageHttp: packageHttp,
                  responseWrapper: originalHttpResponse
                      ? (backend == HttpClientBackend.dio
                            ? 'Response'
                            : 'HttpResponse')
                      : null,
                ),
          bodyPositional,
        );
        if (routes.contains(op)) {
          c.methods.add(
            _withBodyPosition(
              _directMethod(
                op,
                qualified,
                operationMetadata: metadata(op),
                packageHttp: false,
                nativeRetrofit: true,
                decodeInBackground: background(op),
                responseWrapper: originalHttpResponse ? 'HttpResponse' : null,
              ),
              bodyPositional,
            ).rebuild((m) => m..name = '_${op.name}WithOptions'),
          );
        }
        c.methods.add(
          method.rebuild((m) {
            final documentation = DartDocumentation(
              summary: op.summary,
              description: op.description,
              deprecated: op.deprecated,
            );
            m.docs.addAll(_dartdoc(documentation));
            m.annotations.addAll(_deprecation(documentation));
            final Map<String, DartDocumentation> parameters = {
              for (final p in op.parameters) p.name: p.documentation,
              if (op.body case final body?) ...{
                'body': body.documentation,
                for (final field in body.fields)
                  field.name: field.documentation,
              },
            };
            m.optionalParameters.replace(
              method.optionalParameters.map(
                (p) => _documentParameter(p, parameters[p.name]),
              ),
            );
            m.requiredParameters.replace(
              method.requiredParameters.map(
                (p) => _documentParameter(p, parameters[p.name]),
              ),
            );
          }),
        );
      }
    }),
  );
  // Retrofit drops cancellation and base settings when it uses @DioOptions.
  if (routes.isNotEmpty) {
    library.body.add(
      cb.Class((c) {
        c
          ..name = '_${model.clientName}WithOptions'
          ..extend = cb.refer('_${model.clientName}')
          ..constructors.add(
            cb.Constructor(
              (ctor) => ctor
                ..requiredParameters.add(
                  cb.Parameter(
                    (p) => p
                      ..name = 'dio'
                      ..type = cb.refer('Dio'),
                  ),
                )
                ..initializers.add(const cb.Code('super._(dio, dio)')),
            ),
          );
        for (final op in routes) {
          final cb.Method method = _withBodyPosition(
            _retrofitMethod(op, originalHttpResponse: originalHttpResponse),
            bodyPositional,
          );
          final String args = [
            ...method.requiredParameters.map((p) => p.name),
            ...method.optionalParameters.map((p) => '${p.name}: ${p.name}'),
          ].join(', ');
          c.methods.add(
            method.rebuild(
              (m) => m
                ..annotations.clear()
                ..annotations.add(cb.refer('override'))
                ..requiredParameters.replace(
                  method.requiredParameters.map(
                    (p) => p.rebuild((p) => p.annotations.clear()),
                  ),
                )
                ..optionalParameters.replace(
                  method.optionalParameters.map(
                    (p) => p.rebuild((p) => p.annotations.clear()),
                  ),
                )
                ..body = cb.Code(
                  '${_attachMetadata(metadata(op))}return ${background(op) ? '' : 'options == null ? super.${op.name}($args) : '}_${op.name}WithOptions($args);',
                ),
            ),
          );
        }
      }),
    );
  }
}

cb.Method _withBodyPosition(cb.Method method, bool enabled) {
  if (!enabled) {
    return method;
  }
  final cb.Parameter? body = method.optionalParameters
      .where((p) => p.name == 'body' && p.required)
      .firstOrNull;
  if (body == null) {
    return method;
  }
  return method.rebuild(
    (m) => m
      ..optionalParameters.remove(body)
      ..requiredParameters.add(
        body.rebuild(
          (p) => p
            ..named = false
            ..required = false,
        ),
      ),
  );
}

final _pathToken = RegExp(r'\{([^{}]+)\}');

bool _usesRetrofit(
  DartClientOperation op,
  String clientName, {
  required bool hasHeader,
}) {
  bool conflicts(String name) =>
      name == clientName ||
      clientTypeNames.contains(name) ||
      (hasHeader && name == 'Header');
  final DartClientBody? body = op.body;
  final bool form = body != null && _annotatedForm(body);
  if (!const {
        'GET',
        'POST',
        'DELETE',
        'PUT',
        'PATCH',
        'HEAD',
        'OPTIONS',
        'QUERY',
      }.contains(op.method) ||
      op.mediaType != 'application/json' ||
      _hasScalarCodec(op.response) ||
      (body != null &&
          (_hasScalarCodec(body.type) ||
              body.fields.any((f) => _hasScalarCodec(f.type)))) ||
      op.variants.isNotEmpty ||
      op.emptySuccessStatuses.isNotEmpty ||
      (body != null && !form && body.mediaType != 'application/json') ||
      op.parameters.any(
        (p) =>
            p.contentType != null ||
            p.scalarCodec ||
            _hasScalarCodec(p.type) ||
            p.type.typeArguments.any(_needsParameterCodec) ||
            p.allowReserved ||
            p.type.isNullable ||
            p.location == DartClientParameterLocation.cookie ||
            p.location == DartClientParameterLocation.querystring ||
            (p.objectShape != null &&
                p.location != DartClientParameterLocation.query) ||
            p.isFormQueryObject ||
            p.pathStyle != DartPathStyle.simple ||
            p.listSeparator != null ||
            p.objectShape == DartParameterObjectShape.open ||
            (p.objectShape != null &&
                (conflicts(p.type.symbol) || _mapNeedsJson(p.type))) ||
            p.queryListFormat != null &&
                p.queryListFormat != DartQueryListFormat.multi,
      ) ||
      (!op.objectResponse && op.response.symbol != 'void') ||
      conflicts(op.response.symbol) ||
      (body != null &&
          !form &&
          (!body.isObjectDto ||
              !body.isRequired ||
              body.type.isNullable ||
              conflicts(body.type.symbol))) ||
      !_retrofitPath.hasMatch(op.path)) {
    return false;
  }
  // A later Retrofit replacement can match an earlier Dart interpolation.
  final inserted = <String>{};
  for (final DartClientParameter p in op.parameters.where((p) => p.isPath)) {
    if (inserted.contains(p.wireName)) {
      return false;
    }
    inserted.add(p.name);
  }
  return true;
}

bool _annotatedForm(DartClientBody body) {
  if (!body.isRequired || body.fields.isEmpty) {
    return false;
  }
  final multipart = body.mediaType == 'multipart/form-data';
  if (!multipart && body.mediaType != 'application/x-www-form-urlencoded') {
    return false;
  }
  return body.fields.every((field) {
    // retrofit_generator inserts wire names into its generated part.
    if (!RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(field.key) ||
        field.separator != null ||
        field.contentType != null ||
        (multipart &&
            (field.type.isNullable ||
                field.type.typeArguments.any((t) => t.isNullable)))) {
      return false;
    }
    if (field.file) {
      return multipart;
    }
    final DartTypeReference type = field.type;
    final DartTypeReference item = type.symbol == 'List' && !multipart
        ? type.typeArguments.single
        : type;
    return const {'String', 'int', 'num', 'bool'}.contains(item.symbol);
  });
}

final _retrofitPath = RegExp(r'^/[a-zA-Z0-9_/%:.~+{}-]*$');

cb.Parameter _argument(
  DartClientParameter p, {
  bool annotate = false,
  Set<String> qualified = const {},
}) => cb.Parameter((arg) {
  arg
    ..name = p.name
    ..named = true
    ..required = p.isRequired
    ..defaultTo = p.defaultValue?.expression == null
        ? null
        : cb.Code(p.defaultValue!.expression!)
    ..type = _buildType(
      p.type,
      qualified: qualified,
    ).rebuild((t) => t.isNullable = !p.isRequired || p.type.isNullable);
  if (annotate) {
    final String key = p.wireName;
    final cb.Expression literal = key.contains(RegExp(r'[\\$\x00-\x1f]'))
        ? cb.literalString(key, raw: true)
        : cb.literalString(key);
    final String name = switch (p.location) {
      DartClientParameterLocation.path => 'Path',
      DartClientParameterLocation.query => 'Query',
      DartClientParameterLocation.header => 'Header',
      _ => throw StateError('Expected a Retrofit parameter.'),
    };
    arg.annotations.add(cb.refer(name).call([literal]));
  }
});

Iterable<String> _bodyModels(DartTypeReference type) sync* {
  if (type.scalarCodec != null) {
    return;
  }
  switch (type.symbol) {
    case 'List' || 'Map' || 'Stream':
      for (final DartTypeReference arg in type.typeArguments) {
        yield* _bodyModels(arg);
      }
    case 'MultipartRequest' ||
        'MultipartFile' ||
        'FormData' ||
        'DateTime' ||
        'void' ||
        'String' ||
        'int' ||
        'num' ||
        'bool' ||
        'Object' ||
        'Null' ||
        'Never':
      break;
    default:
      yield type.symbol;
  }
}

cb.Parameter _bodyArgument(
  DartClientBody body, {
  bool annotate = false,
  Set<String> qualified = const {},
}) => cb.Parameter(
  (arg) => arg
    ..name = 'body'
    ..named = true
    ..required = body.isRequired
    ..type = _buildType(
      body.type,
      qualified: qualified,
      optional: !body.isRequired,
    )
    ..annotations.addAll([if (annotate) cb.refer('Body').call([])]),
);

cb.Parameter _extraParameter(DartClientOperation op, {bool annotate = false}) =>
    cb.Parameter(
      (p) => p
        ..name = 'extra'
        ..named = true
        ..type = cb.refer('Map<String, Object?>')
        ..defaultTo = cb.Code('const ${_literal(op.extra)}')
        ..annotations.addAll([if (annotate) cb.refer('Extras').call([])]),
    );

Iterable<cb.Parameter> _callParameters(
  DartClientOperation op, {
  bool annotate = false,
  bool packageHttp = false,
}) sync* {
  yield _extraParameter(op, annotate: annotate);
  yield cb.Parameter(
    (p) => p
      ..name = packageHttp ? 'abortTrigger' : 'cancelToken'
      ..named = true
      ..type = cb.refer(packageHttp ? 'Future<void>?' : 'CancelToken?')
      ..annotations.addAll([if (annotate) cb.refer('CancelRequest').call([])]),
  );
  yield cb.Parameter(
    (p) => p
      ..name = 'options'
      ..named = true
      ..type = cb.refer(packageHttp ? 'HttpRequestOptions?' : 'Options?'),
  );
}

cb.Method _retrofitMethod(
  DartClientOperation op, {
  bool originalHttpResponse = false,
}) => cb.Method(
  (m) => m
    ..name = op.name
    ..annotations.add(cb.refer(op.method).call([cb.literalString(op.path)]))
    ..annotations.addAll([
      if (op.body?.mediaType == 'multipart/form-data')
        cb.refer('MultiPart').call([])
      else if (op.body?.mediaType == 'application/x-www-form-urlencoded')
        cb.refer('FormUrlEncoded').call([])
      else if (op.body != null)
        cb.refer('Headers').call([
          cb.literalMap({'Content-Type': 'application/json'}),
        ]),
    ])
    ..returns = cb.refer(
      'Future<${originalHttpResponse ? 'HttpResponse<' : ''}${op.response.symbol}${op.response.isNullable ? '?' : ''}${originalHttpResponse ? '>' : ''}>',
    )
    ..optionalParameters.addAll([
      ..._callParameters(op, annotate: true),
      ...op.parameters.map((p) => _argument(p, annotate: true)),
      if (op.body case final body?)
        if (body.fields.isEmpty)
          _bodyArgument(body, annotate: true)
        else
          for (final f in body.fields)
            cb.Parameter(
              (p) => p
                ..name = f.name
                ..named = true
                ..required = f.required
                ..defaultTo = f.defaultValue?.expression == null
                    ? null
                    : cb.Code(f.defaultValue!.expression!)
                ..type = _buildType(f.type, optional: !f.required)
                ..annotations.add(
                  body.mediaType == 'multipart/form-data'
                      ? cb.refer('Part').call([], {
                          'name': cb.literalString(f.key),
                        })
                      : cb.refer('Field').call([cb.literalString(f.key)]),
                ),
            ),
    ]),
);

cb.Method _flatObject() => cb.Method(
  (m) => m
    ..name = '_flatObject'
    ..static = true
    ..returns = _jsonMap
    ..requiredParameters.addAll([
      cb.Parameter(
        (p) => p
          ..name = 'name'
          ..type = cb.refer('String'),
      ),
      cb.Parameter(
        (p) => p
          ..name = 'json'
          ..type = _jsonValue,
      ),
    ])
    ..body = const cb.Code(r'''
final fields = json as Map<String, Object?>;
for (final entry in fields.entries) {
  final value = entry.value;
  if (value != null && value is! String && value is! num && value is! bool) {
    throw ArgumentError('Expected a scalar at $name[${entry.key}].');
  }
}
return fields;
'''),
);

bool _mapNeedsJson(DartTypeReference type) =>
    type.symbol == 'Map' &&
    (_bodyModels(type).isNotEmpty || _hasScalarCodec(type));

String _objectJson(DartClientParameter p) =>
    p.type.symbol == 'Map' && !_mapNeedsJson(p.type)
    ? p.name
    : _encode(p.type, p.name);

String _objectArgument(DartClientParameter p) {
  final String json = _objectJson(p);
  final String key = _literal(p.wireName);
  if (p.location == DartClientParameterLocation.query) {
    return p.objectShape == DartParameterObjectShape.open
        ? '_flatObject($key, $json)'
        : json;
  }
  final String style = p.isPath ? p.pathStyle.name : 'header';
  final encoder = p.allowReserved && p.isPath ? ', encode: _reservedPath' : '';
  return '_formatObject($key, $json, ${_literal(style)}, explode: ${p.explode}$encoder)';
}

cb.Method _addQueryObject({required bool packageHttp}) => cb.Method(
  (m) => m
    ..name = '_addQueryObject'
    ..static = true
    ..returns = cb.refer('void')
    ..requiredParameters.addAll([
      for (final (name, type) in [
        ('query', 'Map<String, Object?>'),
        ('name', 'String'),
        ('json', 'Object?'),
      ])
        cb.Parameter(
          (p) => p
            ..name = name
            ..type = cb.refer(type),
        ),
    ])
    ..optionalParameters.addAll([
      cb.Parameter(
        (p) => p
          ..name = 'explode'
          ..named = true
          ..required = true
          ..type = cb.refer('bool'),
      ),
      cb.Parameter(
        (p) => p
          ..name = packageHttp ? 'separator' : 'format'
          ..named = true
          ..defaultTo = cb.Code(packageHttp ? "','" : 'ListFormat.csv')
          ..type = cb.refer(packageHttp ? 'String' : 'ListFormat'),
      ),
      cb.Parameter(
        (p) => p
          ..name = 'bracketed'
          ..named = true
          ..defaultTo = const cb.Code('false')
          ..type = cb.refer('bool'),
      ),
    ])
    ..body = cb.Code('''
final fields = _flatObject(name, json);
void add(String key, Object? value) {
  if (query.containsKey(key)) {
    throw ArgumentError('Duplicate query key "\$key" in parameter "\$name".');
  }
  query[key] = value;
}
if (bracketed) {
  for (final entry in fields.entries) {
    add('\$name[\${entry.key}]', entry.value);
  }
} else if (explode) {
  for (final entry in fields.entries) {
    if (entry.value != null) add(entry.key, entry.value);
  }
} else {
  final pairs = <Object>[for (final entry in fields.entries)
    if (entry.value != null) ...[entry.key, entry.value!]];
  if (pairs.isNotEmpty) add(name, ${packageHttp ? 'pairs.join(separator)' : 'ListParam(pairs, format)'});
}
'''),
);

cb.Method _formatObject() => cb.Method(
  (m) => m
    ..name = '_formatObject'
    ..static = true
    ..returns = cb.refer('String')
    ..requiredParameters.addAll([
      for (final (name, type) in [
        ('name', 'String'),
        ('json', 'Object?'),
        ('style', 'String'),
      ])
        cb.Parameter(
          (p) => p
            ..name = name
            ..type = cb.refer(type),
        ),
    ])
    ..optionalParameters.add(
      cb.Parameter(
        (p) => p
          ..name = 'explode'
          ..named = true
          ..required = true
          ..type = cb.refer('bool'),
      ),
    )
    ..optionalParameters.add(
      cb.Parameter(
        (p) => p
          ..name = 'encode'
          ..named = true
          ..type = cb.refer('String Function(String)')
          ..defaultTo = const cb.Code('Uri.encodeComponent'),
      ),
    )
    ..body = const cb.Code(r'''
final fields = _flatObject(name, json);
final path = style != 'header';
final parts = <String>[];
for (final entry in fields.entries) {
  final value = entry.value;
  if (value == null) continue;
  final key = path ? encode(entry.key) : entry.key;
  final text = path ? encode(value.toString()) : value.toString();
  if (!explode) {
    parts.addAll([key, text]);
  } else if (style == 'matrix' && text.isEmpty) {
    parts.add(key);
  } else {
    parts.add('$key=$text');
  }
}
if (parts.isEmpty) return '';
return switch (style) {
  'label' => '.' + parts.join(explode ? '.' : ','),
  'matrix' when explode => ';' + parts.join(';'),
  'matrix' => ';' + Uri.encodeComponent(name) + '=' + parts.join(','),
  _ => parts.join(','),
};
'''),
);

cb.Method _directMethod(
  DartClientOperation op,
  Set<String> qualified, {
  required bool packageHttp,
  bool nativeRetrofit = false,
  bool decodeInBackground = false,
  String? operationMetadata,
  String? responseWrapper,
}) => cb.Method((m) {
  final String? wrapper = op.variants.isEmpty ? responseWrapper : null;
  final wrapped = wrapper != null;
  final bool stream =
      !wrapped && op.variants.isEmpty && op.response.symbol == 'Stream';
  final bool streamed = packageHttp || _readsStream(op) || decodeInBackground;
  final source = packageHttp
      ? (wrapped && !_returnsStream(op)
            ? 'Stream.value(_rawResponse.bodyBytes)'
            : 'response.stream')
      : '(response.data as ResponseBody).stream';
  final cancellation = packageHttp
      ? 'abortTrigger?.then<Object>((_) => http.RequestAbortedException(_url))'
      : 'cancelToken?.whenCancel';
  final cancelCallback = packageHttp
      ? '() { if (!_abort.isCompleted) _abort.complete(); }'
      : '_cancelToken.cancel';
  final json = _JsonBuilder(
    op.objectTypes.isNotEmpty
        ? op.objectTypes
        : {
            if (op.objectResponse) op.response.symbol,
            for (final variant in op.variants.values)
              if (variant.objectPayload) variant.type!.symbol,
          },
    const {},
    matchIntegers: false,
    qualified: qualified,
  );
  final DartClientBody? payload = op.body;
  final bool optionalNull = payload?.allowsAbsentAndNull ?? false;
  m
    ..name = op.name
    ..modifier = stream ? null : cb.MethodModifier.async
    ..returns = stream
        ? _buildType(op.response, qualified: qualified)
        : _buildType(
            DartTypeReference(
              symbol: 'Future',
              typeArguments: [
                if (wrapped)
                  DartTypeReference(
                    symbol: wrapper,
                    typeArguments: [op.returnType],
                  )
                else
                  op.returnType,
              ],
            ),
            qualified: qualified,
          )
    ..optionalParameters.addAll([
      ..._callParameters(op, packageHttp: packageHttp),
      ...op.parameters.map((p) => _argument(p, qualified: qualified)),
      if (payload != null && payload.fields.isEmpty)
        _bodyArgument(payload, qualified: qualified),
      if (payload != null)
        for (final field in payload.fields)
          cb.Parameter(
            (p) => p
              ..name = field.name
              ..named = true
              ..required = field.required
              ..defaultTo = field.defaultValue?.expression == null
                  ? null
                  : cb.Code(field.defaultValue!.expression!)
              ..type = _buildType(
                field.type,
                qualified: qualified,
                optional: !field.required,
              ),
          ),
      if (optionalNull)
        cb.Parameter(
          (p) => p
            ..name = 'sendNullBody'
            ..named = true
            ..type = cb.refer('bool')
            ..defaultTo = const cb.Code('false'),
        ),
    ]);
  final body = StringBuffer(_attachMetadata(operationMetadata));
  final bool cancellable = _returnsStream(op);
  if (cancellable) {
    body.write(
      packageHttp
          ? 'final _abort = Completer<void>(); final _abortTrigger = abortTrigger == null ? _abort.future : Future.any<void>([_abort.future, abortTrigger]);'
          : 'final _cancelToken = CancelToken(); if (cancelToken?.isCancelled ?? false) _cancelToken.cancel(cancelToken!.cancelError); cancelToken?.whenCancel.then((error) => _cancelToken.cancel(error));',
    );
    if (stream) {
      body.write('return _cancelStream(() async* {');
    }
  }
  final pathValues = <String, String>{};
  final query = <String>[];
  final bool hasFormQuery = op.parameters.any(
    (p) => p.isFormQueryObject && !p.allowReserved,
  );
  final objectCalls = <String>[];
  final String accept = _mediaTypes(op).toSet().join(', ');
  final headers = <String>[
    "'Accept': ${_literal(accept.isEmpty ? 'application/json' : accept)}",
  ];
  final cookies = <String>[];
  String? rawQuery;
  final reservedQuery = <String>[];
  for (final DartClientParameter p in op.parameters) {
    if (p.contentType != null) {
      final String name = p.name;
      final String media = p.contentType!;
      final String value;
      if (_jsonMedia(media)) {
        value = _jsonArgument(p.type, name);
      } else if (media == 'application/x-www-form-urlencoded') {
        final String data = _encode(p.type, name);
        value = packageHttp ? '_httpQuery($data)' : '_encodedForm($data)';
      } else {
        value = name;
      }
      final guard = p.isRequired ? '' : 'if ($name != null) ';
      switch (p.location) {
        case DartClientParameterLocation.querystring:
          final encoded = _jsonMedia(media)
              ? 'Uri.encodeComponent($value)'
              : value;
          rawQuery = p.isRequired ? encoded : "($name == null ? '' : $encoded)";
        case DartClientParameterLocation.path:
          pathValues[p.wireName] = 'Uri.encodeComponent($value)';
        case DartClientParameterLocation.query:
          query.add('$guard${_literal(p.wireName)}: $value');
        case DartClientParameterLocation.header:
          headers.add('$guard${_literal(p.wireName)}: $value');
        case DartClientParameterLocation.cookie:
          cookies.add(
            '$guard${_literal('${Uri.encodeComponent(p.wireName)}=')} + Uri.encodeComponent($value)',
          );
      }
    } else if (p.allowReserved &&
        p.location == DartClientParameterLocation.query) {
      final String expression = _reservedQueryArgument(p);
      final guard = p.isRequired ? '' : 'if (${p.name} != null) ';
      reservedQuery.add('$guard...$expression');
    } else if (p.location == DartClientParameterLocation.cookie) {
      cookies.add(_cookieArgument(p));
    } else if (p.isPath) {
      final String expression = nativeRetrofit
          ? '${p.name}.toString()'
          : p.objectShape == null
          ? _pathArgument(p)
          : _objectArgument(p);
      if (p.objectShape != null ||
          p.listSeparator != null ||
          p.pathStyle != DartPathStyle.simple) {
        final segment = '_${p.name}Segment';
        body.write('final $segment = $expression;');
        pathValues[p.wireName] = segment;
      } else {
        pathValues[p.wireName] = expression;
      }
    } else {
      final guard = p.isRequired ? '' : 'if (${p.name} != null) ';
      if (hasFormQuery &&
          p.location == DartClientParameterLocation.query &&
          p.objectShape != null) {
        final String key = _literal(p.wireName);
        final bracketed = p.isFormQueryObject ? '' : ', bracketed: true';
        final format = packageHttp
            ? ', separator: ${_literal(_separator(p.queryListFormat ?? DartQueryListFormat.csv))}'
            : p.queryListFormat == null
            ? ''
            : ', format: ListFormat.${p.queryListFormat!.name}';
        final call =
            '_addQueryObject(queryParameters, $key, ${_objectJson(p)}, explode: ${p.explode}$bracketed$format);';
        objectCalls.add(
          p.isRequired ? call : 'if (${p.name} != null) { $call }',
        );
        continue;
      }
      final String value;
      if (p.listSeparator case final separator?) {
        value =
            '${_parameterWire(p.type, p.name)}.join(${_literal(separator)})';
      } else if (p.objectShape != null) {
        value = _objectArgument(p);
      } else if (nativeRetrofit && p.type.symbol == 'List') {
        value = p.name;
      } else if (p.type.symbol != 'List') {
        value = p.scalarCodec ? _encode(p.type, p.name) : p.name;
      } else if (p.queryListFormat == DartQueryListFormat.tsv) {
        // Dio's tsv format inserts a literal backslash and t.
        value = "${_parameterWire(p.type, p.name)}.join('\\t')";
      } else {
        final DartQueryListFormat format =
            p.queryListFormat ?? DartQueryListFormat.multi;
        value = packageHttp
            ? _httpList(_parameterWire(p.type, p.name), format)
            : 'ListParam(${_parameterWire(p.type, p.name)}, ListFormat.${format.name})';
      }
      final entry = '$guard${_literal(p.wireName)}: $value';
      if (p.location == DartClientParameterLocation.header) {
        headers.add(entry);
      } else {
        query.add(entry);
      }
    }
  }
  if (cookies.isNotEmpty) {
    body.write("final _cookies = <String>[${cookies.join(', ')}];");
    headers.add("if (_cookies.isNotEmpty) 'Cookie': _cookies.join('; ')");
  }
  final String queryMap;
  if (objectCalls.isEmpty) {
    queryMap = query.isEmpty ? '' : '<String, Object?>{${query.join(', ')}}';
  } else {
    body
      ..write("final queryParameters = <String, Object?>{${query.join(', ')}};")
      ..writeAll(objectCalls);
    queryMap = 'queryParameters';
  }
  // Dio normalizes empty and dot segments before it sends the request.
  for (final String segment in op.path.split('/')) {
    if (!nativeRetrofit &&
        _pathToken.hasMatch(segment) &&
        segment.replaceAll(_pathToken, '').replaceAll('.', '').isEmpty) {
      final String value = _pathExpression(segment, pathValues);
      body.write(
        "if (const {'', '.', '..'}.contains($value)) { throw ArgumentError('Invalid path segment.'); }",
      );
    }
  }
  final status = packageHttp ? '_status' : 'status';
  final checks = <String>[
    for (final code in op.variants.keys)
      if (code.endsWith('XX'))
        '$status ~/ 100 == ${code[0]}'
      else if (code != 'default')
        '$status == $code',
  ];
  final String? accepted = nativeRetrofit
      ? null
      : op.variants.containsKey('default')
      ? '$status >= 100 && $status < 600'
      : checks.isNotEmpty
      ? checks.join(' || ')
      : op.status != null
      ? [
          '$status == ${op.status}',
          for (final code in op.emptySuccessStatuses) '$status == $code',
        ].join(' || ')
      : null;
  if (!packageHttp) {
    final contentType = payload == null
        ? ''
        : 'contentType: ${_literal(payload.mediaType)}, ';
    final validation = accepted == null
        ? ''
        : ', validateStatus: (status) => status != null && ($accepted)';
    final optionHeaders = payload == null
        ? '...?options?.headers'
        : "for (final entry in (options?.headers ?? const <String, Object?>{}).entries) if (entry.key.toLowerCase() != 'content-type') entry.key: entry.value";
    body.write(
      'final _options = (options ?? Options()).copyWith(method: ${_literal(op.method)}, responseType: ResponseType.${streamed ? 'stream' : 'json'}, '
      "extra: {...?options?.extra, ...extra}, ${contentType}headers: {$optionHeaders, ${headers.join(', ')}}$validation);",
    );
  }

  String path = _pathExpression(op.path, pathValues);
  if (reservedQuery.isNotEmpty) {
    rawQuery = "<String>[${reservedQuery.join(', ')}].join('&')";
  }
  if (rawQuery != null) {
    body
      ..write('final _rawQuery = $rawQuery;')
      ..write(
        "if (_rawQuery.contains('#')) throw ArgumentError('Encode the query fragment marker.');",
      );
    path += " + (_rawQuery.isEmpty ? '' : '?' + _rawQuery)";
  }
  if (packageHttp) {
    _sendHttpRequest(
      body,
      op,
      path,
      queryMap,
      headers,
      accepted,
      originalHttpResponse: wrapped,
    );
    if (wrapped && !_returnsStream(op)) {
      body.write(
        decodeInBackground
            ? 'final _bytes = await _decoding.readResponseBytes(response.stream, cancelled: $cancellation); final _rawResponse = http.Response.bytes(_bytes, response.statusCode, request: response.request, headers: response.headers, isRedirect: response.isRedirect, persistentConnection: response.persistentConnection, reasonPhrase: response.reasonPhrase);'
            : 'final _rawResponse = await http.Response.fromStream(response);',
      );
    }
  } else {
    final args = queryMap.isEmpty ? '' : ', queryParameters: $queryMap';
    final String data = payload == null
        ? ''
        : _requestData(body, payload, optionalNull);
    final cancel =
        ', cancelToken: ${cancellable ? '_cancelToken' : 'cancelToken'}';
    final result = op.response.symbol == 'void' && !wrapped
        ? ''
        : 'final response = ';
    final decodeError = decodeInBackground
        ? '.catchError((Object error, StackTrace stack) => _decodeResponseError(error, stack, cancelToken))'
        : '';
    if (op.method != op.method.toUpperCase()) {
      body
        ..write(
          'final request = _options.compose(_transport.options, $path$args$data$cancel)..method = ${_literal(op.method)};',
        )
        ..write(
          '${result}await _transport.fetch<dynamic>(request)$decodeError;',
        );
    } else {
      body.write(
        '${result}await _transport.request<dynamic>($path, options: _options$args$data$cancel)$decodeError;',
      );
    }
  }
  if (op.variants.isNotEmpty) {
    body.write('return switch (response.statusCode) {');
    for (final MapEntry<String, DartStatusVariant> entry
        in op.variants.entries) {
      final DartStatusVariant variant = entry.value;
      final DartTypeReference? type = variant.type;
      var value = '';
      if (type != null) {
        value = _readPayload(
          json,
          type,
          variant.mediaType,
          streamed,
          source,
          decoder: decodeInBackground ? '_decode${op.name}_${entry.key}' : null,
          cancelled: cancellation,
        );
        if (type.symbol == 'Stream') {
          value = '_cancelStream($value, $cancelCallback)';
        }
      }
      final String code = entry.key;
      final int? exact = int.tryParse(code);
      final pattern = exact != null
          ? code
          : code == 'default'
          ? 'final int status'
          : 'final int status when status ~/ 100 == ${code[0]}';
      final args = [if (exact == null) 'status', if (value.isNotEmpty) value];
      final ctor = '${variant.name}(${args.join(', ')})';
      final expression = streamed && type == null
          ? 'await $source.drain<void>().then((_) => $ctor)'
          : ctor;
      body.write('$pattern => $expression,');
    }
    if (!(packageHttp && op.variants.containsKey('default'))) {
      body.write(
        r"_ => throw StateError('Unexpected response status: ${response.statusCode}'),",
      );
    }
    body.write('};');
    m.body = cb.Code(body.toString());
    return;
  }
  if (op.response.symbol == 'void') {
    if (wrapped) {
      body.write(
        wrapper == 'Response'
            ? 'return response;'
            : 'return ${_wrapResponse(wrapper, 'null', packageHttp: packageHttp, streamed: false)};',
      );
    }
    m.body = cb.Code(body.toString());
    return;
  }
  if (op.emptySuccessStatuses.isNotEmpty) {
    final String empty = op.emptySuccessStatuses
        .map((code) => 'response.statusCode == $code')
        .join(' || ');
    body.write('if ($empty) {');
    if (streamed && !(packageHttp && wrapped && !_returnsStream(op))) {
      body.write('await $source.drain<void>();');
    }
    if (stream) {
      body.write('return;');
    } else {
      final value = _returnsStream(op) ? 'const Stream.empty()' : 'null';
      body.write(
        'return ${wrapped ? _wrapResponse(wrapper, value, packageHttp: packageHttp, streamed: _returnsStream(op)) : value};',
      );
    }
    body.write('}');
  }
  String value = _readPayload(
    json,
    op.response,
    op.mediaType,
    streamed,
    source,
    decoder: decodeInBackground ? '_decode${op.name}' : null,
    cancelled: cancellation,
  );
  if (wrapped) {
    if (decodeInBackground &&
        !packageHttp &&
        wrapper == 'HttpResponse' &&
        _jsonMedia(op.mediaType)) {
      body.write('final decoded = $value; response.data = decoded.json;');
      value = 'decoded.value';
    }
    if (_returnsStream(op)) {
      value = '_cancelStream($value, $cancelCallback)';
    }
    value = _wrapResponse(
      wrapper,
      value,
      packageHttp: packageHttp,
      streamed: _returnsStream(op),
    );
  }
  body.write("${stream ? 'yield*' : 'return'} $value;");
  if (stream) {
    body.write('}(), $cancelCallback);');
  }
  m.body = cb.Code(body.toString());
});

String _pathArgument(DartClientParameter p) {
  final String name = p.name;
  final array = p.type.symbol == 'List';
  final scalar = p.scalarCodec
      ? '(${_encode(p.type, name)}).toString()'
      : p.type.symbol == 'String' && !p.type.isNullable
      ? name
      : '$name.toString()';
  final encoder = p.allowReserved ? '_reservedPath' : 'Uri.encodeComponent';
  final encoded = '$encoder($scalar)';
  final item = array && _needsParameterCodec(p.type)
      ? '(${_encode(p.type.typeArguments.single, 'item')})'
      : 'item';
  final items = '$name.map((item) => $encoder($item.toString()))';
  switch (p.pathStyle) {
    case DartPathStyle.simple:
      if (!array) {
        return encoded;
      }
      final String separator = p.listSeparator ?? ',';
      final String delimiter = separator == ','
          ? ','
          : Uri.encodeComponent(separator);
      return '$items.join(${_literal(delimiter)})';
    case DartPathStyle.label:
      if (!array) {
        return "'.' + $encoded";
      }
      final String delimiter = _literal(p.explodePath ? '.' : ',');
      return "$name.isEmpty ? '' : '.' + $items.join($delimiter)";
    case DartPathStyle.matrix:
      final key = ';${Uri.encodeComponent(p.wireName)}';
      final String prefix = _literal('$key=');
      final String empty = _literal(key);
      if (!array) {
        final value = '$prefix + $encoded';
        return p.type.symbol == 'String'
            ? '$name.isEmpty ? $empty : $value'
            : value;
      }
      if (p.explodePath) {
        return '$items.map((value) => value.isEmpty ? $empty : $prefix + value).join()';
      }
      return "$name.isEmpty ? '' : $prefix + $items.join(',')";
  }
}

String _pathExpression(String template, Map<String, String> values) {
  final parts = <String>[];
  var start = 0;
  for (final RegExpMatch match in _pathToken.allMatches(template)) {
    if (match.start > start) {
      parts.add(_literal(template.substring(start, match.start)));
    }
    parts.add(values[match.group(1)]!);
    start = match.end;
  }
  if (start < template.length) {
    parts.add(_literal(template.substring(start)));
  }
  return parts.join(' + ');
}

String _wrapResponse(
  String wrapper,
  String value, {
  required bool packageHttp,
  required bool streamed,
}) => wrapper == 'Response'
    ? 'Response(data: $value, requestOptions: response.requestOptions, headers: response.headers, statusCode: response.statusCode, statusMessage: response.statusMessage, isRedirect: response.isRedirect, redirects: response.redirects, extra: response.extra)'
    : 'HttpResponse($value, ${packageHttp && !streamed ? '_rawResponse' : 'response'})';
