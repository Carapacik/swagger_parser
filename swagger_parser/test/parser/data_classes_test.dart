import 'package:path/path.dart' as p;
import 'package:swagger_parser/src/generator/models/universal_data_class.dart';
import 'package:swagger_parser/src/generator/models/universal_type.dart';
import 'package:swagger_parser/src/parser/parser.dart';
import 'package:swagger_parser/src/utils/file_utils.dart';
import 'package:test/test.dart';

void main() {
  group('Empty data class', () {
    test('2.0', () async {
      final schemaPath =
          p.join('test', 'parser', 'schemas', 'empty_class.2.0.json');
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(schemaContent);
      final actualDataClass = parser.parseDataClasses().first;
      const expectedDataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [],
      );
      expect(actualDataClass, expectedDataClass);
    });

    test('3.0', () async {
      final schemaPath =
          p.join('test', 'parser', 'schemas', 'empty_class.3.0.json');
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(schemaContent);
      final actualDataClass = parser.parseDataClasses().first;
      const expectedDataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [],
      );
      expect(actualDataClass, expectedDataClass);
    });
  });

  group('Types check', () {
    test('basic types check 2.0', () async {
      final schemaPath =
          p.join('test', 'parser', 'schemas', 'basic_types_class.2.0.json');
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(schemaContent);
      final actualDataClass = parser.parseDataClasses().first;
      const expectedDataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(
            type: 'integer',
            name: 'integer1',
            jsonKey: 'integer1',
            isRequired: false,
          ),
          UniversalType(
            type: 'number',
            format: 'float',
            name: 'float1',
            jsonKey: 'float1',
            isRequired: false,
          ),
          UniversalType(
            type: 'number',
            format: 'double',
            name: 'double1',
            jsonKey: 'double1',
            isRequired: false,
          ),
          UniversalType(
            type: 'number',
            format: 'string',
            name: 'string1',
            jsonKey: 'string1',
            isRequired: false,
          ),
          UniversalType(
            type: 'number',
            name: 'number1',
            jsonKey: 'number1',
            isRequired: false,
          ),
          UniversalType(
            type: 'string',
            name: 'string2',
            format: 'binary',
            jsonKey: 'string2',
            isRequired: false,
          ),
          UniversalType(
            type: 'string',
            name: 'string3',
            format: 'date',
            jsonKey: 'string3',
            isRequired: false,
          ),
          UniversalType(
            type: 'string',
            name: 'string4',
            format: 'datetime',
            jsonKey: 'string4',
            isRequired: false,
          ),
          UniversalType(
            type: 'string',
            name: 'string5',
            jsonKey: 'string5',
            isRequired: false,
          ),
          UniversalType(
            type: 'file',
            name: 'file1',
            jsonKey: 'file1',
            isRequired: false,
          ),
          UniversalType(
            type: 'boolean',
            name: 'bool1',
            jsonKey: 'bool1',
            isRequired: false,
          ),
          UniversalType(
            type: 'object',
            name: 'object1',
            jsonKey: 'object1',
            isRequired: false,
          ),
          UniversalType(
            type: 'string',
            name: 'array1',
            jsonKey: 'array1',
            arrayDepth: 1,
            isRequired: false,
          ),
          UniversalType(
            type: 'string',
            name: 'array2',
            jsonKey: 'array2',
            arrayDepth: 3,
            isRequired: false,
          ),
        ],
      );
      expect(actualDataClass, expectedDataClass);
    });

    test('basic types check 3.0', () async {
      final schemaPath =
          p.join('test', 'parser', 'schemas', 'basic_types_class.3.0.json');
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(schemaContent);
      final actualDataClass = parser.parseDataClasses().first;
      const expectedDataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(
            type: 'integer',
            name: 'integer1',
            jsonKey: 'integer1',
            isRequired: false,
          ),
          UniversalType(
            type: 'number',
            format: 'float',
            name: 'float1',
            jsonKey: 'float1',
            isRequired: false,
          ),
          UniversalType(
            type: 'number',
            format: 'double',
            name: 'double1',
            jsonKey: 'double1',
            isRequired: false,
          ),
          UniversalType(
            type: 'number',
            format: 'string',
            name: 'string1',
            jsonKey: 'string1',
            isRequired: false,
          ),
          UniversalType(
            type: 'number',
            name: 'number1',
            jsonKey: 'number1',
            isRequired: false,
          ),
          UniversalType(
            type: 'string',
            name: 'string2',
            format: 'binary',
            jsonKey: 'string2',
            isRequired: false,
          ),
          UniversalType(
            type: 'string',
            name: 'string3',
            format: 'date',
            jsonKey: 'string3',
            isRequired: false,
          ),
          UniversalType(
            type: 'string',
            name: 'string4',
            format: 'datetime',
            jsonKey: 'string4',
            isRequired: false,
          ),
          UniversalType(
            type: 'string',
            name: 'string5',
            jsonKey: 'string5',
            isRequired: false,
          ),
          UniversalType(
            type: 'file',
            name: 'file1',
            jsonKey: 'file1',
            isRequired: false,
          ),
          UniversalType(
            type: 'boolean',
            name: 'bool1',
            jsonKey: 'bool1',
            isRequired: false,
          ),
          UniversalType(
            type: 'object',
            name: 'object1',
            jsonKey: 'object1',
            isRequired: false,
          ),
          UniversalType(
            type: 'string',
            name: 'array1',
            jsonKey: 'array1',
            arrayDepth: 1,
            isRequired: false,
          ),
          UniversalType(
            type: 'string',
            name: 'array2',
            jsonKey: 'array2',
            arrayDepth: 3,
            isRequired: false,
          ),
        ],
      );
      expect(actualDataClass, expectedDataClass);
    });

    test('composite types check 2.0', () async {
      final schemaPath =
          p.join('test', 'parser', 'schemas', 'reference_types_class.2.0.json');
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(schemaContent);
      final dataClasses = parser.parseDataClasses().toList();
      const expectedDataClasses = [
        UniversalComponentClass(
          name: 'ClassName',
          imports: {'AnotherClass'},
          parameters: [
            UniversalType(
              type: 'integer',
              name: 'id',
              jsonKey: 'id',
              isRequired: false,
            ),
            UniversalType(
              type: 'AnotherClass',
              name: 'another',
              jsonKey: 'another',
              isRequired: false,
            ),
          ],
        ),
        UniversalComponentClass(
          name: 'AnotherClass',
          imports: {},
          parameters: [
            UniversalType(
              type: 'integer',
              name: 'id',
              jsonKey: 'id',
              isRequired: false,
            ),
            UniversalType(
              type: 'string',
              name: 'name',
              jsonKey: 'name',
              isRequired: false,
            ),
          ],
        ),
      ];
      expect(dataClasses.length, expectedDataClasses.length);
      for (var i = 0; i < dataClasses.length; i++) {
        expect(dataClasses[i], expectedDataClasses[i]);
      }
    });

    test('composite types check 3.0', () async {
      final schemaPath =
          p.join('test', 'parser', 'schemas', 'reference_types_class.3.0.json');
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(schemaContent);
      final dataClasses = parser.parseDataClasses().toList();
      const expectedDataClasses = <UniversalDataClass>[
        UniversalComponentClass(
          name: 'ClassName',
          imports: {'AnotherClass'},
          parameters: [
            UniversalType(
              type: 'integer',
              name: 'id',
              jsonKey: 'id',
              isRequired: false,
            ),
            UniversalType(
              type: 'AnotherClass',
              name: 'another',
              jsonKey: 'another',
              isRequired: false,
            ),
          ],
        ),
        UniversalComponentClass(
          name: 'AnotherClass',
          imports: {},
          parameters: [
            UniversalType(
              type: 'integer',
              name: 'id',
              jsonKey: 'id',
              isRequired: false,
            ),
            UniversalType(
              type: 'string',
              name: 'name',
              jsonKey: 'name',
              isRequired: false,
            ),
          ],
        ),
      ];
      expect(dataClasses.length, expectedDataClasses.length);
      for (var i = 0; i < dataClasses.length; i++) {
        expect(dataClasses[i], expectedDataClasses[i]);
      }
    });

    test('of-like params types check 3.1', () async {
      final schemaPath =
          p.join('test', 'parser', 'schemas', 'of_like_class.3.1.json');
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(schemaContent);
      final dataClasses = parser.parseDataClasses().toList();
      final expectedDataClasses = <UniversalDataClass>[
        const UniversalComponentClass(
          name: 'OneOfElement',
          imports: {'EnumClass'},
          parameters: [
            UniversalType(
              type: 'EnumClass',
              name: 'allClass',
              jsonKey: 'allClass',
              isRequired: false,
            ),
            UniversalType(
              type: 'EnumClass',
              name: 'anyClass',
              jsonKey: 'anyClass',
              enumType: 'EnumClass',
              defaultValue: 'value1',
              isRequired: false,
            ),
            UniversalType(
              type: 'EnumClass',
              name: 'oneClass',
              jsonKey: 'oneClass',
              isRequired: false,
            ),
            UniversalType(
              type: 'integer',
              name: 'allType',
              jsonKey: 'allType',
              isRequired: false,
            ),
            UniversalType(
              type: 'string',
              format: 'date-time',
              name: 'anyType',
              jsonKey: 'anyType',
              isRequired: false,
            ),
            UniversalType(
              type: 'EnumClass',
              name: 'oneType',
              jsonKey: 'oneType',
              defaultValue: '[]',
              arrayDepth: 1,
              isRequired: false,
            ),
            UniversalType(
              type: 'EnumClass',
              name: 'nullableClass',
              jsonKey: 'nullableClass',
              nullable: true,
              isRequired: false,
            ),
            UniversalType(
              type: 'EnumClass',
              name: 'nullableType',
              jsonKey: 'nullableType',
              defaultValue: '[]',
              arrayDepth: 1,
              nullable: true,
              isRequired: false,
            ),
          ],
        ),
        UniversalEnumClass(
          name: 'EnumClass',
          type: 'string',
          items: UniversalEnumItem.listFromNames({'value1', 'value2'}),
        ),
      ];

      expect(dataClasses.length, expectedDataClasses.length);
      final item1 = dataClasses[0] as UniversalComponentClass;
      final item2 = dataClasses[1] as UniversalEnumClass;
      final expectedItem1 = expectedDataClasses[0] as UniversalComponentClass;
      final expectedItem2 = expectedDataClasses[1] as UniversalEnumClass;
      expect(item1.parameters.length, expectedItem1.parameters.length);
      for (var i = 0; i < item1.parameters.length; i++) {
        expect(
          item1.parameters[i],
          expectedItem1.parameters[i],
        );
      }
      expect(item2, expectedItem2);
    });

    test('additionalProperties entity that should not parse to object test 3.0',
        () async {
      final schemaPath = p.join(
        'test',
        'parser',
        'schemas',
        'additional_properties_class.3.0.json',
      );
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(schemaContent);
      final dataClasses = parser.parseDataClasses().toList();
      final expectedDataClasses = <UniversalDataClass>[
        const UniversalComponentClass(
          name: 'Example',
          imports: {},
          parameters: [
            UniversalType(
              type: 'object',
              name: 'data',
              description: 'data',
              jsonKey: 'data',
              isRequired: false,
              mapType: 'string',
            ),
          ],
        ),
        const UniversalComponentClass(
          name: 'ExampleParsable',
          imports: {'Example'},
          parameters: [
            UniversalType(
              type: 'Example',
              name: 'data',
              description: 'data',
              jsonKey: 'data',
              isRequired: false,
              mapType: 'string',
            ),
          ],
        ),
      ];

      expect(dataClasses.length, expectedDataClasses.length);
      final item1 = dataClasses[0] as UniversalComponentClass;
      final item2 = dataClasses[1] as UniversalComponentClass;
      final expectedItem1 = expectedDataClasses[0] as UniversalComponentClass;
      final expectedItem2 = expectedDataClasses[1] as UniversalComponentClass;
      expect(item1.parameters.length, expectedItem1.parameters.length);
      for (var i = 0; i < item1.parameters.length; i++) {
        expect(
          item1.parameters[i],
          expectedItem1.parameters[i],
        );
      }
      expect(item2, expectedItem2);
    });

    test('additionalProperties entity should parse to object test 2.0',
        () async {
      final schemaPath = p.join(
        'test',
        'parser',
        'schemas',
        'additional_properties_class.2.0.json',
      );
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(schemaContent);
      final dataClasses = parser.parseDataClasses().toList();
      final expectedDataClasses = <UniversalDataClass>[
        const UniversalComponentClass(
          name: 'ValueClass',
          imports: {},
          parameters: [
            UniversalType(
              type: 'string',
              name: 'testProp',
              jsonKey: 'testProp',
              description: 'A test property',
            ),
          ],
        ),
        const UniversalComponentClass(
          name: 'WrapperClass',
          imports: {'ValueClass'},
          parameters: [
            UniversalType(
              type: 'ValueClass',
              name: 'map',
              jsonKey: 'map',
              mapType: 'string',
            ),
          ],
        ),
      ];

      expect(dataClasses.length, expectedDataClasses.length);
      final item1 = dataClasses[0] as UniversalComponentClass;
      final item2 = dataClasses[1] as UniversalComponentClass;
      final expectedItem1 = expectedDataClasses[0] as UniversalComponentClass;
      final expectedItem2 = expectedDataClasses[1] as UniversalComponentClass;
      expect(item1.parameters.length, expectedItem1.parameters.length);
      for (var i = 0; i < item1.parameters.length; i++) {
        expect(
          item1.parameters[i],
          expectedItem1.parameters[i],
        );
      }
      expect(item2, expectedItem2);
    });

    test('Enum name test', () async {
      final schemaPath = p.join('test', 'parser', 'schemas', 'enum_class.json');
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(schemaContent);
      final dataClasses = parser.parseDataClasses();
      expect(dataClasses, hasLength(2));
      final enumClass = dataClasses.whereType<UniversalEnumClass>().first;
      expect(enumClass.name, 'Status');
    });
  });
}
