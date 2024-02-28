import 'package:path/path.dart' as p;
import 'package:swagger_parser/src/parser/swagger_parser_core.dart';
import 'package:swagger_parser/src/utils/file/io_file.dart';
import 'package:test/test.dart';

void main() {
  group('Empty data class', () {
    test('2.0', () async {
      final schemaPath =
          p.join('test', 'parser', 'schema', 'empty_class.2.0.json');
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(ParserConfig(schemaContent, isJson: true));
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
          p.join('test', 'parser', 'schema', 'empty_class.3.0.json');
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(ParserConfig(schemaContent, isJson: true));
      final actualDataClass = parser.parseDataClasses().first;
      const expectedDataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [],
      );
      expect(actualDataClass, expectedDataClass);
    });
  });

  group('Empty object class', () {
    test('3.0', () async {
      final schemaPath =
          p.join('test', 'parser', 'schema', 'empty_object.3.0.json');
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(ParserConfig(schemaContent, isJson: true));
      final actualDataClass = parser.parseDataClasses().first;
      const expectedDataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [],
        typeDef: false
      );
      expect(actualDataClass, expectedDataClass);
    });
  });

  group('Types check', () {
    test('basic types check 2.0', () async {
      final schemaPath =
          p.join('test', 'parser', 'schema', 'basic_types_class.2.0.json');
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(ParserConfig(schemaContent, isJson: true));
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
            wrappingCollections: [UniversalCollections.list],
            isRequired: false,
          ),
          UniversalType(
            type: 'string',
            name: 'array2',
            jsonKey: 'array2',
            wrappingCollections: [
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
            ],
            isRequired: false,
          ),
        ],
      );
      expect(actualDataClass, expectedDataClass);
    });

    test('basic types check 3.0', () async {
      final schemaPath =
          p.join('test', 'parser', 'schema', 'basic_types_class.3.0.json');
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(ParserConfig(schemaContent, isJson: true));
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
            wrappingCollections: [UniversalCollections.list],
            isRequired: false,
          ),
          UniversalType(
            type: 'string',
            name: 'array2',
            jsonKey: 'array2',
            wrappingCollections: [
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
            ],
            isRequired: false,
          ),
        ],
      );
      expect(actualDataClass, expectedDataClass);
    });

    test('composite types check 2.0', () async {
      final schemaPath =
          p.join('test', 'parser', 'schema', 'reference_types_class.2.0.json');
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(ParserConfig(schemaContent, isJson: true));
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
          p.join('test', 'parser', 'schema', 'reference_types_class.3.0.json');
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(ParserConfig(schemaContent, isJson: true));
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
          p.join('test', 'parser', 'schema', 'of_like_class.3.1.json');
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(ParserConfig(schemaContent, isJson: true));
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
              wrappingCollections: [UniversalCollections.list],
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
              wrappingCollections: [UniversalCollections.list],
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
        'schema',
        'additional_properties_class.3.0.json',
      );
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(ParserConfig(schemaContent, isJson: true));
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
              wrappingCollections: [UniversalCollections.map],
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
              wrappingCollections: [UniversalCollections.map],
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
        'schema',
        'additional_properties_class.2.0.json',
      );
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(ParserConfig(schemaContent, isJson: true));
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
              isRequired: true,
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
              wrappingCollections: [UniversalCollections.map],
              isRequired: true,
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
      final schemaPath = p.join('test', 'parser', 'schema', 'enum_class.json');
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(
        ParserConfig(
          schemaContent,
          isJson: true,
          enumsParentPrefix: false,
        ),
      );
      final dataClasses = parser.parseDataClasses();
      expect(dataClasses, hasLength(2));
      final enumClass = dataClasses.whereType<UniversalEnumClass>().first;
      expect(enumClass.name, 'Status');
    });
    test('wrapping collections test for swagger 3.0', () async {
      final schemaPath = p.join(
        'test',
        'parser',
        'schema',
        'wrapping_collections.3.0.json',
      );
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(ParserConfig(schemaContent, isJson: true));
      final dataClasses = parser.parseDataClasses().toList();
      final expectedDataClasses = <UniversalDataClass>[
        const UniversalComponentClass(
          name: 'DataClass1',
          imports: {},
          parameters: [
            UniversalType(
              type: 'string',
              name: 'type',
              jsonKey: 'type',
              nullable: true,
              isRequired: false,
            ),
            UniversalType(
              type: 'string',
              name: 'instance',
              jsonKey: 'instance',
              nullable: true,
              isRequired: false,
            ),
            UniversalType(
              type: 'string',
              name: 'errors',
              jsonKey: 'errors',
              isRequired: false,
              wrappingCollections: [
                UniversalCollections.map,
                UniversalCollections.list,
              ],
            ),
          ],
        ),
        const UniversalComponentClass(
          name: 'DataClass2',
          imports: {'DataClass1'},
          parameters: [
            UniversalType(
              type: 'string',
              name: 'title',
              jsonKey: 'title',
              isRequired: false,
              nullable: true,
            ),
            UniversalType(
              type: 'DataClass1',
              name: 'errors',
              jsonKey: 'errors',
              isRequired: false,
              wrappingCollections: [
                UniversalCollections.list,
                UniversalCollections.map,
                UniversalCollections.list,
                UniversalCollections.list,
                UniversalCollections.map,
              ],
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

    test('wrapping collections test for swagger 2.0', () async {
      final schemaPath = p.join(
        'test',
        'parser',
        'schema',
        'wrapping_collections.2.0.json',
      );
      final configFile = schemaFile(schemaPath);
      final schemaContent = configFile!.readAsStringSync();
      final parser = OpenApiParser(ParserConfig(schemaContent, isJson: true));
      final dataClasses = parser.parseDataClasses().toList();
      final expectedDataClasses = <UniversalDataClass>[
        const UniversalComponentClass(
          name: 'DataClass1',
          imports: {},
          parameters: [
            UniversalType(
              type: 'string',
              name: 'type',
              jsonKey: 'type',
              isRequired: false,
            ),
            UniversalType(
              type: 'string',
              name: 'instance',
              jsonKey: 'instance',
              isRequired: false,
            ),
            UniversalType(
              type: 'string',
              name: 'errors',
              jsonKey: 'errors',
              isRequired: false,
              wrappingCollections: [
                UniversalCollections.map,
                UniversalCollections.list,
              ],
            ),
          ],
        ),
        const UniversalComponentClass(
          name: 'DataClass2',
          imports: {'DataClass1'},
          parameters: [
            UniversalType(
              type: 'string',
              name: 'title',
              jsonKey: 'title',
              isRequired: false,
            ),
            UniversalType(
              type: 'DataClass1',
              name: 'errors',
              jsonKey: 'errors',
              isRequired: false,
              wrappingCollections: [
                UniversalCollections.list,
                UniversalCollections.map,
                UniversalCollections.list,
                UniversalCollections.list,
                UniversalCollections.map,
              ],
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
  });
}
