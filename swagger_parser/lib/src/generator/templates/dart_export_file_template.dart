import '../../utils/base_utils.dart';
import '../model/generated_file.dart';

/// Provides template for generating dart export file
String dartExportFileTemplate({
  required bool markFileAsGenerated,
  required List<GeneratedFile> restClients,
  required List<GeneratedFile> dataClasses,
  required GeneratedFile? rootClient,
}) {
  final restClientsNames = restClients.map((e) => e.name).toSet();
  final dataClassesNames = dataClasses.map((e) => e.name).toSet();
  final rootClientName = rootClient?.name;

  return '${generatedFileComment(markFileAsGenerated: markFileAsGenerated)}'
      '${restClientsNames.isNotEmpty ? '// Clients\n' : ''}'
      '${restClientsNames.map((e) => "export '$e';").join('\n')}'
      '${dataClassesNames.isNotEmpty && restClientsNames.isNotEmpty ? '\n' : ''}'
      '${dataClassesNames.isNotEmpty ? '// Data classes\n' : ''}'
      '${dataClassesNames.map((e) => "export '$e';").join('\n')}'
      '${rootClientName != null && (dataClassesNames.isNotEmpty || restClientsNames.isNotEmpty) ? '\n' : ''}'
      '${rootClientName != null ? '// Root client\n' : ''}'
      '${rootClientName != null ? "export '$rootClientName';" : ''}'
      '${rootClientName != null ? '\n\n' : ''}';
}
