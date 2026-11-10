# Generated-file e2e

Input: schema files and CLI config. Output: exact file paths and contents.
These tests run the CLI. They do not construct parser or generator models.
They do not run build_runner, analyze generated code, or call generated clients.
Keep those checks in swagger_parser_tests.

Run from swagger_parser:

```sh
dart test test/e2e
```

The normal `dart test` command includes this suite. CI runs it before builders.
The CLI is compiled to a temporary kernel once per suite to reduce startup cost.
Generated files are never compiled in this suite.

## Add a case

Group related behavior in a folder. Each group contains:

```text
client_models/
  cases.yaml
  inputs/
    v2_0.json
    v2_0.yaml
    ...
  configs/
    plain_retrofit.yaml
    ...
  expected/
    clients/
      retrofit/
        exports.dart.golden
        stations/stations_client.dart.golden
        ...
    models/
      plain/
        stations/models/station.dart.golden
        ...
    api/
      retrofit/
        v2_0/transit_api.dart.golden
        ...
```

1. Add real JSON and block YAML schemas under inputs.
2. Add a normal CLI config under configs. Paths are relative to the config.
3. Add reviewed expected files. Append `.golden` to each output filename.
4. Register the config and output directories in cases.yaml.
5. Run the suite. Review each changed expected file before committing it.

No Dart test edit is needed for a new group or case. The suite finds each
cases.yaml below this folder. Each config runs in a separate temporary directory.
The inputs and configs folders are copied there. Expected files stay read-only.

Example manifest:

```yaml
cases:
  - name: generates plain Retrofit models and clients
    config: configs/plain_retrofit.yaml
    output: out
    expected:
      v2_0_json:
        - expected/models/plain
        - expected/clients/retrofit
        - expected/api/retrofit/v2_0
      v2_0_yaml:
        - expected/models/plain
        - expected/clients/retrofit
        - expected/api/retrofit/v2_0
```

`output` selects the actual output root, relative to the temporary directory.
Each expected key selects a subdirectory under that root. Use `.` for a single
output. Values list expected directories, relative to the fixture group.
Their file sets must not overlap. They combine files; they do not override them.
For a small case, use one expected directory without shared layers.

The suite removes only the `.golden` suffix from expected paths. It does not
normalize file contents, whitespace, versions, imports, or generated comments.
Missing files, extra files, and content changes fail the test. Duplicate expected
paths and unexpected CLI diagnostics also fail. The empty CLI lock file is part
of the expected output tree.

Do not update expected files during a test. To change a baseline, generate into
a temporary directory, inspect the output, then copy only approved files into
expected with the `.golden` suffix. Expected files must not hide a regression.
The suffix keeps source samples out of workspace analysis and builder discovery.

## Current matrix

client_models covers 96 outputs:

- Swagger 2.0 and OpenAPI 3.0.4, 3.1.2, and 3.2.1.
- JSON and YAML schemas; JSON and YAML CLI configs across the cases.
- Plain, json_serializable, Freezed, and dart_mappable.
- Retrofit, Dio, and package:http.

The grouped schema covers GET, JSON POST, a bodyless response, tagged and untagged
clients, and a shared DTO owned by its first client. Models cover named scalar
aliases, enums, allOf, an inline object, nullable fields, defaults, collections,
and an unused named DTO. Expected files include the facade, exports, clients,
models, support code, and part directives. Builder-generated parts are absent.
Only the facade differs by schema version. JSON and YAML share expected files.

Four focused groups add 14 outputs from paired JSON and block YAML:

- `reference_annotations` reuses types through annotation-only `allOf` properties.
- `enum_members` preserves negative numeric names and removes duplicate values.
- `required_inference` checks optional fields by default and explicit inference.
- `bodyless_success` checks nullable payloads and bodyless dispatch in all three clients.

These inputs match the generator and compiled-consumer regression fixtures.

Two more groups add eight outputs from paired JSON and block YAML:

- `reference_metadata` retains referenced enum types and property defaults.
- `contextual_identifiers` preserves `type` and `part` in models and all three clients.
