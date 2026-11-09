final _invalidUriCharacter = RegExp(
  r"[^A-Za-z0-9:/?#\[\]@!$&'()*+,;=._~%\-]|%(?![0-9a-fA-F]{2})",
);

/// Parses a URI reference without repairing invalid characters or escapes.
Uri? parseUriReference(String text) =>
    _invalidUriCharacter.hasMatch(text) ? null : Uri.tryParse(text);
