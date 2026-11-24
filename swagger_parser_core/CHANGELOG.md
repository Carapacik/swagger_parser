# Changelog

## Unreleased

* Checks `allowEmptyValue` and `allowReserved` against the JSON Schema for each
  OpenAPI version and preserves accepted boolean values on export. In 3.0,
  parameters and Header Objects can declare either flag. In 3.1 and 3.2,
  `allowEmptyValue` requires a query parameter. In 3.1, `allowReserved` also
  requires a query parameter. In 3.2, path and form-style cookie parameters
  can also use `allowReserved`. In all three versions, `allowReserved` requires
  `schema`.
  The same checks apply to referenced parameters and headers in external files.
* Adds `withParseWarnings` to collect recoverable errors in a parse scope.
  For example, the parser can discard invalid optional metadata and remove
  duplicate entries from a schema's `required` list. Parsing is strict by default.
* Adds `Diagnostic.location` for the source line and column when available.
  Warnings for referenced fields identify the external file and JSON Pointer.

## 1.0.4

* Expands YAML merge keys (`<<`) with an anchored mapping or a sequence of mappings, following
  YAML 1.1 precedence. Merged entries fill a mapping without replacing its explicit keys, and a
  quoted `"<<"` or explicitly string-tagged key stays an ordinary key. Source locations follow
  the selected fields after merging. Such documents previously parsed with the merge key kept
  as an unknown field, which generated a wrong model without a diagnostic.

## 1.0.3

* Updates package styling.

## 1.0.2

* Adds pub.dev topics, documentation links, and the project icon.

## 1.0.1

* Adds a runnable parsing example and public API documentation.

## 1.0.0

* Initial release.
