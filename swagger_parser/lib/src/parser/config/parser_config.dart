import '../model/replacement_rule.dart';

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
}
