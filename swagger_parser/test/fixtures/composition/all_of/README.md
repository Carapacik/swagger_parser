# Composition regressions

Each version has equivalent JSON and block-style YAML inputs.

- `v2`, `v3_0`, `v3_1`, `v3_2`: inheritance, repeated fields, nested DTOs,
  single-branch wrappers, nullable intersections, and defaults.
- `base`, `sub/branches`: external diamonds, escaped targets, and a cycle.
- `invalid_*`: incompatible types and composition cycles. Tests select one
  named case before generation so the first failure does not hide other cases.

Tests reverse declarations in memory. No duplicate ordering fixture is needed.
