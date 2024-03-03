import 'dart:io';

import '../../generator/model/generation_statistic.dart';
import '../../parser/swagger_parser_core.dart';
import '../base_utils.dart';

const _green = '\x1B[32m';
const _red = '\x1B[31m';
const _reset = '\x1B[0m';

void introMessage() {
  stdout.writeln(
    r'''

┃  ____ _ _ _ ____ ____ ____ ____ ____     ___  ____ ____ ____ ____ ____ 
┃  [__  | | | |__| | __ | __ |___ |__/     |__] |__| |__/ [__  |___ |__/ 
┃  ___] |_|_| |  | |__] |__] |___ |  \ ___ |    |  | |  \ ___] |___ |  \
┃
''',
  );
}

void generateMessage() {
  stdout.writeln('Generate...');
}

void successMessage({
  required int successSchemasCount,
  required int schemesCount,
}) {
  if (successSchemasCount == 0) {
    stdout.writeln(
      '${_red}The generation was completed with errors.\n'
      'No schemes were generated.$_reset',
    );
  } else if (successSchemasCount != schemesCount) {
    stdout.writeln(
      '${_red}The generation was completed with errors.\n'
      '${schemesCount - successSchemasCount} schemes were not generated.$_reset',
    );
  } else {
    stdout.writeln(
      '${schemesCount > 1 ? _green : ''}The generation was completed successfully. '
      'You can run the generation using build_runner.${schemesCount > 1 ? _reset : ''}',
    );
  }
}

void successExtractMessage() {
  stdout.writeln('${_green}The extraction was completed successfully.$_reset');
}

void schemaStatisticsMessage({
  required OpenApiInfo openApi,
  required GenerationStatistic statistics,
  String? name,
}) {
  final version = openApi.apiVersion != null ? 'v${openApi.apiVersion}' : '';

  var title = name ?? '';
  if (title.length > 80) {
    title = '${title.substring(0, 80)}...';
  }

  stdout.writeln(
    '> $title $version: \n'
    '    ${formatNumber(statistics.totalRestClients)} rest clients, '
    '${formatNumber(statistics.totalRequests)} requests, '
    '${formatNumber(statistics.totalDataClasses)} data classes.\n'
    '    ${formatNumber(statistics.totalFiles)} files with ${formatNumber(statistics.totalLines)} lines of code.\n'
    '    ${_green}Success (${statistics.timeElapsed.inMilliseconds / 1000} seconds)$_reset\n',
  );
}

void summaryStatisticsMessage({
  required int successCount,
  required int schemesCount,
  required GenerationStatistic statistics,
}) {
  stdout.writeln(
    'Summary (${statistics.timeElapsed.inMilliseconds / 1000} seconds):\n'
    '${successCount != schemesCount ? '$successCount/$schemesCount' : '$schemesCount'} schemes, '
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

  stdout.writeln(
    '> $title: \n'
    '    ${_red}Failed to generate files.$_reset\n'
    '    $error\n'
    '    ${stack.toString().replaceAll('\n', '\n    ')}\n',
  );
}

void exitWithError(String message) {
  stderr.writeln('${_red}ERROR: $message$_reset');
  exit(2);
}
