import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  test(
    'infer_required_from_nullable treats OpenAPI 3.1 type lists with null as nullable',
    () async {
      final root =
          await Directory.systemTemp.createTemp('swagger-parser-test-');
      addTearDown(() => root.delete(recursive: true));

      final schema = File(p.join(root.path, 'openapi.yaml'))
        ..writeAsStringSync(r'''
openapi: 3.1.0
info:
  title: Infer required from 3.1 type lists
  version: 1.0.0
paths:
  /product:
    get:
      operationId: getProduct
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Product'
components:
  schemas:
    Product:
      type: object
      # No required array: required-ness is inferred from nullability.
      properties:
        id:
          type: integer
        title:
          type: [string, "null"]
        tags:
          type: ["null", array]
          items:
            type: string
        legacyDescription:
          type: string
          nullable: true
''');

      await GenProcessor(
        SWPConfig(
          schemaPath: schema.path,
          outputDirectory: p.join(root.path, 'generated'),
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          inferRequiredFromNullable: true,
        ),
      ).generateFiles();

      final model = File(
        p.join(root.path, 'generated', 'models', 'product.dart'),
      ).readAsStringSync();
      expect(model, contains('required int id,'));
      expect(model, contains('String? title,'));
      expect(model, isNot(contains('required String? title')));
      expect(model, contains('List<String>? tags,'));
      expect(model, isNot(contains('required List<String>? tags')));
      expect(model, contains('String? legacyDescription,'));
      expect(model, isNot(contains('required String? legacyDescription')));
    },
  );
}
