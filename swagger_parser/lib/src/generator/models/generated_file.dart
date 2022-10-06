/// Used to store information for generating files.
class GeneratedFile {
  const GeneratedFile({required this.name, required this.contents});

  /// File name
  final String name;

  /// File content
  final String contents;
}
