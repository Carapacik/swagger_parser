import 'package:swagger_parser_core/swagger_parser_core.dart'
    show Diagnostic, JsonValue;

part 'dart_client_model.dart';
part 'dart_scalar_codec.dart';
part 'dart_structural_union_model.dart';

/// Dart libraries to generate and diagnostics from mapping.
final class DartGenerationModel({
  required Iterable<DartLibraryModel> libraries,
  Iterable<Diagnostic> diagnostics = const [],
}) {
  /// Copies the libraries into an immutable list.
  this;

  /// Libraries to generate.
  final List<DartLibraryModel> libraries = List.unmodifiable(libraries);

  /// Mapping diagnostics, including omitted HTTP operations.
  final List<Diagnostic> diagnostics = List.unmodifiable(diagnostics);
}

/// Source documentation for a generated declaration.
final class const DartDocumentation({
  /// Short source text. Null omits the summary.
  final String? summary,

  /// Full source text. Null omits the description.
  final String? description,

  /// Emits Deprecated independently of documentation settings.
  final bool deprecated = false,
}) {
  /// Keeps source text unchanged.
  this;
}

/// One Dart library and its declarations.
final class DartLibraryModel({
  /// Output path relative to the generation root.
  required final String relativePath,
  required Iterable<DartDtoModel> dtos,

  /// Source documentation keyed by declaration name.
  final Map<String, DartDocumentation> documentation = const {},

  /// Source field documentation keyed by class and Dart field name.
  final Map<String, Map<String, DartDocumentation>> fieldDocumentation =
      const {},

  /// Model names mapped to their validation predicates.
  final Map<String, String> validators = const {},

  /// Allocated validation extension names, keyed by model name.
  final Map<String, String> validatorExtensions = const {},

  /// Emits the shared validation error class.
  final bool validationErrors = false,

  /// Allocated validation error class name.
  final String validationErrorName = 'DtoValidationError',

  /// Relative import of the shared validation error class.
  final String? validationErrorImport,

  /// Emits the shared immutable operation metadata type.
  final bool apiMetadata = false,

  /// Allocated operation metadata type name.
  final String metadataTypeName = 'OperationMetadata',

  /// Shared metadata library path from the generation root.
  final String metadataTypePath = 'api_metadata.dart',

  /// Allocated companion class name for operation constants.
  final String? clientMetadataName,

  /// Companion library path from the generation root.
  final String? clientMetadataPath,

  /// Adds metadata to request extras. Defaults to false.
  final bool attachOperationMetadata = false,

  /// Operations declared as constants in a companion library.
  final List<DartClientOperation> metadataOperations = const [],

  /// Emits shared package:http request settings.
  final bool httpRequestOptions = false,

  /// Emits a package:http payload and response wrapper.
  final bool httpResponse = false,

  /// Request settings library path from the generation root.
  final String httpRequestOptionsPath = 'http_request_options.dart',

  /// Response wrapper library path from the generation root.
  final String httpResponsePath = 'http_response.dart',

  /// Internal response decoder implementation: entry, native, or web.
  final String? responseDecoder,

  /// Response decoder library path from the generation root.
  final String responseDecoderPath = 'response_decoder.dart',

  /// Conditional implementation imports for the response decoder.
  final List<String> responseDecoderImports = const [],

  /// Class name for a library with HTTP operations.
  final String clientName = 'ApiClient',

  /// Model paths keyed by type name.
  final Map<String, String> modelPaths = const {},

  /// Relative imports for this model library.
  final List<String> imports = const [],

  /// Relative exports for this library.
  final List<String> exports = const [],

  /// External public types to export, keyed by import URI.
  final Map<String, List<String>> typeExports = const {},

  /// Aliased imports used by constant default expressions.
  final Map<String, String> constantImports = const {},

  /// Facade class and client fields for the entry file.
  final DartFacadeModel? facade,

  /// Types with a JSON map factory.
  final Set<String> objectNames = const {},

  /// Types that can wrap a null JSON value.
  final Set<String> wrapperNames = const {},

  /// Accept integer-valued numbers in structural codecs.
  final bool matchIntegers = false,
  Iterable<DartEnumModel> enums = const [],
  Iterable<DartUnionModel> unions = const [],
  Iterable<DartValueModel> values = const [],
  Iterable<DartTupleModel> tuples = const [],
  Iterable<DartStructuralUnion> structuralUnions = const [],
  Iterable<DartSchemaMatcher> matchers = const [],
  Iterable<DartClientOperation> operations = const [],
  Iterable<DartClientOperation> results = const [],

  /// Sibling result library exported by the client.
  final String? resultFile,
}) {
  /// Groups DTOs at one relative output path.
  this;

  /// Sealed DTO types selected by a JSON tag.
  final List<DartUnionModel> unions = List.unmodifiable(unions);

  /// Union types selected by schema validation.
  final List<DartStructuralUnion> structuralUnions = List.unmodifiable(
    structuralUnions,
  );

  /// Shared predicates for unions and DTO validation.
  final List<DartSchemaMatcher> matchers = List.unmodifiable(matchers);

  /// Enums with JSON scalar values.
  final List<DartEnumModel> enums = List.unmodifiable(enums);

  /// Named scalar, array, map, and reference wrappers.
  final List<DartValueModel> values = List.unmodifiable(values);

  /// Arrays with typed positional getters.
  final List<DartTupleModel> tuples = List.unmodifiable(tuples);

  /// DTO classes to emit in this library.
  final List<DartDtoModel> dtos = List.unmodifiable(dtos);

  /// Status result types declared in this library.
  final List<DartClientOperation> results = List.unmodifiable(results);

  /// Methods to emit in the HTTP client.
  final List<DartClientOperation> operations = List.unmodifiable(operations);
}

