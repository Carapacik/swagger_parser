/// Registry for tracking YAML anchors and their usage across the OpenAPI specification
class AnchorRegistry {
  /// Map of inline schema name to its definition context
  final Map<String, SchemaContext> inlineSchemaContexts = {};

  /// Map of inline schema name to all contexts where it's referenced
  final Map<String, Set<String>> inlineSchemaReferences = {};

  /// Set of contexts that are included after tag filtering
  final Set<String> includedContexts = {};

  /// Map to track which schemas are referenced from which contexts
  final Map<String, Set<String>> schemaReferencedFrom = {};

  /// Register an inline schema (anchor) definition
  void registerInlineSchema(String schemaName, String context) {
    inlineSchemaContexts[schemaName] = SchemaContext(
      schemaName: schemaName,
      context: context,
    );
    // Initialize reference set if not exists
    inlineSchemaReferences.putIfAbsent(schemaName, () => {});
  }

  /// Register a reference to an inline schema
  void registerInlineSchemaReference(String schemaName, String fromContext) {
    inlineSchemaReferences.putIfAbsent(schemaName, () => {}).add(fromContext);
  }

  /// Register a regular schema reference (non-inline)
  void registerSchemaReference(String schemaName, String fromContext) {
    schemaReferencedFrom.putIfAbsent(schemaName, () => {}).add(fromContext);
  }

  /// Mark a context as included (passed tag filtering)
  void markContextAsIncluded(String context) {
    includedContexts.add(context);
  }

  /// Check if a context is included
  bool isContextIncluded(String context) {
    return includedContexts.contains(context);
  }

  /// Determine which inline schemas should be included based on their usage
  Set<String> resolveIncludedInlineSchemas() {
    final includedSchemas = <String>{};

    for (final entry in inlineSchemaContexts.entries) {
      final schemaName = entry.key;
      final definitionContext = entry.value.context;

      // Include if the definition context itself is included
      if (isContextIncluded(definitionContext)) {
        includedSchemas.add(schemaName);
        continue;
      }

      // Include if any reference context is included
      final references = inlineSchemaReferences[schemaName] ?? {};
      if (references.any(isContextIncluded)) {
        includedSchemas.add(schemaName);
      }
    }

    return includedSchemas;
  }

  /// Get all schemas that should be included (both regular and inline)
  Set<String> resolveAllIncludedSchemas(Set<String> directlyUsedSchemas) {
    final allIncluded = <String>{...directlyUsedSchemas};

    // Add inline schemas that should be included based on context
    final includedInlineSchemas = resolveIncludedInlineSchemas();
    allIncluded.addAll(includedInlineSchemas);

    // Add inline schemas that are transitively reachable from included schemas
    for (final entry in inlineSchemaContexts.entries) {
      final schemaName = entry.key;
      final definitionContext = entry.value.context;

      // Check if this inline schema is defined within a schema that's already included
      // Context format: 'schema:ParentSchemaName'
      const schemaPrefix = 'schema:';
      if (definitionContext.startsWith(schemaPrefix)) {
        final parentSchemaName =
            definitionContext.substring(schemaPrefix.length);
        if (directlyUsedSchemas.contains(parentSchemaName) ||
            allIncluded.contains(parentSchemaName)) {
          allIncluded.add(schemaName);
        }
      }
    }

    // Add schemas referenced from included contexts
    for (final entry in schemaReferencedFrom.entries) {
      final schemaName = entry.key;
      final referencingContexts = entry.value;

      // If any referencing context is included, include the schema
      if (referencingContexts.any(isContextIncluded)) {
        allIncluded.add(schemaName);
      }
    }

    return allIncluded;
  }

  /// Clear the registry
  void clear() {
    inlineSchemaContexts.clear();
    inlineSchemaReferences.clear();
    includedContexts.clear();
    schemaReferencedFrom.clear();
  }
}

/// Represents the context where a schema is defined
class SchemaContext {
  SchemaContext({
    required this.schemaName,
    required this.context,
  });

  final String schemaName;
  final String context;

  @override
  String toString() => 'SchemaContext(schema: $schemaName, context: $context)';
}
