import '../../utils/case_utils.dart';
import '../models/universal_enum_class.dart';

/// Provides template for generating kotlin enum DTO
String kotlinEnumDtoTemplate(UniversalEnumClass dataClass) {
  final className = dataClass.name.toPascal;
  return '$className\nEnums in Kotlin are not supported yet. You can always add PR';
}
