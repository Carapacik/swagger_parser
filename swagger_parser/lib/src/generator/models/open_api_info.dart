import 'package:meta/meta.dart';

/// Information about the API
@immutable
class OpenApiInfo {
  /// Constructor for [OpenApiInfo]
  const OpenApiInfo({
    required this.schemaVersion,
    this.apiVersion,
    this.title,
    this.summary,
    this.description,
  });

  /// OpenApi version of schema
  final OAS schemaVersion;

  /// Version of the API
  final String? apiVersion;

  /// Title of the API
  final String? title;

  /// Summary of the API
  final String? summary;

  /// Description of the API
  final String? description;
}

/// All versions of the OpenApi Specification that this package supports
enum OAS {
  /// 3.1.x
  v3_1,

  /// 3.0.x
  v3,

  /// 2.0
  v2;

  /// Constructor for OpenApi Specification
  const OAS();
}
