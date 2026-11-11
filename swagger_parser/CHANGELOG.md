# Changelog

## Unreleased

* Uses Freezed for all data model classes when selected, including value wrappers,
  `oneOf` variants, `anyOf` models, tuples, unknown values, and typed HTTP results.
  Fixes value equality for primitive union variants
  ([#488](https://github.com/Carapacik/swagger_parser/issues/488)).

## 2.1.0

* Adds `unmatched_union_values` to preserve unmatched `oneOf` and `anyOf` values
  as immutable JSON. Defaults to `reject`
  ([#487](https://github.com/Carapacik/swagger_parser/issues/487)).
* Fixes single-reference `allOf` properties with `default` or `nullable` losing
  their referenced enum types ([#485](https://github.com/Carapacik/swagger_parser/issues/485)).
* Preserves `type` and `part` as field, parameter, and method names
  ([#486](https://github.com/Carapacik/swagger_parser/issues/486)).

## 2.0.1

* Fixes single-reference `allOf` properties with descriptions generating duplicate models
  and losing enum types ([#479](https://github.com/Carapacik/swagger_parser/issues/479)).
* Fixes negative numeric enum names losing their sign
  ([#480](https://github.com/Carapacik/swagger_parser/issues/480)).
* Fixes duplicate enum values generating distinct members for the same JSON value
  ([#481](https://github.com/Carapacik/swagger_parser/issues/481)).
* Defaults `infer_missing_required` to `false`. Set it to `true` to infer required
  non-nullable fields without defaults when `required` is absent
  ([#482](https://github.com/Carapacik/swagger_parser/issues/482)).
* Fixes `first_success` decoding declared bodyless success responses as payloads.
  Buffered return types become nullable when a bodyless success is declared.
  Handle `null` after regenerating affected clients
  ([#483](https://github.com/Carapacik/swagger_parser/issues/483)).
* Adds regression tests, generated-file e2e cases, runnable examples, and public API documentation.

## 2.0.0

* Rebuilds parsing in `swagger_parser_core` for Swagger 2.0 and OpenAPI 3.0–3.2.
* Adds plain Dart JSON codecs alongside `json_serializable`, Freezed, and `dart_mappable`.
* Adds standalone Dio and `package:http` clients alongside Retrofit + Dio.
* Adds typed status results, JSON Lines, and streaming downloads. Retains SSE.
* Adds request/response models, custom type codecs, and optional DTO validation.
* Rebuilds Pages with JSON/YAML file input, config editing, templates, and ZIP output.
* **BREAKING CHANGES**:
  * Requires Dart **^3.13.0**. Update the Dart SDK before upgrading.
  * Replaces v1 configuration. Migrate settings with the
    [configuration reference](CONFIGURATION.md).
  * Moves custom templates and helper files to `swagger_parser_templates`.
    Use its [package and CLI](../swagger_parser_templates/README.md) for custom output.
  * Removes Kotlin generation. Use a generator with a Kotlin backend for Kotlin output.
  * Removes single-file output. Import the generated API entry point to access models and clients.
  * Removes DTO output without serialization. Use custom templates for that output.

## 1.46.0

* Adds `freezed_nullable_presence` (default `false`) to generate a `<name>Present` flag
  for each optional nullable property of Freezed models, so `toJson` can tell an omitted
  key from an explicit `null`, for example to clear a field in a PATCH request body
  ([#477](https://github.com/Carapacik/swagger_parser/issues/477)).

## 1.45.1

* Fixes OpenAPI 3 schemas without a `required` array generating every property as `required`
  when any property uses `allOf`
  ([#460](https://github.com/Carapacik/swagger_parser/issues/460)).

## 1.45.0

* Adds `freezed_json_serialization` (default `true`) to generate Freezed models
  without `.g.dart` and `fromJson` when JSON serialization is not needed.
  Existing JSON-enabled generation remains the default
  ([#473](https://github.com/Carapacik/swagger_parser/issues/473)).
* Documents Freezed 4 and current code generation dependency versions.

## 1.44.3

* Fixes `infer_required_from_nullable` treating OpenAPI 3.1 type lists containing `"null"`
  as non-nullable, which generated them as `required T?`
  ([#472](https://github.com/Carapacik/swagger_parser/pull/472)).

## 1.44.2

* Fixes schema filtering for component schemas referenced by endpoint parameters
  ([#470](https://github.com/Carapacik/swagger_parser/pull/470)).

## 1.44.1

* Fixes `dart_mappable` enum generation for JSON Schema type lists by quoting
  non-numeric JSON values ([#468](https://github.com/Carapacik/swagger_parser/pull/468)).

## 1.44.0

* Adds `preserve_schema_casing` option to preserve original casing of schema-derived identifiers,
  defaults to `false` for backward compatibility, which normalises to PascalCase.
* Fixes crash when a `multipart/form-data` request body references a schema without `properties`.
* Fixes nullable handling for single-element `allOf`, `oneOf`, and `anyOf` schemas with sibling
  `nullable: true`.
* Fixes missing imports for nested union properties in Freezed discriminated-union variants.

## 1.43.1

* Fixes escaping `$unknown` in generated enum `toJson` error messages.
* Fixes generated code when using `json_serializable`.
* Fixes default enum values for `dart_mappable`.
* Adds README section about Server-Sent Events.

## 1.43.0

* Supports standard `dart_mappable` serializer method names.
* Fixes default enum values in forms.
* Fixes name correction errors.

## 1.42.0

* Adds support for streaming and SSE.
* Preserves property names and `required` modifiers in `properties` blocks.
* Fixes API paths incorrectly converted to PascalCase.

## 1.41.0

* Adds `field_parsers` option for field parsers in `json_serializable`.

## 1.40.0

* Adds `include_paths` option for filtering endpoints by paths.
* Adds `generate_urls_constants` option for generating URL constants for all endpoints.

## 1.39.1

* Fixes client methods returning `ModelNameUnion` instead of `ModelNameSealed` for `oneOf` types
  ([#393](https://github.com/Carapacik/swagger_parser/issues/393)).

## 1.39.0

* Handles names for request bodies declared inline.
* Fixes deserialization syntax for Freezed unions without a discriminator.

## 1.38.0

* Adds `replacement_rules_for_raw_schema` option for raw schema objects replacement rules.

## 1.37.1

* Fixes missing import for
  `MultipartFile` ([#408](https://github.com/Carapacik/swagger_parser/issues/408)).
* Fixes references in `components.responses`.

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

* Adds `add_openapi_metadata` (default `false`) to generate OpenAPI `tags`, `operationId`, and
  `externalDocsUrl` constants for each endpoint; when `extras_parameter_by_default` is `true`, the
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

* Fixes `toString` returning an `int` for enum names.

## 1.35.1

* Fixes enum name generation.

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

* Adds `includeIfNull` handling, disabled by default; set `include_if_null: true` to enable it.

## 1.33.0

* Handles nested `allOf` classes.

## 1.32.1

* Fixes duplicate changelog entries.

## 1.32.0

* Adds sealed classes for `oneOf` and `anyOf` with `json_serializable` and `dart_mappable`.
  Uses O(n) try-catch decoding without a discriminator, where n is the number of variants.
  Use a discriminator for O(1) dispatch. Supports fallback variants when decoding fails.
* Adds `dart_mappable_convenient_when` for `dart_mappable` unions.
  Generates `when<T>` and `maybeWhen<T>` when `true`.
  Generates sealed classes when `false` (the default).
* Deprecates `when<T>` and `maybeWhen<T>` with `@Deprecated()` for `dart_mappable`.
  Use Dart pattern matching instead.
* Fixes duplicate `unknown` enum values with `dart_mappable` and `unknown_enum_value: true`.
* Fixes nullable discriminator union handling.

## 1.30.1

* Fixes resolution of inline schemas in tagged operations.

## 1.30.0

* Adds support for merging all generated code into single output file using the `merge_outputs`
  option.

## 1.29.0

* Adds support for non-discriminated unions (`oneOf`/`anyOf` without a discriminator).
* Filters out unused schemas when using `include_tags` or `exclude_tags`.

* Fixes the client name for untagged paths to properly fall back to the configured `fallback_client`
  instead of `client`.
* Fixes the `fallback_client` configuration to default to `fallback` instead of `default` to avoid
  conflicts with the Dart `default` keyword in the generated code.
* Fixes OpenAPI spec parsing to correctly preserve casing for `SCREAMING_SNAKE_CASE`.
* Fixes filtering so paths without tags are filtered out when `include_tags` is specified.

## 1.28.0

* Fixes documentation.
* Fixes file names for tags with alphanumeric suffixes.

## 1.27.0

* Allows filtering generated client endpoints by tags.
* Adds a fallback client for endpoints without tags
  ([#271](https://github.com/Carapacik/swagger_parser/issues/271)).

## 1.26.4

* Allows single `MultipartFile` arguments in multipart requests; requires `retrofit_generator`
  10.0.1 or later.

## 1.26.3

* Fixes collisions between untagged endpoints and endpoints tagged `Client` that caused generated
  clients to overwrite each other.

## 1.26.2

* Aligns default value handling for parameters according to the OpenAPI specification:
  https://swagger.io/docs/specification/v3_0/describing-parameters/#default-parameter-values.

## 1.26.1

* Adds a `toString` override for `dart_mappable`.
* **BREAKING CHANGE**: Makes `dart_mappable` `toJson` return a string.
  Use the returned JSON string instead of a map.

## 1.26.0

* Adds support for the Freezed `fallbackUnion` parameter.

## 1.25.1

* Fixes `dart_mappable` enum generation.

## 1.25.0

* Allows using `MultipartFile` instead of `File` in multipart requests, to support usage on web.

## 1.24.6

* Handles binary responses, such as file downloads, based on
  [retrofit.dart#503](https://github.com/trevorwang/retrofit.dart/issues/503).

## 1.24.5

* Adds an enum `toString()` override that provides a JSON value to third-party consumers such as
  Retrofit.

## 1.24.4

* Adds the `$valuesDefined` getter to filter out unknown values automatically.

## 1.24.3

* Deduplicates property names for `allOf` schemas that mix `ref` and `properties`, preventing naming
  overlaps.

## 1.24.2

* Fixes `typedef` imports when generating `json_serializable`
  classes; see
  [google/json_serializable#1124](https://github.com/google/json_serializable.dart/issues/1124).

## 1.24.1

* Removes duplicate parameters in
  data classes ([#322](https://github.com/Carapacik/swagger_parser/issues/322)).

## 1.24.0

* Fixes detection of nullable list with non-null items vs nullable list with nullable
  items ([#323](https://github.com/Carapacik/swagger_parser/issues/323)).
* **BREAKING CHANGE**: Requires Dart 3.6 or later. Update the Dart SDK before upgrading.

## 1.23.2

* Fixes error with client parameters with
  `$` ([#262](https://github.com/Carapacik/swagger_parser/issues/262)).

## 1.23.1

* Updates the `dart_mappable` template.

## 1.23.0

* Adds support for `allOf` and other schema compositions
  ([#239](https://github.com/Carapacik/swagger_parser/issues/239)).
* Fixes nullable handling ([#251](https://github.com/Carapacik/swagger_parser/issues/251)).
* Makes lists with null items nullable.

## 1.22.1

* Adds support for Freezed 3.

## 1.22.0

* Adds support for `oneOf` polymorphic types with `dart_mappable`
  ([#290](https://github.com/Carapacik/swagger_parser/issues/290)).

## 1.21.4

* Adds `x-enumNames` ([#289](https://github.com/Carapacik/swagger_parser/pull/289)).
* Fixes errors with nullable in enums
  ([#216](https://github.com/Carapacik/swagger_parser/issues/216)).
* Fixes duplicate class generation when using discriminator
  ([#300](https://github.com/Carapacik/swagger_parser/issues/300)).

## 1.21.3

* Fixes errors with config ([#293](https://github.com/Carapacik/swagger_parser/pull/293),
  [#296](https://github.com/Carapacik/swagger_parser/pull/296)).

## 1.21.2

* Adds `use_x_nullable` parameter to
  config ([#295](https://github.com/Carapacik/swagger_parser/pull/295)).
* Fixes error with config ([#296](https://github.com/Carapacik/swagger_parser/pull/296)).

## 1.21.1

* Fixes config properties inheritance with multi-scheme
  URLs ([#293](https://github.com/Carapacik/swagger_parser/issues/293)).

## 1.21.0

* Adds support for union types
  `oneOf` ([#265](https://github.com/Carapacik/swagger_parser/issues/265),
  [#286](https://github.com/Carapacik/swagger_parser/issues/265)).
* Fixes config property inheritance.

## 1.20.1

* Fixes errors with config parsing.

## 1.20.0

* Adds validation parameters to generated Freezed classes.
* Fixes errors with empty schema
  properties ([#280](https://github.com/Carapacik/swagger_parser/issues/280)).

## 1.19.2

* Fixes replacement rules for OpenAPI
  v2 ([#266](https://github.com/Carapacik/swagger_parser/issues/266)).
* Adds `x-nullable` field for null definition in OpenAPI
  v2 ([#268](https://github.com/Carapacik/swagger_parser/issues/268)).

## 1.19.1

* Fixes generation with `anyOf`, `oneOf` and `allOf`
  properties ([#260](https://github.com/Carapacik/swagger_parser/issues/260)).

## 1.19.0

* Adds a version getter to the root client.

```dart

final version = RestClient.version;
```

* Adds `dio_options_parameter_by_default`.

## 1.18.3

* **BREAKING CHANGE**: Maps `int64` to `int` instead of `BigInt`. Update callers to use `int`.

## 1.18.2

* Adds support for `int64` types.

## 1.18.1

* Fixes errors with `nullable: false`.
* Fixes same property name conflict
  ([#235](https://github.com/Carapacik/swagger_parser/issues/235)).

## 1.18.0

* Handles empty enum value case ([#238](https://github.com/Carapacik/swagger_parser/pull/238)).
* Fixes replacement rules.
* Adds support for nullable lists and maps.
* **BREAKING CHANGES**:
  * Removes `required_by_default`. Remove it from config; behavior matches `false`.
  * Requires Dart 3.4. Update the Dart SDK before upgrading.

## 1.17.3

* Fixes unnecessary null types with `required_by_default: false`.
* Fixes generation of class parameters that are set directly from the request specification
  ([#224](https://github.com/Carapacik/swagger_parser/issues/224)).
* Fixes changing case and applying replacement rules to class names
  ([#223](https://github.com/Carapacik/swagger_parser/issues/223)).
* Generates maps with `additionalProperties` correctly
  ([#214](https://github.com/Carapacik/swagger_parser/issues/214)).

## 1.17.2

* Adds `MappableField` to the `dart_mappable` template.

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
* Ignores parameters that start with `x-`
  ([#185](https://github.com/Carapacik/swagger_parser/issues/185)).
* Fixes parameter types ([#186](https://github.com/Carapacik/swagger_parser/issues/186)).
* Fixes `$ref` handling ([#187](https://github.com/Carapacik/swagger_parser/issues/187)) and
  ([#183](https://github.com/Carapacik/swagger_parser/issues/183)).

## 1.16.2

* Exports new exceptions.
* Fixes file names derived from `schemeUrl`.

## 1.16.1

* Fixes the [web interface](https://carapacik.github.io/swagger_parser).

## 1.16.0

* Adds a wrapping collections variable that replaces `arrayDepth` and `mapType`; it stores and
  resolves all collections wrapping a type in their order of appearance
  ([#128](https://github.com/Carapacik/swagger_parser/issues/128)).
* Fixes error with `required_by_default`
  ([#168](https://github.com/Carapacik/swagger_parser/issues/168)).
* **BREAKING CHANGES**:
  * Renames config keys. Replace `squash_clients` with `merge_clients`,
    `enums_prefix` with `enums_parent_prefix`, and `skipp_parameters` with `skipped_parameters`.
  * Removes `put_in_folder`. Remove this key from config.

## 1.15.5

* Supports schema URLs without a file extension
  ([#160](https://github.com/Carapacik/swagger_parser/issues/160)).

## 1.15.4

* Fixes documentation.

## 1.15.3

* Fixes `Object` request bodies in Retrofit clients
  ([#110](https://github.com/Carapacik/swagger_parser/issues/110)).

## 1.15.2

* Fixes errors with enum names ([#163](https://github.com/Carapacik/swagger_parser/issues/163)),
  ([#164](https://github.com/Carapacik/swagger_parser/issues/164)).

## 1.15.1

* Adds support for multipart requests with references
  ([#154](https://github.com/Carapacik/swagger_parser/issues/154)).

## 1.15.0

* Adds new config parameter `required_by_default`.
* Adds a template for end-to-end tests.

## 1.14.2

* Fixes errors with multipart ([#144](https://github.com/Carapacik/swagger_parser/issues/144)).

## 1.14.1

* Removes check that would avoid generating a map when additional properties has a `$ref` value.

## 1.14.0

* Fixes error with empty content type.
* Fixes the Retrofit template.
* Removes special characters from tags.
* Adds new config parameter `skip_parameters`.
* Extracts schemas from URLs ([#150](https://github.com/Carapacik/swagger_parser/issues/150)).

## 1.13.1

* Fixes a crash with path-level parameters
  ([#147](https://github.com/Carapacik/swagger_parser/issues/147)).
* Fixes `dart:io` import in template.

## 1.13.0

* Adds support for [dart_mappable](https://pub.dev/packages/dart_mappable).
* **BREAKING CHANGE**: Replaces the `freezed` config key with `json_serializer`.
  Set `json_serializer` to `freezed`, `dart_mappable`, or `json_serializable` (the default).
* Fixes names for enums defined inside arrays.

## 1.12.2

* Fixes enum duplicate names ([#140](https://github.com/Carapacik/swagger_parser/issues/140)).

## 1.12.1

* Fixes error with `ref` in a case other than PascalCase
  ([#139](https://github.com/Carapacik/swagger_parser/issues/139)).

## 1.12.0

* Adds new config parameter `export_file`.

## 1.11.3

* Fixes client annotations for non-default content types in Swagger 2.0 schemas.

## 1.11.2

* Adds description of request parameters to the code docs.

## 1.11.1

* Fixes referenced components incorrectly classified as maps.
* Removes unused imports for map components.

## 1.11.0

* Adds unknown value to all enums to maintain backward compatibility when adding new values on the
  backend.
* Adds new config parameter `unknown_enum_value` (Dart only)
  ([#106](https://github.com/Carapacik/swagger_parser/issues/106)).
* Adds new config parameter `default_content_type`.
* Supports `String` enum values with spaces
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

* Adds new config parameter `original_http_response` (Dart only)
  ([#115](https://github.com/Carapacik/swagger_parser/issues/115)).

## 1.10.2

* Fixes named `body` parameters in the Dart template.

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

* Adds per-schema and total generation statistics.
* **BREAKING CHANGE**: Changes the generation command. Use `dart run swagger_parser`.
* Fixes error with `required` params in unnamed classes
  ([#98](https://github.com/Carapacik/swagger_parser/issues/98)).
* Fixes error with missing `File` import
  ([#101](https://github.com/Carapacik/swagger_parser/issues/101)).

## 1.8.0

* Adds support for multiple schemas (see the [example](example/swagger_parser.yaml)).
* Adds support for nullable types through `anyOf`.
* Updates the root client template.
* Adds new config parameter `root_client_name`.
* Adds new config parameter `name`.
* Adds new config parameter `put_in_folder`.
* Adds new config parameter `squash_clients`.
* **BREAKING CHANGES**:
  * Renames `root_interface` to `root_client`. Update this key in config.
  * Renames `squish_clients` to `put_clients_in_folder`. Update this key in config.

## 1.7.0

* Adds new config parameter `mark_files_as_generated`.
* Adds support for default values for ref enum types.
* Adds type support for single-element `allOf`, `anyOf`, and `oneOf` schemas.

## 1.6.3

* Fixes error with `allOf` results in the schema with type `object`
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

* Fixes imports in DTO components
  ([#86](https://github.com/Carapacik/swagger_parser/issues/86)).

## 1.5.2

* Fixes grouping words for acronyms and abbreviations
  ([#85](https://github.com/Carapacik/swagger_parser/issues/85)).

## 1.5.1

* Fixes method name generation in a language other than English
  ([#83](https://github.com/Carapacik/swagger_parser/issues/83)).

## 1.5.0

* **BREAKING CHANGE**: Requires Dart 3.0 or later. Update the Dart SDK before upgrading.

## 1.4.0

* Makes values nullable and optional by default when processing default values
  ([#76](https://github.com/Carapacik/swagger_parser/issues/76)).
* Adds support for common parameters for various paths
  ([#78](https://github.com/Carapacik/swagger_parser/issues/78)).

## 1.3.5

* Fixes default enum values in DTOs ([#79](https://github.com/Carapacik/swagger_parser/issues/79)).

## 1.3.4

* Applies enum prefixes only to variable types.

## 1.3.3

* Fixes unique names for unnamed classes
  ([#74](https://github.com/Carapacik/swagger_parser/issues/74)).

## 1.3.2

* Fixes replacement rules in `allOf`.

## 1.3.1

* Fixes `allOf` handling ([#72](https://github.com/Carapacik/swagger_parser/issues/72)).

## 1.3.0

* Adds possibility to add enum prefix from parent component
  ([#29](https://github.com/Carapacik/swagger_parser/issues/29)). Change `enums_prefix` to true to
  enable this option.

## 1.2.4

* Fixes names for negative enum values.

## 1.2.3

* Fixes enum renaming ([#69](https://github.com/Carapacik/swagger_parser/issues/69)).

## 1.2.2

* Fixes parsing of nullable array items
  ([#68](https://github.com/Carapacik/swagger_parser/issues/68)).

## 1.2.1

* Updates `retrofit_generator` dependency to
  [7.0.8](https://github.com/trevorwang/retrofit.dart/releases/tag/7.0.8) and adds a config option
  to generate `.toJson()` methods in enums (`retrofit_generator` will use `.toJson()` instead of
  `.name` in this case).

## 1.2.0

* Updates `retrofit_generator` dependency to
  [7.0.7](https://github.com/trevorwang/retrofit.dart/releases/tag/7.0.7) and removes
  unused `.toJson()` generated methods in enums.

## 1.1.0

* Adds regex replacement for generated class names.
* Fixes null raw parameters in Swagger 2.0
  ([#63](https://github.com/Carapacik/swagger_parser/issues/63)).

## 1.0.7

* Fixes classes as body parameters ([#61](https://github.com/Carapacik/swagger_parser/issues/61)).

## 1.0.6

* Fixes generation of default enum values
  ([#58](https://github.com/Carapacik/swagger_parser/issues/58)).
* Adds new keywords to check the name of variables.

## 1.0.5

* Fixes generation of default enum values in client
  ([#56](https://github.com/Carapacik/swagger_parser/issues/56)).

## 1.0.4

* Fixes parsing of `Body` in Swagger 2.0
  ([#53](https://github.com/Carapacik/swagger_parser/issues/53)).
* Adds multiline comments ([#54](https://github.com/Carapacik/swagger_parser/issues/54)).
* Fixes enum item names
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

* **BREAKING CHANGE**: Requires Dart 2.19 or later. Update the Dart SDK before upgrading.
* Adds support for `description` annotation.
* Adds `root_interface` to generate a root interface for all clients.
* Refactors code related to `nullable`.

## 0.10.3

* Uses `ref` to identify a client method's return type when `type` is also present.

## 0.10.2

* Generates `defaultValue` in the Dart class constructor.
* Fixes error with empty `client_postfix`.

## 0.10.1

* Fixes error with `servers` in requests
  ([#32](https://github.com/Carapacik/swagger_parser/issues/32)).
* Uses `operationId` for method names when the field exists.

## 0.10.0

* Fixes error with `enum` values not parsed in object properties.
* Uses other 2xx codes when a 200 response is absent.
* Adds support for `nullable` types.

## 0.9.1

* Uses `JsonEnum` and `JsonValue` on generated enum.

## 0.9.0

* Defines single-reference sibling elements as typedefs instead of generating unnecessary classes.
* Fixes error with `Null` type with empty type in schema.

## 0.8.1

* Adds `DateTime` format support
  ([#16](https://github.com/Carapacik/swagger_parser/issues/16)).

## 0.8.0

* Adds support for Dio 5.
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

* Updates documentation.

## 0.6.1

* Fixes multipart file types in Retrofit.
* Updates Dart API documentation.
* Updates web interface.

## 0.6.0

* Adds support for `yaml` files.
* **BREAKING CHANGE**: Renames `json_path` to `schema_path`.
  Update this key in `pubspec.yaml`.

## 0.5.1

* Fixes default values in the Freezed template.

## 0.5.0

* Recognizes objects and generates them as DTOs.
* Fixes `defaultValue` handling.
* Fixes return types.
* Fixes parameter names that conflict with Dart keywords.

## 0.4.1

* Fixes parameter names that conflict with Dart keywords.
* Fixes file suffixes in imports.

## 0.4.0

* Adds support for `default` annotations.
* Adds enum support for Dart.
* Fixes multipart handling.
* Fixes errors with Kotlin types.

## 0.3.1

* Fixes error with `@` in URL paths.
* Maps `number` to `double`.
* Maps `object` to Dart `Object`.
* Updates the README with instructions and steps to generate the code.

## 0.3.0

* Adds support for `required` annotations.
* Fixes REST client parameter types in Swagger 2.0.

## 0.2.4

* Fixes error with `.` and `,` in URL paths.

## 0.2.3

* Fixes multipart requests with a single `$ref`.

## 0.2.2

* Removes the `swagger_parser` section from the package `pubspec.yaml`.
* Updates dependencies in example.

## 0.2.1

* Fixes README.
* Fixes workflow files.

## 0.2.0

* Fixes errors with generation of data classes containing `allOf`.
* Fixes errors with templates.
* Adds the [web interface](https://carapacik.github.io/swagger_parser).
* Adds generator tests.

## 0.1.0

* Marks the initial release.
