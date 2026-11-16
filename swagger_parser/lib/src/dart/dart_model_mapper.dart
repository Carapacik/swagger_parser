import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:swagger_parser/src/config/generation_config.dart';
import 'package:swagger_parser/src/config/naming_config.dart';
import 'package:swagger_parser/src/config/type_mapping.dart';
import 'package:swagger_parser/src/dart/dart_generation_model.dart';
import 'package:swagger_parser/src/dart/dart_operation_name.dart';
import 'package:swagger_parser/src/dart/dart_reserved_names.dart';
import 'package:swagger_parser/src/dart/operation_filter.dart';
import 'package:swagger_parser/src/extraction/api_definition.dart';
import 'package:swagger_parser/src/generation/generation_exception.dart';
import 'package:swagger_parser_core/swagger_parser_core.dart';

part 'dart_identifiers.dart';
part 'dart_documentation_mapper.dart';
part 'dart_custom_type_mapper.dart';
part 'dart_schema_scope.dart';
part 'dart_required_inference.dart';
part 'dart_schema_direction.dart';
part 'dart_object_mapper.dart';
part 'dart_default_mapper.dart';
part 'dart_argument_default_mapper.dart';
part 'dart_union_mapper.dart';
part 'dart_discriminator_mapper.dart';
part 'dart_unknown_mapper.dart';
part 'dart_structural_union_mapper.dart';
part 'dart_tuple_mapper.dart';
part 'dart_client_mapper.dart';
part 'dart_layout.dart';
part 'dart_model_selection.dart';
part 'dart_http_media_mapper.dart';

/// Maps API schemas and outbound operations to Dart declarations.
interface class const DartModelMapper() {
  /// Creates the default mapper.
  this;

  /// Reports whether a name can identify a public facade and its file.
  static bool isValidRootApiClassName(String name) =>
      RegExp(r'^[A-Z][A-Za-z0-9]*$').hasMatch(name) &&
      !_typeNames.contains(name) &&
      name != 'Uri' &&
      _clientSnakeCase(name) != 'exports';

  /// Checks filename characters and rejects reserved builder endings.
  static bool isValidFileSuffix(String suffix) =>
      RegExp(r'^[A-Za-z0-9_.-]*$').hasMatch(suffix) &&
      !suffix.contains('..') &&
      !suffix.endsWith('.') &&
      !const [
        '.g',
        '.freezed',
        '.mapper',
        '.dart',
      ].any(suffix.toLowerCase().endsWith);

  /// Builds the DTO and client libraries for the API.
  DartGenerationModel map(ApiDefinition api, GenerationConfig config) =>
      _Mapping(api, config).build();
}

final class _Mapping(final ApiDefinition api, final GenerationConfig config) {
  late final List<ApiOperation> selectedOperations = excludeOperationParameters(
    selectOperations(api.operations, config.operationFilters),
    config.excludeParameters,
    diagnostics,
  );
  final mappingSelectors = <TypeMapping, ReferenceLocation>{};
  final mappingPrefixes = <String, String>{};
  final customTypes = <_SchemaUse, DartTypeReference?>{};
  final typeExports = <String, List<String>>{};
  final nameRules = <(NamingTarget, RegExp, String)>[];

  String _fileName(String stem) => '$stem${config.fileSuffix}.dart';

  String _operationNameCandidate(ApiOperation op) =>
      config.usePathForMethodNames
      ? op.dartPathMethodNameCandidate
      : op.dartMethodNameCandidate;

  String _replaceName(String name, NamingTarget target) {
    var result = name;
    for (final (category, pattern, replacement) in nameRules) {
      if (category == target) {
        result = result.replaceAll(pattern, replacement);
      }
    }
    return result;
  }

  late final _SchemaIndex index = _SchemaIndex(
    api.schemas,
    api.dynamicAnchors,
    config.inferMissingRequired ? _inferRequired : null,
  );
  final names = <_SchemaUse, String>{};
  final intersections = <(_SchemaUse, _SchemaUse), _SchemaUse>{};
  final directionBases = <String, String>{};
  late final Set<String> usedNames = {
    ..._typeNames,
    config.rootApiClassName,
    if (config.serializer == DtoSerializer.freezed ||
        config.serializer == DtoSerializer.jsonSerializable) ...{
      'JsonSerializable',
      'JsonKey',
      'JsonEnum',
    },
    if (config.serializer == DtoSerializer.freezed) ...{
      'Freezed',
      'FreezedUnionValue',
      'Default',
      'DeepCollectionEquality',
      'EqualUnmodifiableListView',
      'EqualUnmodifiableMapView',
    },
    if (config.serializer == DtoSerializer.dartMappable) ...{
      'MappableClass',
      'MappableEnum',
      'MappableValue',
      'GenerateMethods',
      'MappingHook',
      'Field',
      'ClassMapperBase',
      'SubClassMapperBase',
      'MapperContainer',
      'DecodingContext',
      'DecodingData',
      'MappableFields',
      'ClassCopyWithBase',
      'ClassCopyWith',
      'ObjectCopyWith',
      'ListCopyWith',
      'MapCopyWith',
      'CopyWithData',
      'FieldCopyWithData',
      'Then',
      'EnumMapper',
      'MapperException',
    },
  };

