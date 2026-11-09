/// Initial OpenAPI example for the schema editor.
const exampleSchema = r'''
openapi: 3.2.1
info:
  title: Station API
  version: 1.0.0
paths:
  /stations/{id}:
    get:
      operationId: getStation
      tags:
        - Stations
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: A station.
          content:
            application/json:
              schema:
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
''';