/// A JSON tuple with typed positions and an optional tail.
final class DartTupleModel({
  /// Class identifier.
  required final String name,
  required Iterable<DartTypeReference> positions,

  /// Number of positions present in every valid value.
  required final int requiredCount,

  /// Whether the schema requires an array.
  required final bool arrayOnly,

  /// Predicate for the complete JSON value.
  required final String matcher,

  /// Project nested directional values before storing the JSON snapshot.
  final bool project = false,

  /// Tail item type. Null closes the tuple.
  final DartTypeReference? restType,
}) {
  /// Copies the positional types in wire order.
  this;

  /// Type of each prefix item.
  final List<DartTypeReference> positions = List.unmodifiable(positions);
}

/// A Dart class and its constructor fields.
final class DartDtoModel({
  /// Identifier of the generated Dart class.
  required final String name,
  Iterable<DartFieldModel> fields = const [],

  /// Whether this declaration has JSON constructors and methods.
  final bool json = false,

  /// Type of additional JSON properties. Null closes the object.
  final DartTypeReference? extraValueType,
  Iterable<String> ignoredWireKeys = const [],
}) {
  /// Keeps constructor fields in declaration order.
  this;

  /// Fields in schema order, including fixed getters.
  final List<DartFieldModel> fields = List.unmodifiable(fields);

  /// Declared keys omitted in this request or response projection.
  final Set<String> ignoredWireKeys = Set.unmodifiable(ignoredWireKeys);
}

