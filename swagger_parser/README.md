# Swagger Parser
[![pub package](https://img.shields.io/pub/v/swagger_parser.svg)](https://pub.dev/packages/swagger_parser)
[![Style](https://img.shields.io/badge/style-carapacik_lints-40c4ff.svg)](https://pub.dev/packages/carapacik_lints)
[![Star on Github](https://img.shields.io/github/stars/Carapacik/swagger_parser.svg?style=flat&logo=github&colorB=deeppink&label=stars)](https://github.com/Carapacik/swagger_parser)
[![Tests](https://github.com/Carapacik/swagger_parser/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/Carapacik/swagger_parser/actions/workflows/tests.yml)
<a href="https://omega-r.com/"><img src="https://raw.githubusercontent.com/Carapacik/swagger_parser/main/.github/readme/omega_logo.png" width="200" align="right"/></a>

## Dart package that generates REST clients and data classes from swagger json file

## Features

- Supports OpenApi v2, v3.0 and v3.1
- Generate REST client files based on Retrofit
- Generate data classes (also on [freezed](https://pub.dev/packages/freezed))
- Support for multiple languages (Dart, Kotlin)
- Web interface at https://carapacik.github.io/swagger_parser

## Installation

### Add dependency

In your pubspec.yaml, add the following dependencies:

```yaml
dependencies:
  # ...
  dio: ^4.0.0
  json_annotation: ^4.7.0
  retrofit: ^3.3.0

dev_dependencies:
  # ...
  swagger_parser: ^0.3.0
  build_runner: ^2.3.0
  json_serializable: ^6.5.0
  retrofit_generator: ^4.2.0
```

Obs: versions above are just an initial reference and can be removed if conflicting with your versions.

### Create swagger_parser.yaml

This is the configuration file that will be read for running the parser according to your needs.

```yaml
swagger_parser:
  json_path: assets/swagger.json # Required. Sets the json path directory for api definition. This is just a suggestion for path
  output_directory: lib/api # Required. Sets output directory for generated files (api clients and models)
  language: dart # Optional. Sets the programming language. Current available languages are: dart, kotlin. Default: dart
  squish_clients: true # Optional. Set 'true' to put all clients in one folder. Default: false
  client_postfix: ApiClient # Optional. Set postfix for client folder and Class. Works if there is only a single class or squish is true. Default: Client
  freezed: false # Optional (dart only). Set 'true' to generate data classes using freezed package. Default: false
```

### Compile your generator locally

If you are using Flutter, you can replace all "dart run" calls with "flutter pub run".

To generate boilerplate code, run the `generate` program inside directory where your `pubspec.yaml` file is located:
```shell
dart run swagger_parser:generate
```

Add your OpenApi json file configuration to your `pubspec.yaml` or create a new config file called `swagger_parser.yaml`.
An example of YAML is shown below

If you name your configuration file something other than `swagger_parser.yaml` or `pubspec.yaml` 
you will need to specify the name of the YAML file as an argument.

```shell
dart run swagger_parser:generate -f <path to your config file>
```

Now run the builder for retrofit, json_serializable and freezed:

```shell
dart run build_runner build
```

## TODOS

- Dart output:
  - Inheritance mapped reading from "allOf" on model definition (could be a fix for the next item if ancestor class is used as the type).
  - Fix problem with oneOf, anyOf which creates a "List\<Null\>" and adds: import "null.dart"
  - Fix problem mapping properties on swagger named "default" as this is keyword in Flutter and causes crashes.
- Support URL for definition