part of 'dart_model_mapper.dart';

extension on _Mapping {
  void _checkPrefixItems(_SchemaUse id) {
    if (id.family != OpenApiFamily.v31 && id.family != OpenApiFamily.v32) {
      _failAtKeyword(
        id,
        'prefixItems',
        'prefixItems requires OpenAPI 3.1 or 3.2.',
      );
    }
    final Object? entries = id.fields['prefixItems'];
    if (entries is! List<Object?> || entries.isEmpty) {
      _failAtKeyword(
        id,
        'prefixItems',
        'Expected a nonempty array of schemas.',
      );
    }
    for (final (index, value) in entries.indexed) {
      if (value is! bool && value is! Map<String, Object?>) {
        _fail(
          id,
          'Expected a schema object or boolean.',
          field: 'prefixItems/$index',
        );
      }
    }
    if (id.prefixItems.length != entries.length) {
      _failAtKeyword(id, 'prefixItems', 'Missing indexed tuple positions.');
    }
  }

  Iterable<_SchemaUse> _tupleParts(_SchemaUse id, Set<_SchemaUse> seen) sync* {
    if (!seen.add(id)) {
      return;
    }
    yield id;
    for (final _SchemaUse part in [?id.reference, ...id.allOf]) {
      yield* _tupleParts(part, seen);
    }
  }

  _SchemaUse? _tupleSource(_SchemaUse id) {
    final bool hasRefSiblings =
        id.reference != null &&
        (id.family == OpenApiFamily.v31 || id.family == OpenApiFamily.v32) &&
        id.fields.keys.any(
          (key) =>
              key != r'$ref' &&
              key != r'$dynamicRef' &&
              !_annotations.contains(key) &&
              !key.startsWith('x-'),
        );
    if (id.prefixItems.isEmpty && id.allOf.isEmpty && !hasRefSiblings) {
      return null;
    }
    _SchemaUse? source;
    for (final _SchemaUse part in _tupleParts(id, {})) {
      if (part.prefixItems.length > (source?.prefixItems.length ?? 0)) {
        source = part;
      }
    }
    if (source == null || _conjunctiveTypes(id)?.contains('array') == false) {
      return null;
    }
    return source;
  }

  void _addTuple(_SchemaUse id, String name, _SchemaUse source) {
    final String matcher = _matcher(id);
    final Set<String>? types = _conjunctiveTypes(id);
    final bool arrayOnly =
        types != null && types.length == 1 && types.contains('array');
    final int length = source.prefixItems.length;
    var requiredCount = 0;
    var open = true;
    _SchemaUse? tail;
    for (final _SchemaUse part in _tupleParts(id, {})) {
      if (part.fields['minItems'] case final num min when min > requiredCount) {
        requiredCount = min.toInt().clamp(0, length);
      }
      if (part.fields['maxItems'] case final num max when max <= length) {
        open = false;
      }
      if (part.items case final item?) {
        final Object? value = _concrete(item).definition.value;
        if (value == false) {
          open = false;
        } else if (value != true) {
          tail ??= item;
        }
      }
      if (part.prefixItems.any(
        (item) => _concrete(item).definition.value == false,
      )) {
        open = false;
      }
    }
    tuples.add(
      DartTupleModel(
        name: name,
        positions: [
          for (final (index, item) in source.prefixItems.indexed)
            _type(item, '${name}Item${index + 1}'),
        ],
        requiredCount: arrayOnly ? requiredCount : 0,
        restType: !open
            ? null
            : tail == null
            ? _any
            : _type(tail, '${name}RestItem'),
        arrayOnly: arrayOnly,
        matcher: matcher,
        project: id.direction != null,
      ),
    );
  }
}
