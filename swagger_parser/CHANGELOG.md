## 1.35.2
- Fix enum name values being a int returned in a toString

## 1.35.1
- Fixed enum names generation

## 1.35.0
- Add `infer_required_from_nullable`
```
infer_required_from_nullable: true

Schema without required array:
- id: type: integer → required int id
- name: type: string → required String name
- desc: type: string, nullable: true → String? desc
```
- Fix nullable array item types generation

## 1.34.0
- includeIfNull handling, turned off by default, use include_if_null=true to enable

## 1.33.0
- Support correct processing of nested allOf classes

## 1.32.1
- Fix CHANGELOG duplication

## 1.32.0
- Add complete sealed classes(`oneOf`/`anyOf`) support for `json_serializeble` serializer
  - **WARNING**: Undiscriminated sealed classes use O(n) try-catch deserialization where n is the number of variants
  - **RECOMMENDED**: Add discriminator properties to your OpenAPI specification for O(1) performance
  - Add support for sealed classes fallback for failed decoding
- Add complete sealed classes(`oneOf`/`anyOf`) support for `dart_mappable` serializer
  - **WARNING**: Undiscriminated sealed classes use O(n) try-catch deserialization where n is the number of variants
  - **RECOMMENDED**: Add discriminator properties to your OpenAPI specification for O(1) performance
  - Add support for sealed classes fallback for failed decoding
- Add `dart_mappable_convenient_when` option to control union type generation for `dart_mappable` serializer
  - `dart_mappable_convenient_when: true` - generates legacy `when<T>, maybeWhen<T>` methods
  - `dart_mappable_convenient_when: false` (default) - generates sealed classes for better type safety
- Add `@Deprecated()` annotation to `when<T>, maybeWhen<T>` method with dart_mappable. Use dart pattern matching
- Fix creating duplicated `unknown` property enum with dart_mappable and `unknown_enum_value: true`
- Fix for handle nullable discriminator unions properly

## 1.30.1
- Fix resolve inline schemas nested within tagged operations

## 1.30.0
- Add support for merging all generated code into single output file using the `merge_outputs` option

## 1.29.0
### Features
- Add support for non-discriminated unions (`oneOf`/`anyOf` without a discriminator)
- Filter out unused schemas when using `include_tags` or `exclude_tags`

### Fixes
- Fix the client name for untagged paths to properly fall back to the configured `fallback_client` instead of `client`
- Fix the `fallback_client` configuration to default to `fallback` instead of `default` to avoid conflicts with the Dart `default` keyword in the generated code
- Fix OpenAPI spec parsing to correctly preserve casing for `SCREAMING_SNAKE_CASE`
- Fix filtering so paths without tags are filtered out when `include_tags` is specified

## 1.28.0
- Fix documentation
- Fix ensure consistent file naming for tags with alphanumeric suffixes

