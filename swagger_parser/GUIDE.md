# Generation guide

See [Configuration](CONFIGURATION.md) for option values and output comparisons.
See [README](README.md) for setup and commands.

- [Library API](#library)
- [HTTP clients](#generated-http-client)
- [DTOs and codecs](#generated-models)
- [Tuple arrays](#tuple-arrays)
- [Unions](#discriminated-unions)
- [API extraction](#api-extraction)
- [Background decoding](#background-response-decoding)

## Library

```dart
import 'package:swagger_parser/swagger_parser.dart';

const loader = FileSchemaSourceLoader();
final source = await loader.loadPath('stations.yaml');
final result = await const SwaggerParserRunner().generate(source, loader: loader);
for (final file in result.files) {
  // Write file.content at file.relativePath or add it to a ZIP.
}
```

The loader reads UTF-8. The extension selects JSON or YAML. Other extensions
use format detection. Pass the loader to resolve external file references.

On the web, use the same runner with `SchemaSource(text, uri: uri)` or
`SchemaSource.fromBytes(bytes, uri: uri)`. Supply a `DocumentLoader` for
references to other documents. Output stays in memory.

## Generated HTTP client

Save files under `lib/` using each file's relative path. Import `api.dart`
to access the facade, clients, status results, and DTOs. The facade exports
`exports.dart` and creates each client on first use. All clients share the
injected transport. Set `root_api_class_name: TransitApi` to generate
`TransitApi` in `transit_api.dart`.

Each tag group has a client directory with a `models/` subdirectory. The
first operation to use a model owns it, including nested references.
Other clients import the same Dart type. Unused named schemas go in
top-level `models/`. Sealed families share a Dart library. Untagged routes
use `default_client/`.
Choose the backend with `GenerationConfig.httpClient`. All three backends support both response modes.

Generated models, fields, and methods include source `summary` and `description`
as Dartdoc. HTTP parameters, request bodies, and form fields retain their
descriptions. Set `generate_docs: false` or `GenerationConfig(generateDocs: false)`
to omit source comments. Source text stays unchanged.

Deprecated schemas, properties, operations, and parameters receive `@Deprecated`.
These annotations remain when `generate_docs` is false. All four serializers and
all three HTTP clients use the same policy.

### Public API metadata

Select settings in [Configuration](CONFIGURATION.md#generationapi_metadata).

The facade always exposes `title`, `apiVersion`, and `specVersion`.
`apiVersion` comes from `info.version`. `specVersion` is the exact `swagger` or
`openapi` value. `api_metadata` selects operation metadata:

| Value | Operation constants and `Api.operations` | Request extras |
| --- | --- | --- |
| `none` (default) | Omitted | No automatic metadata |
| `generate` | Generated | No automatic metadata |
| `generate_and_attach` | Generated | Add `openapi.operation` |

The const operation list follows source order and contains only operations
emitted after filtering and unsupported-operation checks. Select `generate` or
`generate_and_attach` to use the following operation constants:

```dart
import 'api.dart';

print(Api.title);
print(Api.apiVersion);
print(Api.specVersion);

const operation = StationClientMetadata.lookupStation;
print(operation.method);
print(operation.path); // /stations/{id}
print(operation.operationId);
```

`api_metadata.dart` declares `OperationMetadata`. Each client has a companion
file, such as `station/station_client_metadata.dart`. Both are exported through
`api.dart`. Internal files use `file_suffix`. Names and paths receive numeric
suffixes when they conflict with schema types or the facade.

Each operation records `methodName`, `operationId`, `method`, `path`, `tags`,
`externalDocsUrl`, and `deprecated`. The Dart name follows replacement rules and
collision allocation. The source ID, tags, and mounted path stay unchanged.
An absent `operationId` stays null. A missing operation documentation URL stays
null; it does not inherit document or tag documentation. Schema descriptions
remain in Dartdoc and use the independent `generate_docs` option.

Set `api_metadata: generate_and_attach` to add each operation constant under
`extra['openapi.operation']` in Retrofit, Dio, and package:http clients:

Calls keep the same signature:

```dart
await api.station.lookupStation(
  id: '42',
  extra: {'traceId': 'request-123'},
);
```

Read the object from `RequestOptions.extra` in a Dio interceptor:

```dart
final operation =
    options.extra['openapi.operation'] as OperationMetadata?;
print(operation?.path);
print(options.extra['traceId']);
```

For package:http, read the same key from the map passed to `prepareRequest`.
The generator retains other caller entries and does not mutate the caller map.
In `generate_and_attach`, the generated operation takes priority over the same key in
`extra` or Dio `options.extra`. Metadata is not sent as headers or body data.

The Dart API uses `GenerationConfig(apiMetadata: ApiMetadataMode.generate)`.
This enum replaces the earlier `generate_api_metadata` boolean. Switching to
`none` removes generated metadata files from CLI output. Application files remain
unchanged. Facade client accessor names stay stable across metadata modes.

### package:http

Select `HttpClientBackend.http` and add `http: ^1.6.0` to the application.
Pass an HTTP client and an absolute base URL. A base path applies to all routes.

```dart
import 'package:http/http.dart' as http;
import 'api.dart';

final transport = http.Client();
try {
  final client = Api(transport, baseUrl: Uri.parse('https://stations.example/v1')).api;
  final station = await client.getStationsById(id: 'north/west');
  print(station.id);
} finally {
  transport.close();
}
```

Use `prepareRequest` to apply credentials from the operation metadata before
sending a request. For multipart uploads, pass an `http.MultipartFile`.
This backend reports a diagnostic for operations that declare custom part headers.

### Standalone Dio

Add `dio` to the consuming application. Generate the implementation directly:

```dart
final result = await const SwaggerParserRunner().generate(
  source,
  loader: loader,
  config: const GenerationConfig(httpClient: HttpClientBackend.dio),
);
```

Import the generated client and pass raw path values. The client encodes them:

```dart
final client = ApiClient(Dio(BaseOptions(baseUrl: 'https://stations.example/v1')));
final station = await client.getStationsById(id: 'north/west');
```

The output is ready to compile. When switching an existing output directory
from Retrofit, remove its old generated Retrofit parts.

### Retrofit (default)

Install the client dependencies and build the Retrofit part in the application.

```sh
dart pub add dio retrofit
dart pub add dev:build_runner dev:retrofit_generator
dart run build_runner build
```

```dart
import 'package:dio/dio.dart';
import 'api.dart';

final dio = Dio(BaseOptions(baseUrl: 'https://stations.example/v1'));
final client = Api(dio).api;
final id = Uri.encodeComponent('north/west');
final station = await client.getStationsById(id: id, tag: ['rail', 'bus']);
print(station.id);
final created = await client.postStations(body: const Station(id: 'central'));
print(created.id);
```

Untagged operations share `ApiClient` across all paths. Set
`generation.fallback_client_name` to change its full class name, such as
`CommonClient`. The folder remains `default_client/`. For tagged operations,
the first tag names the client. For example, `Station` gives `StationClient`.
Tags that produce the same Dart client name share one client. Apply client
replacement rules before grouping. For example, `Station` and `station` merge;
`station-info` and `station_info` also merge. No config flag is required.
Operations keep their source order, routes, parameters, and responses. Method
name collisions use numeric suffixes: `getStation`, `getStation2`. Result classes
follow those names. Duplicate source operation IDs remain validation errors.
Filters use the original tags. Shared models belong to the first selected
operation that uses them. Empty replacement names retain separate source groups.
Collisions with model or reserved names add suffixes without merging groups.
If a tag also maps to `ApiClient`, the untagged group keeps that name and
the tagged group gets a numeric suffix.

### Custom types

Select settings in [Configuration](CONFIGURATION.md#custom-types).

Use `generation.type_mappings` to replace scalar or object schemas with imported Dart types.
The default is an empty list. All four serializers use the same codec functions.

For Swagger 2.0, use `#/definitions/StationId`. A schema selector is a URI with a
JSON Pointer. External selectors, such as `types.yaml#/components/schemas/Id`,
resolve against the entry document. Selection uses source identity, not Dart names.
An exact schema rule takes precedence over a `type`/`format` rule. Duplicate or
ambiguous selectors stop generation. A schema selector must resolve to a loaded
schema. A format rule can remain unused.

Supply public type and function identifiers. Use `package:` or `dart:` imports.
Codecs are synchronous top-level functions for non-null JSON scalars:

```dart
StationId stationIdFromJson(String value) => StationId(value);
String stationIdToJson(StationId value) => value.value;
```

Scalar codecs use `String`, `int`, `num`, or `bool`. Object codecs use
`Map<String, Object?>` for both the argument and return type.
Generated adapters check the schema before decoding and after encoding.
Missing fields, nullable values, and PATCH presence records stay outside the codec.
Union predicates inspect raw JSON before a codec runs. Explicit mappings use their
schema constraints; unknown-value policies apply to generated enums and unions.

Mappings apply to DTO fields, lists, maps, HTTP parameters, forms, and payloads.
Text payloads require a non-null string mapping. Parameters are encoded before URL
or header serialization. Retrofit uses the direct Dio path for directly mapped
arguments and responses. An ordinary DTO can still use Retrofit annotations.

Imports get aliases. `exports.dart` exports used custom types with `show`, but
does not export codec functions. No wrapper is generated for
a replaced schema. Naming rules do not rename external types. Conflicting public
names from different imports stop generation. Consumer analysis checks imports
and codec signatures; the generator does not load or execute custom Dart code.

Union replacements are not supported. Imported object variants use local wrappers
when a generated union needs them. No automatic `int64` conversion is added.

In Dart, use `GenerationConfig(typeMappings: [...])`, `TypeMapping`, and
`TypeMappingCodec`. The API uses `dartType`, `importUrl`, `fromJson`, and `toJson`.

### Object mappings and const defaults

Select settings in [Configuration](CONFIGURATION.md#type_mappingsdefaults).

Object mappings require an exact `schema` selector. The codec owns the complete
JSON object, including nested fields. Other mappings do not run inside that codec.
AllOf objects are supported. Mapping a base object does not replace its extended
allOf descendants. Map each complete object schema explicitly.

Use direction-specific rules for objects with different request and response
shapes. This includes nested readOnly/writeOnly differences. A mapped union
variant cannot add common object fields beyond the mapped schema.

The application provides the codec and constant:

```dart
GeoPoint geoPointFromJson(Map<String, Object?> json) => GeoPoint(
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
);

Map<String, Object?> geoPointToJson(GeoPoint value) => {
  'latitude': value.latitude,
  'longitude': value.longitude,
};

const origin = GeoPoint(latitude: 0, longitude: 0);
```

`defaults` is empty by default. It also works for scalar mappings. Each entry
matches a schema default by JSON structure. Object key order has no effect;
array order matters. A missing key differs from a key with null. Duplicate
entries are rejected. Use a public top-level const identifier, not Dart code.

The generator applies a matching constant only when an optional field has a
schema default. Missing JSON keys and omitted constructor arguments use that
constant. Explicit nullable null stays null. Required fields stay required.
A configured constant does not add a default to a schema. JSON null needs no
constant mapping. An applied non-null default without a matching entry fails.
Defaults can also appear inside generated object, list, and map constants.

For an optional nullable location with a matching schema default, the constructor
uses `this.location = defaults.origin`. The decoder checks `containsKey` before
choosing the constant or calling the codec. All four serializers keep this rule.

Consumer analysis checks the imported symbol's type and constness. Test that the
constant encodes to its configured JSON value. The generator does not execute
application code. Constants are imported where needed and are not re-exported.
In Dart, configure entries with `TypeMappingDefault(value: ..., importUrl: ...,
constant: ...)`.

### Directional type mappings

Select settings in [Configuration](CONFIGURATION.md#type_mappingsdirection).

Each mapping accepts `direction: both`, `request`, or `response`. The default is
`both`. It supports scalars and exact object selectors. A `both` object rule
requires identical request and response shapes.

Request bodies and parameters use `CreateStation`. Response payloads use
`Station`. Both codec functions remain required for each rule. For example:

```dart
Future<Station> createStation({required CreateStation body});
```

Select the source schema URI. Do not append `$Request` or `$Response` to it.
Imported class names stay unchanged. The public entry point exports both types.
Map only one direction to keep a generated DTO for the other direction.

Selection first filters rules by direction. An exact schema selector takes
priority over type/format. For the same selector, a direction-specific rule
wins over `both`. Duplicate rules for the same selector and direction fail.
Rule order does not set priority. Two rules can use the same Dart type with
different codecs.

Explicit directional rules preserve direction through references, containers,
compositions, and recursive models. Containing DTOs get `$Request` and
`$Response` variants, including when their JSON shapes are equal. Request
predicates omit readOnly fields. Response predicates omit writeOnly fields.
Swagger 2.0 supports readOnly; it does not define writeOnly.
The object codec owns field conversion. Excluded fields are ignored by schema
predicates; predicates do not remove fields from the codec input or output.

Each rule has its own `defaults`. A request constant must have the request type;
a response constant must have the response type. Match the declared JSON default
without rewriting it. Missing keys, explicit nullable null, and required fields
keep the rules above. All four serializers use the selected direction and codec.

In Dart, set `TypeMapping.direction` to `TypeMappingDirection.request`,
`TypeMappingDirection.response`, or `TypeMappingDirection.both`.

### Retrofit generation

For annotated Retrofit clients, `build_runner` writes the implementation beside the declaration.
See [ApiClient](https://github.com/Carapacik/swagger_parser/blob/main/swagger_parser_tests/example/stations/default_client/api_client.dart)
and [its implementation](https://github.com/Carapacik/swagger_parser/blob/main/swagger_parser_tests/example/stations/default_client/api_client.g.dart).

Retrofit substitutes `@Path` values as supplied. Encode reserved characters in
a path argument before the call. Set the base URL, authentication, query list
format, and accepted statuses on Dio. Retrofit calls the DTO's `fromJson`.
Direct Dio methods, such as a tuple response, take raw path arguments,
encode them, and check the declared success status.

Swagger 2.0 supports GET, HEAD, POST, PUT, PATCH, DELETE, and OPTIONS.
OpenAPI 3.0 and 3.1 also support TRACE. OpenAPI 3.2 adds QUERY and
`additionalOperations`. Custom methods keep their spelling and case.
A `query:` operation in 3.2 can generate this Retrofit declaration:

```dart
@QUERY('/search')
@Headers({'Content-Type': 'application/json'})
Future<Search> search({@Body() required Search body});
```

A required JSON object uses `@Body()`. Optional bodies and other JSON
shapes use Dio directly. Omit an optional body to send no payload. If the
schema also permits null, pass `sendNullBody: true` to send JSON `null`.

Explicitly nullable query schemas skip the operation with a source diagnostic.
Optional non-null query schemas generate optional arguments; null omits the
parameter. No config changes this rule.

### Per-call settings

Each method accepts optional cancellation, `extra`, and `options` arguments.
No generation flag is required. Existing calls remain valid.

Retrofit and Dio use Dio types:

```dart
final cancelToken = CancelToken();
final pending = api.stations.getStation(
  id: '42',
  cancelToken: cancelToken,
  extra: {'screen': 'details'},
  options: Options(
    receiveTimeout: const Duration(seconds: 15),
    headers: {'X-Request-ID': 'request-42'},
  ),
);

cancelToken.cancel('Screen closed');
try {
  await pending;
} on DioException catch (error) {
  if (!CancelToken.isCancel(error)) rethrow;
}
```

Retrofit uses `@CancelRequest()` and `@Extras()`. Calls without `options`
use the built Retrofit implementation. Calls with `options` use a private Dio
fallback. This avoids dropped cancellation and timeout settings in
retrofit_generator 10.3.3's `@DioOptions` path. The fallback retains Retrofit's
path substitution, query list format, and status policy.

`package:http` uses an abort signal and a generated settings class:

```dart
final abort = Completer<void>();
final pending = api.stations.getStation(
  id: '42',
  abortTrigger: abort.future,
  extra: {'screen': 'details'},
  options: const HttpRequestOptions(
    headers: {'X-Request-ID': 'request-42'},
    followRedirects: false,
    maxRedirects: 2,
  ),
);

abort.complete();
try {
  await pending;
} on http.RequestAbortedException {
  // The caller cancelled the request.
}
```

Import `dart:async` for `Completer` and `package:http/http.dart` as `http`.
`HttpRequestOptions` is exported by the generated public API. Null redirect
settings keep transport defaults. Cancellation and redirect support depend on
the injected client and platform. An abort signal must complete without an error.

- Omitted `extra` keeps the generated server and security metadata. An explicit
  map replaces it. Pass `{}` to clear it. Metadata stays local unless an
  interceptor or `prepareRequest` sends it.
- Dio merges base metadata, `Options.extra`, then the method's `extra`.
  Caller maps and `Options` are not modified.
- Per-call headers override base headers. Schema headers take priority.
  The http `prepareRequest` hook runs after request settings are applied.
- The schema controls the method, body encoding, and response decoding.
  `all_statuses` also retains its declared status policy.
- Cancelling a call does not close the shared transport. Cancel a stream
  subscription to stop that stream. This does not cancel the caller's token.

### Bodies and streams

- URL-encoded and multipart forms expose named fields. Swagger `formData`
  and OpenAPI request body properties keep their wire names. Retrofit emits
  `@FormUrlEncoded()` with `@Field` or `@MultiPart()` with `@Part` for compatible
  required bodies. Delimited fields and fixed file content types use Dio directly.
- In a Dio client, pass a Dio `MultipartFile` for a file or a part with custom headers.
  Use `MultipartFile.fromBytes(bytes, filename: 'photo.png', headers: ...)`.
  The client applies the declared part content type. For a free-form multipart
  body or positional encodings, supply a `FormData` body.
- Multipart null values omit parts, including `required T?` arguments. Null
  list items are omitted. Empty files remain parts with zero bytes. An explicit
  JSON part content type sends null as JSON `null`, including null list items.
  Requiredness controls the argument; nullability controls its accepted values.
- Send and receive bytes as `List<int>` by default. Set
  `streamBinaryResponses: true` to receive `Stream<List<int>>`. In
  `allStatuses`, the matching variant holds the stream. Text responses use UTF-8.
  Byte streams preserve raw data, including non-UTF8 bytes. An empty binary
  body yields no bytes. Cancel the subscription to stop reading.
  The standard Dio web adapter buffers XHR responses before exposing the stream.
  This also applies to Retrofit with Dio. It does not provide incremental web
  downloads. VM transports and package:http's browser client can deliver chunks
  while downloading.
  For each status, generation selects the first JSON representation, including
  `+json`. Without JSON, it uses the first declared representation. For example,
  a 200 with PDF and JSON uses the JSON return type and decoder.
- JSON Lines (`application/jsonl` or `application/x-ndjson`) returns one value
  per line. OpenAPI 3.2 `itemSchema` determines the Dart type. A malformed
  line emits a stream error. Empty input emits no records.
- An SSE success response returns `Stream<T>`. In all-status mode the
  corresponding variant holds the stream. OpenAPI 3.2 `itemSchema` describes
  each parsed event. A string item exposes its data. Without an item schema
  or array item type, each event is a map. Cancel the subscription to stop
  reading and cancel the request.

On VM, all three backends can deliver data as it arrives. In Chrome,
`package:http` supports incremental reads. Dio's default web adapter buffers
the response before exposing its stream. This also applies to Retrofit + Dio.

### Servers and credentials

Set `Dio.options.baseUrl` to select a server. Add credentials through a Dio
interceptor. When the schema specifies servers or security, the method
supplies the effective settings in `RequestOptions.extra`:

| Key | Value |
| --- | --- |
| `openapi.servers` | Available server URLs and declared variables |
| `openapi.security` | Alternative requirements and scopes for the operation |
| `openapi.securitySchemes` | Definitions for schemes used by the operation |

An interceptor can select a server, expand its variables, and apply credentials.
An operation with `security: []` permits an anonymous request. Pass `extra`
to override the generated metadata for one call.

### Response mode

Set the response mode when you generate the client:

```dart
final result = await const SwaggerParserRunner().generate(
  source,
  loader: loader,
  config: const GenerationConfig(responseMode: ResponseMode.allStatuses),
);
```

- `ResponseMode.firstSuccess` (default) returns the DTO of the lowest exact
  2xx status. For `500, 202, 200`, the return type comes from `200`.
  An empty selected response or a contract without an exact 2xx returns
  `Future<void>`. A selected list response does not turn a later empty 204
  into an empty list; use `allStatuses` for both shapes. Retrofit uses the caller's Dio status policy.
- `ResponseMode.allStatuses` uses the selected transport directly. Each operation returns a
  sealed result, even for a single status. Declared HTTP errors return
  variants. Exact codes take precedence over ranges, then `default`.
  Range and default variants include the actual `statusCode`. An unmatched
  status raises `DioException` or `http.ClientException` in the selected backend.

A declared JSON media type without `schema`, or with `schema: {}`, returns
`Object?`. Text returns `String`. Binary content returns `List<int>` or the
configured byte stream. Missing `content` remains bodyless. JSON `null` and an empty JSON string remain
distinct values.

Set `original_http_response: true` to include transport metadata in
`first_success`. The default is `false`. In Dart, use
`GenerationConfig(originalHttpResponse: true)`.

| Backend | Return type | Payload | Metadata |
| --- | --- | --- | --- |
| Retrofit | `Future<HttpResponse<T>>` | `result.data` | `result.response` |
| Dio | `Future<Response<T>>` | `result.data` (`T?`) | `result` |
| package:http | `Future<HttpResponse<T>>` | `result.data` | `result.response` |

The public entry point exports the response type. The package:http wrapper is
in `http_response.dart`. Its `response` field is `http.BaseResponse`: ordinary
payloads use `http.Response`; streaming payloads use `http.StreamedResponse`.
Cast a buffered response to `http.Response` to read `body` or `bodyBytes`.
Read streaming content through `data`; the source stream has one listener.

Streaming methods return `Future<HttpResponse<Stream<T>>>`, or
`Future<Response<Stream<T>>>` for Dio. The future completes after headers arrive.
The payload stays streamed. Cancellation and per-call options remain available.

Bodyless methods retain `void` inside the wrapper. Retrofit exposes the payload
through `result.response.data`. With package:http, read the buffered response.
For Dio, assign `Response<void>` to `Response<dynamic>` to inspect its raw data.
Typed Dio responses contain the decoded DTO in `data`.

This option has no effect in `all_statuses`. It does not change accepted statuses
or add typed exceptions, header DTOs, or separate `WithHeaders` methods.

The all-status client exports a sibling file such as `api_client_results.dart`.
It contains the result types and variants. The public entry point also exports the result library.
The operation ID or method and path give the method name. Each variant adds
its response code to that name.

```dart
final message = switch (await client.lookupStation(xRequestId: 'trace-42')) {
  LookupStation200(:final value) => value.name,
  LookupStation201(:final value) => value.id,
  LookupStation202(:final value) => value.token,
  LookupStation204() => 'No station',
  LookupStation400(:final value) => value.field,
  LookupStation404(:final value) => value.detail,
  LookupStation500(:final value) => value.requestId,
};
```

Both modes support JSON scalars, lists, maps, DTOs, text, bytes, SSE, and empty
responses. A selected unsupported response produces a generation diagnostic.

Scalar header parameters use the declared wire name. Retrofit emits
`@Header`. Direct Dio methods add the value to `Options.headers`. Omit an
optional argument to keep the Dio default for that header.

Path, header, and query arrays accept string, number, integer, or boolean items.
Pass raw items to a path array. The client encodes each item before it joins
them. In OpenAPI 3.x, `simple` joins path and header items with a comma.
Swagger 2.0 supports `csv` (default), `ssv`, `tsv`, and `pipes`.
OpenAPI 3.x also supports `label` and `matrix` path scalars and arrays.
For `ids = [12, 34]`, `label` expands to `.12,34` and `matrix` to
`;ids=12,34`. With `explode: true`, they expand to `.12.34` and
`;ids=12;ids=34`. An empty array contributes no text. Direct Dio rejects a
complete path segment that expands to an empty string, `.`, or `..`.

OpenAPI 3.x paths and headers also accept flat objects. Pass a DTO or a typed
map. For a parameter named `filter` with `id: 12` and `active: false`:

| Location and style | `explode: false` | `explode: true` |
| --- | --- | --- |
| Path or header, `simple` | `id,12,active,false` | `id=12,active=false` |
| Path, `label` | `.id,12,active,false` | `.id=12.active=false` |
| Path, `matrix` | `;filter=id,12,active,false` | `;id=12;active=false` |

The client encodes path keys and values separately. Header text stays raw.
These styles omit null properties. A nested property schema produces a
diagnostic. A nested extra value in an open object raises `ArgumentError`
before the request.

Header arrays produce one header value. For example, `[12, 34]` sends
`X-Station-Ids: 12,34`. An empty list sends an empty header value.

| Query array | Swagger 2.0 | OpenAPI 3.x |
| --- | --- | --- |
| Repeated key | `multi` | `form` with `explode: true` (default) |
| Comma | `csv` (default) | `form` with `explode: false` |
| Space | `ssv` | `spaceDelimited` with `explode: false` |
| Pipe | `pipes` | `pipeDelimited` with `explode: false` |
| Tab | `tsv` | — |

A delimited array uses direct Dio for the operation. Each query parameter
keeps its own format. For a Retrofit method with repeated keys, keep the
default Dio list format (`ListFormat.multi`).

Flat query objects also support `spaceDelimited` and `pipeDelimited` with
`explode: false`. Cookie parameters use the `Cookie` header. OpenAPI 3.2
`style: cookie` takes cookie-safe values. For `in: querystring`, pass encoded
query text for `text/plain` or a typed value for JSON or URL-encoded content.

OpenAPI 3.x query objects use `form` by default. For a flat DTO or map
named `filter` with `id: 12` and `active: false`:

| Form setting | Query |
| --- | --- |
| `explode: true` (default) | `?id=12&active=false` |
| `explode: false` | `?filter=id,12,active,false` |

Commas inside keys and values encode as `%2C`. Null properties and empty
objects add no keys. An empty string sends an empty value. If two supplied
operation parameters produce the same key, the client throws `ArgumentError`
before sending. Dio still applies its default query parameters.

OpenAPI 3.x query parameters also support flat `deepObject` filters. Use
`explode: true` in 3.0 and 3.1. In 3.2, any `explode` setting works.

```dart
await client.listStations(
  filter: const StationFilter(name: 'Central', active: true),
  scores: {'rail': 2},
);
```

The request contains `filter[name]=Central`, `filter[active]=true`, and
`scores[rail]=2`. Dio encodes the brackets and the values. An omitted or
empty filter adds no keys. A present null property sends a key without a
value. A nested property schema produces a diagnostic. For open filters,
the client checks extra values before it sends the request.

For other routes, inspect `GenerationResult.diagnostics` for
`unsupportedClientOperation` and the source pointer. Component-only documents
expose all named DTOs through the public entry point.

The build runs in the consuming project. See the [Retrofit setup](https://pub.dev/packages/retrofit).

## Generated models

One run collects named entry schemas and models used by operations. A document
with only reusable schemas also works. Import `api.dart` to access its models.

```dart
final station = Station.fromJson({'id': 'north'});
final parent = Station(id: 'hub', parent: station);
final json = parent.toJson();
```

Select the serializer in the CLI config or pass
`GenerationConfig(serializer: DtoSerializer.freezed)` to the runner.

```yaml
swagger_parser:
  generation:
    serializer: freezed
```

### Serializer dependencies

Add the matching sections to the `pubspec.yaml` of the consuming package.
These constraints set the minimum supported package versions.
These examples use Retrofit + Dio. Set `generation.serializer` to the value
shown for each example. Plain DTOs need no serializer dependency.

#### Plain

`serializer: plain`.

```yaml
dependencies:
  dio: ^5.11.1
  retrofit: ^4.10.0

dev_dependencies:
  build_runner: ^2.16.2
  retrofit_generator: ^10.3.3
  swagger_parser: ^2.0.0
```

#### json_serializable

`serializer: json_serializable`.

```yaml
dependencies:
  dio: ^5.11.1
  json_annotation: ^4.12.0
  retrofit: ^4.10.0

dev_dependencies:
  build_runner: ^2.16.2
  json_serializable: ^6.15.2
  retrofit_generator: ^10.3.3
  swagger_parser: ^2.0.0
```

#### Freezed

`serializer: freezed`.

```yaml
dependencies:
  dio: ^5.11.1
  freezed_annotation: ^3.1.0
  json_annotation: ^4.12.0
  retrofit: ^4.10.0

dev_dependencies:
  build_runner: ^2.16.2
  freezed: ^4.0.3
  json_serializable: ^6.15.2
  retrofit_generator: ^10.3.3
  swagger_parser: ^2.0.0
```

#### dart_mappable

`serializer: dart_mappable`.

```yaml
dependencies:
  dart_mappable: ^4.10.0
  dio: ^5.11.1
  retrofit: ^4.10.0

dev_dependencies:
  build_runner: ^2.16.2
  dart_mappable_builder: ^4.10.0
  retrofit_generator: ^10.3.3
  swagger_parser: ^2.0.0
```

For standalone Dio, remove `retrofit` and `retrofit_generator`.
For `package:http`, also replace `dio` with `http: ^1.6.0`.
With plain DTOs and either standalone client, remove `build_runner` too.
Keep it for the three package serializers.

Run `dart pub get`, then `dart run swagger_parser`.
Run `dart run build_runner build` when using Retrofit or a package serializer.

### Field presence

All four serializers use `T?` for optional nullable properties without defaults.
With `use_presence_records: false` (default), null fields are omitted:

```dart
StationPatch().toJson();                    // {}
StationPatch(name: null).toJson();          // {}
StationPatch(name: 'North').toJson();        // {"name": "North"}
```

Set `generation.use_presence_records: true` to distinguish an absent key from
explicit JSON null. This also applies to PATCH bodies:

```dart
StationPatch().toJson();                      // {}
StationPatch(name: (value: null)).toJson();   // {"name": null}
StationPatch(name: (value: 'North')).toJson(); // {"name": "North"}
```

The Dart API uses `GenerationConfig(usePresenceRecords: true)`. Required nullable
fields stay `required T?`. Nullable fields with defaults keep their default and
explicit-null behavior. This option does not change raw request bodies or items
inside lists and maps.

For dart_mappable object DTOs, `toJson()` and `toMap()` return maps.
Use `jsonEncode(dto)` for JSON text. Freezed DTOs use native Dart 3.13 primary
constructors and final fields. Supplied lists and maps retain their mutability.
Untagged unions use the same schema checks with each serializer.

- Objects have final fields, a const constructor, `fromJson`, and `toJson`.
  Plain DTOs require only Dart.
- Required strings use Dart casts. A missing or invalid required string
  raises a type error with plain codecs. Optional nullable properties use the selected nullable API.
- Wire keys and scalar enum values survive Dart name conversion. Open objects
  retain extra keys in `additionalProperties`. A schema for extra values sets
  the map value type. For example, a reference to `Platform` yields
  `Map<String, Platform>`. Declared wire keys take precedence on encode,
  even when an optional field is omitted. Closed objects reject extra keys.
- Lists, maps, inline objects, recursive references, and compatible object
  `allOf` branches use typed Dart values. Named scalars, containers, and
  reference aliases use a class with a `value` field.
- Unsupported shapes raise `GenerationException` with the source URI and JSON Pointer.
  JSON codecs enforce the mapped shape. They do not validate every schema constraint.

### DTO validation

Set `generation.generate_validators: true` to generate explicit validators.
The default is false. The Dart API uses `GenerationConfig(generateValidators: true)`.
Each input can override this option.

```dart
import 'generated/api.dart';

final errors = station.validate();
for (final error in errors) {
  print('${error.path}: ${error.keyword}: ${error.message}');
}
```

All four serializers use this API. `validate()` returns an immutable
`List<DtoValidationError>`. An empty list means valid. Each error contains:

- `path`: a JSON Pointer, such as `/stations/0/name`. An empty path means the root.
- `keyword`: the failed constraint, such as `minLength` or `minimum`.
- `message`: a short explanation without the input value.

Extensions stay with their model libraries. `dto_validation_error.dart` contains
only the shared error type. Both are exported through `exports.dart` and the
public API file. File suffixes apply. Generated names avoid schema name conflicts.
A model field named `validate` gets a safe Dart name; its JSON key stays unchanged.

Checks include types, required keys, scalar enum and const values, numeric bounds,
`multipleOf`, Unicode string lengths, patterns, collection bounds, structural
`uniqueItems`, nested values, additional properties, and composition. OpenAPI
3.1/3.2 also support tuple items and `contains` counts. Union selection and
validators use the same constraint rules. If no union branch matches, errors
include the union failure and branch details. Duplicate errors are removed.

Validation uses effective required keys after `infer_missing_required`.
Each extension checks its declared model schema. Validation checks the current
`toJson()` result. It does not run automatically in
constructors, codecs, or HTTP clients. Encoding failures propagate. Omitted input
keys and discarded values cannot be recovered; ordinary nullable fields still
merge absent and explicit null. Presence records retain that distinction.
Unknown enum values preserved by codecs can still fail schema validation.

This is not a complete JSON Schema validator. Unsupported assertion keywords
fail generation with their source location when validators are enabled.
Annotations such as `format`, `contentEncoding`, and `contentMediaType` do not add
validation checks. The core document validator remains separate.

### Swagger nullable fields

Swagger 2.0 schemas support `x-nullable` without a config option. `true` allows
null; `false` excludes null. Required properties stay required. Optional nullable
properties without defaults use `T?`, or records when `use_presence_records` is enabled.

An `x-nullable` sibling of `$ref` applies to that use only. It does not change the
referenced schema. Array and item nullability are separate. Enum and `allOf`
constraints still apply. Non-boolean values cause a generation error.
OpenAPI 3.x ignores this extension and uses its version-defined nullable rules.

### Schema defaults

Optional DTO properties with a schema `default` use that value in the constructor
and when a JSON key is absent. Explicit null stays null for nullable properties.
Non-nullable properties reject explicit JSON null. Required properties stay
required, even when their schema has a default.

```dart
class const Example({
  final int limit = 20,
  final String? name = 'North',
});
```

This constructor has an `int limit` and a nullable `String? name`:

```dart
Example().name;             // 'North'
Example(name: null).name;   // null
Example(name: 'South').name; // 'South'
```

A defaulted nullable field uses `T?`. Its value is always written, including null.
Optional nullable fields without defaults follow `use_presence_records`.
Defaults are materialized in JSON output, including PATCH bodies. Optional HTTP
parameters omit defaults unless `apply_parameter_defaults` is enabled.

Defaults support constants for scalars, enums, lists, maps, reference wrappers,
and object DTOs. Collection defaults are constant, as required by Dart parameter
defaults. Invalid types, constructor cycles, or values that cannot be represented
as constants stop generation. Runtime values such as parsed DateTime objects,
tuple defaults, and union defaults are not supported. Union variant fields can
have defaults. All four serializers keep the same missing/null behavior.

### Request and response models

The generator splits a schema when its request and response shapes differ.
Swagger 2.0 uses `readOnly`. OpenAPI 3.x uses `readOnly` and `writeOnly`.
This is a generator policy; the parsed schema and its references stay unchanged.

- Requests omit read-only properties. Responses omit write-only properties.
- Each direction has its own required fields. An excluded field is not required.
- Nested objects, references, arrays, maps, tuples, and compositions keep the direction.
- Unchanged schemas keep one type. Changed schemas use `$Request` and `$Response`.
- Decoders drop excluded keys. Encoders cannot restore them through `additionalProperties`.
- A property with both annotations stops generation.

For `Station` with read-only `id` and write-only `access_code`, the client uses:

```dart
Future<Station$Response> saveStation({required Station$Request body});

final station = await api.stations.saveStation(
  body: Station$Request(name: 'North', accessCode: 'secret'),
);
print(station.id);
```

Files use `station_request.dart` and `station_response.dart`. An existing schema
named `StationRequest` remains a separate type. Name collisions get numeric
suffixes; `$ref` still targets the original schema. Replacement rules run on the
base name before the `$Request` or `$Response` suffix is added.

PATCH fields use the selected nullable API in all four serializers. Tagged
unions use the schema dispatch table when their names contain `$`. This avoids
unescaped identifiers in package-generated diagnostic strings. If a direction
excludes the discriminator, union matching uses the remaining schema constraints.
Ambiguous `oneOf` input is rejected.

### JSON formats

| Schema | Dart type | JSON output |
| --- | --- | --- |
| `string`, `format: date` | `String` | Calendar date, such as `2024-02-29` |
| `string`, `format: date-time` | `DateTime` | ISO 8601 in UTC, with Dart microsecond precision |
| `string`, `format: byte` or `contentEncoding: base64` | `String` | Original Base64 text |

For example, `2024-03-01T00:30:45+02:00` becomes `2024-02-29T22:30:45.000Z`.
Supply an offset or `Z` for a timestamp. Inline URI and form parameters accept
wire strings. Raw binary HTTP responses use `List<int>`. Enable
`streamBinaryResponses` for `Stream<List<int>>`.

All four serializers reject unknown enum values by default. Use
`unknown_enum_values: preserve` to retain unknown scalars and their JSON types.

### Enum member names

Enum codecs preserve JSON scalar types. OpenAPI 3.1/3.2 enum type lists can mix
strings, numbers, booleans, and null. String `"null"` remains distinct from null.
Conflicting enum values and declared types produce a source diagnostic.
Form-urlencoded and multipart fields use scalar wire values. Explicit JSON
part encoding retains JSON quotes for strings.

The generator selects names in this order: `x-enumNames`, `x-enum-varnames`,
then each enum value. It uses the first present extension as a complete list.
Lower-priority extensions are ignored.

```yaml
Status:
  type: integer
  enum:
    - 0
    - 1
  x-enumNames:
    - Pending
    - Active
```

This schema generates `Status.pending` for `0` and `Status.active` for `1`.
The rule applies to all four specification families and serializers.
Swagger 2.0 query and form parameters retain these extensions during extraction.

The selected extension must contain one non-empty string per enum value.
Whitespace-only names, non-string entries, and count mismatches stop generation.
Diagnostics include the source URI and JSON Pointer. A malformed selected
extension does not fall back to another source.

Names pass through `enum_values` replacement rules, camelCase conversion,
reserved-name protection, and collision handling. For example, `default` becomes
`default2`. JSON values and their types stay unchanged. A null enum value keeps
its position in the name list but does not create a Dart enum member.

### Boolean enums

An enum with both `true` and `false` uses the same Dart representation as a
boolean schema. Order does not matter. A null entry also requires schema
nullability. Inline fields use `bool` or `bool?`. Named schemas keep value
wrappers with `value: bool` or `value: bool?`.

```yaml
type: object
properties:
  enabled:
    type: boolean
    enum:
      - true
      - false
```

The `enabled` field uses `bool?` because it is optional and has no default.
Required fields use `bool`. Defaults and explicit null keep their existing rules.
The rule also applies to array items, map values, and inline HTTP parameters.
No config is required. `unknown_enum_values` does not change boolean fields.

Single-value enums and `const` keep their constrained types. `oneOf` and `anyOf`
remain unions with the same branch checks. Mixed scalar enums remain enums.
Explicit `x-enumNames` or `x-enum-varnames` retain named enum cases and strict
name validation. The rule does not simplify schemas with `allOf`.

### Unknown values

The two policies are independent. Both default to `reject`.

```yaml
generation:
  unknown_enum_values: preserve
  unknown_discriminator_values: preserve
```

With `unknown_enum_values: reject`, `Status` is an enum. With `preserve`,
`Status` is sealed. Known values use `StatusKnown` and the `StatusValue` enum.
Unknown values use `StatusUnknown`. Method return types remain `Status`.

```dart
final Status status = await api.api.getStatus();
final message = switch (status) {
  StatusKnown(:final value) => value.name,
  StatusUnknown(:final rawValue) => 'Unknown: $rawValue',
};
final paused = Status.fromJson('paused');
assert(paused is StatusUnknown);
assert(paused.toJson() == 'paused');
assert(Status.active.toJson() == 'active');
```

Unknown values must match the schema's scalar type. Integer enums do not accept
strings or fractional values. Numeric values must be finite. Property nullability
is separate. Defaults and known enum wire values keep their existing behavior.
Helper names get numeric suffixes on a collision.

With `unknown_discriminator_values: preserve`, an unknown string tag selects
`StopUnknown`. Its `rawJson` contains an immutable snapshot of the full object.
`toJson()` returns a detached mutable copy. Missing, null, and non-string tags
are rejected. A known tag still uses its declared decoder and rejects an invalid
payload. Discriminator enum constraints stay strict, even with enum preservation.
OpenAPI 3.2 `defaultMapping` takes precedence over the generated fallback.

```dart
final Stop stop = Stop.fromJson({'kind': 'Boat', 'decks': 2});
assert(stop is StopUnknown);
assert(stop.toJson()['decks'] == 2);
```

The contract is shared by plain, json_serializable, Freezed, and dart_mappable.
Preserved enums and fallback dispatch use shared codecs. Known DTOs still use
the selected serializer. Freezed keeps variant constructors and DTO `copyWith`;
the fallback base does not use Freezed union helpers.

### Fixed discriminators

A required discriminator with a scalar `const` or a single non-null enum value
becomes a typed getter. Constructors and `copyWith` omit that parameter.
No config option is required.

```dart
final stop = RailStop(platform: 2);
stop.kind;     // RailStopKind.rail
stop.toJson(); // {"kind": "rail", "platform": 2}
```

`fromJson` rejects a missing, null, or different tag. `toJson` writes the fixed
wire value. Additional properties cannot override it. Object defaults must
contain the required tag and match its value.

The rule includes inherited discriminator fields and referenced enum types.
It applies to Swagger 2.0 discriminator annotations and OpenAPI 3.x annotations
and tagged union branches. `const` is supported in OpenAPI 3.1 and 3.2.

Optional, nullable, and multi-value tags keep constructor parameters.
A mapping alone does not fix a tag. Alias values retain their exact wire values.
A singleton field without a discriminator keeps its parameter.

## Tuple arrays

In OpenAPI 3.1 and 3.2, `prefixItems` sets the type of each listed position.
`minItems` sets the minimum length. For example:

```yaml
Reading:
  type: array
  minItems: 1
  prefixItems:
    - type: string
    - type:
        - integer
        - 'null'
  items:
    type: boolean
```

```dart
final short = Reading.fromJson(['sensor']);
final String name = short.item1;
assert(!short.hasItem2 && short.item2 == null);

final full = Reading.fromJson(['sensor', null, true]);
assert(full.hasItem2 && full.item2 == null);
final List<bool> flags = full.rest;
final List<Object?> json = full.toJson(); // ['sensor', null, true]
```

`fromJson` checks the complete value. `toJson` returns a detached copy.
`items` sets the tail type. An omitted `items` or `items: true` allows any
JSON tail item. `items: false` closes the tuple and omits `rest`.
Without an array type constraint, `prefixItems` also accepts scalar and object
values. These values have no positions and round-trip through `toJson`.

## Union branch names

Inline `oneOf` and `anyOf` branches use `title` for their Dart names.
No config option is required. Naming priority:

1. The referenced named schema.
2. The inline branch title.
3. The existing type or `VariantN` fallback.

```yaml
Identifier:
  oneOf:
    - title: External code
      type: string
    - title: Internal id
      type: integer
```

This generates `IdentifierExternalCode` with a `String value` and
`IdentifierInternalId` with an `int value`. Both implement `Identifier`.
For an inline object, the generated class exposes its properties.

An inline `anyOf` branch titled `By id` under `Contact` generates `ContactById`,
`hasById`, and `asById`. Multiple branches can match the same JSON object.
Tagged inline branches also use titles: `State` with `title: Online` generates
`StateOnline`. Discriminator mapping keys stay unchanged.

A reference to `RailStop` keeps that name even if the schema or reference has
a different title. A title does not rename the union itself. Generated model
names pass through existing replacement and identifier rules. Branch accessors
use the branch label. Duplicate labels and class names get numeric suffixes.
Empty titles or titles without ASCII letters or digits use the existing fallback.

Titles do not change JSON keys, values, references, or branch matching.
`oneOf` branches with `const` remain a union; they do not become a single enum.
The naming rules apply to OpenAPI 3.0, 3.1, and 3.2 with all four serializers.

## Discriminated unions

OpenAPI 3.x object alternatives with `oneOf` or `anyOf` and a discriminator
generate a sealed class. Its factory reads the wire tag and calls the selected
DTO's decoder. Both codecs use ordinary Dart methods.

```dart
final reading = Reading.fromJson({
  'reading-kind': 'temperature',
  'station': 'A',
  'degrees': 2.5,
});
if (reading is Thermal) {
  print(reading.degrees);
}
final json = reading.toJson(); // Keeps the wire value 'temperature'.
```

Named alternatives accept their component name as a tag. Explicit mappings
take precedence for the same tag. A mapping can use an entry component name
or a URI reference. Use `./` for a relative file name. Inline alternatives
need an explicit mapping or a default. Tag comparisons use strings.

By default, missing or unmapped tags are rejected. OpenAPI 3.2 can select a
fallback DTO with `defaultMapping`. A known tag always uses its own decoder.
Dispatch selects a DTO. Full JSON Schema validation, including counting
matches for `oneOf`, is separate.

Object `allOf` branches merge properties and required keys. A variant can
narrow an inherited scalar tag with `enum` or a scalar `const`. When the
union adds fields or constraints, the generator creates a combined DTO for
that variant. The standalone variant keeps its own shape.

Swagger 2.0 named bases with `discriminator` and `allOf` descendants also
produce sealed unions. Wire tags are original definition names, even after Dart
name replacement. The base name selects a generated `<Base>Value` DTO. Descendant
names select their DTOs. Nested inheritance and directional DTOs are supported.
A base without descendants stays an ordinary DTO. Inline schemas do not define
Swagger discriminator tags.

## Unions without a discriminator

A nullable OpenAPI 3.0 branch with `enum: [null]` represents only null. It can
participate in a union without generating an empty Dart enum.

For `oneOf`, the decoder checks every branch. It returns a sealed variant
when exactly one matches. Zero or multiple matches raise `FormatException`.
Object variants expose their fields. Scalar and container variants expose
their typed `value`.

For `anyOf`, use `hasX` to test a match and `asX` to read its typed value.
A present match can itself be JSON null. Zero matches raise `FormatException`.

```dart
final contact = Contact.fromJson({'id': '42', 'email': 'a@b.co'});
assert(contact.hasById && contact.hasByEmail);
assert(contact.asById!.id == '42');
assert(contact.asByEmail!.email == 'a@b.co');
final original = contact.toJson();
```

The `anyOf` DTO snapshots the input. Getters decode independent views.
`toJson()` returns a detached copy, including unknown keys and explicit nulls.

Predicates check JSON types, required keys, properties, additional properties,
array items, scalar `enum` and `const`, ranges, lengths, counts, and patterns.
They follow references and apply `allOf` and adjacent constraints.
In OpenAPI 3.1 and 3.2, a `$dynamicRef` to a `$dynamicAnchor` selects the
outermost resource that defines the same anchor. JSON Pointers and ordinary
anchors keep their static targets. The decoder uses the selected type for
fields, array items, and union views.
`contains` counts the array items that match its schema. The default minimum
is one. The default maximum is unbounded. Set `minContains` or `maxContains`
beside `contains` to set inclusive limits. These limits apply only to arrays
and only within the same schema object.
`uniqueItems: true` compares nested JSON values. Array order matters.
Object key order is irrelevant. Numbers such as `1` and `1.0` are equal.
`multipleOf` uses the decimal representation of the decoded Dart number.
For a step of `0.1`, `0.3` matches and `0.30000000000000004` fails.
`format` is an annotation for matching.
For example, both `integer` and `number` match `42` and `42.0`.
An unsupported assertion such as `unevaluatedItems` raises a generation diagnostic
with its JSON Pointer.
Recursive references must descend into a property or an array item.

## API extraction

```dart
final api = const ApiDefinitionExtractor().extract(document, references);
final post = api.operations.firstWhere(
  (op) => op.method == 'POST' && op.path == '/stations',
);
final input = post.requestBody?.content['application/json']?.schema;
final output = post.responses['201']?.content['application/json']?.schema;
```

`ApiDefinition` indexes schemas by physical URI and JSON Pointer.
It retains value and content parameters, request bodies, status responses,
headers, multipart encodings, and stream item schemas. Swagger body and form
parameters use operation or document media types. A null media key means that
Swagger omitted the type.

Routes, named webhooks, and linked callbacks stay distinct. Each operation
retains its method, mounted path, source, and effective security and server
settings. Swagger servers keep their `host`, `basePath`, and `schemes` fields.

`operationId` preserves the declared value. Without an ID,
`dartMethodNameCandidate` uses the method and path.

| Route | Dart name candidate |
| --- | --- |
| `GET /stations/{id}` | `getStationsById` |
| `GET /a/{b}/c/{d}/{e}` | `getAByBCByDAndE` |

Pass `parseConfig` to `generate()` or `validate()` to override parsing for
the entry document and every external reference in that call.

The runner validates before extraction and after reference resolution.
Inject stages to customize mapping or rendering. Pass an `OpenApiNormalizer`
to normalize the document before extraction. The backend uses `code_builder`
and `dart_style`.

## Background response decoding

Set `generation.decode_responses_in_background: true` to decode buffered JSON
responses in a VM isolate. The default is `false`. In Dart, use
`GenerationConfig(decodeResponsesInBackground: true)`.

This applies to Retrofit, Dio, and package:http with all four serializers.
The worker parses UTF-8 JSON and builds DTOs. Public return types stay unchanged.
Web uses an inline fallback through a conditional import. No Flutter dependency
is required. Small responses can cost more with an isolate.

Cancellation stops response reads and the VM worker. Web cancellation works
before synchronous decoding starts. It cannot interrupt a running decode.
HTTP errors keep the transport policy and decoded JSON error bodies. Dio
interceptors receive raw streams before this decoding step. JSON and codec
failures complete the returned future with an error. Transfer failures can
produce `RemoteError`.

SSE, JSON Lines, binary responses, and request encoding keep their existing
paths. `original_http_response` remains supported. Custom codecs must work in a
fresh isolate. They cannot depend on caller-zone values or initialized global
state. Their result must be transferable between isolates.

## Run

```sh
dart run example/generate_dto.dart test/fixtures/extraction/open_api_v3_2.yaml
dart run example/parse_file.dart path/to/swagger.yaml
dart test
```

## Decode in-memory settings

Use `PipelineConfig.fromMap` for the `parse`, `normalize`, and `generation`
sections of a decoded JSON or YAML mapping. It uses the same option decoder as
the CLI. It does not read files or fetch URLs. The caller handles source paths,
output paths, batches, and template loading.

```dart
final settings = PipelineConfig.fromMap(config);
final runner = SwaggerParserRunner(
  normalizer: settings.normalize.explicitParameterSerialization
      ? OpenApiNormalizer(config: settings.normalize)
      : null,
);
final result = await runner.generate(
  SchemaSource(schema),
  parseConfig: settings.parse,
  config: settings.generation,
);
```
