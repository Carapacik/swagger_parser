import 'package:meta/meta.dart';

/// Used to store information for generating files
@immutable
class GeneratedFile {
  /// Constructor with [name] and file [content]
  const GeneratedFile({required this.name, required this.content});

  /// File name
  final String name;

  /// File content
  final String content;
}
