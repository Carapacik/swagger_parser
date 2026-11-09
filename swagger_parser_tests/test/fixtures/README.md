# Consumer fixtures

- `dto/serializers`: shared DTO, PATCH, and codec scenarios.
- `dto/unions`: response alternatives.
- `http/bodies`: request bodies and updates.
- `http/forms`: form fields, multipart, and batch values.
- `http/grouping`: tagged and untagged clients.
- `http/parameters`: query, path, header, and object serialization.
- `http/request_options`: cancellation and per-call settings.
- `http/responses`: range and default response selection. Exact status/body
  contracts are shared from `swagger_parser/test/fixtures/responses`.
- `http/streaming`: SSE, JSON Lines, and binary downloads.

Reuse generator fixtures from `swagger_parser/test/fixtures` when both test
layers need the same schema. Do not copy them into this package. Keep related
operations in a versioned document when their names and settings are compatible.
