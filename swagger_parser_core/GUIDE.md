# Core guide

Typed JSON and YAML parsing for Swagger 2.0 and OpenAPI 3.0.x, 3.1.x, and 3.2.x.
Supports the VM and web.

## Input

```dart
const parser = OpenApiParser();

final fromJson = parser.parse(SchemaSource.json(jsonText));
final fromYaml = parser.parse(SchemaSource.yaml(yamlText));
final detected = parser.parse(SchemaSource(text));

final fromBytes = parser.parse(
  SchemaSource.fromBytes(bytes, format: SchemaFormat.yaml, uri: sourceUri),
);
```

Supply document text. Set `uri` to its retrieval URI for diagnostics and
relative references.

`auto` tries JSON, then YAML. Use `SchemaFormat.json` for strict JSON syntax.
Supply UTF-8 bytes with or without a BOM. The decoder rejects malformed UTF-8.
YAML keys must be strings. Quote numeric response codes, such as `'200'`.
The parser rejects cyclic aliases and non-finite numbers.

## Swagger 2.0

```dart
final document = parser.parse(SchemaSource.yaml(text)) as SwaggerV2Document;
final operation = document.paths['/pets']?.get;
final json = document.toJson();
```

Models cover metadata, paths, operations, parameters, responses, headers,
schemas, and security. Body parameters and value parameters have separate
types. Inline parameters/responses and references use `SwaggerV2RefOr<T>`.

Schema models support `$ref`, `allOf`, type arrays, tuple items, and additional
properties. References remain links, including cycles and external URIs.

## OpenAPI 3.0

The parser uses the 3.0.4 specification for every numeric 3.0 patch.
Each 3.x parser preserves the declared patch in `version.value` and JSON output.

```dart
final document = parser.parse(SchemaSource.yaml(text)) as OpenApiV30Document;
final response = document.paths['/events']?.get?.responses['200'];
if (response case OpenApiV30Inline<OpenApiV30Response>(:final value)) {
  final media = value.content?['text/event-stream'];
}
```

Models cover servers, components, request bodies, media types, encoding,
callbacks, links, schema composition, and security schemes.
`OpenApiV30RefOr<T>` holds an inline object or a reference. Reference siblings
are preserved for export. Only `$ref` affects reference semantics. Path Items
can carry both `$ref` and operations.

## OpenAPI 3.1

The parser uses the 3.1.2 specification for each numeric 3.1 patch.
A document can describe paths, webhooks, or reusable components.

```dart
final document = parser.parse(SchemaSource.json(text)) as OpenApiV31Document;
final webhook = document.webhooks?['petEvent'];
final event = document.components?.schemas?['Event'];
if (event case OpenApiV31ObjectSchema(:final properties)) {
  final name = properties?['name'];
}
```

Schema values can be objects or booleans. The parser reads JSON Schema
2020-12 keywords, including type arrays, `$defs`, and `$dynamicRef`.
Schema `$ref` retains sibling keywords. OpenAPI Reference Objects have typed
`summary` and `description` fields.

`jsonSchemaDialect` sets the default dialect. A resource's `$schema` overrides
it. Arbitrary schema keywords survive strict mode. `OpenApiV31ForeignSchema`
preserves objects from other dialects as JSON. The parser never fetches schemas.

## OpenAPI 3.2

The parser uses the 3.2.1 specification for each numeric 3.2 patch.
`query` holds the QUERY operation. `additionalOperations` keeps the exact HTTP
method name. A `querystring` parameter describes the entire query with `content`.

```dart
final document = parser.parse(SchemaSource.yaml(text)) as OpenApiV32Document;
final media = document.components?.mediaTypes?['EventStream'];
if (media case OpenApiV32Inline<OpenApiV32MediaType>(:final value)) {
  final OpenApiV32Schema? event = value.itemSchema;
}
```

Media types can be inline or referenced through `$ref`. `itemSchema` describes
one stream item, including an SSE event. Nested encodings describe multipart
bodies. Other typed fields include `$self`, tag parents, XML node types,
example data and serialized text, and OAuth device authorization.

## JSON export

Collections are immutable. `toJson()` returns detached data and preserves
absent fields, empty collections, and explicit nulls. `JsonValue(null)` differs
from an absent `JsonValue?`. YAML comments, aliases, and formatting are not kept.

## Options and errors

