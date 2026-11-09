# Defaults and PATCH

The four defaults_v* pairs use JSON and block YAML.

- Options: scalar, enum, reference, object, and allOf defaults; directional fields.
- PatchChanges: absent/null/value states, renamed keys, references, and nested data.
  notesPresent and copyWith are ordinary source properties.
- PatchEnvelope: required nullable keys beside optional defaulted fields.
- CollectionDefaults: empty and nested const collections and typed enum defaults.

Swagger nullable fields use x-nullable. OpenAPI 3.0 uses nullable. OpenAPI
3.1/3.2 use null in the type list. Both nullable APIs use the same fixtures.
Malformed defaults stay in separate inputs.

Consumer tests build four serializers and three clients. They check codecs,
PATCH bytes, and supported copyWith APIs on VM and Chrome. copyWith checks
apply to Freezed and dart_mappable only.