  List<String> get _typeSuffixes =>
      config.serializer == DtoSerializer.dartMappable
      ? const ['Mapper', 'Mappable', 'CopyWith', 'ValueCopy', 'MapperExtension']
      : const [];

  String _typeIdentifier(String hint, {bool preserveCase = false}) =>
      _identifier(
        _replaceName(hint, NamingTarget.models),
        usedNames,
        type: true,
        preserveCase: preserveCase,
        suffixes: _typeSuffixes,
      );
  final matcherQueue = <(_SchemaUse, _MatcherMode, String)>[];
  bool buildingMatchers = false;

  final fieldDocumentation = <String, Map<String, DartDocumentation>>{};
  final dtos = <DartDtoModel>[];
  final swaggerConcrete = <_SchemaUse, String>{};
  final fixedDiscriminators = <String, Set<String>>{};
  final enums = <DartEnumModel>[];
  final unions = <DartUnionModel>[];
  final structuralUnions = <DartStructuralUnion>[];
  final matcherNames = <(_SchemaUse, _MatcherMode), String>{};
  final matchers = <String, DartSchemaMatcher>{};
  final matcherSources = <String, _SchemaUse>{};
  final values = <DartValueModel>[];
  final tuples = <DartTupleModel>[];
  final declared = <_SchemaUse>{};
  final enumMetadataMatches = <_SchemaUse, bool>{};

  late final bool hasEnumMetadata = api.schemas.values.any(
    (schema) => switch (schema.definition.value) {
      final Map<String, Object?> fields => fields.containsKey(
        'x-enum-metadata',
      ),
      _ => false,
    },
  );
  final clientFolders = <String, String>{};
  final diagnostics = <Diagnostic>[];

  DartGenerationModel build() {
    _validateFacade();
    _prepareTypeMappings();
    _validateKeepModels();
    try {
      nameRules.addAll([
        for (final rule in config.naming.replaceRules)
          (rule.target, RegExp(rule.pattern), rule.replacement),
      ]);
    } on FormatException catch (e) {
      throw GenerationException('Invalid naming pattern: ${e.message}');
    }
    for (final MapEntry<String, ReferenceLocation> entry
        in api.namedSchemas.entries) {
      _name(index.use(entry.value), entry.key);
    }
    for (final ReferenceLocation id in api.namedSchemas.values) {
      for (final _Direction direction in _Direction.values) {
        final _SchemaUse schema = index.use(id, const {}, direction);
        _name(schema, _componentKey(schema)!);
      }
    }
    for (final ReferenceLocation id in api.namedSchemas.values) {
      for (final _Direction direction in _Direction.values) {
        _declare(index.use(id, const {}, direction));
      }
    }
    for (final ApiOperation op in [
      ...selectedOperations,
      ...api.webhooks,
      ...api.callbacks.values.expand((group) => group),
    ]) {
      final String name = _operationNameCandidate(op);
      _parameters(op.parameters, name);
      if (op.requestBody case final body?) {
        _content(body.content, '${name}Request');
        _parameters(body.formFields, name);
      }
      for (final MapEntry<String, ApiResponse> response
          in op.responses.entries) {
        final hint = '${name}Response${response.key}';
        _content(response.value.content, hint, _Direction.response);
        _parameters(response.value.headers.values, hint, _Direction.response);
      }
    }
    final List<DartLibraryModel> clients = _clientLibraries();
    _applyFixedDiscriminators();
    _applyUnknownValues();
    final _ConstantExpression defaults = _applyDefaults();
    final List<DartLibraryModel> resolvedClients = _resolveArgumentDefaults(
      clients,
      defaults,
    );
    final List<DartLibraryModel> libraries = _layout(resolvedClients);
    _checkMatcherCycles();
    return DartGenerationModel(diagnostics: diagnostics, libraries: libraries);
  }

  void _parameters(
    Iterable<ApiParameter> parameters,
    String hint, [
    _Direction direction = _Direction.request,
  ]) {
    for (final parameter in parameters) {
      final key = '${hint}_${parameter.name}';
      if (parameter.schema case final id?) {
        _payload(id, key, direction);
      }
      _content(parameter.content, key, direction);
    }
  }

