part of 'dart_model_mapper.dart';

extension on _Mapping {
  Set<ReferenceLocation> _validateKeepModels() {
    final roots = <ReferenceLocation>{};
    for (final String selector in config.keepModels) {
      final Uri? uri = Uri.tryParse(selector);
      final ReferenceLocation? id =
          uri == null ||
              !selector.startsWith('#/') ||
              uri.removeFragment().toString().isNotEmpty
          ? null
          : api.namedSchemas.values
                .where((id) => id.pointer == uri.fragment)
                .firstOrNull;
      if (id == null) {
        throw GenerationException(
          'Expected a local named schema reference in keep_models: $selector.',
        );
      }
      roots.add(id);
    }
    return roots;
  }

  void _pruneModelGroups(
    List<DartLibraryModel> clients,
    Map<String, Set<String>> deps,
    Map<String, Set<String>> groups,
    String Function(String) family,
  ) {
    if (!config.pruneUnusedModels) {
      return;
    }
    final reachable = <String>{};
    void visit(String symbol) {
      if (!reachable.add(symbol)) {
        return;
      }
      for (final String member in groups[family(symbol)] ?? const <String>{}) {
        if (member != symbol) {
          visit(member);
        }
        for (final String dep in deps[member] ?? const <String>{}) {
          visit(dep);
        }
      }
    }

    void type(DartTypeReference ref) {
      visit(ref.symbol);
      ref.typeArguments.forEach(type);
    }

    for (final client in clients) {
      for (final DartClientOperation op in client.operations) {
        type(op.response);
        for (final DartStatusVariant variant in op.variants.values) {
          if (variant.type case final ref?) {
            type(ref);
          }
        }
        for (final DartClientParameter parameter in op.parameters) {
          type(parameter.type);
          parameter.defaultValue?.dependencies.forEach(visit);
        }
        if (op.body case final body?) {
          type(body.type);
          for (final DartFormField field in body.fields) {
            type(field.type);
            field.defaultValue?.dependencies.forEach(visit);
          }
        }
      }
    }
    for (final ReferenceLocation id in _validateKeepModels()) {
      for (final _Direction direction in _Direction.values) {
        final _SchemaUse schema = index.use(id, const {}, direction);
        if (_customType(schema) case final mapped?) {
          type(mapped);
        } else if (names[schema] case final name?) {
          visit(name);
        }
      }
    }
    groups.removeWhere((_, members) => !members.any(reachable.contains));
    for (final MapEntry<String, List<String>> entry in typeExports.entries) {
      final String? prefix = mappingPrefixes[entry.key];
      entry.value.removeWhere((name) => !reachable.contains('$prefix.$name'));
    }
    typeExports.removeWhere((_, names) => names.isEmpty);
  }
}
