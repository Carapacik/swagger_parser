# Enum label fixtures

`names_v*` combines label priority, collisions, replacements, null positions,
and scalar types. OpenAPI 3.1 and 3.2 also include const narrowing.

`invalid_v*` combines eight independent label errors. Tests select one named
schema as Invalid before generation. Each case retains its path and source URI
assertions. A failure must not hide the other cases.