`ParseConfig` passed to `parse()` or `resolve()` replaces the corresponding
constructor config for that call.
The default `unknownFields: UnknownFieldPolicy.preserve` keeps unknown keys
on fixed-field objects for JSON export. Use `UnknownFieldPolicy.reject` to
stop at the first unknown key. Extensions and dictionary entries follow
their own rules.

Errors include the source URI, JSON Pointer, and available coordinates.
`captureSourceLocations` defaults to `true`. Set it to `false` to skip the
coordinate index. Missing fields use the parent location.

`maxDepth` defaults to `128` per document. The root is at
depth 0. Each object field or array item adds one level. A value at the
limit is valid. A deeper value raises `SchemaParseException`.
Unsupported versions raise `UnsupportedOpenApiVersionException`.

## Validation and references

```dart
final document = const OpenApiParser().parse(source);
final report = const OpenApiValidator().validate(document);
if (!report.hasErrors) {
  final graph = await const OpenApiReferenceResolver().resolve(
    document, sourceUri: source.uri, loader: loader,
  );
  final operations = const ResolvedOperationValidator().validate(document, graph);
  for (final issue in operations.diagnostics) {
    print('${issue.sourceUri}#${issue.documentPath}: ${issue.message}');
  }
}
```

Local validation checks path templates, parameters, operation IDs, and tags.
After resolution, `ResolvedOperationValidator` follows Path Item and parameter
references. It checks each operation against the path where it is used.
Operation parameters can override inherited parameters with the same name and
location. Errors identify the physical file and JSON Pointer.

Operation IDs must be unique across paths, webhooks, and callbacks. Using one
named operation on two routes reports a duplicate. Unused component IDs stay
out of scope. If a Path Item and its reference both define a method or a
parameter list, the definition closest to the route takes precedence.

The graph indexes `$ref`, schema `$dynamicRef`, and link `operationRef`.
Each edge identifies the physical target document and pointer. Its value is
immutable JSON. Cycles remain edges. Supply schema resource URIs in
outermost-first order to `targetFor(dynamicScope: ...)` for dynamic selection.
`schemaResources` maps schema locations to canonical resource URIs.
`dynamicAnchors` indexes targets by resource URI and anchor name.

The resolver uses the retrieval URI, OpenAPI 3.2 `$self`, and schema `$id` to
establish base URIs. It supports JSON Pointers and schema anchors. Each call
caches its loaded documents. A relative external reference needs an absolute
base URI. Supply a `DocumentLoader` for external JSON or YAML.
`ReferenceResolutionException` identifies the referring field or conflicting
declaration. Example data, extensions, and foreign schema dialects stay opaque.

## Parameter normalization

`OpenApiNormalizer` returns a new immutable document of the same type and
patch version. The default `explicitParameterSerialization: false` preserves
the declared fields. Set it to `true` to write missing serialization settings.

```dart
const normalizer = OpenApiNormalizer(
  config: NormalizeConfig(explicitParameterSerialization: true),
);
final normalized = normalizer.normalize(document);
```

For a query parameter `ids = [1, 2]` with no declared serialization settings:

| Family | `false` | `true` | Effective query |
| --- | --- | --- | --- |
| Swagger 2.0 | Keep `collectionFormat` absent | Add `collectionFormat: csv` | `ids=1,2` |
| OpenAPI 3.x | Keep `style` and `explode` absent | Add `style: form` and `explode: true` | `ids=1&ids=2` |

Swagger 2.0 applies the rule to non-body array parameters. OpenAPI 3.x
applies it to schema-based parameters. The default style is `form` for query
and cookie parameters and `simple` for path and header parameters.
`form` and OpenAPI 3.2's explicit `cookie` style default to `explode: true`.
Other styles default to `false`, except `deepObject`, which keeps an omitted
`explode`. An explicit value always takes precedence.

The rule visits inline parameters and reusable definitions in the entry
document. It preserves references, content-based parameters, and multipart
encoding. To read effective settings directly from a parameter, use:

```dart
final settings = ParameterSerialization.effective(
  document.version.family,
  parameter.toJson(),
);
```

For a resolved external parameter, use the target document's family.

See [Swagger 2.0](https://spec.openapis.org/oas/v2.0.html),
[OpenAPI 3.0.4](https://spec.openapis.org/oas/v3.0.4.html),
[OpenAPI 3.1.2](https://spec.openapis.org/oas/v3.1.2.html), and
[OpenAPI 3.2.1](https://spec.openapis.org/oas/v3.2.1.html).
