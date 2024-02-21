// ignore_for_file: avoid_print
import '../../generator/models/generation_statistics.dart';
import '../../parser/swagger_parser_core.dart';
import '../utils.dart';

void introMessage() {
  print(
    r'''

┃  ____ _ _ _ ____ ____ ____ ____ ____     ___  ____ ____ ____ ____ ____ 
┃  [__  | | | |__| | __ | __ |___ |__/     |__] |__| |__/ [__  |___ |__/ 
┃  ___] |_|_| |  | |__] |__] |___ |  \ ___ |    |  | |  \ ___] |___ |  \
┃
''',
  );
}

void generateMessage() {
  print('Generate...');
}

void successMessage({
  required int successSchemasCount,
  required int schemasCount,
}) {
  if (successSchemasCount == 0) {
    print(
      'The generation was completed with errors.\n'
      'No schemas were generated.',
    );
  } else if (successSchemasCount != schemasCount) {
    print(
      'The generation was completed with errors.\n'
      '${schemasCount - successSchemasCount} schemas were not generated.',
    );
  } else {
    print(
      'The generation was completed successfully. '
      'You can run the generation using build_runner.',
    );
  }
}

void successExtractMessage() {
  print('The extraction was completed successfully.');
}

void schemaStatisticsMessage({
  required OpenApiInfo openApi,
  required GenerationStatistics statistics,
  String? name,
}) {
  final version = openApi.apiVersion != null ? 'v${openApi.apiVersion}' : '';

  var title = name ?? '';
  if (title.length > 80) {
    title = '${title.substring(0, 80)}...';
  }

  print(
    '> $title $version: \n'
    '    ${formatNumber(statistics.totalRestClients)} rest clients, '
    '${formatNumber(statistics.totalRequests)} requests, '
    '${formatNumber(statistics.totalDataClasses)} data classes.\n'
    '    ${formatNumber(statistics.totalFiles)} files with ${formatNumber(statistics.totalLines)} lines of code.\n'
    '    Success (${statistics.timeElapsed.inMilliseconds / 1000} seconds)\n',
  );
}

void summaryStatisticsMessage({
  required int successCount,
  required int schemasCount,
  required GenerationStatistics statistics,
}) {
  print(
    'Summary (${statistics.timeElapsed.inMilliseconds / 1000} seconds):\n'
    '${successCount != schemasCount ? '$successCount/$schemasCount' : '$schemasCount'} schemas, '
    '${formatNumber(statistics.totalRestClients)} clients, '
    '${formatNumber(statistics.totalRequests)} requests, '
    '${formatNumber(statistics.totalDataClasses)} data classes.\n'
    '${formatNumber(statistics.totalFiles)} files with ${formatNumber(statistics.totalLines)} lines of code.\n',
  );
}

void schemaFailedMessage(
  Object error,
  StackTrace stack, {
  String? name,
}) {
  var title = name ?? '';
  if (title.length > 80) {
    title = '${title.substring(0, 80)}...';
  }

  print(
    '> $title: \n'
    '    Failed to generate files.\n'
    '    $error\n'
    '    ${stack.toString().replaceAll('\n', '\n    ')}\n',
  );
}

void exitWithError(String message) {
  print('ERROR: $message');
}
