import 'package:path/path.dart' as p;
import 'package:swagger_parser/src/generator/models/universal_data_class.dart';
import 'package:swagger_parser/src/generator/models/universal_type.dart';
import 'package:swagger_parser/src/parser/parser.dart';
import 'package:swagger_parser/src/utils/file_utils.dart';
import 'package:test/test.dart';

void main() {
  group('Empty data class', () {
    test('2.0', () async {
      final schemaFilePath = p.join('test', 'parser', 'schemas', 'empty_class.2.0.json');
      final configFile = schemaFile(schemaFilePath);
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
      final schemaFilePath = p.join('test', 'parser', 'schemas', 'empty_class.3.0.json');
      final configFile = schemaFile(schemaFilePath);
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
      final schemaFilePath = p.join('test', 'parser', 'schemas', 'basic_types_class.2.0.json');
      final configFile = schemaFile(schemaFilePath);
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
      final schemaFilePath = p.join('test', 'parser', 'schemas', 'basic_types_class.3.0.json');
      final configFile = schemaFile(schemaFilePath);
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
      final schemaFilePath = p.join('test', 'parser', 'schemas', 'reference_types_class.2.0.json');
      final configFile = schemaFile(schemaFilePath);
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
      for (var i = 0; i < dataClasses.length; i++) {
        expect(dataClasses[i], expectedDataClasses[i]);
      }
    });

    test('composite types check 3.0', () async {
      final schemaFilePath = p.join('test', 'parser', 'schemas', 'reference_types_class.3.0.json');
      final configFile = schemaFile(schemaFilePath);
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
      for (var i = 0; i < dataClasses.length; i++) {
        expect(dataClasses[i], expectedDataClasses[i]);
      }
    });
  });
}