## 1.27.0
 - Allow to filter the generation of endpoints in a client by tags
 - Allow to define a fallback client for endpoints that do not have a tag - fixes [[#271](https://github.com/Carapacik/swagger_parser/issues/271)] 

## 1.26.4
 - Allow the use of single MultipartFile arguments in multipart requests (requires retrofit_generator 10.0.1 or later)

## 1.26.3
- Fix for the bug when untagged endpoints and tagged as `Client` will override each other which
  results in `Client` tagged overwritten during file creation

## 1.26.2
- align default value handling for parameters according to OpenAPi Spec https://swagger.io/docs/specification/v3_0/describing-parameters/#default-parameter-values 

## 1.26.1
- dart_mappable toString override 
- dart_mappable toJson return string

## 1.26.0
- Add support for Freezed fallbackUnion parameter

## 1.25.1
- Fix broken dart_mappable enum

## 1.25.0
- Allow using `MultipartFile` instead of `File` in multipart requests, to support usage on web.

## 1.24.6
- proper handling of binary responses aka file downloads, picked up from https://github.com/trevorwang/retrofit.dart/issues/503

## 1.24.5
- enum `toString()` override implementation to provide a json value for third party consumers like retrofit

## 1.24.4
- added generation of getter $valuesDefined to automatically filter out unknown values
  useful when we would like to list only values that we are aware about 

## 1.24.3
- Fixes `allOf` case when a mix of `ref` and `properties` could unintentionally result in naming overlap
  now we are deduplicating properties by name

## 1.24.2
- Fixes `typedef` transparency which results in import errors when generating `json_serializable` classes
  read more details here https://github.com/google/json_serializable.dart/issues/1124

## 1.24.1
- Remove duplicate parameters in dataclass([#322](https://github.com/Carapacik/swagger_parser/issues/322))

## 1.24.0
- Fix detection of nullable list with non null items vs nullable list with nullable items([#323](https://github.com/Carapacik/swagger_parser/issues/323))
- Bump Dart SDK to 3.6

## 1.23.2
- Fixed error with client parameters with `$`([#262](https://github.com/Carapacik/swagger_parser/issues/262))

## 1.23.1
- Update dart_mappable template

## 1.23.0
- Support for allOf composition and xOf ([#239](https://github.com/Carapacik/swagger_parser/issues/239))
- Nullable fixes ([#251](https://github.com/Carapacik/swagger_parser/issues/251))
- Make list with null in items nullable

## 1.22.1
- Add supports for freezed 3  

## 1.22.0
- Add supports oneOf polymorphic types with dart_mappable ([#290](https://github.com/Carapacik/swagger_parser/issues/290))

## 1.21.4
- Add `x-enumNames`([#289](https://github.com/Carapacik/swagger_parser/pull/289))
- Fixed errors with nullable in enums ([#216](https://github.com/Carapacik/swagger_parser/issues/216))
- Fixed duplicate class generation when using discriminator ([#300](https://github.com/Carapacik/swagger_parser/issues/300))

## 1.21.3
- Fixed errors with config([#293](https://github.com/Carapacik/swagger_parser/pull/293), [#296](https://github.com/Carapacik/swagger_parser/pull/296))

## 1.21.2
- Add `use_x_nullable` parameter to config([#295](https://github.com/Carapacik/swagger_parser/pull/295))
- Fixed error with config([#296](https://github.com/Carapacik/swagger_parser/pull/296))

## 1.21.1
- Fixed config properties inheritance with multi-scheme urls([#293](https://github.com/Carapacik/swagger_parser/issues/293))

## 1.21.0
- Add support for union types `oneOf`([#265](https://github.com/Carapacik/swagger_parser/issues/265), [#286](https://github.com/Carapacik/swagger_parser/issues/265))
- Fixed config property inheritance

## 1.20.1
- Fixed errors with config parsing

## 1.20.0
- Add validation params to generated `freezed` classes
- Fixed errors with empty schema properties([#280](https://github.com/Carapacik/swagger_parser/issues/280))

## 1.19.2
- Fix replacement rules for OpenAPI v2([#266](https://github.com/Carapacik/swagger_parser/issues/266))
- Add `x-nullable` field for null definition in OpenAPI v2([#268](https://github.com/Carapacik/swagger_parser/issues/268))

## 1.19.1
- Fix generation with `anyOf`, `oneOf` and `allOf` properties([#260](https://github.com/Carapacik/swagger_parser/issues/260))

## 1.19.0
- Add version getter to root client:
```dart
final version = RestClient.version;
```
- Add `dio_options_parameter_by_default`

## 1.18.3
- Remove support of BigInt in Dart for `int64` types

## 1.18.2
- Added support for `int64` types

## 1.18.1
- Fix errors with `nullable: false`
- Fix same property name conflict([#235](https://github.com/Carapacik/swagger_parser/issues/235))

## 1.18.0
- Handle empty enum value case ([#238](https://github.com/Carapacik/swagger_parser/pull/238))
- Some fixes for the replacement rules
- Support for nullable lists and maps
- Remove config parameter `required_by_default`, behaviour is now consistent `required_by_default: false`
- Requires Dart 3.4

## 1.17.3

- Fixed unnecessary null types with `required_by_default: false`
- Fixed generation of class parameters that are set directly from the request specification ([#224](https://github.com/Carapacik/swagger_parser/issues/224))
- Fixed changing case and applying replacement rules to class names ([#223](https://github.com/Carapacik/swagger_parser/issues/223))
- Maps with `additionalProperties` are now generated correctly ([#214](https://github.com/Carapacik/swagger_parser/issues/214))

## 1.17.2

- Add `MappableField` to dart_mappable template

## 1.17.1

- Fixed error with nullable in multipart ([#211](https://github.com/Carapacik/swagger_parser/issues/211))

## 1.17.0

- Add new config parameter `extras_parameter_by_default` from [retrofit 4.1.0](https://pub.dev/packages/retrofit/changelog#410) for ([#208](https://github.com/Carapacik/swagger_parser/issues/208))
- Fixed errors ([#190](https://github.com/Carapacik/swagger_parser/issues/190)), ([#192](https://github.com/Carapacik/swagger_parser/issues/192)) and ([#195](https://github.com/Carapacik/swagger_parser/issues/195))

## 1.16.4

- Fixed errors with `required_by_default`

## 1.16.3

- Temporary fix for ([#110](https://github.com/Carapacik/swagger_parser/issues/110))
- Ignore parameters start with `x-` for ([#185](https://github.com/Carapacik/swagger_parser/issues/185))
- Fixed parameter type ([#186](https://github.com/Carapacik/swagger_parser/issues/186)
- Fixed handle `$ref` ([#187](https://github.com/Carapacik/swagger_parser/issues/187)) and ([#183](https://github.com/Carapacik/swagger_parser/issues/183))

## 1.16.2

- Add new exceptions to export
- Fixed file name from `schemeUrl`

## 1.16.1

- Fix swagger_parser_pages (https://carapacik.github.io/swagger_parser)

## 1.16.0

- Wrapping collections variable introduced replacing arrayDepth and mapType: this variable presents a list of all collections wrapping a type and will resolve them in order of appearance ([#128](https://github.com/Carapacik/swagger_parser/issues/128))
- Fixed error with `required_by_default` ([#168](https://github.com/Carapacik/swagger_parser/issues/168))
- Refactor config and rename parameters:
    - `squash_clients` to `merge_clients`
    - `enums_prefix` to `enums_parent_prefix`
    - `skipp_parameters` to `skipped_parameters`
- Remove config parameter `put_in_folder`

## 1.15.5

- Support schema url without extension ([#160](https://github.com/Carapacik/swagger_parser/issues/160))

## 1.15.4

- Fix docs

## 1.15.3

- Fixed errors with `Object` body in retrofit client ([#110](https://github.com/Carapacik/swagger_parser/issues/110))

## 1.15.2

- Fixed errors with enum names ([#163](https://github.com/Carapacik/swagger_parser/issues/163)), ([#164](https://github.com/Carapacik/swagger_parser/issues/164))

## 1.15.1

- Support for generation multipart request with ref ([#154](https://github.com/Carapacik/swagger_parser/issues/154))

## 1.15.0

- Add new config parameter `required_by_default`
- Added template for E2E tests

## 1.14.2

- Fixed errors with multipart ([#144](https://github.com/Carapacik/swagger_parser/issues/144))

## 1.14.1

- Removed check that would avoid generating a map when additional properties has a `$ref` value

## 1.14.0

- Fixed error with empty content type
- Fixed retrofit template
- Remove special characters from tags
- Add new config parameter `skip_parameters`
- Extract schemes from url ([#150](https://github.com/Carapacik/swagger_parser/issues/150))

## 1.13.1

- Fixed error with path-level parameters cause crash ([#147](https://github.com/Carapacik/swagger_parser/issues/147))
- Fixed `dart:io` import in template

## 1.13.0

- Added support for [dart_mappable](https://pub.dev/packages/dart_mappable)
- Changed `freezed` schema property to `json_serializer`, which can be set to `freezed`, `dart_mappable` or `json_serializable` (default).
- Fixed enum generation name that are defined inside an array

## 1.12.2

- Fixes enum duplicate names ([#140](https://github.com/Carapacik/swagger_parser/issues/140))

## 1.12.1

- Fixed error with `ref` in a case other than PascalCase ([#139](https://github.com/Carapacik/swagger_parser/issues/139))

## 1.12.0

- Add new config parameter `export_file`

## 1.11.3

- Fixed error with annotating client methods with the first specified content type header in OpenAPI V2 schemes if the specified one is not the default.

## 1.11.2

- Add description of request parameters to the code docs

## 1.11.1

- Fixed ref component being wrongly labeled as map
- Fixed map components being assigned an import despite not needing one

## 1.11.0

- Added unknown value to all enums to maintain backwards compatibility when adding new values on the backend
- Add new config parameter `unknown_enum_value` (dart only) ([#106](https://github.com/Carapacik/swagger_parser/issues/106))
- Add new config parameter `default_content_type`
- Support String values with spaces for enums ([#127](https://github.com/Carapacik/swagger_parser/issues/127))

## 1.10.6

- Fixed map objects parsing as separate entities ([#124](https://github.com/Carapacik/swagger_parser/issues/124))

## 1.10.5

- Fixed error with parsing dictionary objects ([#113](https://github.com/Carapacik/swagger_parser/issues/113))

## 1.10.4

- Fixed error with `additionalProperties` ([#114](https://github.com/Carapacik/swagger_parser/issues/114))

## 1.10.3

- Add new config parameter `original_http_response` (dart only) ([#115](https://github.com/Carapacik/swagger_parser/issues/115))

## 1.10.2

- Fix error in `body` with name in dart template

## 1.10.1

- Fix error with query parameter named `body` ([#108](https://github.com/Carapacik/swagger_parser/issues/108))

## 1.10.0

- Support for generating schemes by url (see [example](https://github.com/Carapacik/swagger_parser/blob/main/swagger_parser/example/swagger_parser.yaml))
- Add new config parameter `schema_url`
- Add new config parameter `schema_from_url_to_file`
- Add new config parameter `prefer_schema_source`

## 1.9.2

- Fix error with `required` in clients ([#101](https://github.com/Carapacik/swagger_parser/issues/103))

## 1.9.1

- Handling incorrect names for classes, enums and methods.
- Additional name for unnamed models ([#98](https://github.com/Carapacik/swagger_parser/issues/98))
- Support for `deprecated` annotations for methods

## 1.9.0

- Added display of generation statistics for each scheme and total
- The command to start generation has been changed to `dart run swagger_parser`
- Fix error with `required` params in unnamed classes ([#98](https://github.com/Carapacik/swagger_parser/issues/98))
- Fix error with missing `File` import ([#101](https://github.com/Carapacik/swagger_parser/issues/101))

## 1.8.0

- Multiple schemes support (see [example](https://github.com/Carapacik/swagger_parser/blob/main/swagger_parser/example/swagger_parser.yaml))
- Support for specifying nullable types via anyOf
- Edit root client template
- Add new config parameter `root_client_name`
- Add new config parameter `name`
- Add new config parameter `put_in_folder`
- Add new config parameter `squash_clients`
- Rename `root_interface` to `root_client`
- Rename `squish_clients` to `put_clients_in_folder`

## 1.7.0

- Add new config parameter `mark_files_as_generated`
- Support of default values for ref enum types
- Type support in one-element allOf, anyOf and oneOf

## 1.6.3

- Fix error with `allOf` results in the schema with type `object` ([#91](https://github.com/Carapacik/swagger_parser/issues/91))

## 1.6.2

- Fix grouping words for abbreviations when special characters are present
- Fix replacement type for enum classes
- Takes case in replacement

## 1.6.1

- Add summary of the methods to the code docs
- Fix indents for multiline code docs
- Add support for root client code docs

## 1.6.0

- Add new config parameter `path_method_name`

## 1.5.3

- Fix error with imports in dto component ([#86](https://github.com/Carapacik/swagger_parser/issues/86))

## 1.5.2

- Fix grouping words for acronyms and abbreviations ([#85](https://github.com/Carapacik/swagger_parser/issues/85))

## 1.5.1

- Fixed method name generation in a language other than English ([#83](https://github.com/Carapacik/swagger_parser/issues/83))

## 1.5.0

- Requires Dart 3.0 or later

## 1.4.0

- By default value nullable and not required for process default values ([#76](https://github.com/Carapacik/swagger_parser/issues/76))
- Add support for common parameters for various paths ([#78](https://github.com/Carapacik/swagger_parser/issues/78))

## 1.3.5

- Fix default enum values in dto ([#79](https://github.com/Carapacik/swagger_parser/issues/79))

## 1.3.4

- Enum prefix only for variable type now

## 1.3.3

- Fix error with unnamed classes uniques names ([#74](https://github.com/Carapacik/swagger_parser/issues/74))

## 1.3.2

- Fix error with replacement rules in allOf

## 1.3.1

- Fix error with allOf ([#72](https://github.com/Carapacik/swagger_parser/issues/72))

## 1.3.0

- Add possibility to add enum prefix from parent component ([#29](https://github.com/Carapacik/swagger_parser/issues/29)). Change `enums_prefix` to true to enable this option

## 1.2.4

- Fixed names for negative enum values

## 1.2.3

- Fixed rename for enums ([#69](https://github.com/Carapacik/swagger_parser/issues/69))

## 1.2.2

- Fixed error with parse nullable item in array ([#68](https://github.com/Carapacik/swagger_parser/issues/68))

## 1.2.1

- Updated `retrofit_generator` dependency to [7.0.8](https://github.com/trevorwang/retrofit.dart/releases/tag/7.0.8) and added config option to generate `.toJson()` methods in enums (`retrofit_generator` will use `.toJson()` instead of `.name` in this case)

## 1.2.0

- Updated `retrofit_generator` dependency to [7.0.7](https://github.com/trevorwang/retrofit.dart/releases/tag/7.0.7) and consequently removed unused `.toJson()` generated methods in enums

## 1.1.0

- Add regex replacement for generated class names
- Fixed error with null raw parameter in OpenApi v2 ([#63](https://github.com/Carapacik/swagger_parser/issues/63))

## 1.0.7

- Fixed classes as body parameters ([#61](https://github.com/Carapacik/swagger_parser/issues/61))

## 1.0.6

- Fixed generation default enum values ([#58](https://github.com/Carapacik/swagger_parser/issues/58))
- Add new keywords to check the name of variables

## 1.0.5

- Fixed generation default enum values in client ([#56](https://github.com/Carapacik/swagger_parser/issues/56))

## 1.0.4

- Fixed parsing ` Body ` in OpenApi v2 ([#53](https://github.com/Carapacik/swagger_parser/issues/53))
- Add multiline comments ([#54](https://github.com/Carapacik/swagger_parser/issues/54))
- Fixed items name in enum generation ([#55](https://github.com/Carapacik/swagger_parser/issues/55))

## 1.0.3

- Fixed error with default value in dart json_serializable generation

## 1.0.2

- Fixed error with ` application/x-www-form-urlencoded ` ([#45](https://github.com/Carapacik/swagger_parser/issues/45))

## 1.0.1

- Fixed error with ` nullable ` in array ([#43](https://github.com/Carapacik/swagger_parser/issues/43))

## 1.0.0+1

- Add ` root_interface ` option to [web interface](https://carapacik.github.io/swagger_parser)
- Add topics

## 1.0.0

- Require Dart >= 2.19
- Add support for ` description ` annotation
- Add ` root_interface ` option to generate root interface for all Clients
- Refactor code related to ` nullable `

## 0.10.3

- Now uses ` ref ` to identify return type of client method if ` type ` also exists

## 0.10.2

- ` defaultValue ` in dart class now generates in constructor
- Fixed error with empty ` client_postfix `

## 0.10.1

- Fixed error with ` servers ` in requests ([#32](https://github.com/Carapacik/swagger_parser/issues/32))
- Use ` operationId ` for method name(if such a field exists)

## 0.10.0

- Fixed error with ` enum ` values not parsed in object properties
- Use 2xx codes if code 200 not found
- ` nullable ` types are now supported

## 0.9.1

- Use ` JsonEnum ` and ` JsonValue ` on generated enum

## 0.9.0

- Single ref sibling elements are now defined as typedefs instead of generating excess classes
- Fixed error with ` Null ` type with empty type in schema

## 0.8.1

- Added DateTime to the format for processing types ([#16](https://github.com/Carapacik/swagger_parser/issues/16))

## 0.8.0

- Support for dio 5
- Downgraded the lower bound of dependencies to support Flutter 3.0
- Complete templates for Kotlin

## 0.7.0

- Fixed error with import for ` File ` type
- Add support for ` additionalProperties ` annotations
- Fixed templates
- Fixed error with yaml files

## 0.6.4

- Update example
- Remove ` implicit_dynamic ` field for analyzer

## 0.6.3

- Fixed error with return type in rest client

## 0.6.2

- Update docs

## 0.6.1

- Fixed error with Multipart file type in retrofit
- Update dart api docs
- Update web interface

## 0.6.0

- Add support for ` yaml ` files
- **BREAKING**: Rename ` json_path ` in pubspec.yaml to ` schema_path `

## 0.5.1

- Fixed problem with default value in freezed template

## 0.5.0

- Objects are now recognized and are being generated as DTOs
- Fixed some problems with defaultValue
- Fixed some problems with return type
- Fixed some problems with naming parameters whose names are similar to dart keywords

## 0.4.1

- Fixed a problem with parameters whose names are similar to dart keywords
- Fixed a problem with postfix in file import

## 0.4.0

- Add support for ` default ` annotations
- Add enum support for dart
- Fixed errors with Multipart
- Fixed errors with Kotlin types

## 0.3.1

- Fixed error with ` @ ` in url path
- Fixed the problem with ` number ` type to map ` double `
- Fixed the problem with ` object ` type to map Dart ` Object `
- Updates the README with instructions and steps to generate the code

## 0.3.0

- Add support for ` required ` annotations
- Fixed error with rest client parameters type in OpenApi v2

## 0.2.4

- Fixed error with ` . ` and ` , ` in url path

## 0.2.3

- Fixed error in MultiPart with single ` $ref `

## 0.2.2

- Remove swagger_parser section from pubspec.yaml
- Update dependencies in example

## 0.2.1

- Fixed README
- Fixed workflow files

## 0.2.0

- Fixed errors with generation of data classes containing ` allOf `
- Fixed errors with templates
- Add web interface for package https://carapacik.github.io/swagger_parser
- Add generator tests

## 0.1.0

- Initial release
