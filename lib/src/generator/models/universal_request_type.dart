import 'package:swagger_parser/src/generator/models/universal_type.dart';

/// Universal template for containing information about Request parameter
class UniversalRequestType {
  const UniversalRequestType({
    required this.parameterType,
    required this.type,
    this.name,
  });

  final String? name;
  final UniversalType type;
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
