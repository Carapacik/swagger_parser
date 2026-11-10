import 'dart:convert';

import 'package:code_builder/code_builder.dart' as cb;
import 'package:path/path.dart' as p;
import 'package:swagger_parser/src/config/generation_config.dart';
import 'package:swagger_parser/src/dart/dart_generation_model.dart';
import 'package:swagger_parser/src/dart/dart_reserved_names.dart';

part 'dart_http_client_builder.dart';
part 'dart_response_decoder_builder.dart';
part 'dart_metadata_builder.dart';
part 'dart_http_media_builder.dart';
part 'dart_json_builder.dart';
part 'dart_custom_type_builder.dart';
part 'dart_matcher_builder.dart';
part 'dart_validator_builder.dart';
part 'dart_package_http_builder.dart';
part 'dart_serializer_builder.dart';
part 'dart_primary_builder.dart';
part 'dart_documentation_builder.dart';
part 'dart_unknown_builder.dart';
part 'dart_status_result_builder.dart';
part 'dart_structural_union_builder.dart';
part 'dart_tuple_builder.dart';

/// Builds a Dart syntax tree from a library model.
abstract interface class DartCodeBuilder() {
  /// Initializes a concrete subtype.
  this;

  /// Builds the syntax tree for one Dart library.
  cb.Library build(DartLibraryModel model);
}

/// Builds Dart DTOs and HTTP clients.
final class const DefaultDartCodeBuilder() implements DartCodeBuilder {
  /// Creates the builder for DTOs with final fields.
  this;

  @override
  cb.Library build(
    DartLibraryModel model, {
    DtoSerializer serializer = DtoSerializer.plain,
    HttpClientBackend httpClient = HttpClientBackend.retrofit,
    bool bodyPositional = false,
    bool originalHttpResponse = false,
    bool decodeResponsesInBackground = false,
  }) {
    if (model.responseDecoder != null) {
      return _buildResponseDecoder(model);
    }
    final json = _JsonBuilder(
      model.objectNames.isNotEmpty
          ? model.objectNames
          : {
              for (final dto in model.dtos) dto.name,
              for (final union in model.unions) union.name,
            },
      model.wrapperNames.isNotEmpty
          ? model.wrapperNames
          : {
              // A wrapper can decode JSON null into a non-null Dart instance.
              for (final wrapper in model.values) wrapper.name,
              for (final tuple in model.tuples) tuple.name,
              for (final union in model.structuralUnions) union.name,
            },
      matchIntegers:
          model.matchIntegers ||
          model.structuralUnions.isNotEmpty ||
          model.tuples.isNotEmpty,
    );
    final interfaces = <String, List<String>>{};
    for (final DartUnionModel union in model.unions) {
      for (final String variant in {
        ...union.mapping.values,
        ?union.defaultType,
      }) {
        (interfaces[variant] ??= []).add(union.name);
      }
    }
    for (final DartStructuralUnion union in model.structuralUnions) {
      for (final DartMatchBranch branch in union.branches) {
        if (branch.implementation == branch.type.symbol) {
          (interfaces[branch.type.symbol] ??= []).add(union.name);
        }
      }
    }
    return cb.Library((library) {
      library.directives.addAll(model.imports.map(cb.Directive.import));
      library.directives.addAll(model.exports.map(cb.Directive.export));
      library.directives.addAll([
        for (final entry in model.typeExports.entries)
          cb.Directive.export(entry.key, show: entry.value),
      ]);
      final List<DartSchemaMatcher> customMatchers = _addScalarCodecs(
        library,
        model,
      );
      _buildMetadata(library, model);
      _addValidators(library, model);
      if (model.httpResponse) {
        library.directives.add(
          cb.Directive.import('package:http/http.dart', as: 'http'),
        );
        library.body.add(const cb.Code(_httpResponse));
      }
      if (model.httpRequestOptions) {
        library.body.add(const cb.Code(_httpRequestOptions));
      }
      if (model.facade case final facade?) {
        _buildFacade(library, facade, httpClient);
      }
      final packages = _SerializerBuilder(serializer, json, model);
      if (model.dtos.any((dto) => dto.json) || model.enums.isNotEmpty) {
        packages.addDirectives(library, model.relativePath);
      }
      if (model.results.isNotEmpty) {
        _buildStatusResults(library, model);
      }
      if (model.operations.isNotEmpty) {
        _buildHttpClient(
          library,
          model,
          httpClient,
          bodyPositional: bodyPositional,
          decodeResponsesInBackground: decodeResponsesInBackground,
          originalHttpResponse: originalHttpResponse,
        );
      }
      library.body
        ..addAll(model.enums.map(packages.buildEnum))
        ..addAll(model.unions.map(packages.buildUnion))
        ..addAll(
          model.unions.where((u) => u.unknownType != null).map(_unknownUnion),
        )
        ..addAll(
          model.dtos.map(
            (dto) => switch (serializer) {
              DtoSerializer.jsonSerializable || DtoSerializer.freezed
                  when dto.json =>
                packages.annotatedDto(dto, interfaces[dto.name] ?? const []),
              DtoSerializer.dartMappable when dto.json => packages.mappedDto(
                _buildDto(dto, json, interfaces[dto.name] ?? const []),
              ),
              _ => _buildDto(dto, json, interfaces[dto.name] ?? const []),
            },
          ),
        )
        ..addAll(
          model.values.map(
            (v) => json.buildValue(v, interfaces[v.name] ?? const []),
          ),
        )
        ..addAll(model.tuples.map(json.buildTuple))
        ..addAll(model.structuralUnions.expand(json.buildStructuralUnion));
      if (serializer == DtoSerializer.dartMappable) {
        packages.addMappers(library, model);
      }
      _addMatchers(
        library,
        {
          for (final m in [...model.matchers, ...customMatchers]) m.name: m,
        }.values.toList(),
        {
          for (final tuple in model.tuples)
            if (tuple.project) tuple.matcher,
          for (final union in model.structuralUnions) ?union.projectionMatcher,
        },
        projectionOnly:
            {
              for (final union in model.structuralUnions)
                if (union.unknownType != null) ?union.projectionMatcher,
            }.difference({
              ...model.validators.values,
              for (final tuple in model.tuples) tuple.matcher,
              for (final union in model.structuralUnions) ...[
                ?union.commonMatcher,
                for (final branch in union.branches) branch.matcher,
                if (union.unknownType == null) ?union.projectionMatcher,
              ],
            }),
      );
      library.body.addAll([
        if (model.unions.any((u) => u.unknownType != null) ||
            model.structuralUnions.any((u) => u.unknownType != null))
          _freezeUnknownJson(),
        if (model.unions.any((u) => u.unknownType != null) ||
            model.tuples.isNotEmpty ||
            model.structuralUnions.any(
              (union) => !union.exclusive || union.unknownType != null,
            ))
          _copyJsonMethod(),
        if (json.usesIntegerReader) _integerReader(),
      ]);
      library.body.replace(
        library.body.build().map(
          (declaration) => _documentDeclaration(declaration, model),
        ),
      );
    });
  }

