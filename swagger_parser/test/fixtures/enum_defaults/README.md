# Enum defaults

Each valid input combines DTO, query, form-urlencoded, multipart, and JSON body defaults.
JSON and block YAML cover all four specification families.

- Inline and referenced enums use declared members after name replacement.
- Numeric enums retain numeric wire values.
- allOf wrappers retain inherited and local defaults.
- Reserved names and escaped strings keep their wire values.
- Nullable DTO and form enums accept null.
- HTTP argument defaults apply only when enabled.
- Body annotations and multiline Dartdoc build with Retrofit.

Invalid DTO and query inputs stay separate for generation diagnostics.
Query default diagnostics apply only when substitution is enabled.
