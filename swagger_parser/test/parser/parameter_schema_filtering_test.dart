import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  test('keeps schemas referenced by filtered endpoint parameters', () async {
    final root = await Directory.systemTemp.createTemp('swagger-parser-test-');
    addTearDown(() => root.delete(recursive: true));

    final schema = File(p.join(root.path, 'openapi.yaml'))
      ..writeAsStringSync(r'''
openapi: 3.0.0
info:
  title: Parameter schema filtering
  version: 1.0.0
paths:
  /public:
    get:
      tags: [public]
      parameters:
        - name: unit
          in: query
          schema:
            $ref: '#/components/schemas/Unit'
      responses:
        '200':
          description: OK
  /admin:
    get:
      tags: [admin]
      responses:
        '200':
          description: OK
components:
  schemas:
    Unit:
      type: string
      enum: [imperial, metric]
''');

    await GenProcessor(
      SWPConfig(
        schemaPath: schema.path,
        outputDirectory: p.join(root.path, 'generated'),
        excludeTags: ['admin'],
        putClientsInFolder: true,
      ),
    ).generateFiles();

    expect(
      File(p.join(root.path, 'generated', 'models', 'unit.dart')).existsSync(),
      isTrue,
    );
  });
}
