# Swagger Parser
[![pub package](https://img.shields.io/pub/v/swagger_parser.svg)](https://pub.dev/packages/swagger_parser)
[![Style](https://img.shields.io/badge/style-carapacik_lints-40c4ff.svg)](https://pub.dev/packages/carapacik_lints)
[![Star on Github](https://img.shields.io/github/stars/Carapacik/swagger_parser.svg?style=flat&logo=github&colorB=deeppink&label=stars)](https://github.com/Carapacik/swagger_parser)
[![Last commit on Github](https://img.shields.io/github/last-commit/Carapacik/swagger_parser)](https://github.com/Carapacik/swagger_parser)
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
  # dio: ^4.0.0
  # json_annotation: ^4.7.0
  # retrofit: ^3.3.0

dev_dependencies:
  # build_runner: ^2.3.0
  # json_serializable: ^6.5.0
  # retrofit_generator: ^4.2.0
  swagger_parser: ^0.6.1
```

### Configure package

Add your OpenApi json file configuration to your `pubspec.yaml` or create a new config file called `swagger_parser.yaml`.
An example of YAML is shown below

```yaml
swagger_parser:
  schema_path: assets/openapi.json # Required. Sets the open api schema path directory for api definition
  output_directory: lib/api # Required. Sets output directory for generated files (api clients and models)
  language: dart # Optional. Sets the programming language. Current available languages are: dart, kotlin. Default: dart
  squish_clients: false # Optional. Set 'true' to put all clients in one folder. Default: false
  client_postfix: ApiClient # Optional. Set postfix for client folder and Class. Works if there is only a single class or squish is true. Default: ApiClient
  freezed: false # Optional (dart only). Set 'true' to generate data classes using freezed package. Default: false
```

### Run the generator

To generate boilerplate code, run the `generate` program inside directory where your `pubspec.yaml` file is located:
```shell
dart run swagger_parser:generate
```
For Flutter projects, you can also run:
```shell
flutter pub run swagger_parser:generate
```

If you name your configuration file something other than `swagger_parser.yaml` or `pubspec.yaml` 
you will need to specify the name of the YAML file as an argument.

```shell
dart run swagger_parser:generate -f <path to your config file>
```

### Generate files using build_runner for retrofit, json_serializable and freezed

To run the code generator, execute the following command:
```shell
dart run build_runner build
```
For Flutter projects, you can also run:
```shell
flutter pub run build_runner build
```
