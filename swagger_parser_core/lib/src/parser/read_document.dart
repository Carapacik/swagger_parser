import 'package:swagger_parser_core/src/config/parse_config.dart';
import 'package:swagger_parser_core/src/exceptions/open_api_exception.dart';
import 'package:swagger_parser_core/src/model/open_api_document.dart';
import 'package:swagger_parser_core/src/parser/decoder/source_decoder.dart';
import 'package:swagger_parser_core/src/parser/object_reader.dart';
import 'package:swagger_parser_core/src/parser/v2/swagger_v2_document_parser.dart';
import 'package:swagger_parser_core/src/parser/v3_0/open_api_v3_0_document_parser.dart';
import 'package:swagger_parser_core/src/parser/v3_1/open_api_v3_1_document_parser.dart';
import 'package:swagger_parser_core/src/parser/v3_2/open_api_v3_2_document_parser.dart';

final _openApi3 = RegExp(r'^3\.(\d+)\.(?:0|[1-9]\d*)$');

/// Reads a versioned document from decoded JSON and its source positions.
OpenApiDocument readDocument(DecodedDocument decoded, ParseConfig config) {
  final context = ReadContext(decoded, config);
  final Object? value = decoded.value;
  if (value is! Map<String, Object?>) {
    context.fail('Expected an object.', '');
  }
  if (value.containsKey('swagger') && value.containsKey('openapi')) {
    context.fail('Use one version field: swagger or openapi.', '');
  }
  final key = value.containsKey('swagger') ? 'swagger' : 'openapi';
  if (!value.containsKey(key)) {
    context.fail('Missing specification version.', '');
  }
  final String version = context.string(value[key], '/$key');
  if (key == 'swagger' && version == '2.0') {
    return SwaggerV2DocumentParser(context).parse(value);
  }
  if (key == 'openapi') {
    switch (_openApi3.firstMatch(version)?.group(1)) {
      case '0':
        return OpenApiV30DocumentParser(context).parse(value);
      case '1':
        return OpenApiV31DocumentParser.parse(context, value);
      case '2':
        return OpenApiV32DocumentParser.parse(context, value);
    }
  }
  throw UnsupportedOpenApiVersionException(
    'Unsupported OpenAPI version: $version.',
    sourceUri: decoded.sourceUri,
    documentPath: '/$key',
    location: decoded.locations['/$key'],
  );
}
