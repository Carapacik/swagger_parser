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
  # dart_mappable: ^4.2.2 # for dart_mappable
  # dio: ^5.7.0
  # freezed_annotation: ^2.4.4 # for freezed
  # json_annotation: ^4.9.0
  # retrofit: ^4.4.1

dev_dependencies:
  # build_runner: ^2.4.12
  # carapacik_lints: ^1.9.1
  # dart_mappable_builder: ^4.2.3 # for dart_mappable
  # freezed: ^2.5.7 # for freezed
  # json_serializable: ^6.8.0
  # retrofit_generator: ^9.1.2
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

  # Optional. Skip parameters with names.
  skipped_parameters:
    - 'X-Some-Token'
```

For multiple schemes:

```yaml
swagger_parser:
  # <...> Set default parameters for all schemes.
  output_directory: lib/api
  squash_clients: true

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
If you name your configuration file something other than `swagger_parser.yaml` or `pubspec.yaml` 
you will need to specify the name of the YAML file as an argument.

```shell
dart run swagger_parser -f <path to your config file>
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

## Contributing

Contributions are welcome!

Here is a curated list of how you can help:

- Report bugs and scenarios that do not match the expected behavior
- Implement new features by making a pull-request
- Write tests or supplement [E2E tests](https://github.com/Carapacik/swagger_parser/tree/main/swagger_parser/test/e2e) with your own scenarios that are not yet covered
