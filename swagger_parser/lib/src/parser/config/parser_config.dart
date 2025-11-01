import 'package:swagger_parser/src/parser/model/replacement_rule.dart';

/// The configuration that the OpenApiParser uses
class ParserConfig {
  /// Creates a [ParserConfig].
  const ParserConfig(
    this.fileContent, {
    required this.isJson,
    this.name,
    this.defaultContentType = 'application/json',
    this.pathMethodName = false,
    this.mergeClients = false,
    this.enumsParentPrefix = true,
    this.skippedParameters = const <String>[],
    this.replacementRules = const [],
    this.useXNullable = false,
    this.excludeTags = const <String>[],
    this.includeTags = const <String>[],
    this.fallbackClient = 'fallback',
    this.inferRequiredFromNullable = false,
  });

  /// Specification file content as [String]
  final String fileContent;

  /// Set `true` if your specification is json.
  /// Set `false` if yaml.
  final bool isJson;

  /// Optional. Set API name for folder and export file.
  /// If not specified, the file name is used.
  final String? name;

  /// DART ONLY
  /// Default content type for all requests and responses.
  ///
  /// If the content type does not match the default, generates:
  /// `@Headers(<String, String>{'Content-Type': 'PARSED CONTENT TYPE'})`
  final String defaultContentType;

  /// If `true`, use the endpoint path for the method name.
  /// if `false`, use `operationId`.
  final bool pathMethodName;

  /// Set `true` to merge all clients in single client.
  final bool mergeClients;

  /// Set 'true' to set enum prefix from parent component.
  final bool enumsParentPrefix;

  /// List of parameter names that should skip during parsing
  final List<String> skippedParameters;

  /// Optional. Set regex replacement rules for the names of the generated classes/enums.
  /// All rules are applied in order.
  final List<ReplacementRule> replacementRules;

  /// Does the Schema use x-nullable to indicate nullable fields
  /// Only used for OpenApi v2
  final bool useXNullable;

  /// Optional. Set excluded tags.
  ///
  /// Endpoints with these tags will not be included in the generated clients.
  final List<String> excludeTags;

  /// Optional. Set included tags.
  ///
  /// If set, only endpoints with these tags will be included in the generated clients.
  /// **NOTE: This will override the [excludeTags] if set.**
  final List<String> includeTags;

  /// DART ONLY
  /// Optional. Fallback client name for endpoints without tags.
  ///
  /// defaults to 'fallback' which results in a client named `FallbackClient`.
  final String fallbackClient;

  /// When true, infer required properties from nullability.
  /// Properties without nullable: true in schema are marked as required.
  /// Only applies when schema has no explicit required array.
  final bool inferRequiredFromNullable;
}
