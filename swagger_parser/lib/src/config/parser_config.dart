/// The configuration that the OpenApiParser uses
class ParserConfig {
  /// Creates a [ParserConfig].
  const ParserConfig(
    this.content, {
    required this.isJson,
    this.defaultContentType = 'application/json',
    this.pathMethodName = false,
    this.requiredByDefault = true,
    this.mergeClients = false,
    this.skippedParameters = const [],
  });

  /// Specification file content
  final Map<String, dynamic> content;

  /// Set `true` if your specification is json.
  /// Set `false` if yaml.
  final bool isJson;

  /// DART ONLY
  /// Default content type for all requests and responses.
  ///
  /// If the content type does not match the default, generates:
  /// @Headers(<String, String>{'Content-Type': 'PARSED CONTENT TYPE'})
  final String defaultContentType;

  /// DART ONLY
  /// It is used if the value does not have the annotations `required` and `nullable`.
  /// If the value is `true`, then value be `required`.
  /// If the value is `false`, then `nullable`.
  final bool requiredByDefault;

  /// If `true`, use the endpoint path for the method name.
  /// if `false`, use `operationId`.
  final bool pathMethodName;

  /// DART ONLY
  /// Set `true` to merge all clients in single client.
  final bool mergeClients;

  /// List of parameter names that should skip during parsing
  final List<String> skippedParameters;
}
