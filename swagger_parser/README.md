# Swagger Parser
[![pub package](https://img.shields.io/pub/v/swagger_parser.svg)](https://pub.dev/packages/swagger_parser)
[![Style](https://img.shields.io/badge/style-carapacik_lints-40c4ff.svg)](https://pub.dev/packages/carapacik_lints)
[![Star on Github](https://img.shields.io/github/stars/Carapacik/swagger_parser.svg?style=flat&logo=github&colorB=deeppink&label=stars)](https://github.com/Carapacik/swagger_parser)
[![build](https://github.com/Carapacik/swagger_parser/workflows/tests.yml/badge.svg)](https://github.com/Carapacik/swagger_parser/actions/workflows/tests.yml)
<a href="https://omega-r.com/"><img src="https://raw.githubusercontent.com/Carapacik/swagger_parser/main/.github/readme/omega_logo.png" width="200" align="right"/></a>

## Dart package that generates REST clients and data classes from swagger json file

## Features

- Supports OpenApi v2, v3.0 and v3.1
- Generate REST client files based on Retrofit
- Generate data classes (also on [freezed](https://pub.dev/packages/freezed))
- Support for multiple languages (Dart, Kotlin)
- Web interface at https://carapacik.github.io/swagger_parser

### Run command

To generate boilerplate code, run the `generate` program inside directory where your `pubspec.yaml` file is located:
```shell
dart run swagger_parser:generate
```

Add your OpenApi json file configuration to your `pubspec.yaml` or create a new config file called `swagger_parser.yaml`.
An example of YAML is shown below

### Configure package
```yaml
dev_dependencies:
  swagger_parser: ^0.2.0

swagger_parser:
  json_path: assets/swagger.json # Required. Sets the json path directory for generated files
  output_directory: generated # Required. Sets output directory for generated files
  language: dart # Optional. Sets the programming language. Current available languages are: dart, kotlin. Default: dart
  squish_clients: true # Optional. Set 'true' to put all clients in one folder. Default: false
  client_postfix: Client # Optional. Set postfix for client folder and Class. Works if there is only a single class or squish is true. Default: Client
  freezed: false # Optional (dart only). Set 'true' to generate data classes using freezed package. Default: false
```

If you name your configuration file something other than `swagger_parser.yaml` or `pubspec.yaml` 
you will need to specify the name of the YAML file as an argument.

```shell
dart run swagger_parser:generate -f <path to your config file>
```
