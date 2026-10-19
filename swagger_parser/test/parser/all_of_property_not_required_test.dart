import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  test(
    'properties not listed in required stay optional when a sibling uses allOf',
    () async {
      final root =
          await Directory.systemTemp.createTemp('swagger-parser-test-');
      addTearDown(() => root.delete(recursive: true));

      final schema = File(p.join(root.path, 'openapi.yaml'))
        ..writeAsStringSync(r'''
openapi: 3.0.0
info:
  title: allOf properties without required
  version: 1.0.0
paths:
  /foo:
    get:
      operationId: getFoo
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Foo'
  /order:
    get:
      operationId: getOrder
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Order'
components:
  schemas:
    Bar:
      type: object
      properties:
        name:
          type: string
      required: [name]
    Status:
      type: string
      enum: [active, inactive]
    Foo:
      type: object
      # No required array: every property is optional.
      properties:
        a:
          type: string
        b:
          allOf:
            - $ref: '#/components/schemas/Bar'
    Order:
      type: object
      # No required array: every property is optional.
      properties:
        id:
          type: integer
        status:
          nullable: true
          allOf:
            - $ref: '#/components/schemas/Status'
''');

      await GenProcessor(
        SWPConfig(
          schemaPath: schema.path,
          outputDirectory: p.join(root.path, 'generated'),
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
      ).generateFiles();

      final foo = File(
        p.join(root.path, 'generated', 'models', 'foo.dart'),
      ).readAsStringSync();
      expect(foo, contains('String? a,'));
      expect(foo, isNot(contains('required String? a')));
      expect(foo, contains('Bar? b,'));
      expect(foo, isNot(contains('required Bar? b')));

      final order = File(
        p.join(root.path, 'generated', 'models', 'order.dart'),
      ).readAsStringSync();
      expect(order, contains('int? id,'));
      expect(order, isNot(contains('required int? id')));
      expect(order, contains('Status? status,'));
      expect(order, isNot(contains('required Status? status')));
    },
  );
}
