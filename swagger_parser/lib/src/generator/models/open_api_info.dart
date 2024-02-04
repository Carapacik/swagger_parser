import 'package:meta/meta.dart';

/// Information about the API
@immutable
class OpenApiInfo {
  /// Constructor for [OpenApiInfo]
  const OpenApiInfo({
    this.title,
    this.summary,
    this.description,
    this.version,
  });

  /// Title of the API
  final String? title;

  /// Summary of the API
  final String? summary;

  /// Description of the API
  final String? description;

  /// Version of the API
  final String? version;
}
