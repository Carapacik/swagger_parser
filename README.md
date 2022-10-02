# Swagger Parser
[![pub package](https://img.shields.io/pub/v/carapacik_lints.svg)](https://pub.dev/packages/carapacik_lints)
[![Style](https://img.shields.io/badge/style-carapacik_lints-40c4ff.svg)](https://github.com/Carapacik/carapacik_lints)
[![Star on Github](https://img.shields.io/github/stars/Carapacik/swagger_parser.svg?style=flat&logo=github&colorB=deeppink&label=stars)](https://github.com/Carapacik/swagger_parser)
<a href="https://omega-r.com/"><img src="./.github/readme/omega_logo.png" width="200" align="right"/></a>

## Dart package that generates REST clients and data classes from swagger json file

## Features

- Supports OpenApi v2, v3.0 and v3.1
- Generate REST client files based on Retrofit
- Generate data classes on [Freezed](https://pub.dev/packages/freezed)
- Support for multiple languages (Dart, Kotlin)

### Run command

To generate boilerplate code, run the `generate` program inside directory where your `pubspec.yaml` file is located:
```shell
dart pub run swagger_parser:generate
```

Add your OpenApi json file configuration to your `pubspec.yaml` or create a new config file called `swagger_parser.yaml`.
An example of YAML is shown below

### Configure package
```yaml
dev_dependencies:
  swagger_parser: ^0.1.0

swagger_parser:
  json_path: assets/swagger.json # Required. Sets the json path directory for generated files
  output_directory: generated # Required. Sets output directory for generated files
  language: dart # Optional. Sets the programming language. Current available languages are: dart, kotlin. Default: dart
  freezed: false # Optional (dart only). Set 'true' to generate data classes using freezed package. Default: false
```

If you name your configuration file something other than `swagger_parser.yaml` or `pubspec.yaml` 
you will need to specify the name of the YAML file as an argument.

```shell
dart pub run swagger_parser:generate -f <path to your config file>
```

### In future versions
 - [ ] Tests
