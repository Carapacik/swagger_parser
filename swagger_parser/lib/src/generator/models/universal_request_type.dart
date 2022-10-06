import 'universal_type.dart';

/// Universal template for containing information about Request parameter
class UniversalRequestType {
  const UniversalRequestType({
    required this.parameterType,
    required this.type,
    this.name,
  });

  /// Request parameter key
  final String? name;

  /// Request parameter type
  final UniversalType type;

  /// Request parameter http type
  final HttpParameterType parameterType;
}

enum HttpParameterType {
  header('Header'),
  path('Path'),
  body('Body'),
  query('Query'),
  part('Part'),
  formData('Part');

  const HttpParameterType(this.type);

  final String type;

  bool get isPart =>
      this == HttpParameterType.part || this == HttpParameterType.formData;

  bool get isBody => this == HttpParameterType.body;
}
