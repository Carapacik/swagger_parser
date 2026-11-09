import 'package:swagger_parser_core/src/config/parse_config.dart';
import 'package:swagger_parser_core/src/exceptions/open_api_exception.dart';
import 'package:swagger_parser_core/src/model/json_value.dart';
import 'package:swagger_parser_core/src/model/open_api_document.dart';
import 'package:swagger_parser_core/src/model/open_api_version.dart';
import 'package:swagger_parser_core/src/model/v3_1/open_api_v3_1_objects.dart';
import 'package:swagger_parser_core/src/model/v3_2/open_api_v3_2_objects.dart';
import 'package:swagger_parser_core/src/parser/decoder/source_decoder.dart';
import 'package:swagger_parser_core/src/parser/read_document.dart';
import 'package:swagger_parser_core/src/parser/schema_dialect.dart';
import 'package:swagger_parser_core/src/parser/uri_reference.dart';
import 'package:swagger_parser_core/src/source/schema_source.dart';
import 'package:swagger_parser_core/src/traversal/document_node.dart';

part 'reference_index.dart';

/// Physical document URI and JSON Pointer. In-memory input can omit the URI.
typedef ReferenceLocation = ({Uri? documentUri, String pointer});

/// An object or boolean schema at a resolved location.
final class ReferenceTarget {
  /// Copies a JSON target supplied by a custom resolver.
  new({
    required this.location,
    required this.baseUri,
    required Object? value,
    this.family,
    this.dialect,
  }) : value = JsonValue(value).value;

  const new _(
    this.location,
    this.baseUri,
    this.value,
    this.family,
    this.dialect,
  );

  /// Schema dialect inherited at the target, if available.
  final String? dialect;

  /// OpenAPI family of the target document, if known.
  final OpenApiFamily? family;

  /// Physical location of the target in the input.
  final ReferenceLocation location;

  /// Base URI for relative references at this target.
  final Uri baseUri;

  /// Immutable JSON at the target, including any further references.
  final Object? value;
}

/// One reference from a source field to its initial target.
final class const ResolvedReference({
  /// Reference URI after resolution against the source base URI.
  required final Uri uri,

  /// Target before dynamic scope selection.
  required final ReferenceTarget target,

  /// Anchor to select from the dynamic scope, when applicable.
  final String? dynamicAnchor,
}) {
  /// Pairs the resolved [uri] with its initial [target].
  this;
}

/// References indexed by the physical location of each URI field.
class ReferenceGraph {
  /// Copies the edges and dynamic anchors from a resolution pass.
  new(
    Map<ReferenceLocation, ResolvedReference> edges, {
    this.documentUri,
    Map<(Uri, String), ReferenceTarget> dynamicAnchors = const {},
    Map<ReferenceLocation, Uri> schemaResources = const {},
  }) : references = Map.unmodifiable(edges),
       dynamicAnchors = Map.unmodifiable(dynamicAnchors),
       schemaResources = Map.unmodifiable(schemaResources);

  /// Creates an empty graph.
  const new empty({this.documentUri})
    : references = const {},
      dynamicAnchors = const {},
      schemaResources = const {};

  /// Physical URI of the entry document, if supplied.
  final Uri? documentUri;

  /// Initial targets of reference fields, including edges in cycles.
  final Map<ReferenceLocation, ResolvedReference> references;

  /// Dynamic anchors by canonical resource URI and anchor name.
  final Map<(Uri, String), ReferenceTarget> dynamicAnchors;

  /// Canonical resource URI of each indexed OpenAPI 3.1 or 3.2 schema.
  final Map<ReferenceLocation, Uri> schemaResources;

  /// Selects a target using schema resource URIs in outermost-first order.
  ReferenceTarget? targetFor(
    ReferenceLocation source, {
    Iterable<Uri> dynamicScope = const [],
  }) {
    final ResolvedReference? edge = references[source];
    if (edge?.dynamicAnchor case final String name) {
      for (final resource in dynamicScope) {
        final ReferenceTarget? target =
            dynamicAnchors[(resource.removeFragment(), name)];
        if (target != null) {
          return target;
        }
      }
    }
    return edge?.target;
  }
}

/// Builds a reference graph without changing the document.
class const OpenApiReferenceResolver({
  final ParseConfig _config = const ParseConfig(),
}) {
  /// Applies the parse options to external documents.
  this;

  /// Resolves references in the document and loads external resources on demand.
  ///
  /// [config] overrides the constructor settings for this call.
  /// Each call owns its cache. Throws [ReferenceResolutionException] on failure.
  Future<ReferenceGraph> resolve(
    OpenApiDocument document, {
    Uri? sourceUri,
    DocumentLoader? loader,
    ParseConfig? config,
  }) => _ReferenceIndex(config ?? _config, loader).resolve(document, sourceUri);
}
