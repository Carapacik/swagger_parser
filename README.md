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
- Generate data classes, using one of the following serializer:
  - [json_serializable](https://pub.dev/packages/json_serializable)
  - [freezed](https://pub.dev/packages/freezed)
  - [dart_mappable](https://pub.dev/packages/dart_mappable)
- Support for multiple languages (Dart, Kotlin)
- Web interface at https://carapacik.github.io/swagger_parser
