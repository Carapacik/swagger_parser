# Swagger Parser

[![pub version](https://img.shields.io/pub/v/swagger_parser?logo=dart)](https://pub.dev/packages/swagger_parser)
[![pub likes](https://img.shields.io/pub/likes/swagger_parser?logo=dart)](https://pub.dev/packages/swagger_parser)
[![dart style](https://img.shields.io/badge/style-carapacik__lints%20-brightgreen?logo=dart)](https://pub.dev/packages/carapacik_lints)
[![Star on Github](https://img.shields.io/github/stars/Carapacik/swagger_parser?logo=github)](https://github.com/Carapacik/swagger_parser)
[![Last commit on Github](https://img.shields.io/github/last-commit/Carapacik/swagger_parser?logo=github)](https://github.com/Carapacik/swagger_parser)
[![Tests](https://github.com/Carapacik/swagger_parser/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/Carapacik/swagger_parser/actions/workflows/tests.yml)

## Dart package that generates REST clients and data classes from OpenApi definition files or links

## Features

- Supports OpenApi v2, v3.0 and v3.1
- Support JSON and YAML format
- Support for generation by link
- Support for multiple schemes
- Generate REST client files based on Retrofit
- Generate data classes, using one of the following serializer:
  - [json_serializable](https://pub.dev/packages/json_serializable)
  - [freezed](https://pub.dev/packages/freezed)
  - [dart_mappable](https://pub.dev/packages/dart_mappable)
- Support for multiple languages (Dart, Kotlin)
- Web interface at https://carapacik.github.io/swagger_parser

## Usage

### Install

In your pubspec.yaml, add the following dependencies:

```yaml
dependencies:
  # dart_mappable: ^4.6.1 # for dart_mappable
  # dio: ^5.9.0
  # freezed_annotation: ^3.1.0 # for freezed
  # json_annotation: ^4.9.0
  # retrofit: ^4.9.1

dev_dependencies:
  # build_runner: ^2.10.4
  # carapacik_lints: ^3.10.2
  # dart_mappable_builder: ^4.6.1 # for dart_mappable
  # freezed: ^3.2.3 # for freezed
  # json_serializable: ^6.11.2
  # retrofit_generator: ^10.2.0
  swagger_parser:
```

### Configure package

Add your OpenApi json file configuration to your `pubspec.yaml` or create a new config file called `swagger_parser.yaml`.
An example of YAML is shown below. A default value is specified for each of the optional parameters.

```yaml
swagger_parser:
  # You must provide the file path and/or url to the OpenApi schema.

  # Sets the OpenApi schema path directory for api definition.
  schema_path: schemes/openapi.json

  # Sets the url of the OpenApi schema.
  schema_url: https://petstore.swagger.io/v2/swagger.json

  # Required. Sets output directory for generated files (Clients and DTOs).
  output_directory: lib/api

  # Optional. Set API name for folder and export file
  # If not specified, the file name is used.
  name: null

  # Optional. Sets the programming language.
  # Current available languages are: dart, kotlin.
  language: dart

  # Optional (dart only).
  # Current available serializers are: json_serializable, freezed, dart_mappable.
  json_serializer: json_serializable

  # Optional. Set default content-type for all requests.
  default_content_type: "application/json"

  # Optional (dart only).
  # Support @Extras annotation for interceptors.
  # If the value is 'true', then the annotation will be added to all requests.
  extras_parameter_by_default: false

  # Optional (dart only).
  # Generate static OpenAPI metadata (tags, operationId, externalDocsUrl) for each request.
  # If extras_parameter_by_default is true, this metadata is also used as the default `extras` value.
  # Disabled by default.
  add_openapi_metadata: false

  # Optional (dart only).
  # Support @DioOptions annotation for interceptors.
  # If the value is 'true', then the annotation will be added to all requests.
  dio_options_parameter_by_default: false

  # Optional (dart only). Set 'true' to generate root client
  # with interface and all clients instances.
  root_client: true

  # Optional (dart only). Set root client name.
  root_client_name: RestClient

  # Optional (dart only). Set 'true' to generate export file.
  export_file: true

  # Optional. Set to 'true' to put the all api in its folder.
  put_in_folder: false

  # Optional. Set 'true' to put all clients in clients folder.
  put_clients_in_folder: false

  # Optional. Set to 'true' to squash all clients in one client.
  merge_clients: false

  # Optional. Set postfix for Client class and file.
  client_postfix: Client

  # Optional. Set 'true' to use only the endpoint path for the method name.
  # Set 'false' to use operationId
  path_method_name: false

  # Optional (dart only). Set 'true' to include toJson() in enums.
  # If set to false, serialization will use .name instead.
  enums_to_json: false

  # Optional. Set 'true' to set enum prefix from parent component.
  enums_parent_prefix: true

  # Optional (dart only). Set 'true' to maintain backwards compatibility
  # when adding new values on the backend.
  unknown_enum_value: true

  # Optional. Set 'false' to not put a comment at the beginning of the generated files.
  mark_files_as_generated: true

  # Optional (dart only). Set 'true' to wrap all request return types with HttpResponse.
  original_http_response: false

  # Optional. Set regex replacement rules for the names of the generated classes/enums.
  # All rules are applied in order.
  replacement_rules:
    # Example of rule
    - pattern: "[0-9]+"
      replacement: ""

  # Optional. Set raw regex replacement rules for the names of the raw schema objects.
  # Applies to the raw schema objects before the generator will try to parse them into a Dart class.
  # Useful when raw schema objects have names that are not valid Dart class names (e.g. "filters[name]")
  replacement_rules_for_raw_schema:
   - pattern: "\\]\\["
     replacement: "_"
   - pattern: "\\[]\\["
     replacement: "_"
   - pattern: "\\["
     replacement: "_"
   - pattern: "\\]"
     replacement: "_"

  # Optional. Set paths to be included on endpoint generation.
  #
  # Also supports wildcard paths (e.g. `/path/*/update` or `/path/**`)
  #
  # If set, only endpoints with these paths will be included in the generated clients.
  include_paths:
    - "/some/concrete/path/{id}"
    - "/some/wildcard/*/path"
    - "/another/wildcard/**"

  # Optional (dart & json_serializable only). Set field parsers for JSON serializable.
  #
  # Field parsers are used to parse specific fields of a DTO.
  #
  # Parser must implements JsonConverter<T, Object?> interface from json_annotation package.
  field_parsers:
    - apply_to_type: "int"
      parser_name: "CustomIntParser"
      parser_absolute_path: "package:your_package/lib/utils/parsers/custom_int_parser.dart"
    - apply_to_type: "int?"
      parser_name: "CustomNullableIntParser"
      parser_absolute_path: "package:your_package/lib/utils/parsers/custom_nullable_int_parser.dart"
    - apply_to_type: "bool"
      parser_name: "CustomBoolParser"
      parser_absolute_path: "package:your_package/lib/utils/parsers/custom_bool_parser.dart"

  # Optional. Skip parameters with names.
  skipped_parameters:
    - "X-Some-Token"

  # Optional (dart & freezed only). Set 'true' to use Freezed 3.x code generation syntax.
  # Set 'false' to maintain compatibility with Freezed 2.x.
  use_freezed3: false

  # Optional (dart & freezed/dart_mappable). Set string value to use fallbackUnion parameter.
  # For freezed: adds fallbackUnion: <value> to the @Freezed annotation.
  # For dart_mappable: creates additional fallback variant for unknown discriminator values.
  # When not set (null) or empty, no fallback union is generated.
  # Examples: "unknown"
  # Default: "" (no fallbackUnion parameter)
  fallback_union: ""

  # Optional (dart_mappable only). Set false to generate sealed classes for union types.
  # Set true to generate when/maybeWhen convenience methods for legacy support of deprecated union features from versions prior to 3.31.
  # Default: false
  dart_mappable_convenient_when: false

  # Optional (dart_mappable only).
  # Set to true to use the standard `toMap` and `fromMap` serialization from dart_mappable.
  # The default implementation requires you to rename the serialization methods in the `build.yaml` to
  # ensure compatibility between retrofit and dart_mappable
  # ```yaml
  # global_options:
  #   dart_mappable_builder:
  #     runs_before:
  #       - retrofit_generator
  #     options:
  #       renameMethods:
  #         toJson: toJsonString
  #         toMap: toJson
  # ```
  # 
  # Default: false
  use_dart_mappable_naming: false

  # DART ONLY
  # Optional. Set `true` to use MultipartFile instead of File as argument type for file parameters.
  use_multipart_file: false

  # DART ONLY
  # Optional. Set `true` to generate URL constants for all endpoints.
  generate_urls_constants: false

  # DART ONLY
  # Optional. Set tags to be excluded on endpoint generation.
  #
  # Endpoints with these tags will not be included in the generated clients.
  exclude_tags:
    - "sellPet"

  # DART ONLY
  # Optional. Set tags to be included on endpoint generation.
  #
  # If set, only endpoints with these tags will be included in the generated clients.
  # **NOTE: This will override the [exclude_tags] if set.**
  include_tags:
    - "buyPet"

  # DART ONLY
  # Optional. Set fallback client name for endpoints without tags.
  #
  # In general the first tag of an endpoint defines in which client the
  # endpoint will be included. If no tag is specified, the fallback client
  # name will be used.

  # defaults to 'fallback' which results in a client named `FallbackClient`.
  fallback_client: "fallback"

  # Optional. Set to true to merge all generated code into a single file.
  #
  # This is useful when using swagger_parser together with build_runner, which needs to map
  # input files to output files 1-to-1.
  merge_outputs: false

  # DART ONLY
  # Optional. Set `true` to generate includeIfNull annotations for nullable fields.
  # If set to `false`, includeIfNull annotations will not be generated.
  include_if_null: false

  # DART ONLY
  # Optional. Set `true` to infer required properties from nullability.
  # When enabled and the schema has no explicit required array:
  # - Properties without nullable: true are marked as required
  # - Properties with nullable: true remain optional
  # If the schema defines a required array, this option has no effect.
  infer_required_from_nullable: false

  # DART/FLUTTER ONLY
  # Optional. Set `true` to generate Retrofit clients with `Parser.FlutterCompute`
  # and serialize/deserialize top-level functions for isolate-based multithreading.
  # This enables parsing models on a separate thread using Flutter's compute function.
  use_flutter_compute: false
```

For multiple schemes:

```yaml
swagger_parser:
  # <...> Set default parameters for all schemes.
  output_directory: lib/api
  merge_clients: true

  # Optional. You can pass a list of schemes.
  # Each schema inherits the parameters described in swagger_parser,
  # any parameter for any schema can be set manually.
  # Cannot be used at the same time as schema_path.
  schemes:
    - schema_path: schemes/openapi.json
      root_client_name: ApiMicroservice
      json_serializer: freezed
      put_in_folder: true
      replacement_rules: []
      replacement_rules_for_raw_schema: []

    - schema_url: https://petstore.swagger.io/v2/swagger.json
      name: pet_service_dart_mappable
      json_serializer: dart_mappable
      client_postfix: Service
      put_clients_in_folder: true
      put_in_folder: true

    - schema_url: https://petstore.swagger.io/v2/swagger
      name: pet_service
      client_postfix: Service
      put_clients_in_folder: true
      put_in_folder: true

    - schema_path: schemes/pet_store.json
      schema_url: https://petstore.swagger.io/v2/swagger.json
      output_directory: lib/api/kotlin
      language: kotlin
```

### Run the generator

To generate code, run the `swagger_parser` program inside directory where your `pubspec.yaml` file is located:

```shell
dart run swagger_parser
```

### Generator arguments

There are some configuration parameters that you can pass as an argument to the generator. These arguments will override configuration parameters set in your configuration file.

#### Help argument
```shell
-help
```
If you want to see the help message upon running ``swagger_parser`` use the ``-help`` argument.
```shell
dart run swagger_parser -help
```

#### File argument
**``-f`` or ``--file``**

If you name your configuration file something other than `swagger_parser.yaml` or `pubspec.yaml`
you will need to specify the name of the YAML file as an argument.

```shell
dart run swagger_parser -f <path to your config file>
```

#### Output directory argument
**``--output_directory``**

If you want to pass in the output directory dynamically upon running ``swagger_parser`` use the ``-output_directory`` argument.
```shell
dart run swagger_parser --output_directory <path to your output directory>
```

**NOTE: The following arguments will be ignored if multiple schemes are defined in your configuration file.**

#### Schema path argument (Only for single scheme)
**``--schema_path``**

If you want to pass in the schema path dynamically upon running ``swagger_parser`` use the ``-schema_path`` argument.
```shell
dart run swagger_parser --schema_path <path to your schema file>
```

#### Schema URL argument (Only for single scheme)
**``--schema_url``**

If you want to pass in the schema URL dynamically upon running ``swagger_parser`` use the ``-schema_url`` argument.
```shell
dart run swagger_parser --schema_url <url to your schema file>
```

#### Name argument
**``--name``**

If you want to pass in the name dynamically upon running ``swagger_parser`` use the ``-name`` argument.
```shell
dart run swagger_parser --name <your name>
```

#### JSON serializer argument
**``--json_serializer``**

If you want to pass in the JSON serializer dynamically upon running ``swagger_parser`` use the ``-json_serializer`` argument.
```shell
dart run swagger_parser --json_serializer <dart_mappable | freezed | json_serializable>
```


### (Only for freezed) Generate files using [build_runner](https://pub.dev/packages/build_runner) for retrofit, json_serializable and freezed

#### For `freezed` with `retrofit` use build.yaml file with this content:

```yaml
global_options:
  freezed:
    runs_before:
      - json_serializable
  json_serializable:
    runs_before:
      - retrofit_generator
```

To run the code generation with build_runner, execute the following command:

```shell
dart run build_runner build -d
```

### (Only for dart_mappable) Generate files using [dart_mappable](https://pub.dev/packages/build_runner) for retrofit and dart_mappable

While most JSON serializer stick to the convention of naming the serializers `fromJson` and `toJson`, `dart_mappable` names these methods
according to the used data type `Map`. Therefore these serializing methods are called `toMap` and `fromMap`. This conflicted with `retrofit`.

#### Default settings

In the default settings the parameter `use_dart_mappable_naming` is set to `false` in the `swagger_parser.yaml`. 
`retrofit` will therefore expect a `fromJson` and `toJson` method to be provided. In order to achieve that, set the following options
in the `build.yaml`:

```yaml
global_options:
  dart_mappable_builder:
    runs_before:
      - retrofit_generator
    options:
      renameMethods:
        toJson: toJsonString
        toMap: toJson
```

This will result in the following code usage:

```dart

@MappableClass()
class Foo with FooMappable {
  final String name;

  const Foo(this.name);

  static Foo fromJson(Map<String, dynamic> json);
}

void main() {
  final Foo foo = Foo('Dave');
  // parse to JSON
  final Map<String, dynamic> serializedFoo = foo.toJson();
  // parse from JSON
  final Foo deserializedFoo = Foo.fromJson(serializedFoo);
}
```

This has been made default as `retrofit` prior to version `retrofit: 4.9.2`, did not support `dart_mappable`. 
The `retrofit` package was expecting the `toJson` method being able to handle objects of type 
`Map<String, dynamic>`. Therefore the standard naming convention in dart_mappable had to be overriden using the `build.yaml`. 
To avoid breaking changes, this behaviour has been made default and may be changed in a future major release.

#### use `dart_mappable` standard naming

In order to use the default namings of `dart_mappable` set the `use_dart_mappable_naming` to `true`.

This will result in the following code usage:

```dart

@MappableClass()
class Foo with FooMappable {
  final String name;

  const Foo(this.name);

  static Foo fromMap(Map<String, dynamic> json);
}

void main() {
  final Foo foo = Foo('Dave');
  // parse to JSON
  final Map<String, dynamic> serializedFoo = foo.toMap();
  // parse from JSON
  final Foo deserializedFoo = Foo.fromMap(serializedFoo);
}
```

**NOTE:** If you want to migrate existing projects that have been using the renaming options, do not forget to remove these
options from the `build.yaml`.


## Contributing

Contributions are welcome!

Here is a curated list of how you can help:

- Report bugs and scenarios that do not match the expected behavior
- Implement new features by making a pull-request
- Write tests or supplement [E2E tests](https://github.com/Carapacik/swagger_parser/tree/main/swagger_parser/test/e2e) with your own scenarios that are not yet covered
