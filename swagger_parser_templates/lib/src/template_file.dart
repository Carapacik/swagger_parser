/// An extra Dart file rendered from a Mustache template.
final class const TemplateFile({
  /// Output path relative to the output directory. Must end in .dart.
  required final String relativePath,

  /// Template text. The CLI loads this text from a file.
  required final String source,

  /// Adds this file to the default exports.dart. Defaults to true.
  final bool export = true,
}) {
  /// Declares a helper file. Invalid or conflicting paths fail generation.
  this;
}
