## 1.9.0
- Added display of generation statistics for each scheme and total
- The command to start generation has been changed to `dart run swagger_parser`
- Fix error with `required` params in unnamed classes ([#98](https://github.com/Carapacik/swagger_parser/issues/98))
- Fix error with missing File import ([#101](https://github.com/Carapacik/swagger_parser/issues/101))

## 1.8.0
- Multiple schemas support(see ([example](https://github.com/Carapacik/swagger_parser/blob/main/swagger_parser/example/swagger_parser.yaml)))
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
