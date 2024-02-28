# Swagger Parser
[![pub version](https://img.shields.io/pub/v/swagger_parser?logo=dart)](https://pub.dev/packages/swagger_parser)
[![pub likes](https://img.shields.io/pub/likes/swagger_parser?logo=dart)](https://pub.dev/packages/swagger_parser)
[![dart style](https://img.shields.io/badge/style-carapacik__lints%20-brightgreen?logo=dart)](https://pub.dev/packages/carapacik_lints)
[![Star on Github](https://img.shields.io/github/stars/Carapacik/swagger_parser?logo=github)](https://github.com/Carapacik/swagger_parser)
[![Last commit on Github](https://img.shields.io/github/last-commit/Carapacik/swagger_parser?logo=github)](https://github.com/Carapacik/swagger_parser)
[![Tests](https://github.com/Carapacik/swagger_parser/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/Carapacik/swagger_parser/actions/workflows/tests.yml)

## Swagger Parser is a Dart package that takes an OpenApi definition file and generates REST clients based on **retrofit** and data classes for your project.

* Supports OpenApi v2, v3.0 and v3.1
* Can generate files from `JSON` and `YAML` format
* Generation by definition link or from file
* Support for multiple definitions
* Supports **Dart** and **Kotlin**
  * Serializers supported for _dart_:  
    * [json_serializable](https://pub.dev/packages/json_serializable)
    * [freezed](https://pub.dev/packages/freezed)
    * [dart_mappable](https://pub.dev/packages/dart_mappable)
  * Serializers supported for _kotlin_:
    * [moshi](https://github.com/square/moshi)
***
We also have a web interface so you can try out swagger parser: https://carapacik.github.io/swagger_parser
