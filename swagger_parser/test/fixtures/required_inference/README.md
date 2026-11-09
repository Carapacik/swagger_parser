# Required fields

Each family has matching JSON and block YAML inputs.

- `Station`, `Empty`, and `Partial`: missing and explicit required lists.
- `All*`: required lists across object compositions.
- `Sibling*`: one composed property beside plain, nullable, and defaulted fields.
  `SiblingDirect` replaces allOf with a direct reference. `SiblingReduced`
  removes required names. `Code` and `code` remain distinct wire keys.
- `RequiredChild`: nested required fields do not set parent requiredness.
- `external_*`: referenced nullability and defaults.
- `*_invalid_empty`: legacy empty-list errors.
- `*_invalid_case`: a closed object requires an undeclared, case-mismatched key.
- `config_*`: defaults, input overrides, and invalid settings.

Only OpenAPI 3.1/3.2 inputs use valid empty required lists. Their boolean
`plain` property includes an unsupported `nullable` annotation. It must not
override the boolean type. Swagger uses x-nullable; OpenAPI 3.0 uses nullable.

Tests vary required inference and presence records independently. Consumer
tests build all four serializers and run codecs on VM and Chrome.