/// A DTO field and its JSON rules.
final class DartFieldModel({
  /// Identifier of the generated field.
  required final String name,

  /// Declared Dart type.
  required final DartTypeReference type,

  /// Whether the JSON property is required. Fixed fields have no parameter.
  final bool isRequired = true,

  /// Original JSON property name.
  final String? wireName,

  /// Whether explicit JSON null is valid.
  final bool acceptsNull = false,

  /// Enables presence records for optional nullable fields without defaults.
  final bool usePresenceRecord = false,

  /// Allowed discriminator enum values. Empty means no enum constraint.
  final List<Object> discriminatorValues = const [],

  /// Fixed discriminator wire value. Null means a caller-supplied field.
  final JsonValue? fixedValue,

  /// Constant getter expression for [fixedValue].
  final String? fixedExpression,

  /// Named types used by the fixed getter expression.
  final Set<String> fixedDependencies = const {},

  /// Schema default for an optional field. Null means no default.
  final JsonValue? defaultValue,

  /// Constant Dart expression for [defaultValue], allocated by the mapper.
  final String? defaultExpression,

  /// Types and imported symbols used by the constant default expression.
  final Set<String> defaultDependencies = const {},
}) {
  /// Defines a named parameter. Optional fields need nullability or a default.
  this {
    if (!isRequired &&
        defaultValue == null &&
        !type.isNullable &&
        type.symbol != 'Null') {
      throw ArgumentError(
        'An optional field without a default must be nullable.',
      );
    }
  }

  /// Wraps optional nullable JSON values in a presence record.
  bool get tracksPresence =>
      usePresenceRecord && !isRequired && acceptsNull && defaultValue == null;
}

/// A Dart type with an optional import and type arguments.
final class DartTypeReference({
  /// Dart identifier of the referenced type.
  required final String symbol,

  /// Import URI that provides the type.
  final String? importUrl,

  /// Codec for an imported scalar or object. Null uses the standard codec.
  final DartScalarCodec? scalarCodec,

  /// Whether the type permits null.
  final bool isNullable = false,
  Iterable<DartTypeReference> typeArguments = const [],
}) {
  /// Records the type name, import, nullability, and type arguments.
  this;

  /// Generic arguments in declaration order.
  final List<DartTypeReference> typeArguments = List.unmodifiable(
    typeArguments,
  );
}

/// A Dart enum and its JSON scalar values.
final class DartEnumModel(
  /// Enum type identifier.
  final String name,
  Map<String, Object> values, {

  /// Helper declarations for preserved unknown values. Null keeps a Dart enum.
  final DartOpenEnumNames? openNames,

  /// Declared non-null JSON types for unknown values.
  final Set<String> types = const {},
}) {
  /// Copies values in declaration order.
  this;

  /// JSON values keyed by Dart case name.
  final Map<String, Object> values = Map.unmodifiable(values);
}

/// Names and payload type for an enum with unknown values.
final class const DartOpenEnumNames(
  /// Enum of known values.
  final String values,

  /// Known-value variant.
  final String known,

  /// Unknown-value variant.
  final String unknown,

  /// Dart scalar type of the wire value.
  final String rawType,
) {
  /// Records allocated helper names.
  this;
}

/// A named JSON value with a Dart type.
final class const DartValueModel(
  /// Class identifier.
  final String name,

  /// Type of the wrapped value.
  final DartTypeReference type,
) {
  /// Records the wrapper name and payload type.
  this;
}

/// A sealed type with object DTO variants.
final class DartUnionModel(
  /// Identifier of the generated sealed class.
  final String name,

  /// Wire name of the discriminator.
  final String propertyName,
  Map<String, String> mapping, {

  /// Variant that preserves an unknown string tag and its JSON object.
  final String? unknownType,

  /// DTO for a missing or unmapped value.
  final String? defaultType,
}) {
  /// Copies the dispatch table.
  this;

  /// DTO type names keyed by wire value.
  final Map<String, String> mapping = Map.unmodifiable(mapping);
}

/// The public entry point for generated clients.
final class const DartFacadeModel(
  /// Public class name.
  final String name,

  /// OpenAPI info.version.
  final String version,

  /// Client type names keyed by facade field name.
  final Map<String, String> clients, {

  /// Entry info.title.
  final String title = '',

  /// Exact Swagger or OpenAPI version.
  final String specVersion = '',

  /// Allocated shared operation metadata type. Null omits operation metadata.
  final String? metadataTypeName = 'OperationMetadata',

  /// Companion classes imported through exports.dart.
  final List<String> metadataNames = const [],

  /// Companion constant references in source operation order.
  final List<String> operationConstants = const [],

  /// Client library paths keyed by type name.
  final Map<String, String> clientPaths = const {},
}) {
  /// Records the facade name, API version, and client fields.
  this;
}
