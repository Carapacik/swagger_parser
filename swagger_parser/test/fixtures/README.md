# Generator fixtures

Group inputs by behavior. Keep equivalent JSON and block-style YAML pairs.
Use one versioned schema for related valid cases when names and options agree.
Keep independent files for external references, CLI config, source-location
checks, incompatible settings, and large graphs.

| Group | Coverage |
| --- | --- |
| `collections`, `composition/all_of` | Nested containers, inherited fields, and reference graphs |
| `references` | Reusable definitions, scalar aliases, case, imports, and reference diagnostics |
| `scalar_formats`, `binary_types` | Dates, int64, binary aliases, and wire values |
| `enum_names`, `enum_values`, `unknown_values` | Labels, scalar enums, and fallback policies |
| `enum_values/contracts` | Exact JSON types, external enums, allOf, and HTTP wire values |
| `enum_defaults` | Declared members, renamed labels, const defaults, and query/form wire values |
| `fixed_discriminators`, `union_titles` | Discriminator fields and branch names |
| `defaults`, `required_inference`, `x_nullable`, `directions` | Field presence, defaults, and projections |
| `type_mappings`, `object_mappings`, `directional_mappings` | Custom types, imports, codecs, and constants |
| `naming`, `method_naming`, `file_suffix`, `tag_grouping` | Public names and output paths |
| `extraction` | Baseline API extraction and composed schemas |
| `extraction/background_decoding` | JSON response DTOs, enums, nulls, and errors in all four families |
| `documentation`, `dto_validation` | Dartdoc, deprecation, and explicit validators |
| `api_metadata`, `body_positional`, `original_http_response`, `parameter_defaults` | HTTP method APIs |
| `operation_filters`, `model_selection` | Operation, parameter, and model selection |
| `cli`, `inputs`, `schema_download` | CLI config, batch output, and downloads |
| `schema_graphs` | Large cyclic schemas |

`enum_names/invalid_v*` stores independent named cases. Tests select one case
before generation and retain URI and JSON Pointer assertions. CLI errors remain
separate documents because each test must parse the complete config file.

Do not duplicate fixtures for issue numbers. Keep those links in
the local audit. Do not merge schemas with different semantics to reduce files.

- `multipart/contracts/`: upload cardinality, nulls, metadata, references, raw bodies, and URL-encoded forms.

- `responses/`: shared status/body contracts and invalid response type diagnostics.

- `responses/binary/`: PDF/XLSX payloads, raw byte streams, and response wrappers.

- `collections/nullability/`: container/item nulls, defaults, compositions, and query diagnostics.
- `composition/unions/`: shared branches, nullable variants, custom offset codecs, and invalid mappings.
- `naming/contracts/`: scalar types, reserved names, escaped keys, and enum literals.
- `http_media/`: JSON media selection, cookies, and invalid URL-encoded bodies.
- `extraction/path_metadata/`: inherited parameters, extensions, servers, and security.
- `diagnostics/contracts/`: invalid schema fields with source locations.
