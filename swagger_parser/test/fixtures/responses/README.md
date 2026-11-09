# Response contracts

`status_v*` groups response status and body cases for all four schema families.
Each document has JSON and block YAML. The generator and consumer tests share
these inputs. They replace the consumer-only status fixtures.

- Unordered 200, 201, 202, 204, 400, 404, and 500 responses use distinct DTOs.
- One 201, one 207 with an inline enum, and 226 before 299 test success selection.
- List 200 and bodyless 204 responses test separate result variants.
- Bodyless 200 and only-error operations use void in first_success.
- An unconstrained JSON schema retains Object?, including JSON null and empty text.
- Required and optional headers retain existing client checks.

`*_empty_type` isolates the invalid empty type token and its source diagnostic.
Range/default cases remain in the consumer HTTP fixtures. They use different
contracts and do not test exact-success selection.
