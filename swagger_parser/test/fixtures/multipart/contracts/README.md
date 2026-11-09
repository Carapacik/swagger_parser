# Multipart contracts

Each version has JSON and block YAML inputs. Related upload cases share one
schema. External targets and malformed inputs stay separate.

- Files: scalar, optional, nullable, repeated, empty, and in-memory bytes.
- Fields: requiredness, descriptions, wire names, enums, and null omission.
- Forms: URL encoding, repeated fields, and explicit JSON multipart parts.
- References: inline, named, external, allOf, and reuse as a JSON DTO.
- Raw bodies: empty objects, closed objects, arrays, dynamic fields, and absence.

Swagger 2.0 supports scalar form files. Its file-array input is a diagnostic
case. OpenAPI 3.x covers file arrays, object parts, and request body references.
Explicit JSON part encoding sends null as JSON `null`. Other null parts and
null list items are omitted. Empty files remain parts with zero bytes.