  void _content(
    Map<String?, ApiMediaType> content,
    String hint, [
    _Direction direction = _Direction.request,
  ]) {
    for (final ApiMediaType media in content.values) {
      if (media.schema case final id?) {
        _payload(id, hint, direction);
      }
      if (media.itemSchema case final id?) {
        _payload(id, '${hint}Item', direction);
      }
      for (final ApiEncoding encoding in media.encodings.values) {
        _parameters(encoding.headers.values, hint, direction);
      }
    }
  }

  void _payload(ReferenceLocation location, String hint, _Direction direction) {
    final _SchemaUse id = index.use(location, const {}, direction);
    if (id.types.contains('file')) {
      return; // Swagger file parts use the HTTP backend.
    }
    _type(id, hint);
  }

  String _name(_SchemaUse id, String hint) => names.putIfAbsent(id, () {
    if (id.direction case final direction?) {
      final String base = _name(index.use(id.location, id.bindings), hint);
      final String name = _identifier(
        base,
        usedNames,
        type: true,
        preserveCase: true,
        ending: direction == _Direction.request ? r'$Request' : r'$Response',
        suffixes: _typeSuffixes,
      );
      directionBases[name] = base;
      return name;
    }
    final String? key = _componentKey(id);
    return _typeIdentifier(
      key ?? _baseHint(hint),
      preserveCase: key != null && config.naming.preserveSchemaCasing,
    );
  });

