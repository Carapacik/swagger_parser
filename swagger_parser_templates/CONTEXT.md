# Template context

Mustache templates receive mapped Dart declarations, not raw OpenAPI objects.
Names, filters, custom types, and file paths are resolved before rendering.
Use the [README](README.md) for installation, selectors, helpers, and CLI examples.

## File context

In Dart, pass template **text** to `MustacheSourceRenderer`.
Each template receives `contractVersion` (1), `relativePath`, `kind`,
`options`, `library`, and the complete formatted `defaultSource`.
The library contains the mapped DTOs, operations, results, facade fields,
or exports for that file. Options use Dart names and enum values.
Naming options are available as `options.fallbackClientName` and `options.naming`.
Unknown-value policies use `options.unknownEnumValues` and
`options.unknownDiscriminatorValues`. Open enums expose `openNames` with
`values`, `known`, `unknown`, and `rawType`. Unions expose `unknownType`.
Fields expose `discriminatorValues` for strict known-tag checks.
Type rules are in `options.typeMappings`, including `direction`. Mapped types expose `scalarCodec`
with import URIs, prefixes, function names, wire type, adapter, and predicate.
For compatibility, `scalarCodec` also describes object codecs. Its `wireType` is
`Map<String, Object?>`. Its `defaults` list contains JSON values and qualified
constant expressions. `options.typeMappings[].defaults` retains the config entries.
`library.constantImports` provides URI-to-prefix pairs for constant expressions.
Unmapped types expose null. `library.typeExports` lists public external types.
Use `defaultSource` to retain the built-in scalar adapters and predicates.
Template paths and declarations use the final generated names.
`options.operationFilters` exposes include/exclude paths and tags in camelCase.
`options.originalHttpResponse` wraps first-success payloads with transport metadata.
It defaults to `false` and has no effect in all-status mode. The package:http
wrapper uses the `support` template kind.
`options.decodeResponsesInBackground` enables native response workers. It defaults
to `false`. Decoder libraries use `support`; web uses an inline fallback.

`options.applyParameterDefaults` enables defaults for optional HTTP arguments.
It defaults to false. Parameters and form fields expose `defaultExpression`.
Use that expression as a Dart argument default; do not replace explicit null.

`options.bodyPositional` selects required positional body arguments. It defaults
to false. Custom client templates must keep optional bodies and form fields named.

`options.inferMissingRequired` defaults to true. Fields expose the effective
`isRequired` value. Core schema objects stay unchanged.
`options.usePresenceRecords` defaults to false. Use each field's `tracksPresence`
value to select a record. Plain optional nullable fields omit null keys.

Operations are already filtered. Models follow pruning and retention settings.
Directional DTOs expose `ignoredWireKeys`. Omit these keys in both codecs,
including additional properties. Types already use their request or response names.
Fixed discriminator fields expose `isFixed`, `fixedValue`, and `fixedExpression`.
Keep these fields out of constructors and copyWith. Emit a getter, validate the
required wire value on input, and write that value on output.
Fields expose `hasDefault`, `defaultValue`, and `defaultExpression`. Use the mapped
expression for constructor defaults. Apply JSON defaults only when a key is absent.
Use `{{defaultSource}}` to keep the built-in output. Interpolated values
use raw text. Escape schema strings before placing them in Dart literals.
The renderer applies `page_width` to the result. Package builders produce
their own parts. A template error stops generation before generated files are written.

## Helper context

Helper context contains `contractVersion`, `relativePath`, `kind: helper`,
`options`, an empty library model, and `files`. Each `files` item contains a
planned library context, including `relativePath`, `kind`, and `library`.
`defaultSource` is empty for helpers and for entries in this list. Extra files
are not included in the list. Helpers use their own templates, not kind selectors.

## Generation settings and metadata

Template options include `excludeParameters`, `pruneUnusedModels`, and
`keepModels`. Parameter rules expose `name`, `location`, `paths`, and `methods`.
Selection runs before rendering. Templates receive retained declarations only.

`options.usePathForMethodNames` exposes the method naming mode. It defaults to
false. Method and result names are resolved before template rendering.

`options.fileSuffix` exposes the internal filename suffix. The default is empty.
`relativePath`, imports, exports, model paths, and client paths use final names.
Client contexts expose `library.httpRequestOptionsPath` and
`library.httpResponsePath` for support imports. Per-file template overrides use
suffixed paths. The public entry and `exports.dart` keep their names.

The facade title and versions are always generated. `options.apiMetadata` is
`none` (default), `generate`, or `generateAndAttach`. Operation constants and the
facade operation list are omitted in `none`. Only `generateAndAttach` adds request
extras. Shared metadata and client companions use
the `support` kind. The context exposes `metadataTypeName`, `metadataTypePath`,
`clientMetadataName`, `clientMetadataPath`, `metadataOperations`, and
`attachOperationMetadata`. Operations include source `operationId`, `tags`, and
`externalDocsUrl`. Facade context includes `title`, `specVersion`, `metadataNames`,
and `operationConstants`; `version` remains the API version.

`options.generateValidators` defaults to false. Enabled model contexts expose
`validators`, `validatorExtensions`, `validationErrorName`, and
`validationErrorImport`. The shared error library uses the `support` kind and
sets `validationErrors`. Preserve these declarations when replacing model output.

Source metadata is available in `library.documentation` by declaration name and
`library.fieldDocumentation` by class and field name. Entries contain `summary`,
`description`, and `deprecated`. Client parameters, bodies, and form fields expose
the same keys. `generate_docs: false` removes source text but retains deprecation.
