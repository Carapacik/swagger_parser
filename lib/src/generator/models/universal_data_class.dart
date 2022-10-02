import 'package:swagger_parser/src/generator/models/universal_type.dart';

/// Universal template for containing information about Rest component
class UniversalDataClass {
  UniversalDataClass({
    required this.name,
    required this.imports,
    required this.parameters,
  });

  final String name;
  final Set<String> imports;
  final List<UniversalType> parameters;
}
