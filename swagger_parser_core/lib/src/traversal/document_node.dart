import 'package:swagger_parser_core/src/model/open_api_version.dart';
import 'package:swagger_parser_core/src/parser/decoder/source_decoder.dart';

/// Object roles that contain references or operations.
enum NodeKind() {
  /// Root OpenAPI object.
  document,

  /// Operations on one path.
  pathItem,

  /// An HTTP operation.
  operation,

  /// A request parameter.
  parameter,

  /// A response or part header.
  header,

  /// A status response.
  response,

  /// A request body.
  requestBody,

  /// A payload schema.
  schema,

  /// A callback path map.
  callback,

  /// One payload representation.
  mediaType,

  /// Encoding for one part.
  encoding,

  /// An example definition.
  example,

  /// A link to an operation.
  link,

  /// An authentication scheme.
  securityScheme,
}

/// One object at a physical JSON Pointer in an OpenAPI document.
final class const DocumentNode(
  /// The object's role in its parent.
  final NodeKind kind,

  /// Source JSON at [pointer].
  final Object? value,

  /// JSON Pointer from the document root.
  final String pointer,
) {
  /// Records the expected role of [value].
  this;

  /// Last unescaped JSON Pointer token.
  String get key => pointer
      .substring(pointer.lastIndexOf('/') + 1)
      .replaceAll('~1', '/')
      .replaceAll('~0', '~');

  /// Object fields, or an empty map for a boolean schema.
  Map<String, Object?> get fields => switch (value) {
    final Map<String, Object?> map => map,
    _ => const {},
  };

  /// Whether this position permits a reference in [family].
  bool allowsRef(OpenApiFamily family) => switch (kind) {
    NodeKind.document || NodeKind.operation || NodeKind.encoding => false,
    NodeKind.mediaType => family == OpenApiFamily.v32,
    NodeKind.header ||
    NodeKind.securityScheme => family != OpenApiFamily.swaggerV2,
    _ => true,
  };

  /// Visits OpenAPI objects and schema keywords. Example data stays opaque.
  Iterable<DocumentNode> children(OpenApiFamily family) sync* {
    final v2 = family == OpenApiFamily.swaggerV2;
    final v32 = family == OpenApiFamily.v32;
    final bool modern = v32 || family == OpenApiFamily.v31;
    final Map<String, Object?> data = fields;
    if (data.containsKey(r'$ref') &&
        allowsRef(family) &&
        kind != NodeKind.pathItem &&
        !(modern && kind == NodeKind.schema)) {
      return;
    }
    Iterable<DocumentNode> one(String key, NodeKind role) sync* {
      if (data.containsKey(key)) {
        yield DocumentNode(role, data[key], appendPointer(pointer, key));
      }
    }

    Iterable<DocumentNode> entries(
      Object? map,
      String path,
      NodeKind role, {
      bool extensions = false,
    }) sync* {
      if (map is Map<String, Object?>) {
        for (final MapEntry<String, Object?> entry in map.entries) {
          if (extensions && entry.key.startsWith('x-')) {
            continue;
          }
          yield DocumentNode(role, entry.value, appendPointer(path, entry.key));
        }
      }
    }

    Iterable<DocumentNode> dict(
      String key,
      NodeKind role, {
      bool extensions = false,
    }) => entries(
      data[key],
      appendPointer(pointer, key),
      role,
      extensions: extensions,
    );
    Iterable<DocumentNode> list(String key, NodeKind role) sync* {
      if (data[key] case final List<Object?> items) {
        for (var i = 0; i < items.length; i++) {
          yield DocumentNode(role, items[i], '$pointer/$key/$i');
        }
      }
    }

    switch (kind) {
      case NodeKind.document:
        yield* dict('paths', NodeKind.pathItem, extensions: true);
        if (v2) {
          yield* dict('definitions', NodeKind.schema);
          yield* dict('parameters', NodeKind.parameter);
          yield* dict('responses', NodeKind.response);
          yield* dict('securityDefinitions', NodeKind.securityScheme);
          return;
        }
        if (modern) {
          yield* dict('webhooks', NodeKind.pathItem);
        }
        if (data['components'] case final Map<String, Object?> components) {
          for (final MapEntry(:String key, :NodeKind value)
              in _componentKinds.entries) {
            if ((key == 'pathItems' && !modern) ||
                (key == 'mediaTypes' && !v32)) {
              continue;
            }
            yield* entries(components[key], '$pointer/components/$key', value);
          }
        }
      case NodeKind.pathItem:
        yield* list('parameters', NodeKind.parameter);
        for (final method in const [
          'get',
          'put',
          'post',
          'delete',
          'options',
          'head',
          'patch',
        ]) {
          yield* one(method, NodeKind.operation);
        }
        if (!v2) {
          yield* one('trace', NodeKind.operation);
        }
        if (v32) {
          yield* one('query', NodeKind.operation);
          yield* dict('additionalOperations', NodeKind.operation);
        }
      case NodeKind.operation:
        yield* list('parameters', NodeKind.parameter);
        yield* dict('responses', NodeKind.response, extensions: true);
        if (!v2) {
          yield* one('requestBody', NodeKind.requestBody);
          yield* dict('callbacks', NodeKind.callback);
        }
      case NodeKind.callback:
        yield* entries(data, pointer, NodeKind.pathItem, extensions: true);
      case NodeKind.parameter || NodeKind.header:
        if (!v2 || (kind == NodeKind.parameter && data['in'] == 'body')) {
          yield* one('schema', NodeKind.schema);
        }
        if (!v2) {
          yield* dict('examples', NodeKind.example);
          yield* dict('content', NodeKind.mediaType);
        }
      case NodeKind.response:
        yield* dict('headers', NodeKind.header);
        if (v2) {
          yield* one('schema', NodeKind.schema);
        } else {
          yield* dict('content', NodeKind.mediaType);
          yield* dict('links', NodeKind.link);
        }
      case NodeKind.requestBody:
        yield* dict('content', NodeKind.mediaType);
      case NodeKind.mediaType || NodeKind.encoding:
        if (kind == NodeKind.mediaType) {
          yield* one('schema', NodeKind.schema);
          yield* dict('examples', NodeKind.example);
          if (v32) {
            yield* one('itemSchema', NodeKind.schema);
          }
        } else {
          yield* dict('headers', NodeKind.header);
        }
        if (kind == NodeKind.mediaType || v32) {
          yield* dict('encoding', NodeKind.encoding);
        }
        if (v32) {
          yield* list('prefixEncoding', NodeKind.encoding);
          yield* one('itemEncoding', NodeKind.encoding);
        }
      case NodeKind.schema:
        yield* dict('properties', NodeKind.schema);
        yield* list('allOf', NodeKind.schema);
        if (modern || data['additionalProperties'] is Map<String, Object?>) {
          yield* one('additionalProperties', NodeKind.schema);
        }
        if (v2 && data['items'] is List<Object?>) {
          yield* list('items', NodeKind.schema);
        } else {
          yield* one('items', NodeKind.schema);
        }
        if (!v2) {
          yield* list('oneOf', NodeKind.schema);
          yield* list('anyOf', NodeKind.schema);
          yield* one('not', NodeKind.schema);
        }
        if (modern) {
          for (final key in const [
            r'$defs',
            'definitions',
            'patternProperties',
            'dependentSchemas',
          ]) {
            yield* dict(key, NodeKind.schema);
          }
          yield* list('prefixItems', NodeKind.schema);
          for (final key in const [
            'if',
            'then',
            'else',
            'contains',
            'propertyNames',
            'unevaluatedItems',
            'unevaluatedProperties',
            'contentSchema',
          ]) {
            yield* one(key, NodeKind.schema);
          }
        }
      case NodeKind.link || NodeKind.example || NodeKind.securityScheme:
        return;
    }
  }

  /// Roles of the reusable component maps.
  static const Map<String, NodeKind> _componentKinds = {
    'schemas': NodeKind.schema,
    'responses': NodeKind.response,
    'parameters': NodeKind.parameter,
    'examples': NodeKind.example,
    'requestBodies': NodeKind.requestBody,
    'headers': NodeKind.header,
    'securitySchemes': NodeKind.securityScheme,
    'links': NodeKind.link,
    'callbacks': NodeKind.callback,
    'pathItems': NodeKind.pathItem,
    'mediaTypes': NodeKind.mediaType,
  };
}