  cb.Class _buildDto(
    DartDtoModel dto,
    _JsonBuilder json,
    List<String> interfaces,
  ) => cb.Class((type) {
    type.name = dto.name;
    type.implements.addAll(interfaces.map(cb.refer));
    type.fields.addAll(
      dto.fields
          .where((f) => f.fixedValue == null)
          .map(
            (field) => cb.Field((builder) {
              builder
                ..name = field.name
                ..modifier = cb.FieldModifier.final$
                ..type = dto.json ? _fieldType(field) : _buildType(field.type);
            }),
          ),
    );
    type.methods.addAll(
      dto.fields.where((f) => f.fixedValue != null).map(_fixedGetter),
    );
    type.constructors.add(
      cb.Constructor((constructor) {
        constructor.constant = true;
        constructor.optionalParameters.addAll(
          dto.fields
              .where((f) => f.fixedValue == null)
              .map(
                (field) => cb.Parameter((parameter) {
                  parameter
                    ..name = field.name
                    ..named = true
                    ..required = field.isRequired
                    ..toThis = true;
                  if (field.defaultExpression case final value?) {
                    parameter.defaultTo = cb.Code(value);
                  }
                }),
              ),
        );
        if (dto.json) {
          json.addParameters(dto, constructor);
        }
      }),
    );
    if (dto.json) {
      json.addSerialization(dto, type);
    }
  });
}

cb.Reference _fieldType(DartFieldModel field) => field.tracksPresence
    ? cb.RecordType(
        (r) => r
          ..isNullable = true
          ..namedFieldTypes['value'] = _buildType(field.type),
      )
    : _buildType(field.type);

cb.TypeReference _buildType(
  DartTypeReference type, {
  Set<String> qualified = const {},
  bool optional = false,
}) => cb.TypeReference(
  (builder) => builder
    ..symbol = qualified.contains(type.symbol)
        ? 'models.${type.symbol}'
        : type.symbol
    ..url = type.importUrl
    ..isNullable = (type.isNullable || optional) && type.symbol != 'Null'
    ..types.addAll(
      type.typeArguments.map((arg) => _buildType(arg, qualified: qualified)),
    ),
);

