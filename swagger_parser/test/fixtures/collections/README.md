# Collection regressions

Each version has equivalent JSON and block-style YAML inputs.

- `v2`, `v3_0`, `v3_1`, `v3_2`: maps, lists, nullable layers, and colliding names.
- `sub/status`: recursive DTO values and a relative external reference.
- `base`: the escaped external reference target.
- `values`: nested values for codec round trips.

Keep related cases in these schemas. Add a separate file only when resolution
or test isolation requires it.
