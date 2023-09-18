/// Used to store information for generating files
class GeneratedFile {
  /// Constructor with [name] and file [contents]
  const GeneratedFile({required this.name, required this.contents});

  /// File name
  final String name;

  /// File content
  final String contents;
}