Iterable<cb.Directive> _modelImports(
  DartLibraryModel model,
  Set<String> names, {
  String? prefix,
}) sync* {
  final grouped = <String, List<String>>{};
  for (final name in names) {
    final String? target = model.modelPaths[name];
    final String path = target == null
        ? 'models.dart'
        : p.posix.relative(target, from: p.posix.dirname(model.relativePath));
    (grouped[path] ??= []).add(name);
  }
  for (final MapEntry<String, List<String>> entry in grouped.entries) {
    yield cb.Directive.import(entry.key, as: prefix, show: entry.value);
  }
}

void _buildFacade(
  cb.LibraryBuilder library,
  DartFacadeModel facade,
  HttpClientBackend backend,
) {
  final http = backend == HttpClientBackend.http;
  final bool hasClients = facade.clients.isNotEmpty;
  if (hasClients || facade.metadataTypeName != null) {
    library.directives.add(
      cb.Directive.import(
        'exports.dart',
        as: 'clients',
        show: [
          ?facade.metadataTypeName,
          ...facade.metadataNames,
          ...facade.clients.values,
        ],
      ),
    );
  }
  if (hasClients) {
    library.directives.addAll([
      cb.Directive.import(
        http ? 'package:http/http.dart' : 'package:dio/dio.dart',
        as: 'transport',
      ),
    ]);
  }
  final String name = facade.name;
  library.body.add(
    cb.Code('''
final class $name {
  /// API title from info.title.
  static const String title = ${_literal(facade.title)};
  /// API version from info.version.
  static const String apiVersion = ${_literal(facade.version)};
  /// Exact Swagger or OpenAPI version.
  static const String specVersion = ${_literal(facade.specVersion)};
  ${facade.metadataTypeName == null ? '' : '''
  /// Generated operations in source order.
  static const List<clients.${facade.metadataTypeName}> operations = [
    ${facade.operationConstants.map((name) => 'clients.$name').join(',')}
  ];
  '''}
  ${!hasClients
        ? 'const $name();'
        : http
        ? '''
  $name(this._client, {required this.baseUrl, this.prepareRequest});
  final transport.Client _client;
  final Uri baseUrl;
  final void Function(transport.BaseRequest, Map<String,Object?>)? prepareRequest;
  '''
        : '''
  $name(this._client);
  final transport.Dio _client;
  '''}
  ${facade.clients.entries.map((e) => 'late final clients.${e.value} ${e.key} = clients.${e.value}(_client${http ? ', baseUrl: baseUrl, prepareRequest: prepareRequest' : ''});').join('\n')}
}
'''),
  );
}

cb.Method _fixedGetter(DartFieldModel field) => cb.Method(
  (m) => m
    ..name = field.name
    ..type = cb.MethodType.getter
    ..returns = _buildType(field.type)
    ..lambda = true
    ..body = cb.Code(field.fixedExpression!),
);

String _fixedChecks(DartDtoModel dto) => dto.fields.map((f) {
  final String key = _literal(f.wireName ?? f.name);
  final String error = _literal(
    'Invalid discriminator: ${f.wireName ?? f.name}',
  );
  if (f.fixedValue != null) {
    return 'if (!json.containsKey($key) || json[$key] != ${_literal(f.fixedValue!.value)}) { throw ArgumentError($error); }';
  }
  if (f.discriminatorValues.isEmpty) {
    return '';
  }
  return "if (json.containsKey($key) && ${f.acceptsNull ? 'json[$key] != null && ' : ''}!const <Object>{${f.discriminatorValues.map(_literal).join(',')}}.contains(json[$key])) { throw ArgumentError($error); }";
}).join();

cb.Method _checkedToJson(DartDtoModel dto, cb.Method method) {
  final checks = StringBuffer();
  for (final DartFieldModel f in dto.fields) {
    if (f.fixedValue != null || f.discriminatorValues.isEmpty) {
      continue;
    }
    final access = 'this.${f.name}';
    final value = f.tracksPresence ? '$access!.value' : access;
    final guard = f.tracksPresence
        ? '$access != null && '
        : !f.isRequired || f.acceptsNull
        ? '$access != null && '
        : '';
    checks.write(
      "if ($guard${f.acceptsNull && f.tracksPresence ? '$value != null && ' : ''}!const <Object>{${f.discriminatorValues.map(_literal).join(',')}}.contains(${_encode(f.type, value)})) { throw ArgumentError(${_literal('Invalid discriminator: ${f.wireName ?? f.name}')}); }",
    );
  }
  if (checks.isEmpty) {
    return method;
  }
  return method.rebuild(
    (m) => m
      ..lambda = false
      ..body = cb.Code('${checks}return ${method.body};'),
  );
}
