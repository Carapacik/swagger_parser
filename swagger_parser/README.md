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
  # dio: ^5.2.0
  # freezed_annotation: ^2.2.0 # for freezed
  # json_annotation: ^4.8.1
  # retrofit: ^4.0.1

dev_dependencies:
  # build_runner: ^2.3.3
  # freezed: ^2.3.5 # for freezed
  # json_serializable: ^6.6.2
  # retrofit_generator: ^7.0.7
  swagger_parser:
```

### Configure package

Add your OpenApi json file configuration to your `pubspec.yaml` or create a new config file called `swagger_parser.yaml`.
An example of YAML is shown below

```yaml
swagger_parser:
  schema_path: assets/openapi.json # Required. Sets the OpenApi schema path directory for api definition
  output_directory: lib/api # Required. Sets output directory for generated files (Clients and Dtos)
  language: dart # Optional. Sets the programming language. Current available languages are: dart, kotlin. Default: dart
  root_interface: true # Optional (dart only). Set 'true' to generate interface with all clients instances. Default: true
  squish_clients: false # Optional. Set 'true' to put all clients in one folder. Default: false
  client_postfix: Client # Optional. Set postfix for Client class and file. Default: Client
  freezed: false # Optional (dart only). Set 'true' to generate data classes using freezed package. Default: false
  replacement_rules: # Optional. Set regex replacement rules for the names of the generated classes/enums. All rules are applied in order.
    - pattern: "[0-9]+"
      replacement: ""
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

### Generate files using [build_runner](https://pub.dev/packages/build_runner) for retrofit, json_serializable and freezed
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
