import 'package:swagger_parser/swagger_parser.dart';

Future<void> main() async {
  const source = SchemaSource.yaml(r'''
openapi: 3.2.1
info:
  title: Stations
  version: '1'
paths:
  /stations:
    get:
      tags:
        - Stations
      operationId: getStations
      responses:
        '200':
          description: Stations
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Station'
components:
  schemas:
    Station:
      type: object
      required:
        - id
        - name
      properties:
        id:
          type: string
        name:
          type: string
''');
  final GenerationResult result = await const SwaggerParserRunner().generate(
    source,
  );
  for (final GeneratedFile file in result.files) {
    // ignore: avoid_print
    print('${file.relativePath}\n${file.content}');
  }
}
