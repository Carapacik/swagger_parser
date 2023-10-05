# Swagger Parser
[![pub version](https://img.shields.io/pub/v/swagger_parser?logo=dart)](https://pub.dev/packages/swagger_parser)
[![pub likes](https://img.shields.io/pub/likes/swagger_parser?logo=dart)](https://pub.dev/packages/swagger_parser)
[![dart style](https://img.shields.io/badge/style-carapacik__lints%20-brightgreen?logo=dart)](https://pub.dev/packages/carapacik_lints)
[![Star on Github](https://img.shields.io/github/stars/Carapacik/swagger_parser?logo=github)](https://github.com/Carapacik/swagger_parser)
[![Last commit on Github](https://img.shields.io/github/last-commit/Carapacik/swagger_parser?logo=github)](https://github.com/Carapacik/swagger_parser)
[![Tests](https://github.com/Carapacik/swagger_parser/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/Carapacik/swagger_parser/actions/workflows/tests.yml)
<a href="https://omega-r.com/"><img src="https://raw.githubusercontent.com/Carapacik/swagger_parser/main/.github/readme/omega_logo.png" width="200" align="right"/></a>

## Dart package that generates REST clients and data classes from OpenApi definition file

## Features

- Supports OpenApi v2, v3.0 and v3.1
- Support JSON and YAML format
- Generate REST client files based on Retrofit
- Generate data classes (also on [freezed](https://pub.dev/packages/freezed))
- Support for multiple languages (Dart, Kotlin)
- Web interface at https://carapacik.github.io/swagger_parser

## Usage

### Install

In your pubspec.yaml, add the following dependencies:

```yaml
dependencies:
  # dio: ^5.3.0
  # freezed_annotation: ^2.4.1 # for freezed
  # json_annotation: ^4.8.1
  # retrofit: ^4.0.2

dev_dependencies:
  # build_runner: ^2.4.6
  # freezed: ^2.4.3 # for freezed
  # json_serializable: ^6.7.1
  # retrofit_generator: ^8.0.0
  swagger_parser:
```

### Configure package

Add your OpenApi json file configuration to your `pubspec.yaml` or create a new config file called `swagger_parser.yaml`.
An example of YAML is shown below

```yaml
swagger_parser:
  # Required. Sets the OpenApi schema path directory for api definition
  schema_path: schemas/openapi.json

  # Required. Sets output directory for generated files (Clients and Dtos)
  output_directory: lib/api

  # Optional. Sets the programming language.
  # Current available languages are: dart, kotlin. Default: dart
  language: dart

  # Optional (dart only). Set 'true' to generate data classes using freezed package. Default: false
  freezed: false

  # Optional (dart only). Set 'true' to generate root client
  # with interface and all clients instances. Default: true
  root_client: true

  # Optional (dart only). Set root client name. Default: RestClient
  root_client_name: RestClient

  # Optional. Set API name for folder and export file (coming soon).
  # If not specified, the file name is used.
  name: null

  # Optional. Set to 'true' to put the all api in its folder. Default: false
  put_in_folder: false

  # Optional. Set 'true' to put all clients in clients folder. Default: false.
  put_clients_in_folder: false

  # Optional. Set to 'true' to squash all clients in one client. Default: false
  squash_clients: false

  # Optional. Set postfix for Client class and file. Default: Client
  client_postfix: Client

  # Optional. Set 'true' to use only the endpoint path for the method name.
  # Set 'false' to use operationId. Default: false
  path_method_name: false

  # Optional (dart only). Set 'true' to include toJson() in enums. 
  # If set to false, serialization will use .name instead. Default: false
  enums_to_json: false

  # Optional. Set 'true' to set enum prefix from parent component. Default: false
  enums_prefix: false

  # Optional. Set 'false' to not put a comment at the beginning of the generated files. Default: true
  mark_files_as_generated: true

  # Optional. Set regex replacement rules for the names of the generated classes/enums.
  # All rules are applied in order.
  replacement_rules:
    # Example of rule
    - pattern: "[0-9]+"
      replacement: ""
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
  schemas:
    - schema_path: schemas/openapi.json
      root_client_name: ApiMicroservice
      freezed: true
      put_in_folder: true
      replacement_rules: []

    - schema_path: schemas/openapi.json
      name: pet_service
      client_postfix: Repository
      put_clients_in_folder: true
      enums_to_json: true
      put_in_folder: true

    - schema_path: schemas/openapi.json
      output_directory: lib/api/kotlin
      language: kotlin
```


### Run the generator
To generate boilerplate code, run the `generate` program inside directory where your `pubspec.yaml` file is located:
```shell
dart run swagger_parser:generate
```
If you name your configuration file something other than `swagger_parser.yaml` or `pubspec.yaml` 
you will need to specify the name of the YAML file as an argument.

```shell
dart run swagger_parser:generate -f <path to your config file>
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
