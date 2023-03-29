## 0.9.0
- Single ref sibling elements are now defined as typedefs instead of generating excess classes
- Fix error with ` Null ` type with empty type in schema

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
- Fix the problem with ` number ` type to map ` double `
- Fix the problem with ` object ` type to map Dart ` Object `
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
