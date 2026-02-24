import 'dart:convert' show json;

import 'package:swagger_parser/src/parser/corrector/open_api_corrector.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

/// Generates a large OpenAPI YAML string with [schemaCount] schemas,
/// each having [propertiesPerSchema] properties with $ref references.
String _generateLargeSchema({
  required int schemaCount,
  required int propertiesPerSchema,
}) {
  final buf = StringBuffer()
    ..writeln('openapi: 3.0.0')
    ..writeln('info:')
    ..writeln('  title: Performance Test API')
    ..writeln('  version: 1.0.0')
    ..writeln('paths:')
    ..writeln('  /test:')
    ..writeln('    get:')
    ..writeln('      operationId: getTest')
    ..writeln('      responses:')
    ..writeln("        '200':")
    ..writeln('          description: OK')
    ..writeln('          content:')
    ..writeln('            application/json:')
    ..writeln('              schema:')
    ..writeln("                \$ref: '#/components/schemas/Schema0'")
    ..writeln('components:')
    ..writeln('  schemas:');

  for (var i = 0; i < schemaCount; i++) {
    buf
      ..writeln('    Schema$i:')
      ..writeln('      type: object')
      ..writeln('      properties:');

    for (var j = 0; j < propertiesPerSchema; j++) {
      final refIndex = (i + j + 1) % schemaCount;
      buf
        ..writeln('        field_$j:')
        ..writeln("          \$ref: '#/components/schemas/Schema$refIndex'");
    }
  }

  return buf.toString();
}

void main() {
  group('OpenApiCorrector performance', () {
    test(
      'corrector with replacement rules completes in reasonable time '
      'for large schemas',
      () {
        final schemaCount = 200;
        final schema = _generateLargeSchema(
          schemaCount: schemaCount,
          propertiesPerSchema: 5,
        );

        final config = ParserConfig(
          schema,
          isJson: false,
          replacementRules: [
            ReplacementRule(pattern: RegExp(r'$'), replacement: 'Dto'),
          ],
        );

        final corrector = OpenApiCorrector(config);

        final sw = Stopwatch()..start();
        final result = corrector.correct();
        final elapsed = sw.elapsedMilliseconds;

        // Must complete in under 30 seconds (generous limit).
        // Before the fix this would take 7+ minutes on a similar sized schema.
        expect(elapsed, lessThan(5000),
            reason: 'Corrector took ${elapsed}ms, expected < 30s');

        // Verify corrections were actually applied
        final schemas = (result['components']
            as Map<String, dynamic>)['schemas'] as Map<String, dynamic>;
        expect(schemas.length, schemaCount);

        // Verify that schema names and $ref values contain corrected names
        final resultJson = json.encode(result);
        expect(resultJson, contains('Schema0Dto'));
      },
    );
  });
}
