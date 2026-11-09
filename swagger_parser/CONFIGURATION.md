# Configuration reference

Use this reference with the [quick start](README.md) and [generation guide](GUIDE.md). Each option shows its
accepted values, default, and effect. All examples target Dart 3.13.

YAML and JSON use the same keys. Use snake_case in config. Dart constructors
use camelCase: `page_width` becomes `GenerationConfig(pageWidth: 120)`.
Code examples show the affected declarations or calls. They omit unrelated
fields, transport options, imports, and generated implementation details.

## Contents

- [Complete defaults](#complete-defaults)
- [Sources and output](#sources-and-output)
- [Multiple inputs](#multiple-inputs)
- [Schema downloads](#schema-downloads)
- [Parsing](#parsing)
- [Normalization](#normalization)
- [Names and files](#names-and-files)
- [HTTP clients](#http-clients)
- [DTOs and codecs](#dtos-and-codecs)
- [Operation and model selection](#operation-and-model-selection)
- [Custom types](#custom-types)
- [Optional templates](#optional-templates)
- [Interactions and errors](#interactions-and-errors)
- [Dart API](#dart-api)

## Complete defaults

Supply a source. The other values below are defaults, not required boilerplate.
`inputs` and `generation.templates` are optional alternatives described below.

```yaml
swagger_parser:
  schema_path: api/stations.yaml
  output_directory: lib/generated
  schema_download:
    credentials: []
  parse:
    max_depth: 128
    capture_source_locations: true
    unknown_fields: preserve
  normalize:
    explicit_parameter_serialization: false
  generation:
    root_api_class_name: Api
    file_suffix: ''
    fallback_client_name: ApiClient
    naming:
      preserve_schema_casing: false
      replace_rules: []
    http_client: retrofit
    serializer: plain
    response_mode: first_success
    original_http_response: false
    unknown_enum_values: reject
    unknown_discriminator_values: reject
    generate_docs: true
    api_metadata: none
    body_positional: false
    use_path_for_method_names: false
    apply_parameter_defaults: false
    infer_missing_required: true
    use_presence_records: false
    generate_validators: false
    stream_binary_responses: false
    decode_responses_in_background: false
    page_width: 80
    type_mappings: []
    exclude_parameters: []
    prune_unused_models: false
    keep_models: []
    operation_filters:
      include_paths: null
      exclude_paths: []
      include_tags: null
      exclude_tags: []
```

## Sources and output

### Config location and command-line overrides

```sh
dart run swagger_parser -f config/swagger.yaml
dart run swagger_parser api/stations.yaml -o lib/stations
dart run swagger_parser --schema_url https://example.org/openapi.yaml
```

| Selection | Effect |
| --- | --- |
| No `-f` | Read `swagger_parser.yaml` in the working directory; otherwise read `pubspec.yaml`. |
| `-f path.yaml` or `-f path.json` | Read that file. Config-relative paths use its directory. |
| Standalone config | Accept a `swagger_parser:` section or its fields at the root. |
| `pubspec.yaml` | Read only its `swagger_parser:` section. |
| Source argument | Override the configured source. Relative paths use the working directory. |
| `-o` / `--output` / `--output_directory` | Override the configured output. Relative paths use the working directory. |

Unknown keys and wrong value types fail. Booleans must be `true` or `false`,
not quoted strings. Omit a field to use its default. `null` is accepted only
where the option permits it; it is not a general reset value.

Compatibility aliases accept camelCase keys in `parse`, `normalize`,
`generation`, `naming`, and `operation_filters`, plus camelCase enum values.
Do not supply both forms of the same key. Use snake_case for all new config,
including source keys and entries in rule lists.

### `schema_path`, `schema_url`, and `input`

No default. Select exactly one source per input.

```yaml
schema_path: api/stations.yaml
```

```yaml
schema_url: https://specs.example.com/openapi.json
```

```yaml
input: api/stations.json
```

| Option | Accepted value | Effect |
| --- | --- | --- |
| `schema_path` | Non-empty file path | Read a local JSON or YAML document. |
| `schema_url` | HTTP(S) URL | Download the document and resolve external refs from its retrieval URL. |
| `input` | File path or HTTP(S) URL | Select the matching loader. |

JSON and YAML produce the same declarations for equivalent schemas. `.json`,
`.yaml`, and `.yml` extensions select a decoder, without case sensitivity.
An extensionless remote URL uses content detection, not its Content-Type header.
URLs cannot contain userinfo or fragments. Use credentials below for headers.

Generation from a URL saves the entry bytes in the working directory. The name
comes from the final URL, with a detected extension when needed. Unsuitable
names use `openapi.json` or `openapi.yaml`. Batch copies add the input ID.
External references stay in memory. `validate` and `--check` do not save copies.

### `output_directory` and `output`

Default: `lib/generated`. These are aliases; use only one.

```yaml
schema_path: api/stations.yaml
output_directory: lib/transit
```

Result: `lib/transit/api.dart`, `exports.dart`, and client/model folders.
A relative config path uses the config directory. An absolute path stays absolute.
Generated files have an ownership marker. A normal run replaces marked files
and removes stale marked files. An unmarked file at an expected path stops the run.

### Read-only commands

```sh
dart run swagger_parser validate -f swagger_parser.yaml
dart run swagger_parser --check -f swagger_parser.yaml
```

`validate` parses, normalizes, resolves refs, and validates operations. It does
not map Dart types. `--check` generates in memory and compares output bytes.
Missing, changed, obsolete, or conflicting files produce exit code `1`.
Do not combine `validate` with `--check`.

## Multiple inputs

### `inputs`

Default: absent, for one schema. Use a non-empty map for multiple schemas.
Each ID starts with a lowercase letter and contains only lowercase letters,
digits, or underscores.

```yaml
output_directory: lib/generated
generation:
  serializer: freezed
  http_client: retrofit
  naming:
    preserve_schema_casing: true
    replace_rules:
      - target: models
        pattern: 'Dto$'
        replacement: ''
inputs:
  transit:
    schema_path: api/transit.yaml
    generation:
      root_api_class_name: TransitApi
      http_client: dio
  billing:
    schema_path: api/billing.json
    generation:
      root_api_class_name: BillingApi
      naming:
        replace_rules: []
  users:
    schema_path: api/users.yaml
    output_directory: lib/users
    generation:
      root_api_class_name: UsersApi
      serializer: plain
      http_client: http
```

| Input | Effective settings | Public file |
| --- | --- | --- |
| `transit` | Freezed, Dio, inherited naming rules | `lib/generated/transit/transit_api.dart` |
| `billing` | Freezed, Retrofit, preserved casing, no replacement rules | `lib/generated/billing/billing_api.dart` |
| `users` | Plain, http, inherited naming rules | `lib/users/users_api.dart` |

Apply package defaults, then shared root fields, then child fields.
`parse`, `normalize`, `generation`, and `schema_download` merge by field.
Nested `naming` and `operation_filters` also merge by field. Lists replace;
they do not append. `false` and empty lists override inherited values.
For nullable include filters, `null` restores inclusion of all operations.

Each child supplies its own source. Root source fields are invalid with `inputs`;
the root is not another schema. A child output is a complete path relative to
the config, not a path appended to the root output. Otherwise use `<base>/<id>`.

Separate outputs have separate facades and model identities. Equal or nested
output directories, including physical symlink aliases, fail. Source/output
CLI overrides are allowed for one input but rejected for multiple inputs.

## Schema downloads

### `schema_download.credentials`

```yaml
schema_download:
  credentials: []
```

Default. Add no credentials to schema downloads.

```text
No configured Authorization or API key headers.
```

Credentials below affect schema downloads, not generated client requests.

```yaml
schema_url: https://specs.example.com/api/openapi.yaml
schema_download:
  credentials:
    - origin: https://specs.example.com
      headers:
        Authorization:
          env: SCHEMA_AUTHORIZATION
        X-Schema-Client: generator
    - origin: https://refs.example.com
      headers:
        X-Api-Key:
          env: REFERENCE_API_KEY
```

| Field or value | Effect |
| --- | --- |
| `credentials: []` | Send no configured credential headers. Also clears inherited credentials in an input. |
| `origin` | Required exact HTTP(S) origin: scheme, host, and effective port. No path, wildcard, query, fragment, or userinfo. |
| `headers` | Required map. Header names match without case; an empty map sends none. |
| Literal header string | Send that complete value. |
| `env: VARIABLE` | Read the complete header value from the environment. No automatic `Bearer ` prefix. |

For `Authorization` above, set `SCHEMA_AUTHORIZATION` to `Bearer <token>`.
Missing or empty environment values fail when their origin is requested.
Duplicate origins or case-insensitive header names fail. Invalid header names,
control characters, and transport headers such as `Host` are rejected.

The loader selects credentials again for each external `$ref` and redirect.
A request to `refs.example.com` uses only its own rule. A third origin gets no
configured headers. HTTPS-to-HTTP redirects fail. Credentials in a child input
replace the entire inherited list. In-memory callers supply their own loader.

## Parsing

Parsing options apply to the entry document and each external reference file.
They control OpenAPI input, not JSON returned by generated HTTP clients.

### `parse.unknown_fields`

```yaml
parse:
  unknown_fields: preserve
```

Default. Keep an unknown fixed OpenAPI field such as info.typo.

```text
Parsed document toJson: info.typo remains.
Generated DTOs: no field is invented.
```

```yaml
parse:
  unknown_fields: reject
```

Stop at the unknown field.

```text
Parsing fails. No Dart output.
```

x- extensions are exempt. Schema property names are data. This option does not
control HTTP response JSON, DTO additional properties, or unknown enum values.

### `parse.capture_source_locations`

```yaml
parse:
  capture_source_locations: true
```

Default. Store available source coordinates.

```text
Diagnostic: URI + JSON Pointer + available line/column.
```

```yaml
parse:
  capture_source_locations: false
```

Omit the coordinate map.

```text
Diagnostic: URI + JSON Pointer where available.
Generated API: unchanged.
```

Decoder syntax errors can still include coordinates. Normalized documents can
lack original coordinates. No position map is embedded in generated Dart.

### `parse.max_depth`

```yaml
parse:
  max_depth: 128
```

Default. Limit each decoded document to depth 128.

```text
A value at depth 129 fails before generation.
```

```yaml
parse:
  max_depth: 256
```

Allow deeper documents.

```text
A value at depth 129 passes this depth check.
```

Use a positive integer. Root depth is 0. Each field or array item adds one,
including extensions. This does not count ref hops, change timeouts, or add
support for an unsupported Dart shape.

## Normalization

### `normalize.explicit_parameter_serialization`

```yaml
normalize:
  explicit_parameter_serialization: false
```

Default. Keep omitted parameter settings omitted.

```text
OpenAPI query: style and explode stay absent.
Effective wire settings: form, true.
```

```yaml
normalize:
  explicit_parameter_serialization: true
```

Write applicable implicit settings in a new document of the same version.

```text
OpenAPI query: style: form, explode: true.
Effective wire settings: form, true.
```

The extractor uses the same calculation in both modes. Generation normally
keeps the same wire format. Swagger array parameters use collectionFormat: csv;
OpenAPI path/header parameters use simple and false. Explicit values win.
deepObject gets no implicit explode. Content and whole-query parameters are
not rewritten. CLI normalization applies to the entry document.

## Names and files

### `generation.root_api_class_name`

```yaml
generation:
  root_api_class_name: Api
```

Default. Generate the `Api` facade.

```text
api.dart
exports.dart
```

```yaml
generation:
  root_api_class_name: TransitApi
```

Rename the facade to `TransitApi`.

```text
transit_api.dart
exports.dart
```

Both facades expose the generated clients and export `exports.dart`.
Use `[A-Z][A-Za-z0-9]*`. Protected names and `Exports` fail. Naming rules and
`file_suffix` do not change this name.

### `generation.fallback_client_name`

For operations without tags:

```yaml
generation:
  fallback_client_name: ApiClient
```

Default. Put untagged operations in one client.

```text
default_client/api_client.dart
Api.api → ApiClient
```

```yaml
generation:
  fallback_client_name: CommonClient
```

Change the untagged client name.

```text
default_client/common_client.dart
Api.common → CommonClient
```

Tagged clients are unchanged. Use the same name constraints as the facade.
Client replacement rules do not change this full name. Collisions get safe names.

### `generation.file_suffix`

```yaml
generation:
  file_suffix: ''
```

Default. Keep standard filenames.

```text
stations/models/station.dart
stations/stations_client.dart
stations/stations_client.g.dart
```

```yaml
generation:
  file_suffix: _generated
```

Add a suffix to internal files and their part directives.

```text
stations/models/station_generated.dart
stations/stations_client_generated.dart
stations/stations_client_generated.g.dart
```

Class names, the facade file, and `exports.dart` stay unchanged. Imports follow
the new paths. Explicit template helper paths stay unchanged.

Use letters, digits, `_`, `.`, or `-`. Paths, `..`, a trailing `.`, and endings
`.dart`, `.g`, `.freezed`, or `.mapper` fail. Builder endings ignore case.

### `generation.page_width`

```yaml
generation:
  page_width: 80
```

Default. Prefer 80-column lines.

```dart
const Station({
  required this.id,
  this.name,
  this.platform,
  this.zone,
  this.address,
});
```

```yaml
generation:
  page_width: 120
```

Allow more text on one line when it fits.

```dart
const Station({required this.id, this.name, this.platform, this.zone, this.address});
```

The layout above illustrates wrapping. `dart_style` chooses actual breaks after
`code_builder` emits source. Use a positive integer. Long literals or comments
can exceed the width. Templates use this width; external builders format their own parts.

### `generation.naming.preserve_schema_casing`

```yaml
generation:
  naming:
    preserve_schema_casing: false
```

Default. Normalize named schema casing.

```text
kUserStatus → KUserStatus
```

```yaml
generation:
  naming:
    preserve_schema_casing: true
```

Keep the source casing.

```text
kUserStatus → kUserStatus
```

Both modes remove separators and protect identifiers. Fields, wire keys, paths,
and imported custom types keep their own rules. Collisions get numeric suffixes.

### `generation.naming.replace_rules`

```yaml
generation:
  naming:
    replace_rules: []
```

Default. Apply standard naming without replacements.

```text
StationDto → StationDto
InternalStations → InternalStationsClient
lookupStation → lookupStation
status_active → statusActive
```

```yaml
generation:
  naming:
    replace_rules:
      - target: models
        pattern: 'Dto$'
        replacement: ''
```

Remove the DTO suffix from generated model names.

```text
StationDto → Station
```

```yaml
generation:
  naming:
    replace_rules:
      - target: clients
        pattern: '^Internal'
        replacement: ''
```

Rename tags before adding Client.

```text
InternalStations → StationsClient
```

```yaml
generation:
  naming:
    replace_rules:
      - target: methods
        pattern: '^lookup'
        replacement: 'get'
```

Rename methods and their result classes.

```text
lookupStation → getStation
LookupStationResult → GetStationResult
```

```yaml
generation:
  naming:
    replace_rules:
      - target: enum_values
        pattern: '^status_'
        replacement: ''
```

Rename enum members. Keep JSON values unchanged.

```text
status_active → active
JSON: status_active
```

Each entry requires target, pattern, and replacement. Rules replace all regex
matches in list order, before casing and collision checks. Patterns are
case-sensitive. Replacement is literal: $1 is not a capture substitution.
An empty replacement removes matches. Invalid patterns or targets fail.

Fields, parameters, wire keys, refs, and URLs stay unchanged. Rules do not
rename the facade, fallback client, codec methods, or imported mapped types.
Method result names follow the method; a referenced Aboba payload stays Aboba
unless a model rule changes it. A child list replaces inherited rules.

### `generation.use_path_for_method_names`

For `GET /stations/{id}` with `operationId: lookupStation`:

```yaml
generation:
  use_path_for_method_names: false
```

Default. Prefer operationId.

```dart
Future<Station> lookupStation({required String id});
```

```yaml
generation:
  use_path_for_method_names: true
```

Use the HTTP method and path.

```dart
Future<Station> getStationsById({required String id});
```

Without operationId, both modes use the path name.
`GET /a/{b}/c/{d}/{e}` gives `getAByBCByDAndE` before collision checks.
Method replacement rules run next. Result names follow the final method;
referenced DTO names stay independent.

## HTTP clients

### `generation.http_client`

For a GET operation with a Station response:

```yaml
generation:
  http_client: retrofit
```

Default. Generate Retrofit annotations and Dio fallbacks. Build the parts.

```dart
@GET('/stations/{id}')
Future<Station> lookupStation({@Path('id') required String id});
```

```yaml
generation:
  http_client: dio
```

Generate concrete Dio methods. No client build step.

```dart
final api = Api(Dio(BaseOptions(baseUrl: 'https://example.com')));
final Station station = await api.stations.lookupStation(id: '42');
```

```yaml
generation:
  http_client: http
```

Generate package:http methods. No client build step.

```dart
final api = Api(http.Client(), baseUrl: Uri.parse('https://example.com'));
final Station station = await api.stations.lookupStation(id: '42');
```

Retrofit also receives a Dio instance. Unsupported native contracts use that
instance directly. All three backends support all four serializers.

Dio uses `CancelToken` and `Options`. http uses `Future<void>? abortTrigger`
and `HttpRequestOptions`. Per-call extras remain available. A package serializer
can require build_runner even when the client does not.
See [consumer setup](GUIDE.md#generated-models).

### `generation.response_mode`

Suppose lookupStation declares 200: Station, 202: Ticket, 204 without a body,
and 404: Problem.

```yaml
generation:
  response_mode: first_success
```

Default. Select the lowest exact declared 2xx payload.

```dart
Future<Station> lookupStation({required String id});
```

```yaml
generation:
  response_mode: all_statuses
```

Generate a result variant for every declared response.

```dart
Future<LookupStationResult> lookupStation({required String id});

final message = switch (await client.lookupStation(id: '42')) {
  LookupStation200(:final value) => value.name,
  LookupStation202(:final value) => value.token,
  LookupStation204() => 'No station',
  LookupStation404(:final value) => value.message,
};
```

Results live in the sibling `*_results.dart` file and are publicly exported.
A declared 500 gets its own variant. Exact codes win over ranges, then default.
An undescribed status fails. No separate application exception API is added.

In first_success, only 201 selects its payload. Only 204, only 400, or no exact
2xx gives `Future<void>`. Declared untyped JSON gives `Object?`. Native Retrofit
keeps the caller's Dio status policy. Direct methods check the selected declared
status when available. A selected Station cannot also decode Ticket or an empty
204. Use all_statuses for different shapes. Response mode also affects pruning.

### `generation.original_http_response`

For a selected Station payload:

```yaml
generation:
  original_http_response: false
```

Default. Return the decoded payload.

```dart
Future<Station> lookupStation({required String id});
```

```yaml
generation:
  original_http_response: true
```

Wrap first-success payloads with transport data.

```dart
// Retrofit and http
Future<HttpResponse<Station>> lookupStation({required String id});
// Dio
Future<Response<Station>> lookupStation({required String id});
```

Read the payload through `data`. Retrofit and http expose `response`; Dio
returns the response directly. The http wrapper stores `http.BaseResponse`: a
Response for buffered bodies or StreamedResponse for streams.

With all_statuses, this option has no effect. No WithHeaders method or typed
response-header model is added.

### `generation.body_positional`

For a required whole request body:

```yaml
generation:
  body_positional: false
```

Default. Keep the body named.

```dart
await client.createStation(body: request);
```

```yaml
generation:
  body_positional: true
```

Make that body positional.

```dart
await client.createStation(request);
```

Other arguments stay named. Optional bodies and individual form fields stay
named. Parameter defaults do not change required bodies.

### `generation.apply_parameter_defaults`

For optional query parameter limit with schema default 25:

```yaml
generation:
  apply_parameter_defaults: false
```

Default. Omit the parameter when the caller omits the argument.

```dart
@Query('limit') int? limit
// No argument: no limit query entry.
```

```yaml
generation:
  apply_parameter_defaults: true
```

Use the default when the caller omits the argument.

```dart
@Query('limit') int? limit = 25
// No argument: limit=25.
```

Explicit `limit: null` omits the entry in both modes. Required parameters,
whole bodies, and DTO defaults keep their rules. Enum defaults use wire values.
Empty collection defaults use `const []` or `const {}`; their wire form depends
on parameter serialization. No empty item is invented. Unsupported constants
fail when applied. Excluded parameters are not restored.

### `generation.stream_binary_responses`

For a binary response:

```yaml
generation:
  stream_binary_responses: false
```

Default. Collect bytes in memory.

```dart
Future<List<int>> download();
```

```yaml
generation:
  stream_binary_responses: true
```

Expose byte chunks as a stream.

```dart
Future<Stream<List<int>>> download();
```

Response wrappers and status variants contain the selected payload. JSON,
text, SSE, JSON Lines, and uploads keep their own types. Dio browser XHR can
buffer the network response even with a stream API. See [streams](GUIDE.md#bodies-and-streams).

### `generation.decode_responses_in_background`

For buffered JSON responses:

```yaml
generation:
  decode_responses_in_background: false
```

Default. Parse JSON and create DTOs on the caller isolate.

```dart
await client.lookupStation(id: '42'); // Inline decoding.
```

```yaml
generation:
  decode_responses_in_background: true
```

Use a VM worker. Web keeps inline decoding.

```dart
await client.lookupStation(id: '42'); // Same return type.
```

All clients, serializers, response modes, and wrappers work. SSE, JSON Lines,
binary responses, and request encoding keep their paths. Custom codecs must
work in a fresh isolate and return transferable values. Caller-zone values
and initialized mutable globals are not copied.

Cancellation can stop the VM worker. Web cannot interrupt an active synchronous
decode. Codec errors complete the future with an error. Transfer errors can
produce RemoteError. Small responses can be slower with an isolate.

### `generation.api_metadata`

The facade always exposes title, apiVersion, and specVersion.

```yaml
generation:
  api_metadata: none
```

Default. Omit operation metadata.

```dart
Api.title;
Api.apiVersion;
Api.specVersion;
```

```yaml
generation:
  api_metadata: generate
```

Add operation constants and the facade operation list.

```dart
StationsClientMetadata.lookupStation;
Api.operations;
```

```yaml
generation:
  api_metadata: generate_and_attach
```

Generate the same constants and attach them to requests.

```dart
final operation = options.extra['openapi.operation'] as OperationMetadata;
```

For http, read extras in prepareRequest. The generated operation wins at
openapi.operation; other caller extras remain. Metadata contains source method,
path, tags, and deprecation. It does not set authentication or send headers.
generate_docs and original_http_response remain independent.

## DTOs and codecs

### `generation.serializer`

The public codec API stays fromJson/toJson. These excerpts omit other members.

```yaml
generation:
  serializer: plain
```

Default. Generate direct Dart codecs without serializer packages.

```dart
factory Station.fromJson(Map<String, Object?> json) =>
    Station(id: json['id'] as String);
Map<String, Object?> toJson() => {'id': id};
```

```yaml
generation:
  serializer: json_serializable
```

Generate annotations and delegate to a built part.

```dart
part 'station.g.dart';

factory Station.fromJson(Map<String, Object?> json) => _$StationFromJson(json);
Map<String, Object?> toJson() => _$StationToJson(this);
```

```yaml
generation:
  serializer: freezed
```

Add Freezed output. Ordinary DTOs use native primary constructors.

```dart
part 'station.freezed.dart';
part 'station.g.dart';

@Freezed(fromJson: false, toJson: false)
// JsonSerializable annotations and class const Station(...) with _$Station follow.
```

```yaml
generation:
  serializer: dart_mappable
```

Generate mapper annotations, a part, and wire hooks.

```dart
part 'station.mapper.dart';

factory Station.fromJson(Map<String, Object?> json) => StationMapper.fromMap(json);
Map<String, Object?> toJson() => toMap();
```

The three package serializers need build_runner. Retrofit also needs it with
plain DTOs. See [dependencies](GUIDE.md#generated-models). Freezed collections
remain mutable. Freezed and dart_mappable provide copy APIs; plain and
json_serializable do not gain copyWith. Unions and preserved unknown values
can use shared adapters instead of only package-native dispatch.

### `generation.generate_docs`

For description "A station." and deprecated: true:

```yaml
generation:
  generate_docs: true
```

Default. Keep source Dartdoc and deprecation.

```dart
/// A station.
@Deprecated('Deprecated in the API specification.')
class Station {}
```

```yaml
generation:
  generate_docs: false
```

Omit source Dartdoc. Keep deprecation.

```dart
@Deprecated('Deprecated in the API specification.')
class Station {}
```

The same rule applies to supported fields, methods, and arguments. Source
summary/description text is preserved. No dart doc build or website is created.
Generator-owned API comments and API metadata have separate rules.

### `generation.infer_missing_required`

For an object without required: id rejects null, name accepts null, and enabled
has default true.

```yaml
generation:
  infer_missing_required: true
```

Default. Infer non-null fields without defaults.

```dart
Station({required String id, String? name, bool enabled = true});
```

```yaml
generation:
  infer_missing_required: false
```

Use only explicit required declarations.

```dart
Station({String? id, String? name, bool enabled = true});
```

An explicit list wins; do not add missing entries. In 3.1/3.2, required: []
disables inference. Swagger 2.0 and OpenAPI 3.0 reject that empty list; use false.
Refs, allOf, and inherited defaults participate. Core documents and HTTP
parameter/body required flags stay unchanged. Validators use effective required keys.

### `generation.use_presence_records`

For optional nullable name without a schema default:

```yaml
generation:
  use_presence_records: false
```

Default. Use String? and omit null keys.

```dart
Patch().toJson();               // {}
Patch(name: null).toJson();     // {}
Patch(name: 'North').toJson();  // {"name":"North"}
```

```yaml
generation:
  use_presence_records: true
```

Use ({String? value})? to distinguish absence from explicit null.

```dart
Patch().toJson();                           // {}
Patch(name: (value: null)).toJson();         // {"name":null}
Patch(name: (value: 'North')).toJson();      // {"name":"North"}
```

All serializers follow this contract. Required nullable fields stay required
T?. Defaulted nullable fields stay T?: omission applies the default, explicit
null stays null, and both values are written. List items, map values, and raw
bodies do not become records. Optional non-nullable fields can use T? for
absence but still reject explicit JSON null.

### `generation.generate_validators`

```yaml
generation:
  generate_validators: false
```

Default. Generate no explicit DTO validator.

```text
No validate() extension. Existing codec and union checks remain.
```

```yaml
generation:
  generate_validators: true
```

Add exported validation extensions and field-path errors.

```dart
final errors = station.validate();
for (final error in errors) {
  print('${error.path}: ${error.keyword}: ${error.message}');
}
```

Call validate explicitly. It checks current toJson output and effective required
fields. Empty errors mean valid. Constructors and clients do not call it.
Encoding errors propagate; discarded keys cannot be recovered. Preserved
unknown enum values can still fail schema validation. Unsupported assertions
fail generation when enabled. Format annotations do not add format checks.

### `generation.unknown_enum_values`

Status declares active and closed. The server sends paused.

```yaml
generation:
  unknown_enum_values: reject
```

Default. Generate a strict enum.

```dart
enum Status { active, closed }
// Status.fromJson('paused') fails.
```

```yaml
generation:
  unknown_enum_values: preserve
```

Generate known and unknown wrappers under Status.

```dart
final Status result = Status.fromJson('paused');
assert(result is StatusUnknown);
assert(result.toJson() == 'paused');
assert(Status.active.toJson() == 'active');
```

Preserve adds StatusKnown, StatusValue, and StatusUnknown. HTTP return types
remain Status. Unknown scalars must match the schema type. Nullability and
discriminator policies are separate. Custom mappings keep their own checks.

### `generation.unknown_discriminator_values`

Stop has known rail and bus tags in its kind field.

```yaml
generation:
  unknown_discriminator_values: reject
```

Default. Reject an unknown tag.

```dart
// Stop.fromJson({'kind': 'boat', 'decks': 2}) fails.
```

```yaml
generation:
  unknown_discriminator_values: preserve
```

Keep the full JSON in an unknown variant.

```dart
final Stop result = Stop.fromJson({'kind': 'boat', 'decks': 2});
assert(result is StopUnknown);
assert(result.toJson()['decks'] == 2);
```

The fallback stores an immutable snapshot; toJson returns a detached copy.
Missing, null, or non-string tags still fail. Known tags with invalid bodies
still fail. Untagged unions gain no fallback. OpenAPI 3.2 defaultMapping wins.
Known discriminator enums stay strict even with unknown_enum_values: preserve.
An ordinary kind field is independent when another field is the discriminator.

## Operation and model selection

### `generation.operation_filters`

```yaml
generation:
  operation_filters:
    include_paths: null
    exclude_paths: []
    include_tags: null
    exclude_tags: []
```

Default. Include every outbound operation. Null includes also reset inherited lists.

```text
All supported methods remain.
```

```yaml
generation:
  operation_filters:
    include_paths: []
```

Include no paths.

```text
No client methods. Named models remain.
```

```yaml
generation:
  operation_filters:
    include_tags: []
```

Include no tags.

```text
No client methods. Named models remain.
```

```yaml
generation:
  operation_filters:
    include_paths:
      - /stations/**
```

Keep matching mounted paths.

```text
GET /stations and GET /stations/42 remain.
GET /trips is omitted.
```

```yaml
generation:
  operation_filters:
    exclude_paths:
      - /stations/internal/**
```

Remove matching paths.

```text
GET /stations/42 remains.
GET /stations/internal/stats is omitted.
```

```yaml
generation:
  operation_filters:
    include_tags:
      - Public
```

Require any exact original tag.

```text
An operation tagged Public remains.
An untagged operation is omitted.
```

```yaml
generation:
  operation_filters:
    exclude_tags:
      - Internal
```

Remove an operation if any original tag matches.

```text
Tags Public, Internal: omitted.
Tag Public alone: retained.
```

Path and tag includes combine with AND. Entries in each list combine with OR.
Exclusions win. * matches one non-empty path segment; ** matches zero or more.
Wildcards must occupy a full segment. Tags are case-sensitive and use all
source tags, before naming rules.

Filters run after parsing and ref resolution. They cannot hide invalid input.
Named schemas remain unless prune_unused_models removes them. Empty excludes
remove no operations. Child lists replace inherited lists.

### `generation.exclude_parameters`

```yaml
generation:
  exclude_parameters: []
```

Default. Keep every supported HTTP argument.

```text
getStations({String? debug, String? xTraceId, ...})
```

```yaml
generation:
  exclude_parameters:
    - name: X-Trace-Id
      in: header
    - name: debug
      in: query
      paths:
        - /stations/**
      methods:
        - GET
```

Remove matching arguments and their wire entries.

```text
GET /stations: debug and X-Trace-Id omitted.
POST /stations: only X-Trace-Id omitted.
```

Required entry fields: name and in. Use the original wire name. Header names
ignore case; other names and method tokens match exactly.

| in | Effect |
| --- | --- |
| query | Remove the matching URL query argument. |
| header | Remove the matching header argument. |
| cookie | Remove the matching cookie argument. |
| querystring | Remove the matching whole-query argument. |
| path | Invalid; path parameters cannot be excluded. |

Omitted or empty paths/methods match all operations. Paths use the filter globs.
Rules run after operation selection, inheritance, and refs. Excluding a required
argument emits excludedRequiredParameter; application transport code must supply
it. Unmatched rules do nothing. DTO fields, forms, and bodies are unchanged.
Defaults do not restore excluded arguments. Child lists replace inherited lists.

### `generation.prune_unused_models`

AuditRecord is named but unused by any generated operation.

```yaml
generation:
  prune_unused_models: false
```

Default. Retain all named component models.

```text
models/audit_record.dart remains.
```

```yaml
generation:
  prune_unused_models: true
```

Keep only client dependencies and keep_models roots.

```text
Unused AuditRecord is removed.
```

Keep transitive fields, parameters, enums, defaults, refs, unions, tuples, and
codec dependencies. Response mode changes response reachability. With no
operations, only keep_models roots and dependencies remain. Pruning does not
bypass schema validation or mapping errors.

### `generation.keep_models`

For unused named AuditRecord with pruning enabled:

```yaml
generation:
  prune_unused_models: true
  keep_models: []
```

Default. Add no retention roots.

```text
AuditRecord is removed.
```

```yaml
generation:
  prune_unused_models: true
  keep_models:
    - '#/components/schemas/AuditRecord'
```

Keep this model and its dependencies.

```text
AuditRecord and its request/response projections remain.
```

Use source names. Swagger uses #/definitions/AuditRecord. Unknown or external
root selectors fail; dependencies can reference external schemas. With pruning
disabled, all named models already remain. A child list replaces the root list.

## Custom types

### `generation.type_mappings`

```yaml
generation:
  type_mappings: []
```

Default. Use built-in type mapping.

```text
date-time → DateTime in UTC
Named schemas → generated Dart models
```

A non-empty list selects application types. All serializers use the same codecs.

```yaml
generation:
  type_mappings:
    - schema: '#/components/schemas/StationId'
      dart_type: StationId
      import: package:app/domain/station_id.dart
      codec:
        import: package:app/api/codecs.dart
        from_json: stationIdFromJson
        to_json: stationIdToJson
    - type: string
      format: date-time
      dart_type: OffsetTimestamp
      import: package:app/domain/offset_timestamp.dart
      codec:
        import: package:app/api/codecs.dart
        from_json: timestampFromJson
        to_json: timestampToJson
```

Before, a date-time field uses `DateTime` and UTC conversion. After, it uses
`OffsetTimestamp`; its codec can retain the original offset. A mapped
`StationId` uses the imported type instead of a generated wrapper.

| Field | Accepted values and default |
| --- | --- |
| `schema` | Optional exact schema URI with a JSON Pointer. Alternative to `type` plus `format`. |
| `type` | Scalar type: `string`, `integer`, `number`, or `boolean`. Requires `format`. |
| `format` | Exact non-empty format. Requires `type`. |
| `dart_type` | Required public Dart type identifier. No generic expression. |
| `import` | Required `package:` or `dart:` URI for the type. |
| `codec.import` | Required `package:` or `dart:` URI for both functions. |
| `codec.from_json` | Required public synchronous top-level decoder identifier. |
| `codec.to_json` | Required public synchronous top-level encoder identifier. |
| `direction` | `both` (default), `request`, or `response`. |
| `defaults` | `[]` by default. Explicit imported constants for applied schema defaults. |

Use exactly one selector form. For Swagger 2.0, use `#/definitions/StationId`.
External selectors resolve against the entry URI and must identify a loaded
schema. An unused type/format rule is allowed. Object mappings require an exact
schema selector. Whole union replacements are not supported.

The generator imports and exports used custom types. It does not load the
application library or verify function signatures. Consumer analysis performs
that check. Codec functions and constants are not publicly re-exported.

### Scalar and object codecs

```dart
StationId stationIdFromJson(String value) => StationId(value);
String stationIdToJson(StationId value) => value.value;

GeoPoint pointFromJson(Map<String, Object?> json) => GeoPoint(
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
);
Map<String, Object?> pointToJson(GeoPoint value) => {
  'latitude': value.latitude,
  'longitude': value.longitude,
};
```

Scalar wire types are `String`, `int`, `num`, or `bool`. Object codecs consume
and return `Map<String, Object?>`. Null and field-presence handling remain
outside the codec. An object codec owns nested conversion; other mapping rules
do not run inside it. Mapping an allOf base does not replace every descendant.

Naming replacements do not alter imported type names. Distinct imports cannot
expose the same mapped public name. Directly mapped HTTP arguments and payloads
can require the Dio fallback in Retrofit. Background codecs must be isolate-safe.

### `type_mappings[].direction`

Select the original schema, not a generated $Request or $Response name.

```yaml
generation:
  type_mappings:
    - schema: '#/components/schemas/Station'
      direction: both
      dart_type: Station
      import: package:app/domain/station.dart
      codec:
        import: package:app/api/codecs.dart
        from_json: stationFromJson
        to_json: stationToJson
```

Default. Replace both uses when their object shapes match.

```text
Requests: imported Station.
Responses: imported Station.
```

```yaml
generation:
  type_mappings:
    - schema: '#/components/schemas/Station'
      direction: request
      dart_type: CreateStation
      import: package:app/domain/station.dart
      codec:
        import: package:app/api/codecs.dart
        from_json: createStationFromJson
        to_json: createStationToJson
```

Replace only request bodies and parameters.

```text
Requests: imported CreateStation.
Responses: generated DTO, unless another rule maps it.
```

```yaml
generation:
  type_mappings:
    - schema: '#/components/schemas/Station'
      direction: response
      dart_type: Station
      import: package:app/domain/station.dart
      codec:
        import: package:app/api/codecs.dart
        from_json: stationFromJson
        to_json: stationToJson
```

Replace only response payloads.

```text
Requests: generated DTO, unless another rule maps it.
Responses: imported Station.
```

Combine request and response rules to use two imported types:

```dart
Future<Station> createStation({required CreateStation body});
```

Both codec functions are required in each rule. Exact schema selectors win over
format rules. For the same selector, a specific direction wins over both.
Duplicate selector/direction pairs fail; list order sets no priority. A both
object rule with different request/response shapes fails. Use two explicit rules.

### `type_mappings[].defaults`

```yaml
generation:
  type_mappings:
    - schema: '#/components/schemas/GeoPoint'
      dart_type: GeoPoint
      import: package:app/domain/geo_point.dart
      codec:
        import: package:app/api/codecs.dart
        from_json: pointFromJson
        to_json: pointToJson
      defaults:
        - value:
            latitude: 0
            longitude: 0
          import: package:app/api/defaults.dart
          constant: origin
```

| Field or variant | Effect |
| --- | --- |
| `defaults: []` | No custom constant substitution. An applied non-null mapped default without a matching constant fails. |
| `value` | Required finite JSON value to match against a schema default. Object key order does not matter; array order does. |
| `import` | Required `package:` or `dart:` URI for the constant. |
| `constant` | Required public top-level const name, such as `origin`. Dart expressions are not accepted. |

The application declares `const origin = GeoPoint(latitude: 0, longitude: 0)`.
An optional mapped field with that schema default gets a constructor default
and a missing-key fallback to `origin`. A mapping does not add a schema default.
Explicit nullable null stays null. Required fields stay required. JSON null
needs no custom constant.

Each direction has its own default rules. Duplicate JSON values fail. Consumer
analysis checks constness and type; application tests must check that the
constant encodes to the configured JSON value. HTTP defaults apply these rules
only when `apply_parameter_defaults` enables the relevant argument default.

## Optional templates

### `generation.templates`

This setting requires the separate
[swagger_parser_templates CLI](https://github.com/Carapacik/swagger_parser/tree/main/swagger_parser_templates).
The built-in `swagger_parser` CLI rejects it. Omit it in the built-in CLI.

```yaml
generation:
  templates: {}
```

Default renderer, with no shared template overrides.

```text
Standard generated files. No extra helpers.
```

```yaml
generation:
  templates:
    client: templates/client.mustache
    stations/models/station.dart: templates/station.mustache
    files:
      - template: templates/page.mustache
        output: helpers/page.dart
      - template: templates/internal.mustache
        output: helpers/internal.dart
        export: false
```

```sh
dart run swagger_parser_templates -f swagger_parser.yaml
```

| Selector or field | Variants and effect |
| --- | --- |
| Absent or `{}` | Use standard output. In a child input, `{}` does not clear inherited selector entries. |
| `api` | Override the facade file. |
| `exports` | Override `exports.dart`. |
| `models` | Override model libraries. |
| `client` | Override client libraries. |
| `results` | Override operation-result libraries. |
| `support` | Override support libraries, including background decoders and response wrappers. |
| Exact output path | Override that file; takes priority over its kind selector. Use the final suffixed path. |
| `files` | Add helper files. Default: none. A child list replaces the inherited list; `[]` disables inherited helpers. |
| `files[].template` | Required template path relative to the config file. |
| `files[].output` | Required relative POSIX `.dart` output path. `file_suffix` does not change it. |
| `files[].export` | `true` by default: add to default `exports.dart`. `false`: keep it internal. |

For an unchanged file, a template can contain `{{defaultSource}}`.
Custom output is formatted with `page_width`. A custom exports template must
retain `defaultSource` or write the required exports itself.

Input overrides merge selectors by key. There is no null selector to remove an
inherited override. Change its template, use a passthrough template, or move it
to the relevant child inputs. Helper paths cannot escape the output, collide
with generated files, or use builder endings `.g.dart`, `.freezed.dart`, or
`.mapper.dart`. Exact and case-insensitive file/directory collisions fail.
Templates render the already selected and mapped API; they do not bypass
source validation, add removed operations, or restore pruned models.

## Interactions and errors

### Allowed combinations and precedence

| Combination | Result |
| --- | --- |
| `original_http_response: true` + `all_statuses` | Valid; original-response wrapping has no effect. Use the result variants. |
| `stream_binary_responses: true` + background decoding | Independent. Binary streams do not enter the JSON worker. |
| Background decoding + web | Valid; inline fallback. |
| `body_positional: true` + optional body or form fields | Valid; those arguments stay named. |
| `generate_docs: false` + deprecated schema | Dartdoc omitted; deprecation retained. |
| `generate_docs: false` + metadata generation | Metadata still generated. |
| `api_metadata: generate_and_attach` + caller metadata at the same key | Generated operation metadata wins at `openapi.operation`. |
| Presence records + required or defaulted nullable field | Valid; that field stays `T?`. |
| Required inference + explicit `required` | Explicit declaration wins. |
| Validators + unknown-value preservation | Codec may preserve a value that explicit schema validation rejects. |
| Parameter default + parameter exclusion | Exclusion wins. |
| Include + exclude matching the same operation | Exclusion wins. |
| Operation filtering + pruning disabled | All named component models remain. |
| Pruning + `keep_models` | Retain selected roots and transitive dependencies. |
| Model renaming + type mappings / keep roots | Select original schema identities. Imported type names stay fixed. |
| Method renaming + `all_statuses` | Result type names follow the final method. Named payload types remain independent. |
| Exact schema mapping + type/format mapping | Exact schema mapping wins for the selected direction. |
| Directional mapping + `both` for the same selector | Direction-specific mapping wins. |
| Child map + shared map | Merge supported sections by field. |
| Child list + shared list | Replace the entire list. |
| Exact template path + kind template | Exact path wins. |
| `file_suffix` + template helper output | Helper output remains exactly as configured. |

### Rejected combinations

| Config | Reason or correction |
| --- | --- |
| Several of `input`, `schema_path`, `schema_url` in one input | Choose one source. |
| Both `output` and `output_directory` | Choose one alias. |
| Root source plus `inputs` | Put each source in its child entry. |
| Multiple inputs plus a CLI source/output override | The target is ambiguous. Change child config instead. |
| Equal, nested, or symlink-aliased output roots | Give each input a separate directory. |
| `validate` plus `--check` | Choose one command. |
| Duplicate snake_case/camelCase option | Keep one spelling. |
| `max_depth <= 0` or `page_width <= 0` | Use a positive integer. |
| Invalid facade/fallback name or reserved file suffix | Use a valid public identifier or internal suffix. |
| Parameter exclusion with `in: path` | Keep required path arguments. |
| Unknown or external `keep_models` root | Use a local named schema ref. |
| Mapping `schema` plus `type`/`format` | Choose one selector form. |
| Duplicate mapping selector and direction | Remove the duplicate; list order does not give priority. |
| Mapped object with differing directions under `both` | Add request and response rules. |
| Applied mapped default without a constant | Supply a matching const mapping. |
| Duplicate origin/header or invalid credential value | Correct the retrieval credential record. |
| Templates in the built-in CLI | Run `swagger_parser_templates`. |
| Helper path outside output, conflicting path, or builder suffix | Choose a distinct relative Dart path. |

A valid config does not guarantee that every schema shape is supported.
Generation diagnostics still identify unsupported operations or models.
Explicitly nullable query schemas skip their operation with a diagnostic.
No additional config switch changes that policy.

## Dart API

CLI source/output paths and schema-download credentials are I/O concerns.
The in-memory library returns `GenerationResult.files`; the caller chooses
how to load external documents and save or archive output.

```dart
import 'package:swagger_parser/swagger_parser.dart';

final runner = SwaggerParserRunner(
  normalizer: OpenApiNormalizer(
    config: NormalizeConfig(explicitParameterSerialization: true),
  ),
);
final result = await runner.generate(
  SchemaSource(schemaText),
  parseConfig: const ParseConfig(
    unknownFields: UnknownFieldPolicy.preserve,
    maxDepth: 128,
    captureSourceLocations: true,
  ),
  config: const GenerationConfig(
    rootApiClassName: 'TransitApi',
    httpClient: HttpClientBackend.dio,
    serializer: DtoSerializer.plain,
    responseMode: ResponseMode.firstSuccess,
    pageWidth: 80,
  ),
);
```

Pass a source URI and `loader` when the document has external references.
A per-call `parseConfig` applies to entry and reference parsing. Without that
override, each configured parser/resolver retains its constructor settings.
The core parser and normalizer do not read CLI files or download credentials.
For template text, inject `MustacheSourceRenderer` through `DartGenerator`.
