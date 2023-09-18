/// Exception thrown when a yaml config is not correct
class ConfigException implements Exception {
  /// Constructor for [ConfigException]
  const ConfigException(this.message);

  /// A message describing the config error
  final String message;

  @override
  String toString() => 'ConfigException: $message';
}
