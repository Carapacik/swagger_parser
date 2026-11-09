import 'package:swagger_parser/swagger_parser.dart';

/// Loads a renderer from one generation option.
abstract interface class CliRendererExtension() {
  /// Defines a renderer option for the CLI.
  this;

  /// File config key owned by this extension.
  String get option;

  /// Reads the option relative to the config directory.
  Future<DartSourceRenderer> load(Object? value, String directory);
}
