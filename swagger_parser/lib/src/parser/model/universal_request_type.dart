import 'package:meta/meta.dart';
import 'package:swagger_parser/src/parser/model/universal_type.dart';

/// Universal template for containing information about Request parameter
@immutable
final class UniversalRequestType {
  /// Constructor for [UniversalRequestType]
  const UniversalRequestType({
    required this.parameterType,
    required this.type,
    this.description,
    this.name,
    this.deprecated = false,
  });

  /// Request parameter key
  final String? name;

  /// Request parameter type
  final UniversalType type;

  /// Request parameter http type
  final HttpParameterType parameterType;

  /// Request parameter description
  final String? description;

  /// Whether or not this parameter is deprecated
  final bool deprecated;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UniversalRequestType &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          type == other.type &&
          parameterType == other.parameterType &&
          deprecated == other.deprecated;

  @override
  int get hashCode =>
      name.hashCode ^
      type.hashCode ^
      parameterType.hashCode ^
      deprecated.hashCode;

  @override
  String toString() => 'UniversalRequestType(name: $name, '
      'type: $type, '
      'parameterType: $parameterType, '
      'deprecated: $deprecated)';
}

/// Type of parameter in rest client
enum HttpParameterType {
  /// `@Header`
  header('Header'),

  /// `@Path`
  path('Path'),

  /// `@Body`
  body('Body'),

  /// `@Extras`
  extras('Extras'),

  /// `@Query`
  query('Query'),

  /// `@Part`
  part('Part'),

  /// `@Part`
  formData('Part');

  /// Constructor for [HttpParameterType]
  const HttpParameterType(this.type);

  /// Parameter type
  final String type;

  /// Is element used in multipart
  bool get isPart =>
      this == HttpParameterType.part || this == HttpParameterType.formData;

  /// Is element used as body
  bool get isBody => this == HttpParameterType.body;
}
