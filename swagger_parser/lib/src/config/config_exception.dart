/// Exception thrown when a config is not correct
class ConfigException implements Exception {
  /// Creates a  [ConfigException].
  const ConfigException(this.message);

  /// A message describing the config error
  final String message;

  @override
  String toString() => 'ConfigException: $message';
}
