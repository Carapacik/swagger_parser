# Core fixtures

- `parsing`: complete Swagger 2.0 and OpenAPI 3.x documents.
- `parsing/security_metadata`: OAuth grants, security alternatives, server
  variables, and service metadata for OpenAPI 3.1/3.2. Invalid auth stays separate.
- `normalization`: parameter serialization across four versions.
- `references`: external resources, anchors, and URI resolution.
- `validation`: Path Items, reused parameters, duplicates, and cycles.

Each parsing document already combines its version's schema and operation
features. Keep versions separate. Keep external resources and location-sensitive
errors in separate files. Preserve source descriptions, examples, and JSON/YAML pairs.
