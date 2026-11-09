# Model identity

Each family has matching JSON and block YAML inputs.

- Equal login response shapes keep separate inline DTOs and nested DTOs.
- LoginResponse200 reserves a name that an inline response would otherwise use.
- Station and Depot have equal shapes but different schema identities.
- Trips uses Shared before Stations. Shared references Station twice.
- Type and type define different enums. EnumUse also repeats one reference.
- CaseModel uses case-sensitive keys, quoted keys, nested objects, and an example.
- Merged repeats one allOf property and contains two colliding Dart identifiers.
- Nearby returns inline array items with referenced coordinates.
- Authentication inputs use operationId and full method/path fallback names.

Tests derive a changed inline occurrence, reordered paths, and an inline-only
document from each input. They verify independence, ownership, and exact file
sets without duplicate fixtures. Browser tests use the in-memory generator.
