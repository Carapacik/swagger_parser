## 1.44.1

* Fixes `dart_mappable` enum generation for JSON Schema type lists by quoting
  non-numeric JSON values ([#468](https://github.com/Carapacik/swagger_parser/pull/468)).

## 1.44.0

* Adds `preserve_schema_casing` option to preserve original casing of schema-derived identifiers,
  defaults to `false` for backwards compatibility, which normalises to PascalCase.
* Fixes crash when a `multipart/form-data`request body references a schema without`properties`.
* Fixes nullable handling for single-element `allOf`, `oneOf`, and `anyOf` schemas with sibling
  `nullable: true`.
* Fixes missing imports for nested union properties in Freezed discriminated-union variants.

## 1.43.1

* Fixes escaping `$unknown`in generated enum`toJson` error messages.
* Fixes generated code when using `json_serializable`.
* Fixes default enum values for `dart_mappable`.
* Adds README section about Server-Sent Events.

## 1.43.0

* Allows standard dart_mappable serializer method naming convention.
* Fixes default values for Enums in forms.
* Fixes errors with corrector.

## 1.42.0

* Adds support for streaming & SSE.
* Fixes preserve property names and required modifiers in properties blocks.
* Fixes API path definitions are incorrectly converted to PascalCase.

## 1.41.0

* Adds `field_parsers` option for setting field parsers for JSON serializable.

## 1.40.0

* Adds `include_paths` option for filtering endpoints by paths.
* Adds `generate_urls_constants` option for generating URL constants for all endpoints.

## 1.39.1

* Fixes client methods returning `ModelNameUnion`instead of`ModelNameSealed` for oneOf types
  ([#393](https://github.com/Carapacik/swagger_parser/issues/393)).

## 1.39.0

* Handles request body name generation case when request body is declared within request.
* Fixes incorrect deserialization syntax for undiscriminated unions (Freezed serializer).

## 1.38.0

* Adds `replacement_rules_for_raw_schema` option for raw schema objects replacement rules.

## 1.37.1

* Fixes missing import for
  MultipartFile([#408](https://github.com/Carapacik/swagger_parser/issues/408)).
* Fixes refs in `components.responses`.

## 1.37.0

* Adds `use_flutter_compute` option for Flutter isolate-based multithreading support.
  * Generates `@RestApi(parser: Parser.FlutterCompute)` annotation in Retrofit clients.
  * Generates top-level serialization functions in each DTO model file following Retrofit's naming
    convention.
  * Works with all serializers: `freezed`, `json_serializable`, `dart_mappable`.
```yaml
swagger_parser:
  use_flutter_compute: true
```

## 1.36.0

* Adds `add_openapi_metadata`(default`false`) to generate OpenAPI `tags`, `operationId`, and
  `externalDocsUrl`constants for each endpoint; when`extras_parameter_by_default`is`true`, the
  metadata is also prefilled into Dio `extras`—handy for interceptors and logging without
  overwriting user-supplied extras.
* Uses fully-qualified default extras values (e.g. `BannerApi.findAllBannersOpenapiExtras`) so
  generated implementations can access the static metadata constants.
```
swagger_parser:
  extras_parameter_by_default: true
  add_openapi_metadata: true

abstract class PetsClient {
  static const Map<String, dynamic> listPetsOpenapiExtras =
      <String, dynamic>{
    'openapi': <String, dynamic>{
      'tags': <String>['pets'],
      'operationId': 'listPets',
      'externalDocsUrl': 'https://docs.example.com/pets',
    },
  };

  @GET('/pets')
  Future<void> listPets({
    // defaults to the OpenAPI metadata; merge with your own extras if needed
    @Extras() Map<String, dynamic>? extras =
        PetsClient.listPetsOpenapiExtras,
    @DioOptions() RequestOptions? options,
  });
}

# https://openapi.sepc/pets/listPets
```

## 1.35.2

* Fixes enum name values being an int returned in a toString.

## 1.35.1

* Fixes enum names generation.

## 1.35.0

* Adds `infer_required_from_nullable`.
```
infer_required_from_nullable: true

Schema without required array:
- id: type: integer → required int id
- name: type: string → required String name
- desc: type: string, nullable: true → String? desc
```
* Fixes nullable array item types generation.

## 1.34.0

* Adds `includeIfNull`handling, disabled by default; set`include_if_null: true` to enable it.

## 1.33.0

* Supports correct processing of nested allOf classes.

## 1.32.1

* Fixes CHANGELOG duplication.

## 1.32.0

* Adds complete support for sealed classes (`oneOf`/`anyOf`) with the `json_serializable`
  serializer.
  * **WARNING**: Undiscriminated sealed classes use O(n) try-catch deserialization where n is the
    number of variants.
  * **RECOMMENDED**: Adds discriminator properties to your OpenAPI specification for O(1)
    performance.
  * Adds support for sealed classes fallback for failed decoding.
* Adds complete support for sealed classes (`oneOf`/`anyOf`) with the `dart_mappable` serializer.
  * **WARNING**: Undiscriminated sealed classes use O(n) try-catch deserialization where n is the
    number of variants.
  * **RECOMMENDED**: Adds discriminator properties to your OpenAPI specification for O(1)
    performance.
  * Adds support for sealed classes fallback for failed decoding.
* Adds `dart_mappable_convenient_when`option to control union type generation for`dart_mappable`
  serializer.
  * `dart_mappable_convenient_when: true`generates legacy`when<T>, maybeWhen<T>` methods.
  * `dart_mappable_convenient_when: false` (default) generates sealed classes for better type
    safety.
* Adds the `@Deprecated()`annotation to the`when<T>`and`maybeWhen<T>` methods for
  `dart_mappable`; use Dart pattern matching instead.
* Fixes duplicate `unknown`enum values for`dart_mappable` when
  `unknown_enum_value: true` is enabled.
* Fixes nullable discriminator union handling.

## 1.30.1

* Fixes resolve inline schemas nested within tagged operations.

## 1.30.0

* Adds support for merging all generated code into single output file using the `merge_outputs`
  option.

## 1.29.0

### Features

* Adds support for non-discriminated unions (`oneOf`/`anyOf` without a discriminator).
* Filters out unused schemas when using `include_tags`or`exclude_tags`.

### Fixes

* Fixes the client name for untagged paths to properly fall back to the configured `fallback_client`
  instead of `client`.
* Fixes the `fallback_client`configuration to default to`fallback`instead of`default` to avoid
  conflicts with the Dart `default` keyword in the generated code.
* Fixes OpenAPI spec parsing to correctly preserve casing for `SCREAMING_SNAKE_CASE`.
* Fixes filtering so paths without tags are filtered out when `include_tags` is specified.

## 1.28.0

* Fixes documentation.
* Fixes ensure consistent file naming for tags with alphanumeric suffixes.

## 1.27.0

* Allows filtering generated client endpoints by tags.
* Adds a fallback client for endpoints without tags
  ([#271](https://github.com/Carapacik/swagger_parser/issues/271)).

## 1.26.4

* Allows single `MultipartFile`arguments in multipart requests; requires`retrofit_generator`
  10.0.1 or later.

## 1.26.3

* Fixes collisions between untagged endpoints and endpoints tagged `Client` that caused generated
  clients to overwrite each other.

## 1.26.2

* Aligns default value handling for parameters according to OpenAPi Spec
  https://swagger.io/docs/specification/v3_0/describing-parameters/#default-parameter-values.

## 1.26.1

* Adds a `toString`override for`dart_mappable`.
* Makes `dart_mappable` `toJson` return a string.

## 1.26.0

* Adds support for Freezed fallbackUnion parameter.

## 1.25.1

* Fixes broken dart_mappable enum.

## 1.25.0

* Allows using `MultipartFile`instead of`File` in multipart requests, to support usage on web.

## 1.24.6

* Handles binary responses, such as file downloads, based on
  [retrofit.dart#503](https://github.com/trevorwang/retrofit.dart/issues/503).

## 1.24.5

* Adds an enum `toString()` override that provides a JSON value to third-party consumers such as
  Retrofit.

## 1.24.4

* Adds the `$valuesDefined` getter to filter out unknown values automatically.

## 1.24.3

* Deduplicates property names for `allOf`schemas that mix`ref`and`properties`, preventing naming
  overlaps.

## 1.24.2

* Fixes `typedef`transparency that causes import errors when generating`json_serializable`
  classes; see
  [google/json_serializable#1124](https://github.com/google/json_serializable.dart/issues/1124).

## 1.24.1

* Removes duplicate parameters in
  dataclass([#322](https://github.com/Carapacik/swagger_parser/issues/322)).

## 1.24.0

* Fixes detection of nullable list with non-null items vs nullable list with nullable
  items([#323](https://github.com/Carapacik/swagger_parser/issues/323)).
* Requires Dart 3.6 or later.

## 1.23.2

* Fixes error with client parameters with
  `$`([#262](https://github.com/Carapacik/swagger_parser/issues/262)).

## 1.23.1

* Updates dart_mappable template.

## 1.23.0

* Adds support for allOf composition and xOf
  ([#239](https://github.com/Carapacik/swagger_parser/issues/239)).
* Fixes nullable handling ([#251](https://github.com/Carapacik/swagger_parser/issues/251)).
* Makes list with null in items nullable.

## 1.22.1

* Adds supports for freezed 3.

## 1.22.0

* Adds supports oneOf polymorphic types with dart_mappable
  ([#290](https://github.com/Carapacik/swagger_parser/issues/290)).

## 1.21.4

* Adds `x-enumNames`([#289](https://github.com/Carapacik/swagger_parser/pull/289)).
* Fixes errors with nullable in enums
  ([#216](https://github.com/Carapacik/swagger_parser/issues/216)).
* Fixes duplicate class generation when using discriminator
  ([#300](https://github.com/Carapacik/swagger_parser/issues/300)).

## 1.21.3

* Fixes errors with config([#293](https://github.com/Carapacik/swagger_parser/pull/293),
  [#296](https://github.com/Carapacik/swagger_parser/pull/296)).

## 1.21.2

* Adds `use_x_nullable` parameter to
  config([#295](https://github.com/Carapacik/swagger_parser/pull/295)).
* Fixes error with config([#296](https://github.com/Carapacik/swagger_parser/pull/296)).

## 1.21.1

* Fixes config properties inheritance with multi-scheme
  URLs([#293](https://github.com/Carapacik/swagger_parser/issues/293)).

## 1.21.0

* Adds support for union types
  `oneOf`([#265](https://github.com/Carapacik/swagger_parser/issues/265),
  [#286](https://github.com/Carapacik/swagger_parser/issues/265)).
* Fixes config property inheritance.

## 1.20.1

* Fixes errors with config parsing.

## 1.20.0

* Adds validation params to generated `freezed` classes.
* Fixes errors with empty schema
  properties([#280](https://github.com/Carapacik/swagger_parser/issues/280)).

## 1.19.2

* Fixes replacement rules for OpenAPI
  v2([#266](https://github.com/Carapacik/swagger_parser/issues/266)).
* Adds `x-nullable` field for null definition in OpenAPI
  v2([#268](https://github.com/Carapacik/swagger_parser/issues/268)).

## 1.19.1

* Fixes generation with `anyOf`, `oneOf`and`allOf`
  properties([#260](https://github.com/Carapacik/swagger_parser/issues/260)).

## 1.19.0

* Adds version getter to root client:
```dart
final version = RestClient.version;
```
* Adds `dio_options_parameter_by_default`.

## 1.18.3

* Removes support of BigInt in Dart for `int64` types.

## 1.18.2

* Adds support for `int64` types.

## 1.18.1

* Fixes errors with `nullable: false`.
* Fixes same property name conflict([#235](https://github.com/Carapacik/swagger_parser/issues/235)).

## 1.18.0

* Handles empty enum value case ([#238](https://github.com/Carapacik/swagger_parser/pull/238)).
* Fixes replacement rules.
* Adds support for nullable lists and maps.
* Removes the `required_by_default` config parameter; behavior now matches
  `required_by_default: false`.
* Requires Dart 3.4.

## 1.17.3

* Fixes unnecessary null types with `required_by_default: false`.
* Fixes generation of class parameters that are set directly from the request specification
  ([#224](https://github.com/Carapacik/swagger_parser/issues/224)).
* Fixes changing case and applying replacement rules to class names
  ([#223](https://github.com/Carapacik/swagger_parser/issues/223)).
* Generates maps with `additionalProperties` correctly
  ([#214](https://github.com/Carapacik/swagger_parser/issues/214)).

## 1.17.2

* Adds `MappableField` to dart_mappable template.

## 1.17.1

* Fixes error with nullable in multipart
  ([#211](https://github.com/Carapacik/swagger_parser/issues/211)).

## 1.17.0

* Adds new config parameter `extras_parameter_by_default` from [retrofit
  4.1.0](https://pub.dev/packages/retrofit/changelog#410) for
  ([#208](https://github.com/Carapacik/swagger_parser/issues/208)).
* Fixes errors ([#190](https://github.com/Carapacik/swagger_parser/issues/190)),
  ([#192](https://github.com/Carapacik/swagger_parser/issues/192)) and
  ([#195](https://github.com/Carapacik/swagger_parser/issues/195)).

## 1.16.4

* Fixes errors with `required_by_default`.

## 1.16.3

* Adds a temporary fix for
  [#110](https://github.com/Carapacik/swagger_parser/issues/110).
* Ignores parameters start with `x-` for
  ([#185](https://github.com/Carapacik/swagger_parser/issues/185)).
* Fixes parameter type ([#186](https://github.com/Carapacik/swagger_parser/issues/186).
* Fixes handle `$ref` ([#187](https://github.com/Carapacik/swagger_parser/issues/187)) and
  ([#183](https://github.com/Carapacik/swagger_parser/issues/183)).

## 1.16.2

* Adds new exceptions to export.
* Fixes file name from `schemeUrl`.

## 1.16.1

* Fixes swagger_parser_pages (https://carapacik.github.io/swagger_parser).

## 1.16.0

* Adds a wrapping collections variable that replaces `arrayDepth`and`mapType`; it stores and
  resolves all collections wrapping a type in their order of appearance
  ([#128](https://github.com/Carapacik/swagger_parser/issues/128)).
* Fixes error with `required_by_default`
  ([#168](https://github.com/Carapacik/swagger_parser/issues/168)).
* Refactors config and rename parameters:
    * `squash_clients`to`merge_clients`.
    * `enums_prefix`to`enums_parent_prefix`.
    * `skipp_parameters`to`skipped_parameters`.
* Removes config parameter `put_in_folder`.

## 1.15.5

* Supports schema url without extension
  ([#160](https://github.com/Carapacik/swagger_parser/issues/160)).

## 1.15.4

* Fixes docs.

## 1.15.3

* Fixes errors with `Object` body in retrofit client
  ([#110](https://github.com/Carapacik/swagger_parser/issues/110)).

## 1.15.2

* Fixes errors with enum names ([#163](https://github.com/Carapacik/swagger_parser/issues/163)),
  ([#164](https://github.com/Carapacik/swagger_parser/issues/164)).

## 1.15.1

* Adds support for generation multipart request with ref
  ([#154](https://github.com/Carapacik/swagger_parser/issues/154)).

## 1.15.0

* Adds new config parameter `required_by_default`.
* Adds template for E2E tests.

## 1.14.2

* Fixes errors with multipart ([#144](https://github.com/Carapacik/swagger_parser/issues/144)).

## 1.14.1

* Removes check that would avoid generating a map when additional properties has a `$ref` value.

## 1.14.0

* Fixes error with empty content type.
* Fixes retrofit template.
* Removes special characters from tags.
* Adds new config parameter `skip_parameters`.
* Extracts schemes from url ([#150](https://github.com/Carapacik/swagger_parser/issues/150)).

## 1.13.1

* Fixes error with path-level parameters cause crash
  ([#147](https://github.com/Carapacik/swagger_parser/issues/147)).
* Fixes `dart:io` import in template.

## 1.13.0

* Adds support for [dart_mappable](https://pub.dev/packages/dart_mappable).
* Changes `freezed`schema property to`json_serializer`, which can be set to `freezed`,
  `dart_mappable`or`json_serializable` (default).
* Fixes enum generation name that are defined inside an array.

## 1.12.2

* Fixes enum duplicate names ([#140](https://github.com/Carapacik/swagger_parser/issues/140)).

## 1.12.1

* Fixes error with `ref` in a case other than PascalCase
  ([#139](https://github.com/Carapacik/swagger_parser/issues/139)).

## 1.12.0

* Adds new config parameter `export_file`.

## 1.11.3

* Fixes error with annotating client methods with the first specified content type header in OpenAPI
  V2 schemes if the specified one is not the default.

## 1.11.2

* Adds description of request parameters to the code docs.

## 1.11.1

* Fixes ref component being wrongly labeled as map.
* Fixes map components being assigned an import despite not needing one.

## 1.11.0

* Adds unknown value to all enums to maintain backwards compatibility when adding new values on the
  backend.
* Adds new config parameter `unknown_enum_value` (dart only)
  ([#106](https://github.com/Carapacik/swagger_parser/issues/106)).
* Adds new config parameter `default_content_type`.
* Supports String values with spaces for enums
  ([#127](https://github.com/Carapacik/swagger_parser/issues/127)).

## 1.10.6

* Fixes map objects parsing as separate entities
  ([#124](https://github.com/Carapacik/swagger_parser/issues/124)).

## 1.10.5

* Fixes error with parsing dictionary objects
  ([#113](https://github.com/Carapacik/swagger_parser/issues/113)).

## 1.10.4

* Fixes error with `additionalProperties`
  ([#114](https://github.com/Carapacik/swagger_parser/issues/114)).

## 1.10.3

* Adds new config parameter `original_http_response` (dart only)
  ([#115](https://github.com/Carapacik/swagger_parser/issues/115)).

## 1.10.2

* Fixes error in `body` with name in dart template.

## 1.10.1

* Fixes error with query parameter named `body`
  ([#108](https://github.com/Carapacik/swagger_parser/issues/108)).

## 1.10.0

* Adds support for generating schemas by URL (see the [example](example/swagger_parser.yaml)).
* Adds new config parameter `schema_url`.
* Adds new config parameter `schema_from_url_to_file`.
* Adds new config parameter `prefer_schema_source`.

## 1.9.2

* Fixes error with `required` in clients
  ([#101](https://github.com/Carapacik/swagger_parser/issues/103)).

## 1.9.1

* Handles invalid names for classes, enums, and methods.
* Adds a name for unnamed models
  ([#98](https://github.com/Carapacik/swagger_parser/issues/98)).
* Adds support for `deprecated` annotations for methods.

## 1.9.0

* Adds display of generation statistics for each scheme and total.
* Changes the generation command to `dart run swagger_parser`.
* Fixes error with `required` params in unnamed classes
  ([#98](https://github.com/Carapacik/swagger_parser/issues/98)).
* Fixes error with missing `File` import
  ([#101](https://github.com/Carapacik/swagger_parser/issues/101)).

## 1.8.0

* Adds support for multiple schemas (see the [example](example/swagger_parser.yaml)).
* Adds support for specifying nullable types via anyOf.
* Edits root client template.
* Adds new config parameter `root_client_name`.
* Adds new config parameter `name`.
* Adds new config parameter `put_in_folder`.
* Adds new config parameter `squash_clients`.
* Renames `root_interface`to`root_client`.
* Renames `squish_clients`to`put_clients_in_folder`.

## 1.7.0

* Adds new config parameter `mark_files_as_generated`.
* Adds support for default values for ref enum types.
* Adds type support for single-element `allOf`, `anyOf`, and `oneOf` schemas.

## 1.6.3

* Fixes error with `allOf`results in the schema with type`object`
  ([#91](https://github.com/Carapacik/swagger_parser/issues/91)).

## 1.6.2

* Fixes grouping words for abbreviations when special characters are present.
* Fixes replacement type for enum classes.
* Preserves casing in replacements.

## 1.6.1

* Adds summary of the methods to the code docs.
* Fixes indents for multiline code docs.
* Adds support for root client code docs.

## 1.6.0

* Adds new config parameter `path_method_name`.

## 1.5.3

* Fixes error with imports in dto component
  ([#86](https://github.com/Carapacik/swagger_parser/issues/86)).

## 1.5.2

* Fixes grouping words for acronyms and abbreviations
  ([#85](https://github.com/Carapacik/swagger_parser/issues/85)).

## 1.5.1

* Fixes method name generation in a language other than English
  ([#83](https://github.com/Carapacik/swagger_parser/issues/83)).

## 1.5.0

* Requires Dart 3.0 or later.

## 1.4.0

* Makes values nullable and optional by default when processing default values
  ([#76](https://github.com/Carapacik/swagger_parser/issues/76)).
* Adds support for common parameters for various paths
  ([#78](https://github.com/Carapacik/swagger_parser/issues/78)).

## 1.3.5

* Fixes default enum values in dto ([#79](https://github.com/Carapacik/swagger_parser/issues/79)).

## 1.3.4

* Applies enum prefixes only to variable types.

## 1.3.3

* Fixes error with unnamed classes uniques names
  ([#74](https://github.com/Carapacik/swagger_parser/issues/74)).

## 1.3.2

* Fixes error with replacement rules in allOf.

## 1.3.1

* Fixes error with allOf ([#72](https://github.com/Carapacik/swagger_parser/issues/72)).

## 1.3.0

* Adds possibility to add enum prefix from parent component
  ([#29](https://github.com/Carapacik/swagger_parser/issues/29)). Change `enums_prefix` to true to
  enable this option.

## 1.2.4

* Fixes names for negative enum values.

## 1.2.3

* Fixes rename for enums ([#69](https://github.com/Carapacik/swagger_parser/issues/69)).

## 1.2.2

* Fixes error with parse nullable item in array
  ([#68](https://github.com/Carapacik/swagger_parser/issues/68)).

## 1.2.1

* Updates `retrofit_generator` dependency to
  [7.0.8](https://github.com/trevorwang/retrofit.dart/releases/tag/7.0.8) and added config option to
  generate `.toJson()` methods in enums (`retrofit_generator`will use`.toJson()` instead of
  `.name` in this case).

## 1.2.0

* Updates `retrofit_generator` dependency to
  [7.0.7](https://github.com/trevorwang/retrofit.dart/releases/tag/7.0.7) and consequently removed
  unused `.toJson()` generated methods in enums.

## 1.1.0

* Adds regex replacement for generated class names.
* Fixes error with null raw parameter in OpenApi v2
  ([#63](https://github.com/Carapacik/swagger_parser/issues/63)).

## 1.0.7

* Fixes classes as body parameters ([#61](https://github.com/Carapacik/swagger_parser/issues/61)).

## 1.0.6

* Fixes generation default enum values
  ([#58](https://github.com/Carapacik/swagger_parser/issues/58)).
* Adds new keywords to check the name of variables.

## 1.0.5

* Fixes generation default enum values in client
  ([#56](https://github.com/Carapacik/swagger_parser/issues/56)).

## 1.0.4

* Fixes parsing `Body` in OpenApi v2
  ([#53](https://github.com/Carapacik/swagger_parser/issues/53)).
* Adds multiline comments ([#54](https://github.com/Carapacik/swagger_parser/issues/54)).
* Fixes items name in enum generation
  ([#55](https://github.com/Carapacik/swagger_parser/issues/55)).

## 1.0.3

* Fixes error with default value in `json_serializable` generation.

## 1.0.2

* Fixes error with `application/x-www-form-urlencoded`
  ([#45](https://github.com/Carapacik/swagger_parser/issues/45)).

## 1.0.1

* Fixes error with `nullable` in array
  ([#43](https://github.com/Carapacik/swagger_parser/issues/43)).

## 1.0.0+1

* Adds `root_interface` option to [web interface](https://carapacik.github.io/swagger_parser).
* Adds topics.

## 1.0.0

* Requires Dart >= 2.19.
* Adds support for `description` annotation.
* Adds `root_interface` option to generate root interface for all Clients.
* Refactors code related to `nullable`.

## 0.10.3

* Uses `ref`to identify a client method's return type when`type` is also present.

## 0.10.2

* `defaultValue` in dart class now generates in constructor.
* Fixes error with empty `client_postfix`.

## 0.10.1

* Fixes error with `servers` in requests
  ([#32](https://github.com/Carapacik/swagger_parser/issues/32)).
* Uses `operationId` for method name(if such a field exists).

## 0.10.0

* Fixes error with `enum` values not parsed in object properties.
* Uses 2xx codes if code 200 not found.
* `nullable` types are now supported.

## 0.9.1

* Uses `JsonEnum` and `JsonValue` on generated enum.

## 0.9.0

* Defines single-reference sibling elements as typedefs instead of generating unnecessary classes.
* Fixes error with `Null` type with empty type in schema.

## 0.8.1

* Adds DateTime to the format for processing types
  ([#16](https://github.com/Carapacik/swagger_parser/issues/16)).

## 0.8.0

* Adds support for dio 5.
* Downgrades the lower bound of dependencies to support Flutter 3.0.
* Completes templates for Kotlin.

## 0.7.0

* Fixes error with import for `File` type.
* Adds support for `additionalProperties` annotations.
* Fixes templates.
* Fixes error with YAML files.

## 0.6.4

* Updates example.
* Removes `implicit_dynamic` field for analyzer.

## 0.6.3

* Fixes error with return type in rest client.

## 0.6.2

* Updates docs.

## 0.6.1

* Fixes error with Multipart file type in retrofit.
* Updates dart api docs.
* Updates web interface.

## 0.6.0

* Adds support for `yaml` files.
* **BREAKING CHANGE**: Renames `json_path`in`pubspec.yaml`to`schema_path`.

## 0.5.1

* Fixes problem with default value in freezed template.

## 0.5.0

* Recognizes objects and generates them as DTOs.
* Fixes some problems with defaultValue.
* Fixes some problems with return type.
* Fixes some problems with naming parameters whose names are similar to dart keywords.

## 0.4.1

* Fixes a problem with parameters whose names are similar to dart keywords.
* Fixes a problem with postfix in file import.

## 0.4.0

* Adds support for `default` annotations.
* Adds enum support for dart.
* Fixes errors with Multipart.
* Fixes errors with Kotlin types.

## 0.3.1

* Fixes error with `@` in url path.
* Fixes the problem with `number` type to map `double`.
* Fixes the problem with `object` type to map Dart `Object`.
* Updates the README with instructions and steps to generate the code.

## 0.3.0

* Adds support for `required` annotations.
* Fixes error with rest client parameters type in OpenApi v2.

## 0.2.4

* Fixes error with `.` and `,` in url path.

## 0.2.3

* Fixes error in MultiPart with single `$ref`.

## 0.2.2

* Removes swagger_parser section from pubspec.yaml.
* Updates dependencies in example.

## 0.2.1

* Fixes README.
* Fixes workflow files.

## 0.2.0

* Fixes errors with generation of data classes containing `allOf`.
* Fixes errors with templates.
* Adds web interface for package https://carapacik.github.io/swagger_parser.
* Adds generator tests.

## 0.1.0

* Marks the initial release.
