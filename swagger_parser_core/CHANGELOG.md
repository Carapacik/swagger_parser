# Changelog

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
