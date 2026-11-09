# Enum contracts

Pair JSON and block-style YAML for each schema family.

- `v*`: named and inline enums, aliases, nullable values, allOf, and HTTP inputs.
- `v*_external`: external enum targets.
- `v*_missing`: unresolved enum references.
- `v*_object_enum`: object types with incompatible scalar enum values.
- `value.json`: shared runtime input. Modern cases add a nullable mixed enum.

The valid schemas include an empty allOf intersection. Its generated validator
rejects every candidate. Decoding does not run validators automatically.
Mixed scalar type lists apply to OpenAPI 3.1/3.2 only.
