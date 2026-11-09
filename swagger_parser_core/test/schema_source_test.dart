import 'dart:convert';

import 'package:swagger_parser_core/swagger_parser_core.dart';
import 'package:test/test.dart';

void main() {
  const yaml = "{swagger: '2.0', info: {title: Café, version: '1'}, paths: {}}";

  test('auto accepts YAML flow syntax', () {
    expect(
      const OpenApiParser().parse(const SchemaSource(yaml)),
      isA<SwaggerV2Document>(),
    );
    expect(
      () => const OpenApiParser().parse(const SchemaSource.json(yaml)),
      throwsA(isA<SchemaParseException>()),
    );
  });

  test('decodes UTF-8 bytes with a BOM', () {
    final source = SchemaSource.fromBytes(
      [0xef, 0xbb, 0xbf, ...utf8.encode(yaml)],
      format: SchemaFormat.yaml,
      uri: Uri.parse('memory:api.yaml'),
    );
    final document = const OpenApiParser().parse(source) as SwaggerV2Document;
    expect(document.info.title, 'Café');
    expect(source.uri, Uri.parse('memory:api.yaml'));
  });

  test('rejects malformed UTF-8', () {
    expect(
      () => SchemaSource.fromBytes([0xc3, 0x28]),
      throwsA(isA<SchemaParseException>()),
    );
  });

  test('JSON errors keep available decoder coordinates', () {
    try {
      const OpenApiParser().parse(const SchemaSource.json('{\n  "swagger": }'));
      fail('Expected a parse error.');
    } on SchemaParseException catch (error) {
      expect(error.cause, isA<FormatException>());
      final cause = error.cause! as FormatException;
      expect(error.location?.line, cause.offset == null ? isNull : 2);
      expect(error.documentPath, '');
    }
  });

  test('rejects duplicate JSON keys', () {
    expect(
      () => const OpenApiParser().parse(
        const SchemaSource.json(
          '{"swagger":"2.0","info":{"title":"a","title":"b","version":"1"},"paths":{}}',
        ),
      ),
      throwsA(isA<SchemaParseException>()),
    );
  });
}
