import 'dart:convert';

import 'package:swagger_parser_core/swagger_parser_core.dart';

void main() {
  const source = SchemaSource.yaml('''
swagger: '2.0'
info: {title: Pets, version: '1'}
paths:
  /pets:
    get:
      responses:
        '200':
          description: Pets
          schema: {type: array, items: {type: string}}
''');
  final document = const OpenApiParser().parse(source) as SwaggerV2Document;
  // ignore: avoid_print
  print(const JsonEncoder.withIndent('  ').convert(document.toJson()));
}
