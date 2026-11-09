import 'dart:io';

/// Enables Chrome checks unless SWAGGER_PARSER_TEST_CHROME is false.
bool get runChromeTests =>
    Platform.environment['SWAGGER_PARSER_TEST_CHROME'] != 'false';