  String _baseHint(String hint) {
    final List<MapEntry<String, String>> entries =
        directionBases.entries.toList()
          ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final entry in entries) {
      if (hint.startsWith(entry.key)) {
        return '${entry.value}${hint.substring(entry.key.length)}';
      }
    }
    return hint;
  }

  _SchemaUse _concrete(_SchemaUse id) {
    final seen = <_SchemaUse>{};
    var current = id;
    while (current.reference != null) {
      if (!seen.add(current)) {
        _fail(current, 'Cyclic variant reference.');
      }
      if (_tupleSource(current) != null) {
        return _schema(current);
      }
      _checkRef(_schema(current));
      current = current.reference!;
    }
    return current;
  }

  Never _fail(_SchemaUse id, String message, {String? field}) =>
      throw GenerationException(
        message,
        diagnostics: [
          Diagnostic(
            code: 'unsupportedDartSchema',
            severity: DiagnosticSeverity.error,
            message: message,
            sourceUri: id.location.documentUri,
            documentPath: field == null ? id.pointer : '${id.pointer}/$field',
          ),
        ],
      );

  _SchemaUse _schema(_SchemaUse id) {
    if (id.fields.containsKey(r'$dynamicRef') &&
        id.raw.dynamicReference == null) {
      _fail(id, r'Missing resolved $dynamicRef.', field: r'$dynamicRef');
    }
    final Map<String, Object?> fields = id.fields;
    if (hasEnumMetadata &&
        fields.containsKey('x-enum-metadata') &&
        (fields['enum'] is! List<Object?> && !fields.containsKey('const'))) {
      _fail(
        id,
        'x-enum-metadata requires an enum schema.',
        field: 'x-enum-metadata',
      );
    }
    if (id.dialect case final dialect?
        when SchemaDialect.identify(dialect, id.family) ==
            SchemaDialect.unknown) {
      _fail(id, 'Unsupported schema dialect: $dialect.');
    }
    if (id.family == OpenApiFamily.swaggerV2 &&
        fields.containsKey('x-nullable') &&
        fields['x-nullable'] is! bool) {
      _fail(id, 'Expected a boolean x-nullable value.');
    }
    if (fields.containsKey('prefixItems')) {
      _checkPrefixItems(id);
    }
    for (final keyword in const [
      'not',
      'patternProperties',
      'if',
      'then',
      'else',
      'dependentSchemas',
      'unevaluatedProperties',
    ]) {
      if (fields.containsKey(keyword)) {
        _fail(id, 'Dart mapping does not support $keyword.');
      }
    }
    if ((fields.containsKey('oneOf') && id.oneOf.isEmpty) ||
        (fields.containsKey('anyOf') && id.anyOf.isEmpty)) {
      _fail(id, 'Expected one or more supported union branches.');
    }
    if (fields.containsKey('const')) {
      final Object? value = fields['const'];
      if ((id.family != OpenApiFamily.v31 && id.family != OpenApiFamily.v32) ||
          (value is! String && value is! num && value is! bool) ||
          !_allowsScalar(id.types, value) ||
          (fields['enum'] is List<Object?> &&
              !(fields['enum']! as List<Object?>).contains(value))) {
        _fail(id, 'Expected a compatible scalar const.');
      }
    }
    if (id.types.where((type) => type != 'null').length > 1 &&
        _cases(id) == null) {
      _fail(id, 'Expected a single Dart value type.');
    }
    return id;
  }

  bool _nullable(_SchemaUse id, [Set<_SchemaUse>? visited]) {
    final _SchemaUse schema = _schema(id);
    if (schema.swaggerNullable == false) {
      return false;
    }
    if (!_hasAlternatives(schema) && _tupleSource(schema) != null) {
      final Set<String>? types = _conjunctiveTypes(schema);
      return types == null || types.contains('null');
    }
    if (schema.reference case final target?) {
      if (!(visited ??= {}).add(id)) {
        _fail(id, 'Schema references form a cycle without a value type.');
      }
      if (schema.swaggerNullable == true) {
        final _SchemaUse concrete = _concrete(target);
        final List<Object?>? cases = _cases(concrete);
        return (cases == null || cases.contains(null)) &&
            concrete.allOf.every((part) => _nullable(part, {...?visited}));
      }
      return _nullable(target, visited);
    }
    if (_hasAlternatives(schema) || schema.definition.value == false) {
      return false;
    }
    if (_cases(schema) case final values?) {
      return values.contains(null) &&
          (schema.types.isEmpty || schema.types.contains('null'));
    }
    if (schema.swaggerNullable == true) {
      return schema.allOf.every((part) => _nullable(part, {...?visited}));
    }
    return schema.types.contains('null') ||
        (schema.types.isEmpty &&
            schema.properties.isEmpty &&
            schema.allOf.isEmpty &&
            !schema.fields.containsKey('additionalProperties'));
  }

  DartTypeReference _type(_SchemaUse id, String hint) {
    final _SchemaUse schema = _schema(id);
    if (schema.intersectionBranches != null) {
      return _scalarAllOfType(schema)!;
    }
    if (_customType(id) case final type?) {
      return type;
    }
    final DartTypeReference? unwrapped = hasEnumMetadata
        ? _nullableEnumType(schema, hint)
        : null;
    if (unwrapped != null) {
      return unwrapped;
    }
    if (!names.containsKey(id) &&
        !_namedSchema.hasMatch(id.pointer) &&
        schema.allOf.length == 1 &&
        schema.allOf.single.reference != null &&
        schema.rawFields.keys.every(
          const {
            'allOf',
            'title',
            'summary',
            'description',
            'default',
            'nullable',
            'deprecated',
            'externalDocs',
            'example',
            'examples',
            r'$comment',
          }.contains,
        )) {
      return _type(schema.allOf.single, hint);
    }
    if (names.containsKey(id) ||
        _namedSchema.hasMatch(id.pointer) ||
        _hasObjectShape(schema) ||
        _tupleSource(schema) != null ||
        _hasAlternatives(schema) ||
        (_cases(schema) != null &&
            (!_isFullBooleanEnum(schema) ||
                (hasEnumMetadata &&
                    schema.rawFields.containsKey('x-enum-metadata'))))) {
      final String name = _name(id, hint);
      _declare(id);
      return DartTypeReference(
        symbol: name,
        isNullable: _nullable(id),
        isMetadataEnum:
            hasEnumMetadata && schema.rawFields.containsKey('x-enum-metadata'),
      );
    }
    if (schema.reference case final target?) {
      _checkRef(schema);
      if (schema.raw.dynamicReference != null) {
        return _type(_concrete(schema), hint);
      }
      final String targetName = target.pointer
          .split('/')
          .last
          .replaceAll('~1', '/')
          .replaceAll('~0', '~');
      _name(target, targetName.isEmpty ? hint : targetName);
      return _referenceType(schema, hint);
    }
    return _valueType(id, hint);
  }

  DartTypeReference _referenceType(_SchemaUse schema, String hint) {
    final DartTypeReference type = _type(schema.reference!, hint);
    if (schema.swaggerNullable == null) {
      return type;
    }
    return DartTypeReference(
      symbol: type.symbol,
      importUrl: type.importUrl,
      scalarCodec: type.scalarCodec,
      typeArguments: type.typeArguments,
      isNullable: _nullable(schema),
      isMetadataEnum: type.isMetadataEnum,
    );
  }

  DartTypeReference? _nullableEnumType(_SchemaUse schema, String hint) {
    final _SchemaUse? target = _nullableReferenceTarget(schema);
    if (target == null) {
      return null;
    }
    final DartTypeReference type = _type(target, hint);
    return DartTypeReference(
      symbol: type.symbol,
      importUrl: type.importUrl,
      scalarCodec: type.scalarCodec,
      typeArguments: type.typeArguments,
      isNullable: true,
      isMetadataEnum: type.isMetadataEnum,
    );
  }

  _SchemaUse? _nullableReferenceTarget(_SchemaUse schema) {
    if (schema.swaggerNullable == false ||
        schema.allOf.isNotEmpty ||
        (schema.oneOf.isNotEmpty && schema.anyOf.isNotEmpty)) {
      return null;
    }
    final List<_SchemaUse> branches = schema.oneOf.isNotEmpty
        ? schema.oneOf
        : schema.anyOf;
    if (branches.length != 2) {
      return null;
    }
    final List<_SchemaUse> references = branches
        .where((branch) => branch.reference != null)
        .toList();
    final List<_SchemaUse> nulls = branches.where(_isNullAlternative).toList();
    if (references.length != 1 || nulls.length != 1) {
      return null;
    }
    final _SchemaUse? target = references.single.reference;
    return target != null && _containsEnumMetadata(target) ? target : null;
  }

  bool _isNullAlternative(_SchemaUse schema) {
    if (schema.reference != null ||
        schema.allOf.isNotEmpty ||
        schema.anyOf.isNotEmpty ||
        schema.oneOf.isNotEmpty) {
      return false;
    }
    if (_cases(schema) case final cases?) {
      return cases.length == 1 && cases.single == null;
    }
    return schema.types.length == 1 && schema.types.contains('null');
  }

  bool _containsEnumMetadata(_SchemaUse schema) =>
      enumMetadataMatches[schema] ??= _scanEnumMetadata(schema);

  bool _scanEnumMetadata(_SchemaUse schema) {
    final pending = <_SchemaUse>[schema];
    final visited = <_SchemaUse>{};
    var found = false;
    while (pending.isNotEmpty) {
      final _SchemaUse current = pending.removeLast();
      if (!visited.add(current)) {
        continue;
      }
      final bool? known = enumMetadataMatches[current];
      if (known != null) {
        found = found || known;
        continue;
      }
      if (current.rawFields.containsKey('x-enum-metadata')) {
        found = true;
        continue;
      }
      final _SchemaUse? reference = current.reference;
      if (reference != null) {
        pending.add(reference);
      }
      pending
        ..addAll(current.allOf)
        ..addAll(current.oneOf)
        ..addAll(current.anyOf);
    }
    enumMetadataMatches[schema] = found;
    return found;
  }

  void _preflightEnumMetadata(_SchemaUse id, _SchemaUse schema) {
    final bool hasExtension = schema.rawFields.containsKey('x-enum-metadata');
    if ((schema.allOf.isNotEmpty || _hasAlternatives(schema)) &&
        (_nullableReferenceTarget(schema) == null || hasExtension) &&
        _containsEnumMetadata(schema)) {
      _fail(
        id,
        'x-enum-metadata is not supported on composed schemas.',
        field: 'x-enum-metadata',
      );
    }
    if (!hasExtension) {
      return;
    }
    if (schema.rawFields['x-enum-metadata'] is! Map) {
      _fail(id, 'x-enum-metadata must be an object.', field: 'x-enum-metadata');
    }
  }

  (Map<String, String>, Map<String, Map<String, Object>>) _enumMetadata(
    _SchemaUse id,
    List<Object?> cases,
    List<String>? labels,
    Map<String, Object> entries,
  ) {
    final Object? raw = id.fields['x-enum-metadata'];
    if (!id.fields.containsKey('x-enum-metadata')) {
      return (<String, String>{}, <String, Map<String, Object>>{});
    }
    Never invalid(String why) =>
        _fail(id, 'Invalid x-enum-metadata: $why.', field: 'x-enum-metadata');
    if (raw is! Map<String, Object?> ||
        raw.length != 3 ||
        raw['version'] != 1 ||
        raw['fields'] is! Map ||
        raw['values'] is! Map) {
      invalid('expected exactly version 1, fields, and values');
    }
    final Map<String, Object?> metadata = raw;
    final Set<String> declaredTypes = id.types
        .where((t) => t != 'null')
        .toSet();
    final List<Object?> nonNullCases = cases
        .where((value) => value != null)
        .toList();
    final bool inferredString =
        declaredTypes.isEmpty &&
        nonNullCases.isNotEmpty &&
        nonNullCases.every((v) => v is String);
    final bool inferredInteger =
        declaredTypes.isEmpty &&
        nonNullCases.isNotEmpty &&
        nonNullCases.every((v) => v is int);
    final bool inferredBoolean =
        declaredTypes.isEmpty &&
        nonNullCases.isNotEmpty &&
        nonNullCases.every((v) => v is bool);
    if ((!inferredString &&
            !inferredInteger &&
            !inferredBoolean &&
            (declaredTypes.difference({
                  'string',
                  'integer',
                  'boolean',
                }).isNotEmpty ||
                declaredTypes.length != 1)) ||
        (declaredTypes.isEmpty &&
            !inferredString &&
            !inferredInteger &&
            !inferredBoolean)) {
      invalid('only string, integer, and boolean enums are supported');
    }
    final definitions = metadata['fields']! as Map<dynamic, dynamic>;
    final rows = metadata['values']! as Map<dynamic, dynamic>;
    final types = <String, String>{};
    final generatedMembers = <String>{
      'name',
      'index',
      'hashCode',
      'toString',
      'noSuchMethod',
      'runtimeType',
      'rawValue',
      'copyWith',
      'wireValue',
      'tryFromJson',
      'fromJson',
      'toJson',
      'json',
      'values',
      'value',
      'byName',
      ..._memberNames,
    };
    for (final MapEntry<dynamic, dynamic> entry in definitions.entries) {
      final Object? rawField = entry.key;
      final Object? definition = entry.value;
      if (rawField is! String ||
          !RegExp(r'^[a-z][A-Za-z0-9]*$').hasMatch(rawField) ||
          definition is! Map ||
          definition.length != 1 ||
          !definition.containsKey('type') ||
          !const {
            'string',
            'integer',
            'number',
            'boolean',
          }.contains(definition['type'])) {
        invalid('unsupported field definition $rawField');
      }
      final String field = rawField;
      final String protected = _identifier(field, <String>{});
      final List<String> rawLabels =
          labels ?? cases.map((value) => value.toString()).toList();
      final bool collidesWithMember = rawLabels.any((label) {
        final String converted = _identifierBase(label);
        final finalName = converted.isEmpty ? 'empty' : converted;
        return field == finalName ||
            field ==
                'value${finalName[0].toUpperCase()}${finalName.substring(1)}';
      });
      if (protected != field ||
          generatedMembers.contains(field) ||
          collidesWithMember ||
          entries.keys.any((n) => _identifierBase(n) == field) ||
          types.containsKey(field)) {
        invalid('unsupported field name $field');
      }
      types[field] = definition['type'] as String;
    }
    final expected = <String>{
      for (final v in cases.where((v) => v != null)) v.toString(),
    };
    if (rows.keys.any((k) => k is! String || !expected.contains(k)) ||
        rows.length != expected.length ||
        !expected.every(rows.containsKey)) {
      invalid('values must be keyed by each exact enum wire value');
    }
    final result = <String, Map<String, Object>>{};
    for (final wire in expected) {
      final Object? rawRow = rows[wire];
      if (rawRow is! Map ||
          rawRow.length != types.length ||
          !types.keys.every(rawRow.containsKey)) {
        invalid('row $wire must define every field exactly once');
      }
      final Map<dynamic, dynamic> row = rawRow;
      final values = <String, Object>{};
      for (final MapEntry<String, String> field in types.entries) {
        final Object? value = row[field.key];
        if ((field.value == 'string' && value is! String) ||
            (field.value == 'integer' && value is! int) ||
            (field.value == 'boolean' && value is! bool) ||
            (field.value == 'number' && value is! num)) {
          invalid('invalid ${field.value} for $wire.${field.key}');
        }
        if (field.value == 'number') {
          final number = value! as num;
          if (!number.isFinite ||
              !number.toDouble().isFinite ||
              (number is int && number.abs() > 9007199254740991)) {
            invalid(
              'expected a finite, exactly representable double for $wire.${field.key}',
            );
          }
          values[field.key] = number.toDouble();
        } else {
          values[field.key] = value!;
        }
      }
      result[wire] = values;
    }
    return (types, result);
  }

  bool _hasObjectShape(_SchemaUse schema) =>
      schema.fields['additionalProperties'] == false ||
      schema.raw.properties.isNotEmpty ||
      schema.allOf.isNotEmpty ||
      (schema.reference == null &&
          schema.types.contains('object') &&
          !schema.fields.containsKey('additionalProperties'));

  bool _isDto(_SchemaUse schema) =>
      _hasObjectShape(schema) && _tupleSource(schema) == null;

  void _checkRef(_SchemaUse schema) {
    if (schema.raw.dynamicReference == null &&
        (schema.family == OpenApiFamily.v31 ||
            schema.family == OpenApiFamily.v32) &&
        schema.fields.keys.any(
          (key) => key != 'type' && _referenceShapeKeywords.contains(key),
        )) {
      _fail(schema, 'Cannot combine a reference with local shape constraints.');
    }
  }

  void _declare(_SchemaUse id) {
    if (_customType(id) != null) {
      if (hasEnumMetadata && _containsEnumMetadata(_schema(id))) {
        _fail(
          id,
          'x-enum-metadata is not supported with custom type mappings.',
          field: 'x-enum-metadata',
        );
      }
      return;
    }
    if (!declared.add(id)) {
      return;
    }
    final _SchemaUse schema = _schema(id);
    final String name = names[id]!;
    final _SchemaUse? tuple = _tupleSource(id);
    if (hasEnumMetadata) {
      _preflightEnumMetadata(id, schema);
    }
    if (schema.reference != null && tuple == null) {
      _checkRef(schema);
      _nullable(id);
      values.add(DartValueModel(name, _referenceType(schema, '${name}Value')));
    } else if (_hasAlternatives(schema)) {
      if (!_usesDiscriminator(schema)) {
        _structuralUnion(id, name);
      } else {
        _union(id, name);
      }
    } else if (_isFullBooleanEnum(schema) &&
        !schema.fields.containsKey('x-enum-metadata')) {
      values.add(DartValueModel(name, _booleanType(schema)));
    } else if (_cases(schema) case final cases?) {
      final Set<String> used = {
        ..._memberNames,
        if (schema.fields.containsKey('x-enum-metadata')) ...{
          'wireValue',
          'tryFromJson',
        },
        'values',
        'index',
        'name',
        'byName',
        'value',
        name,
      };
      final List<String>? labels = _enumNames(schema, cases);
      final entries = <String, Object>{};
      final seen = <Object>{};
      for (final (int position, Object? value) in cases.indexed) {
        if (value == null) {
          continue;
        }
        if (hasEnumMetadata &&
            schema.fields.containsKey('x-enum-metadata') &&
            schema.types.contains('number')) {
          _fail(
            id,
            'Number enum wire values are not supported with x-enum-metadata.',
            field: 'enum/$position',
          );
        }
        if (value is! String && value is! num && value is! bool) {
          _fail(id, 'Enum values must be JSON scalars.');
        }
        if (hasEnumMetadata &&
            schema.fields.containsKey('x-enum-metadata') &&
            schema.types.contains('integer') &&
            value is! int) {
          _fail(
            id,
            'Integer enum values must be integers.',
            field: 'enum/$position',
          );
        }
        if (!_allowsScalar(schema.types, value)) {
          _fail(
            id,
            'Enum value does not match the schema type.',
            field: 'enum/$position',
          );
        }
        if (!seen.add(value)) {
          continue;
        }
        String candidate = _replaceName(
          labels?[position] ?? value.toString(),
          NamingTarget.enumValues,
        );
        if (labels == null &&
            value is num &&
            value < 0 &&
            candidate == value.toString()) {
          candidate = 'fieldMinus${value.abs()}'.replaceAll('.', 'Point');
        }
        entries[_identifier(candidate, used)] = value;
      }
      if (entries.isEmpty) {
        _fail(id, 'Expected a non-null enum value.');
      }
      final (Map<String, String>, Map<String, Map<String, Object>>) metadata =
          hasEnumMetadata
          ? _enumMetadata(id, cases, labels, entries)
          : (<String, String>{}, <String, Map<String, Object>>{});
      enums.add(
        DartEnumModel(
          name,
          entries,
          types: Set.unmodifiable(schema.types.difference({'null'})),
          metadataFields: metadata.$1,
          metadataValues: metadata.$2,
          hasMetadata:
              hasEnumMetadata &&
              schema.rawFields.containsKey('x-enum-metadata'),
        ),
      );
    } else if (tuple != null) {
      _addTuple(id, name, tuple);
    } else if (_scalarAllOfType(id) case final type?) {
      values.add(DartValueModel(name, type));
    } else if (_isDto(schema)) {
      if (!_swaggerUnion(id, name)) {
        _object(name, _shape(id));
        _collectDiscriminators(name, id);
      }
    } else {
      values.add(DartValueModel(name, _valueType(id, name)));
    }
  }

  List<String>? _enumNames(_SchemaUse schema, List<Object?> cases) {
    final Object? values = schema.fields['enum'];
    if (values is! List<Object?>) {
      return null;
    }
    final String? key = const [
      'x-enumNames',
      'x-enum-varnames',
    ].where(schema.fields.containsKey).firstOrNull;
    if (key == null) {
      return null;
    }
    final Object? labels = schema.fields[key];
    if (labels is! List<Object?> || labels.length != values.length) {
      _fail(
        schema,
        'Expected $key to contain ${values.length} names.',
        field: key,
      );
    }
    for (final (int index, Object? label) in labels.indexed) {
      if (label is! String || label.trim().isEmpty) {
        _fail(schema, 'Expected a non-empty enum name.', field: '$key/$index');
      }
    }
    final List<String> names = labels.cast<String>();
    return schema.fields.containsKey('const')
        ? [names[values.indexOf(cases.single)]]
        : names;
  }

  DartTypeReference _valueType(_SchemaUse id, String name) {
    if (_isFullBooleanEnum(id) &&
        !(hasEnumMetadata && id.rawFields.containsKey('x-enum-metadata'))) {
      return _booleanType(id);
    }
    if (id.definition.value == false) {
      return DartTypeReference(symbol: 'Never');
    }
    final bool nullable = _nullable(id);
    final String? type = id.types.where((type) => type != 'null').firstOrNull;
    switch (type) {
      case 'array':
        return DartTypeReference(
          symbol: 'List',
          isNullable: nullable,
          typeArguments: [
            if (id.items case final child?)
              _type(child, '${name}Item')
            else
              _any,
          ],
        );
      case 'object':
      case null when id.fields.containsKey('additionalProperties'):
        return DartTypeReference(
          symbol: 'Map',
          isNullable: nullable,
          typeArguments: [
            _string,
            if (id.additionalProperties case final child?)
              _type(child, '${name}Value')
            else
              _any,
          ],
        );
      case 'integer' || 'number' || 'boolean' || 'string':
        return DartTypeReference(
          symbol: _scalarSymbol(type!, id),
          isNullable: nullable,
        );
      case null:
        return id.types.contains('null')
            ? DartTypeReference(symbol: 'Null')
            : id.swaggerNullable == false
            ? DartTypeReference(symbol: 'Object')
            : _any;
      default:
        _fail(id, 'Unsupported JSON value type: $type.');
    }
  }

  String _scalarSymbol(String type, _SchemaUse id) {
    if (type != 'string') {
      return _dartScalars[type]!;
    }
    final formats = <String>{};
    final visited = <_SchemaUse>{};
    void collect(_SchemaUse schema) {
      if (!visited.add(schema)) {
        return;
      }
      if (schema.fields['format'] case final String format) {
        formats.add(format);
      }
      if (schema.reference case final target?) {
        collect(target);
      }
      schema.allOf.forEach(collect);
    }

    collect(id);
    return formats.length == 1 && formats.single == 'date-time'
        ? 'DateTime'
        : 'String';
  }

  Set<String>? _conjunctiveTypes(_SchemaUse id, [Set<_SchemaUse>? visited]) {
    final Set<_SchemaUse> seen = visited ?? <_SchemaUse>{};
    if (!seen.add(id)) {
      return null;
    }
    Set<String>? result = id.types.isEmpty
        ? null
        : {...id.types, if (id.types.contains('number')) 'integer'};
    for (final _SchemaUse child in [?id.reference, ...id.allOf]) {
      final Set<String>? types = _conjunctiveTypes(child, seen);
      if (types != null) {
        result = result?.intersection(types) ?? types;
      }
    }
    return result;
  }

  DartTypeReference? _scalarAllOfType(_SchemaUse id) {
    if (id.allOf.isEmpty) {
      return null;
    }
    final Set<String>? types = _conjunctiveTypes(id);
    if (types == null ||
        types.isEmpty ||
        types.any((t) => !_dartScalars.containsKey(t) && t != 'null')) {
      return null;
    }
    final Iterable<String> concrete = types.where(
      (t) => t != 'null' && !(t == 'integer' && types.contains('number')),
    );
    if (concrete.isEmpty) {
      return DartTypeReference(symbol: 'Null');
    }
    if (concrete.length != 1) {
      return null;
    }
    return DartTypeReference(
      symbol: _scalarSymbol(concrete.single, id),
      isNullable: types.contains('null'),
    );
  }

  bool _hasAlternatives(_SchemaUse schema) =>
      schema.oneOf.isNotEmpty || schema.anyOf.isNotEmpty;

  List<Object?>? _cases(_SchemaUse schema) {
    final Map<String, Object?> fields = schema.fields;
    return fields.containsKey('const')
        ? [fields['const']]
        : fields['enum'] as List<Object?>?;
  }

  bool _isFullBooleanEnum(_SchemaUse schema) {
    if (schema.reference != null ||
        schema.allOf.isNotEmpty ||
        _hasAlternatives(schema) ||
        schema.fields.containsKey('const') ||
        schema.fields.containsKey('x-enumNames') ||
        schema.fields.containsKey('x-enum-varnames') ||
        (schema.types.isNotEmpty && !schema.types.contains('boolean')) ||
        schema.types.any((type) => type != 'boolean' && type != 'null')) {
      return false;
    }
    final List<Object?>? cases = _cases(schema);
    return cases != null &&
        cases.contains(true) &&
        cases.contains(false) &&
        cases.every((value) => value is bool || value == null);
  }

  DartTypeReference _booleanType(_SchemaUse schema) =>
      DartTypeReference(symbol: 'bool', isNullable: _nullable(schema));
}

final _any = DartTypeReference(symbol: 'Object', isNullable: true);
final _string = DartTypeReference(symbol: 'String');

final _namedSchema = RegExp(r'^/(?:definitions|components/schemas)/([^/]+)$');

String? _componentKey(_SchemaUse? id) {
  if (id == null) {
    return null;
  }
  return _namedSchema
      .firstMatch(id.pointer)?[1]
      ?.replaceAll('~1', '/')
      .replaceAll('~0', '~');
}

const _dartScalars = {
  'integer': 'int',
  'number': 'num',
  'boolean': 'bool',
  'string': 'String',
};
