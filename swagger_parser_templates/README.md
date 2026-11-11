# swagger_parser_templates

[![Pub version](https://img.shields.io/pub/v/swagger_parser_templates?logo=dart)](https://pub.dev/packages/swagger_parser_templates)
[![Pub likes](https://img.shields.io/pub/likes/swagger_parser_templates?logo=dart)](https://pub.dev/packages/swagger_parser_templates)
[![Dart style](https://img.shields.io/badge/style-carapacik__lints%20-brightgreen?logo=dart)](https://pub.dev/packages/carapacik_lints)
[![GitHub stars](https://img.shields.io/github/stars/Carapacik/swagger_parser?logo=github)](https://github.com/Carapacik/swagger_parser)
[![Last commit](https://img.shields.io/github/last-commit/Carapacik/swagger_parser?logo=github)](https://github.com/Carapacik/swagger_parser)
[![Tests](https://github.com/Carapacik/swagger_parser/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/Carapacik/swagger_parser/actions/workflows/tests.yml)

Optional Mustache templates for [`swagger_parser`](../swagger_parser/README.md).
Extend or replace generated Dart files and add helpers.
Supports all four serializers and three HTTP clients. Runs on VM and web.

## Install

```yaml
dev_dependencies:
  swagger_parser: ^2.1.0
  swagger_parser_templates: ^1.1.0
```

Run `dart pub get`. Core is a transitive dependency. For runtime generation,
put both packages under `dependencies`.

## How it works

The parser resolves the schema and maps Dart types first. The renderer then
selects a template for each planned file. Files without a template keep their
built-in source. `{{defaultSource}}` retains that source inside a template.
The result is formatted with `generation.page_width`.

Templates change source output. They do not change reference resolution,
model selection, type mapping, or the planned file names. Package builders
still produce Retrofit, Freezed, json_serializable, and dart_mappable parts.

## Replace or extend files

Create `swagger_parser.yaml`:

```yaml
schema_path: api/stations.yaml
output_directory: lib/generated
generation:
  page_width: 80
  templates:
    client: templates/routes.mustache
    stations/models/station.dart: templates/station.mustache
```

Template paths are relative to the config file. An exact output path overrides
a kind selector. Unknown selectors fail. An empty map keeps all built-in files.

| Selector | Files |
| --- | --- |
| `api` | Root API class |
| `exports` | Public exports |
| `models` | DTOs, enums, and unions |
| `client` | HTTP clients |
| `results` | Operation result variants |
| `support` | Request options, response wrappers, decoders, validators, and metadata |
| Exact path | One planned file, including its configured suffix |

For example, `templates/routes.mustache` adds route constants:

```mustache
{{defaultSource}}
abstract final class {{library.clientName}}Routes {
{{#library.operations}}
  static const {{name}} = {{pathLiteral}};
{{/library.operations}}
}
```

`pathLiteral` includes Dart quotes and escapes. Omit `{{defaultSource}}` only
when replacing the whole file. Preserve its required declarations and codecs.
Mustache values are not HTML-escaped. Escape raw schema text for Dart literals.

Run the template CLI:

```sh
dart run swagger_parser_templates -f swagger_parser.yaml
dart run swagger_parser_templates --check -f swagger_parser.yaml
dart run swagger_parser_templates -h
```

It uses the main CLI's config discovery, arguments, URL downloads, credentials,
and validation command. `--check` compares generated files without writing.
Use this command for `generation.templates`; the main CLI does not load templates.
See the shared [configuration reference](../swagger_parser/CONFIGURATION.md).

## Add helper files

```yaml
generation:
  templates:
    files:
      - template: templates/page.mustache
        output: helpers/page.dart
      - template: templates/internal.mustache
        output: helpers/internal.dart
        export: false
```

`template` and `output` are required. `export` defaults to `true`. Exported
helpers are added to `exports.dart` and exposed by the public API import.
A custom exports template must keep `{{defaultSource}}` or emit these exports.
Helpers are included in generated files and `--check`.

For example, `templates/page.mustache` can contain:

```dart
class Page<T> {
  const Page({required this.items});

  final List<T> items;
}
```

To use this base, also replace the concrete page model and retain its codecs.
Adding a helper does not change existing types. See the tested
[generic page templates](test/fixtures/pagination/).

Helper outputs are relative POSIX paths inside the output directory. They must
end in `.dart`. Paths cannot escape that directory or collide with another file
or directory, including case-only differences. Builder suffixes `.g.dart`,
`.freezed.dart`, and `.mapper.dart` are rejected. `file_suffix` does not rename helpers.
Invalid paths, templates, or Dart syntax stop generation before output is written.

## Multiple schemas

```yaml
output_directory: lib/generated
generation:
  templates:
    client: templates/routes.mustache
    files:
      - template: templates/page.mustache
        output: helpers/page.dart
inputs:
  stations:
    schema_path: api/stations.yaml
  trips:
    schema_path: api/trips.yaml
    generation:
      templates:
        client: templates/trips.mustache
        files: []
```

Each input has its own output directory and effective settings. Child selectors
override matching keys and retain other root selectors. A child helper list
replaces the inherited list. `files: []` disables inherited helpers.
All template paths remain relative to the config file.

## Use from Dart

Pass template text, not paths:

```dart
import 'package:swagger_parser/swagger_parser.dart';
import 'package:swagger_parser_templates/swagger_parser_templates.dart';

Future<GenerationResult> generate(String schema, String client, String helper) {
  final runner = SwaggerParserRunner(
    generator: DartGenerator(
      renderer: MustacheSourceRenderer(
        {'client': client},
        files: [
          TemplateFile(
            relativePath: 'helpers/page.dart',
            source: helper,
            export: true,
          ),
        ],
      ),
    ),
  );
  return runner.generate(SchemaSource(schema));
}
```

`result.files` contains relative paths and rendered source. The application
writes files or creates an archive. The renderer does not read the filesystem.

## Template data

| Key | Value |
| --- | --- |
| `contractVersion` | Context version, currently `1` |
| `relativePath` | Final output path |
| `kind` | File kind or `helper` |
| `defaultSource` | Formatted built-in source; empty for helpers |
| `options` | Effective generation settings, with Dart camelCase names |
| `library` | Declarations, types, imports, operations, and metadata for this file |
| `files` | Planned file contexts; available to helpers only |

Helpers can inspect the planned libraries through `files`. Extra helpers are
not included in that list. Its entries have an empty `defaultSource`.
Credentials are never exposed in template data.

See the [context reference](CONTEXT.md) for defaults, presence, custom codecs,
directional models, discriminators, documentation, validators, and API metadata.
See [CONTRIBUTING.md](../CONTRIBUTING.md) for checks.
