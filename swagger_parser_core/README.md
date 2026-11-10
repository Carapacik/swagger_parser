# swagger_parser_core

[![Pub version](https://img.shields.io/pub/v/swagger_parser_core?logo=dart)](https://pub.dev/packages/swagger_parser_core)
[![Pub likes](https://img.shields.io/pub/likes/swagger_parser_core?logo=dart)](https://pub.dev/packages/swagger_parser_core)
[![Dart style](https://img.shields.io/badge/style-carapacik__lints%20-brightgreen?logo=dart)](https://pub.dev/packages/carapacik_lints)
[![GitHub stars](https://img.shields.io/github/stars/Carapacik/swagger_parser?logo=github)](https://github.com/Carapacik/swagger_parser)
[![Last commit](https://img.shields.io/github/last-commit/Carapacik/swagger_parser?logo=github)](https://github.com/Carapacik/swagger_parser)
[![Tests](https://github.com/Carapacik/swagger_parser/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/Carapacik/swagger_parser/actions/workflows/tests.yml)

OpenAPI parsing, validation, reference resolution, and normalization for
[`swagger_parser`](../swagger_parser/README.md). Also works as a standalone library.

Supports Swagger 2.0 and OpenAPI 3.0.x, 3.1.x, and 3.2.x in JSON or YAML.
Runs on VM and web. Does not generate Dart code.

## Install

```yaml
dependencies:
  swagger_parser_core: ^1.0.1
```

Run `dart pub get`.

## Parse

```dart
import 'package:swagger_parser_core/swagger_parser_core.dart';

final document = const OpenApiParser().parse(SchemaSource(text));
final report = const OpenApiValidator().validate(document);
final json = document.toJson();
```

`text` contains JSON or YAML. Use `SchemaSource.json` or `SchemaSource.yaml`
to require one format. Parsing returns an immutable, version-specific document.
Errors include the source URI, JSON Pointer, and available coordinates.

See the [guide](GUIDE.md) for input bytes, parser settings, external references,
and normalization. See [CONTRIBUTING.md](../CONTRIBUTING.md) for checks.
