import '../../utils/utils.dart';
import '../model/generated_file.dart';

/// Provides template for generating dart export file
String dartExportFileTemplate({
  required bool markFileAsGenerated,
  required List<GeneratedFile> restClients,
  required List<GeneratedFile> dataClasses,
  GeneratedFile? rootClient,
}) {
  final restClientsNames = restClients.map((e) => e.name).toSet();
  final dataClassesNames = dataClasses.map((e) => e.name).toSet();
  final rootClientName = rootClient?.name;

  return '${generatedFileComment(
    markFileAsGenerated: markFileAsGenerated,
  )}'
      '${rootClientName != null ? '// Root client\n' : ''}'
      '${rootClientName != null ? "export '$rootClientName';" : ''}'
      '${rootClientName != null ? '\n\n' : ''}'
      '${restClientsNames.isNotEmpty ? '// Clients\n' : ''}'
      '${restClientsNames.map((e) => "export '$e';").join('\n')}'
      '${restClientsNames.isNotEmpty ? '\n\n' : ''}'
      '${dataClassesNames.isNotEmpty ? '// Data classes\n' : ''}'
      '${dataClassesNames.map((e) => "export '$e';").join('\n')}\n';
}
