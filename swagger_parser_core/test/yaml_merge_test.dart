import 'package:swagger_parser_core/swagger_parser_core.dart';
import 'package:test/test.dart';

Map<String, Object?> _parse(String yaml) =>
    const OpenApiParser().parse(SchemaSource.yaml(yaml)).toJson();

Map<String, Object?> _schemas(Map<String, Object?> document) =>
    (document['components']! as Map<String, Object?>)['schemas']!
        as Map<String, Object?>;

const _head = '''
openapi: 3.0.3
info:
  title: Merge keys
  version: '1'
paths: {}
''';

void main() {
  test('merges a referenced mapping into the mapping that uses it', () {
    final Map<String, Object?> document = _parse('''
$_head
components:
  schemas:
    Defaults: &defaults
      type: object
      properties:
        name:
          type: string
        age:
          type: integer
    Base:
      <<: *defaults
      description: merged
''');
    final Map<String, Object?> schemas = _schemas(document);
    final base = schemas['Base']! as Map<String, Object?>;
    expect(base['type'], 'object');
    expect(base['description'], 'merged');
    expect(
      (base['properties']! as Map<String, Object?>).keys,
      containsAll(<String>['name', 'age']),
    );
    // The merge key is not part of the decoded document.
    expect(base.containsKey('<<'), isFalse);
  });

  test('keeps explicit keys and earlier merge sources', () {
    final Map<String, Object?> document = _parse('''
$_head
components:
  schemas:
    First: &first
      type: string
      description: first
    Second: &second
      type: integer
      description: second
    Merged:
      <<: [*first, *second]
      type: number
''');
    final Map<String, Object?> schemas = _schemas(document);
    final merged = schemas['Merged']! as Map<String, Object?>;
    expect(merged['type'], 'number');
    expect(merged['description'], 'first');
  });

  test('expands merges inside a merged mapping', () {
    final Map<String, Object?> document = _parse('''
$_head
components:
  schemas:
    Base: &base
      type: object
      properties:
        id:
          type: string
    Middle: &middle
      <<: *base
      description: middle
    Leaf:
      <<: *middle
      title: leaf
''');
    final Map<String, Object?> schemas = _schemas(document);
    final leaf = schemas['Leaf']! as Map<String, Object?>;
    expect(leaf['type'], 'object');
    expect(leaf['description'], 'middle');
    expect(leaf['title'], 'leaf');
    expect((leaf['properties']! as Map<String, Object?>).keys, contains('id'));
  });

  test('keeps a quoted merge key as data', () {
    final Map<String, Object?> document = _parse('''
$_head
components:
  schemas:
    Quoted:
      type: object
      properties:
        "<<":
          type: string
''');
    final Map<String, Object?> schemas = _schemas(document);
    final quoted = schemas['Quoted']! as Map<String, Object?>;
    expect(
      (quoted['properties']! as Map<String, Object?>).keys,
      contains('<<'),
    );
  });

  test('rejects a merge value that is not a mapping', () {
    expect(
      () => _parse('''
$_head
components:
  schemas:
    Broken:
      <<: 3
'''),
      throwsA(
        isA<SchemaParseException>().having(
          (error) => error.message,
          'message',
          contains('Expected a mapping for a merge key.'),
        ),
      ),
    );
  });
}
