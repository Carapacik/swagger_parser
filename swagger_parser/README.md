# swagger_parser

[![Pub version](https://img.shields.io/pub/v/swagger_parser?logo=dart)](https://pub.dev/packages/swagger_parser)
[![Pub likes](https://img.shields.io/pub/likes/swagger_parser?logo=dart)](https://pub.dev/packages/swagger_parser)
[![Dart style](https://img.shields.io/badge/style-carapacik__lints%20-brightgreen?logo=dart)](https://pub.dev/packages/carapacik_lints)
[![GitHub stars](https://img.shields.io/github/stars/Carapacik/swagger_parser?logo=github)](https://github.com/Carapacik/swagger_parser)
[![Last commit](https://img.shields.io/github/last-commit/Carapacik/swagger_parser?logo=github)](https://github.com/Carapacik/swagger_parser)
[![Tests](https://github.com/Carapacik/swagger_parser/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/Carapacik/swagger_parser/actions/workflows/tests.yml)

Generate Dart models and HTTP clients from OpenAPI JSON or YAML.

## Features

- Swagger 2.0 and OpenAPI 3.0.x, 3.1.x, and 3.2.x.
- Plain JSON codecs, json_serializable, Freezed, or dart_mappable.
- Retrofit + Dio, standalone Dio, or package:http clients.
- References, allOf, oneOf, anyOf, enums, and request/response models.
- Forms, multipart uploads, binary responses, SSE, and JSON Lines.
- Local files, authenticated schema URLs, and multiple inputs.
- CLI and in-memory generation for Dart VM and web.
- [Web interface](https://carapacik.github.io/swagger_parser) with config, templates, and ZIP downloads.

## Install

Minimum supported package versions for `pubspec.yaml`:

```yaml
dependencies:
  dart_mappable: ^4.10.0
  dio: ^5.11.1
  freezed_annotation: ^3.1.0
  http: ^1.6.0
  json_annotation: ^4.12.0
  retrofit: ^4.10.0

dev_dependencies:
  build_runner: ^2.16.2
  dart_mappable_builder: ^4.10.0
  freezed: ^4.0.3
  json_serializable: ^6.15.2
  retrofit_generator: ^10.3.3
  swagger_parser: ^2.0.0
```

Install only the packages for your chosen client and serializer.
Plain DTOs need no serializer dependency. See the
[separate examples](GUIDE.md#serializer-dependencies), then run `dart pub get`.

## Generate

Create `swagger_parser.yaml`. Supply your schema path. The generation values
below are defaults; omitted options also use their defaults.

```yaml
swagger_parser:
  schema_path: api/stations.yaml
  output_directory: lib/generated
  generation:
    root_api_class_name: Api
    http_client: retrofit
    serializer: plain
    response_mode: first_success
    generate_docs: true
    page_width: 80
```

Generate models and clients:

```sh
dart run swagger_parser
```

For Retrofit or a package serializer, build the generated parts:

```sh
dart run build_runner build
```

Import one file to use the clients and models:

```dart
import 'package:dio/dio.dart';
import 'generated/api.dart';

final api = Api(Dio(BaseOptions(baseUrl: 'https://example.com')));
final station = await api.stations.getStation(id: '42');
```

Client and method names come from your schema.

See [Configuration](CONFIGURATION.md) for every option, default, output example,
and conflict. See the [generation guide](GUIDE.md) for library APIs, consumer
dependencies, DTOs, and HTTP behavior.

## Other commands

```sh
dart run swagger_parser -f config.yaml
dart run swagger_parser --schema_url https://example.com/openapi.yaml
dart run swagger_parser validate -f config.yaml
dart run swagger_parser --check -f config.yaml
dart run swagger_parser -h
```

`validate` checks the schema. `--check` compares generated files without writing.
Use `-o` to override the output directory.

## Custom output and web

For output beyond the built-in options, use
[swagger_parser_templates](https://github.com/Carapacik/swagger_parser/tree/main/swagger_parser_templates).
It supports custom templates and extra helper files through a separate CLI.

The web editor generates files locally and downloads a ZIP.

## Contributing

See [CONTRIBUTING.md](https://github.com/Carapacik/swagger_parser/blob/main/CONTRIBUTING.md)
for issues, PRs, code style, fixtures, and checks. Report vulnerabilities through
[SECURITY.md](https://github.com/Carapacik/swagger_parser/blob/main/SECURITY.md).
