import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Empty data class', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [],
      );
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: ''),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';

part 'class_name.g.dart';

@JsonSerializable()
class ClassName {
  const ClassName();
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
  
  Map<String, Object?> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + freezed', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [],
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          jsonSerializer: JsonSerializer.freezed,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
class ClassName with _$ClassName {
  const factory ClassName() = _ClassName;
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('kotlin + moshi', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [],
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          language: ProgrammingLanguage.kotlin,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = '''
import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class ClassName()
''';
      expect(filledContent.content, expectedContents);
    });
  });

  group('Imports', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {
          'camelClass',
          'snake_class',
          'kebab-class',
          'PascalClass',
          'Space class',
        },
        parameters: [],
      );
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: ''),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';

import 'camel_class.dart';
import 'snake_class.dart';
import 'kebab_class.dart';
import 'pascal_class.dart';
import 'space_class.dart';

part 'class_name.g.dart';

@JsonSerializable()
class ClassName {
  const ClassName();
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
  
  Map<String, Object?> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + freezed', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {
          'camelClass',
          'snake_class',
          'kebab-class',
          'PascalClass',
          'Space class',
        },
        parameters: [],
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          jsonSerializer: JsonSerializer.freezed,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

import 'camel_class.dart';
import 'snake_class.dart';
import 'kebab_class.dart';
import 'pascal_class.dart';
import 'space_class.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
class ClassName with _$ClassName {
  const factory ClassName() = _ClassName;
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('kotlin + moshi', () async {
      // Imports in Kotlin are not supported yet. You can always add PR
    });
  });

  group('Parameters', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(
            type: 'integer',
            name: 'intType',
            isRequired: true,
          ),
          UniversalType(
            type: 'number',
            name: 'numberType',
            isRequired: true,
          ),
          UniversalType(
            type: 'number',
            format: 'double',
            name: 'doubleNumberType',
            isRequired: true,
          ),
          UniversalType(
            type: 'number',
            format: 'float',
            name: 'floatNumberType',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            name: 'stringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            format: 'binary',
            name: 'binaryStringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            format: 'date',
            name: 'dateStringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            format: 'date-time',
            name: 'dateTimeStringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'file',
            name: 'fileType',
            isRequired: true,
          ),
          UniversalType(
            type: 'boolean',
            name: 'boolType',
            isRequired: true,
          ),
          UniversalType(
            type: 'object',
            name: 'objectType',
            isRequired: true,
          ),
          UniversalType(
            type: 'Another',
            name: 'anotherType',
            isRequired: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: ''),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

part 'class_name.g.dart';

@JsonSerializable()
class ClassName {
  const ClassName({
    required this.intType,
    required this.numberType,
    required this.doubleNumberType,
    required this.floatNumberType,
    required this.stringType,
    required this.binaryStringType,
    required this.dateStringType,
    required this.dateTimeStringType,
    required this.fileType,
    required this.boolType,
    required this.objectType,
    required this.anotherType,
  });
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
  
  final int intType;
  final num numberType;
  final double doubleNumberType;
  final double floatNumberType;
  final String stringType;
  final File binaryStringType;
  final DateTime dateStringType;
  final DateTime dateTimeStringType;
  final File fileType;
  final bool boolType;
  final dynamic objectType;
  final Another anotherType;

  Map<String, Object?> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + freezed', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(
            type: 'integer',
            name: 'intType',
            isRequired: true,
          ),
          UniversalType(
            type: 'number',
            name: 'numberType',
            isRequired: true,
          ),
          UniversalType(
            type: 'number',
            format: 'double',
            name: 'doubleNumberType',
            isRequired: true,
          ),
          UniversalType(
            type: 'number',
            format: 'float',
            name: 'floatNumberType',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            name: 'stringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            format: 'binary',
            name: 'binaryStringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            format: 'date',
            name: 'dateStringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            format: 'date-time',
            name: 'dateTimeStringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'file',
            name: 'fileType',
            isRequired: true,
          ),
          UniversalType(
            type: 'boolean',
            name: 'boolType',
            isRequired: true,
          ),
          UniversalType(
            type: 'object',
            name: 'objectType',
            isRequired: true,
          ),
          UniversalType(
            type: 'Another',
            name: 'anotherType',
            isRequired: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          jsonSerializer: JsonSerializer.freezed,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
class ClassName with _$ClassName {
  const factory ClassName({
    required int intType,
    required num numberType,
    required double doubleNumberType,
    required double floatNumberType,
    required String stringType,
    required File binaryStringType,
    required DateTime dateStringType,
    required DateTime dateTimeStringType,
    required File fileType,
    required bool boolType,
    required dynamic objectType,
    required Another anotherType,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + dart_mappable', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(
            type: 'integer',
            name: 'intType',
            isRequired: true,
          ),
          UniversalType(
            type: 'number',
            name: 'numberType',
            isRequired: true,
          ),
          UniversalType(
            type: 'number',
            format: 'double',
            name: 'doubleNumberType',
            isRequired: true,
          ),
          UniversalType(
            type: 'number',
            format: 'float',
            name: 'floatNumberType',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            name: 'stringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            format: 'binary',
            name: 'binaryStringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            format: 'date',
            name: 'dateStringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            format: 'date-time',
            name: 'dateTimeStringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'file',
            name: 'fileType',
            isRequired: true,
          ),
          UniversalType(
            type: 'boolean',
            name: 'boolType',
            isRequired: true,
          ),
          UniversalType(
            type: 'object',
            name: 'objectType',
            isRequired: true,
          ),
          UniversalType(
            type: 'Another',
            name: 'anotherType',
            isRequired: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          jsonSerializer: JsonSerializer.dartMappable,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = '''
import 'package:dart_mappable/dart_mappable.dart';

part 'class_name.mapper.dart';

@MappableClass()
class ClassName with ClassNameMappable {

  const ClassName({
    required this.intType,
    required this.numberType,
    required this.doubleNumberType,
    required this.floatNumberType,
    required this.stringType,
    required this.binaryStringType,
    required this.dateStringType,
    required this.dateTimeStringType,
    required this.fileType,
    required this.boolType,
    required this.objectType,
    required this.anotherType,
  });

  final int intType;
  final num numberType;
  final double doubleNumberType;
  final double floatNumberType;
  final String stringType;
  final File binaryStringType;
  final DateTime dateStringType;
  final DateTime dateTimeStringType;
  final File fileType;
  final bool boolType;
  final dynamic objectType;
  final Another anotherType;

  static ClassName fromJson(Map<String, dynamic> json) => ClassNameMapper.ensureInitialized().decodeMap<ClassName>(json);
}
''';
      expect(
        filledContent.content,
        equalsIgnoringWhitespace(expectedContents),
      );
    });

    test('kotlin + moshi', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(
            type: 'integer',
            name: 'intType',
            isRequired: true,
          ),
          UniversalType(
            type: 'number',
            name: 'numberType',
            isRequired: true,
          ),
          UniversalType(
            type: 'number',
            format: 'double',
            name: 'doubleNumberType',
            isRequired: true,
          ),
          UniversalType(
            type: 'number',
            format: 'float',
            name: 'floatNumberType',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            name: 'stringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            format: 'binary',
            name: 'binaryStringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            format: 'date',
            name: 'dateStringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            format: 'date-time',
            name: 'dateTimeStringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'file',
            name: 'fileType',
            isRequired: true,
          ),
          UniversalType(
            type: 'boolean',
            name: 'boolType',
            isRequired: true,
          ),
          UniversalType(
            type: 'object',
            name: 'objectType',
            isRequired: true,
          ),
          UniversalType(
            type: 'Another',
            name: 'anotherType',
            isRequired: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          language: ProgrammingLanguage.kotlin,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = '''
import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class ClassName(
    var intType: Int,
    var numberType: Double,
    var doubleNumberType: Double,
    var floatNumberType: Float,
    var stringType: String,
    var binaryStringType: MultipartBody.Part,
    var dateStringType: Date,
    var dateTimeStringType: Date,
    var fileType: MultipartBody.Part,
    var boolType: Boolean,
    var objectType: Any,
    var anotherType: Another,
)
''';
      expect(filledContent.content, expectedContents);
    });
  });

  group('Array type', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {'Another'},
        parameters: [
          UniversalType(
            type: 'integer',
            name: 'list0',
            wrappingCollections: [UniversalCollections.list],
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            name: 'list1',
            wrappingCollections: [
              UniversalCollections.list,
              UniversalCollections.list,
            ],
            isRequired: true,
          ),
          UniversalType(
            type: 'Another',
            name: 'list5',
            wrappingCollections: [
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
            ],
            isRequired: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: ''),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';

import 'another.dart';

part 'class_name.g.dart';

@JsonSerializable()
class ClassName {
  const ClassName({
    required this.list0,
    required this.list1,
    required this.list5,
  });
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
  
  final List<int> list0;
  final List<List<String>> list1;
  final List<List<List<List<List<Another>>>>> list5;

  Map<String, Object?> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + freezed', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {'Another'},
        parameters: [
          UniversalType(
            type: 'integer',
            name: 'list0',
            wrappingCollections: [UniversalCollections.list],
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            name: 'list1',
            wrappingCollections: [
              UniversalCollections.list,
              UniversalCollections.list,
            ],
            isRequired: true,
          ),
          UniversalType(
            type: 'Another',
            name: 'list5',
            wrappingCollections: [
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
            ],
            isRequired: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          jsonSerializer: JsonSerializer.freezed,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

import 'another.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
class ClassName with _$ClassName {
  const factory ClassName({
    required List<int> list0,
    required List<List<String>> list1,
    required List<List<List<List<List<Another>>>>> list5,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('kotlin + moshi', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {'Another'},
        parameters: [
          UniversalType(
            type: 'integer',
            name: 'list0',
            wrappingCollections: [UniversalCollections.list],
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            name: 'list1',
            wrappingCollections: [
              UniversalCollections.list,
              UniversalCollections.list,
            ],
            isRequired: true,
          ),
          UniversalType(
            type: 'Another',
            name: 'list5',
            wrappingCollections: [
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
            ],
            isRequired: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          language: ProgrammingLanguage.kotlin,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = '''
import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class ClassName(
    var list0: List<Int>,
    var list1: List<List<String>>,
    var list5: List<List<List<List<List<Another>>>>>,
)
''';
      expect(filledContent.content, expectedContents);
    });
  });

  group('JsonKey name', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(
            type: 'integer',
            name: 'intType',
            jsonKey: 'int_type',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            name: 'stringType',
            jsonKey: 'stringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'boolean',
            name: 'boolType',
            jsonKey: 'bool-type',
            isRequired: true,
          ),
          UniversalType(
            type: 'Another',
            name: 'anotherType',
            jsonKey: 'another',
            isRequired: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: ''),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';

part 'class_name.g.dart';

@JsonSerializable()
class ClassName {
  const ClassName({
    required this.intType,
    required this.stringType,
    required this.boolType,
    required this.anotherType,
  });
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
  
  @JsonKey(name: 'int_type')
  final int intType;
  final String stringType;
  @JsonKey(name: 'bool-type')
  final bool boolType;
  @JsonKey(name: 'another')
  final Another anotherType;

  Map<String, Object?> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + freezed', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(
            type: 'integer',
            name: 'intType',
            jsonKey: 'int_type',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            name: 'stringType',
            jsonKey: 'stringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'boolean',
            name: 'boolType',
            jsonKey: 'bool-type',
            isRequired: true,
          ),
          UniversalType(
            type: 'Another',
            name: 'anotherType',
            jsonKey: 'another',
            isRequired: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          jsonSerializer: JsonSerializer.freezed,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
class ClassName with _$ClassName {
  const factory ClassName({
    @JsonKey(name: 'int_type')
    required int intType,
    required String stringType,
    @JsonKey(name: 'bool-type')
    required bool boolType,
    @JsonKey(name: 'another')
    required Another anotherType,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('kotlin + moshi', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(
            type: 'integer',
            name: 'intType',
            jsonKey: 'int_type',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            name: 'stringType',
            jsonKey: 'stringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'boolean',
            name: 'boolType',
            jsonKey: 'bool-type',
            isRequired: true,
          ),
          UniversalType(
            type: 'Another',
            name: 'anotherType',
            jsonKey: 'another',
            isRequired: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          language: ProgrammingLanguage.kotlin,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = '''
import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class ClassName(
    @Json("int_type")
    var intType: Int,
    var stringType: String,
    @Json("bool-type")
    var boolType: Boolean,
    @Json("another")
    var anotherType: Another,
)
''';
      expect(filledContent.content, expectedContents);
    });
  });

  group('defaultValue', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {'Haha'},
        parameters: [
          UniversalType(
            type: 'integer',
            name: 'intType',
            defaultValue: '1',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            name: 'stringType',
            defaultValue: 'str',
            isRequired: true,
          ),
          UniversalType(
            type: 'boolean',
            name: 'boolType',
            defaultValue: 'false',
            isRequired: true,
          ),
          UniversalType(
            type: 'number',
            name: 'nullableType',
            defaultValue: '-1.1',
            nullable: true,
            isRequired: true,
          ),
          UniversalType(
            type: 'Haha',
            name: 'enumType',
            defaultValue: 'HEHE',
            enumType: 'string',
            isRequired: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: ''),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';

import 'haha.dart';

part 'class_name.g.dart';

@JsonSerializable()
class ClassName {
  const ClassName({
    this.intType = 1,
    this.stringType = 'str',
    this.boolType = false,
    this.nullableType = -1.1,
    this.enumType = Haha.hehe,
  });
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
  
  final int intType;
  final String stringType;
  final bool boolType;
  final num nullableType;
  final Haha enumType;

  Map<String, Object?> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + freezed', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {'Haha'},
        parameters: [
          UniversalType(
            type: 'integer',
            name: 'intType',
            defaultValue: '1',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            name: 'stringType',
            defaultValue: 'str',
            isRequired: true,
          ),
          UniversalType(
            type: 'boolean',
            name: 'boolType',
            defaultValue: 'false',
            isRequired: true,
          ),
          UniversalType(
            type: 'number',
            name: 'nullableType',
            defaultValue: '-1.1',
            nullable: true,
            isRequired: true,
          ),
          UniversalType(
            type: 'Haha',
            name: 'enumType',
            defaultValue: 'HEHE',
            enumType: 'string',
            isRequired: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          jsonSerializer: JsonSerializer.freezed,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

import 'haha.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
class ClassName with _$ClassName {
  const factory ClassName({
    @Default(1)
    int intType,
    @Default('str')
    String stringType,
    @Default(false)
    bool boolType,
    @Default(-1.1)
    num nullableType,
    @Default(Haha.hehe)
    Haha enumType,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('kotlin + moshi', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(
            type: 'integer',
            name: 'intType',
            defaultValue: '1',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            name: 'stringType',
            defaultValue: 'str',
            isRequired: true,
          ),
          UniversalType(
            type: 'boolean',
            name: 'boolType',
            defaultValue: 'false',
            isRequired: true,
          ),
          UniversalType(
            type: 'number',
            name: 'nullableType',
            defaultValue: '-1.1',
            nullable: true,
            isRequired: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          language: ProgrammingLanguage.kotlin,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = '''
import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class ClassName(
    var intType: Int = 1,
    var stringType: String = "str",
    var boolType: Boolean = false,
    var nullableType: Double = -1.1,
)
''';
      expect(filledContent.content, expectedContents);
    });
  });

  group('Required parameters', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {'Another'},
        parameters: [
          UniversalType(
            type: 'integer',
            name: 'intType',
            isRequired: false,
          ),
          UniversalType(
            type: 'string',
            wrappingCollections: [UniversalCollections.list],
            name: 'list',
            isRequired: false,
          ),
          UniversalType(
            type: 'Another',
            name: 'another',
            isRequired: false,
          ),
          UniversalType(
            type: 'Another',
            wrappingCollections: [
              UniversalCollections.list,
              UniversalCollections.list,
            ],
            name: 'anotherList',
            isRequired: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: ''),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';

import 'another.dart';

part 'class_name.g.dart';

@JsonSerializable()
class ClassName {
  const ClassName({
    required this.anotherList,
    this.intType,
    this.list,
    this.another,
  });
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
  
  final int? intType;
  final List<String>? list;
  final Another? another;
  final List<List<Another>> anotherList;

  Map<String, Object?> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + freezed', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {'Another'},
        parameters: [
          UniversalType(
            type: 'integer',
            name: 'intType',
            isRequired: false,
          ),
          UniversalType(
            type: 'string',
            wrappingCollections: [UniversalCollections.list],
            name: 'list',
            isRequired: false,
          ),
          UniversalType(
            type: 'Another',
            name: 'another',
            isRequired: false,
          ),
          UniversalType(
            type: 'Another',
            wrappingCollections: [
              UniversalCollections.list,
              UniversalCollections.list,
            ],
            name: 'anotherList',
            isRequired: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          jsonSerializer: JsonSerializer.freezed,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

import 'another.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
class ClassName with _$ClassName {
  const factory ClassName({
    required List<List<Another>> anotherList,
    int? intType,
    List<String>? list,
    Another? another,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('kotlin + moshi', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {'Another'},
        parameters: [
          UniversalType(
            type: 'integer',
            name: 'intType',
            isRequired: false,
          ),
          UniversalType(
            type: 'string',
            wrappingCollections: [UniversalCollections.list],
            name: 'list',
            isRequired: false,
          ),
          UniversalType(
            type: 'Another',
            name: 'another',
            isRequired: false,
          ),
          UniversalType(
            type: 'Another',
            wrappingCollections: [
              UniversalCollections.list,
              UniversalCollections.list,
            ],
            name: 'anotherList',
            isRequired: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          language: ProgrammingLanguage.kotlin,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = '''
import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class ClassName(
    var intType: Int?,
    var list: List<String>?,
    var another: Another?,
    var anotherList: List<List<Another>>,
)
''';
      expect(filledContent.content, expectedContents);
    });
  });

  group('Put required parameters first', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {'Another'},
        parameters: [
          UniversalType(
            type: 'integer',
            name: 'intNotRequired',
            isRequired: false,
          ),
          UniversalType(
            type: 'integer',
            name: 'intRequired',
            isRequired: true,
          ),
          UniversalType(
            type: 'Another',
            name: 'anotherNotRequired',
            isRequired: false,
          ),
          UniversalType(
            type: 'Another',
            name: 'list',
            wrappingCollections: [UniversalCollections.list],
            isRequired: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: ''),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';

import 'another.dart';

part 'class_name.g.dart';

@JsonSerializable()
class ClassName {
  const ClassName({
    required this.intRequired,
    required this.list,
    this.intNotRequired,
    this.anotherNotRequired,
  });
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
  
  final int? intNotRequired;
  final int intRequired;
  final Another? anotherNotRequired;
  final List<Another> list;

  Map<String, Object?> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + freezed', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {'Another'},
        parameters: [
          UniversalType(
            type: 'integer',
            name: 'intNotRequired',
            isRequired: false,
          ),
          UniversalType(
            type: 'integer',
            name: 'intRequired',
            isRequired: true,
          ),
          UniversalType(
            type: 'Another',
            name: 'anotherNotRequired',
            isRequired: false,
          ),
          UniversalType(
            type: 'Another',
            name: 'list',
            wrappingCollections: [UniversalCollections.list],
            isRequired: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          jsonSerializer: JsonSerializer.freezed,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

import 'another.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
class ClassName with _$ClassName {
  const factory ClassName({
    required int intRequired,
    required List<Another> list,
    int? intNotRequired,
    Another? anotherNotRequired,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('kotlin + moshi', () async {
      // In Kotlin this is optional
    });
  });

  group('Enum', () {
    group('dart + json_serializable', () {
      test('without toJson()', () async {
        final dataClasses = [
          UniversalEnumClass(
            name: 'EnumName',
            type: 'int',
            items: UniversalEnumItem.listFromNames({'1', '2', '3'}),
          ),
          UniversalEnumClass(
            name: 'EnumNameString',
            type: 'string',
            items: UniversalEnumItem.listFromNames(
              {'itemOne', 'ItemTwo', 'item_three', 'ITEM-FOUR', 'пятый'},
            ),
          ),
          UniversalEnumClass(
            name: 'KeywordsName',
            type: 'string',
            items: UniversalEnumItem.listFromNames({'FALSE', 'for', 'do'}),
          ),
          UniversalEnumClass(
            name: 'EnumNameStringWithLeadingNumbers',
            type: 'string',
            items: UniversalEnumItem.listFromNames(
              {
                '1itemOne',
                '2ItemTwo',
                '3item_three',
                '4ITEM-FOUR',
                '5иллегалчарактер',
                '6 item six',
              },
            ),
          ),
        ];

        const fillController = FillController(
          config: GeneratorConfig(
            name: '',
            outputDirectory: '',
            unknownEnumValue: false,
          ),
        );
        final files = <GeneratedFile>[];
        for (final enumClass in dataClasses) {
          files.add(fillController.fillDtoContent(enumClass));
        }
        const expectedContent0 = '''
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum EnumName {
  @JsonValue(1)
  value1,
  @JsonValue(2)
  value2,
  @JsonValue(3)
  value3;
}
''';

        const expectedContent1 = '''
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum EnumNameString {
  @JsonValue('itemOne')
  itemOne,
  @JsonValue('ItemTwo')
  itemTwo,
  @JsonValue('item_three')
  itemThree,
  @JsonValue('ITEM-FOUR')
  itemFour,
  /// Incorrect name has been replaced. Original name: `пятый`.
  @JsonValue('пятый')
  undefined0;
}
''';
        const expectedContent2 = '''
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum KeywordsName {
  /// The name has been replaced because it contains a keyword. Original name: `FALSE`.
  @JsonValue('FALSE')
  valueFalse,
  /// The name has been replaced because it contains a keyword. Original name: `for`.
  @JsonValue('for')
  valueFor,
  /// The name has been replaced because it contains a keyword. Original name: `do`.
  @JsonValue('do')
  valueDo;
}
''';

        const expectedContent3 = '''
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum EnumNameStringWithLeadingNumbers {
  @JsonValue('1itemOne')
  value1itemOne,
  @JsonValue('2ItemTwo')
  value2ItemTwo,
  @JsonValue('3item_three')
  value3itemThree,
  @JsonValue('4ITEM-FOUR')
  value4ItemFour,
  /// Incorrect name has been replaced. Original name: `5иллегалчарактер`.
  @JsonValue('5иллегалчарактер')
  undefined0,
  @JsonValue('6 item six')
  value6ItemSix;
}
''';

        expect(files[0].content, expectedContent0);
        expect(files[1].content, expectedContent1);
        expect(files[2].content, expectedContent2);
        expect(files[3].content, expectedContent3);
      });

      test('with toJson() in enums', () async {
        final dataClasses = [
          UniversalEnumClass(
            name: 'EnumName',
            type: 'int',
            items: UniversalEnumItem.listFromNames({'1', '2', '3'}),
          ),
          UniversalEnumClass(
            name: 'EnumNameString',
            type: 'string',
            items: UniversalEnumItem.listFromNames(
              {'itemOne', 'ItemTwo', 'item_three', 'ITEM-FOUR'},
            ),
          ),
        ];

        const fillController = FillController(
          config: GeneratorConfig(
            name: '',
            outputDirectory: '',
            enumsToJson: true,
            unknownEnumValue: false,
          ),
        );
        final files = <GeneratedFile>[];
        for (final enumClass in dataClasses) {
          files.add(fillController.fillDtoContent(enumClass));
        }
        const expectedContent0 = '''
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum EnumName {
  @JsonValue(1)
  value1(1),
  @JsonValue(2)
  value2(2),
  @JsonValue(3)
  value3(3);

  const EnumName(this.json);

  final int? json;

  int? toJson() => json;
}
''';

        const expectedContent1 = '''
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum EnumNameString {
  @JsonValue('itemOne')
  itemOne('itemOne'),
  @JsonValue('ItemTwo')
  itemTwo('ItemTwo'),
  @JsonValue('item_three')
  itemThree('item_three'),
  @JsonValue('ITEM-FOUR')
  itemFour('ITEM-FOUR');

  const EnumNameString(this.json);

  final String? json;

  String? toJson() => json;
}
''';

        expect(files[0].content, expectedContent0);
        expect(files[1].content, expectedContent1);
      });
    });

    group('dart + freezed', () {
      test('without toJson()', () async {
        final dataClasses = [
          UniversalEnumClass(
            name: 'EnumName',
            type: 'int',
            items: UniversalEnumItem.listFromNames({'1', '2', '3'}),
          ),
          UniversalEnumClass(
            name: 'EnumNameString',
            type: 'string',
            items: UniversalEnumItem.listFromNames(
              {'itemOne', 'ItemTwo', 'item_three', 'ITEM-FOUR'},
            ),
          ),
          UniversalEnumClass(
            name: 'KeywordsName',
            type: 'string',
            items: UniversalEnumItem.listFromNames({'FALSE', 'for', 'do'}),
          ),
        ];
        const fillController = FillController(
          config: GeneratorConfig(
            name: '',
            outputDirectory: '',
            jsonSerializer: JsonSerializer.freezed,
            unknownEnumValue: false,
          ),
        );
        final files = <GeneratedFile>[];
        for (final enumClass in dataClasses) {
          files.add(fillController.fillDtoContent(enumClass));
        }
        const expectedContent0 = '''
import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum EnumName {
  @JsonValue(1)
  value1,
  @JsonValue(2)
  value2,
  @JsonValue(3)
  value3;
}
''';

        const expectedContent1 = '''
import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum EnumNameString {
  @JsonValue('itemOne')
  itemOne,
  @JsonValue('ItemTwo')
  itemTwo,
  @JsonValue('item_three')
  itemThree,
  @JsonValue('ITEM-FOUR')
  itemFour;
}
''';
        const expectedContent2 = '''
import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum KeywordsName {
  /// The name has been replaced because it contains a keyword. Original name: `FALSE`.
  @JsonValue('FALSE')
  valueFalse,
  /// The name has been replaced because it contains a keyword. Original name: `for`.
  @JsonValue('for')
  valueFor,
  /// The name has been replaced because it contains a keyword. Original name: `do`.
  @JsonValue('do')
  valueDo;
}
''';
        expect(files[0].content, expectedContent0);
        expect(files[1].content, expectedContent1);
        expect(files[2].content, expectedContent2);
      });

      test('with toJson()', () async {
        final dataClasses = [
          UniversalEnumClass(
            name: 'EnumName',
            type: 'int',
            items: UniversalEnumItem.listFromNames({'1', '2', '3'}),
          ),
          UniversalEnumClass(
            name: 'EnumNameString',
            type: 'string',
            items: UniversalEnumItem.listFromNames(
              {'itemOne', 'ItemTwo', 'item_three', 'ITEM-FOUR', 'Item five'},
            ),
          ),
        ];
        const fillController = FillController(
          config: GeneratorConfig(
            name: '',
            outputDirectory: '',
            jsonSerializer: JsonSerializer.freezed,
            enumsToJson: true,
          ),
        );
        final files = <GeneratedFile>[];
        for (final enumClass in dataClasses) {
          files.add(fillController.fillDtoContent(enumClass));
        }

        const expectedContent0 = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum EnumName {
  @JsonValue(1)
  value1(1),
  @JsonValue(2)
  value2(2),
  @JsonValue(3)
  value3(3),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const EnumName(this.json);

  factory EnumName.fromJson(int json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final int? json;

  int? toJson() => json;
}
''';

        const expectedContent1 = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum EnumNameString {
  @JsonValue('itemOne')
  itemOne('itemOne'),
  @JsonValue('ItemTwo')
  itemTwo('ItemTwo'),
  @JsonValue('item_three')
  itemThree('item_three'),
  @JsonValue('ITEM-FOUR')
  itemFour('ITEM-FOUR'),
  @JsonValue('Item five')
  itemFive('Item five'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const EnumNameString(this.json);

  factory EnumNameString.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  String? toJson() => json;
}
''';
        expect(files[0].content, expectedContent0);
        expect(files[1].content, expectedContent1);
      });
    });

    test('kotlin + moshi', () async {
      final dataClasses = [
        UniversalEnumClass(
          name: 'EnumName',
          type: 'int',
          items: UniversalEnumItem.listFromNames({'1', '2', '3'}),
        ),
        UniversalEnumClass(
          name: 'EnumNameString',
          type: 'string',
          items: UniversalEnumItem.listFromNames(
            {'itemOne', 'ItemTwo', 'item_three', 'ITEM-FOUR'},
          ),
        ),
        UniversalEnumClass(
          name: 'KeywordsName',
          type: 'string',
          items: UniversalEnumItem.listFromNames({'FALSE', 'for', 'do'}),
        ),
      ];
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          language: ProgrammingLanguage.kotlin,
        ),
      );
      final files = <GeneratedFile>[];
      for (final enumClass in dataClasses) {
        files.add(fillController.fillDtoContent(enumClass));
      }
      const expectedContent0 = '''
import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
enum class EnumName {
    @Json("1")
    VALUE_1,
    @Json("2")
    VALUE_2,
    @Json("3")
    VALUE_3,
}
''';
      const expectedContent1 = '''
import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
enum class EnumNameString {
    @Json("itemOne")
    ITEM_ONE,
    @Json("ItemTwo")
    ITEM_TWO,
    @Json("item_three")
    ITEM_THREE,
    @Json("ITEM-FOUR")
    ITEM_FOUR,
}
''';
      const expectedContent2 = '''
import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
enum class KeywordsName {
    /// The name has been replaced because it contains a keyword. Original name: `FALSE`.
    @Json("FALSE")
    VALUE_FALSE,

    /// The name has been replaced because it contains a keyword. Original name: `for`.
    @Json("for")
    VALUE_FOR,

    /// The name has been replaced because it contains a keyword. Original name: `do`.
    @Json("do")
    VALUE_DO,
}
''';
      expect(files[0].content, expectedContent0);
      expect(files[1].content, expectedContent1);
      expect(files[2].content, expectedContent2);
    });
  });

  group('Enum negative values', () {
    test('dart + json_serializable', () async {
      final dataClass = UniversalEnumClass(
        name: 'EnumName',
        type: 'int',
        items: UniversalEnumItem.listFromNames({'-2', '-1', '0', '1'}),
      );
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: ''),
      );
      final file = fillController.fillDtoContent(dataClass);

      const expectedContent = r'''
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum EnumName {
  @JsonValue(-2)
  valueMinus2(-2),
  @JsonValue(-1)
  valueMinus1(-1),
  @JsonValue(0)
  value0(0),
  @JsonValue(1)
  value1(1),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const EnumName(this.json);

  factory EnumName.fromJson(int json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final int? json;
}
''';

      expect(file.content, expectedContent);
    });

    test('dart + freezed', () async {
      final dataClass = UniversalEnumClass(
        name: 'EnumName',
        type: 'int',
        items: UniversalEnumItem.listFromNames({'-2', '-1', '0', '1'}),
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          jsonSerializer: JsonSerializer.freezed,
        ),
      );
      final file = fillController.fillDtoContent(dataClass);

      const expectedContent = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum EnumName {
  @JsonValue(-2)
  valueMinus2(-2),
  @JsonValue(-1)
  valueMinus1(-1),
  @JsonValue(0)
  value0(0),
  @JsonValue(1)
  value1(1),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const EnumName(this.json);

  factory EnumName.fromJson(int json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final int? json;
}
''';

      expect(file.content, expectedContent);
    });

    test('kotlin + moshi', () async {
      final dataClass = UniversalEnumClass(
        name: 'EnumName',
        type: 'int',
        items: UniversalEnumItem.listFromNames({'-2', '-1', '0', '1'}),
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          language: ProgrammingLanguage.kotlin,
        ),
      );
      final file = fillController.fillDtoContent(dataClass);
      const expectedContent = '''
import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
enum class EnumName {
    @Json("-2")
    VALUE_MINUS_2,
    @Json("-1")
    VALUE_MINUS_1,
    @Json("0")
    VALUE_0,
    @Json("1")
    VALUE_1,
}
''';
      expect(file.content, expectedContent);
    });
  });

  group('Typedef data class', () {
    test('dart', () async {
      const dataClasses = [
        UniversalComponentClass(
          name: 'Date',
          imports: {},
          parameters: [
            UniversalType(
              type: 'string',
              format: 'date',
              isRequired: true,
            ),
          ],
          typeDef: true,
        ),
        UniversalComponentClass(
          name: 'BooleanList',
          imports: {},
          parameters: [
            UniversalType(
              type: 'boolean',
              wrappingCollections: [UniversalCollections.list],
              isRequired: true,
            ),
          ],
          typeDef: true,
        ),
        UniversalComponentClass(
          name: 'AnotherValue',
          imports: {'Another'},
          parameters: [
            UniversalType(
              type: 'Another',
              isRequired: true,
            ),
          ],
          typeDef: true,
        ),
      ];
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: ''),
      );
      final files = <GeneratedFile>[];
      for (final enumClass in dataClasses) {
        files.add(fillController.fillDtoContent(enumClass));
      }
      const expectedContent0 = '''
typedef Date = DateTime;
''';
      const expectedContent1 = '''
typedef BooleanList = List<bool>;
''';
      const expectedContent2 = '''
import 'another.dart';

typedef AnotherValue = Another;
''';
      expect(files[0].content, expectedContent0);
      expect(files[1].content, expectedContent1);
      expect(files[2].content, expectedContent2);
    });

    test('kotlin', () async {
      const dataClasses = [
        UniversalComponentClass(
          name: 'Date',
          imports: {},
          parameters: [
            UniversalType(
              type: 'string',
              format: 'date',
              isRequired: true,
            ),
          ],
          typeDef: true,
        ),
        UniversalComponentClass(
          name: 'BooleanList',
          imports: {},
          parameters: [
            UniversalType(
              type: 'boolean',
              wrappingCollections: [UniversalCollections.list],
              isRequired: true,
            ),
          ],
          typeDef: true,
        ),
        UniversalComponentClass(
          name: 'AnotherValue',
          imports: {'Another'},
          parameters: [
            UniversalType(
              type: 'Another',
              isRequired: true,
            ),
          ],
          typeDef: true,
        ),
      ];
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          language: ProgrammingLanguage.kotlin,
        ),
      );
      final files = <GeneratedFile>[];
      for (final enumClass in dataClasses) {
        files.add(fillController.fillDtoContent(enumClass));
      }
      const expectedContent0 = '''
typealias Date = Date;
''';
      const expectedContent1 = '''
typealias BooleanList = List<Boolean>;
''';
      const expectedContent2 = '''
typealias AnotherValue = Another;
''';
      expect(files[0].content, expectedContent0);
      expect(files[1].content, expectedContent1);
      expect(files[2].content, expectedContent2);
    });
  });

  group('nullable', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(
            type: 'string',
            wrappingCollections: [
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
            ],
            name: 'list1',
            isRequired: false,
            nullable: true,
          ),
          UniversalType(
            type: 'string',
            name: 'list2',
            isRequired: false,
            nullable: true,
          ),
          UniversalType(
            type: 'string',
            name: 'list3',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            name: 'list4',
            isRequired: false,
          ),
          UniversalType(
            type: 'string',
            name: 'list5',
            isRequired: true,
            nullable: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: ''),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';

part 'class_name.g.dart';

@JsonSerializable()
class ClassName {
  const ClassName({
    required this.list3,
    required this.list5,
    this.list1,
    this.list2,
    this.list4,
  });
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
  
  final List<List<List<List<String>>>>? list1;
  final String? list2;
  final String list3;
  final String? list4;
  final String? list5;

  Map<String, Object?> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + freezed', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(
            type: 'string',
            wrappingCollections: [
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
            ],
            name: 'list1',
            isRequired: false,
            nullable: true,
          ),
          UniversalType(
            type: 'string',
            name: 'list2',
            isRequired: false,
            nullable: true,
          ),
          UniversalType(
            type: 'string',
            name: 'list3',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            name: 'list4',
            isRequired: false,
          ),
          UniversalType(
            type: 'string',
            name: 'list5',
            isRequired: true,
            nullable: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          jsonSerializer: JsonSerializer.freezed,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
class ClassName with _$ClassName {
  const factory ClassName({
    required String list3,
    required String? list5,
    List<List<List<List<String>>>>? list1,
    String? list2,
    String? list4,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('kotlin + moshi', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(
            type: 'string',
            wrappingCollections: [
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
              UniversalCollections.list,
            ],
            name: 'list1',
            isRequired: false,
            nullable: true,
          ),
          UniversalType(
            type: 'string',
            name: 'list2',
            isRequired: false,
            nullable: true,
          ),
          UniversalType(
            type: 'string',
            name: 'list3',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            name: 'list4',
            isRequired: false,
          ),
          UniversalType(
            type: 'string',
            name: 'list5',
            isRequired: true,
            nullable: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          language: ProgrammingLanguage.kotlin,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContent = '''
import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class ClassName(
    var list1: List<List<List<List<String>>>>?,
    var list2: String?,
    var list3: String,
    var list4: String?,
    var list5: String?,
)
''';
      expect(filledContent.content, expectedContent);
    });
  });

  group('description', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        description: 'Test class',
        parameters: [
          UniversalType(
            type: 'string',
            description: 'Some string',
            name: 'stringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            description: 'Default value',
            name: 'defaultType',
            defaultValue: 'str',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            description: 'JsonKey here',
            name: 'jsonKeyValue',
            jsonKey: 'json_key_value',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            description: 'Mega mind',
            name: 'megaMind',
            jsonKey: 'mega_MIND',
            isRequired: true,
          ),
          UniversalType(
            type: 'object',
            description: '',
            name: 'emptyDescription',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            description: 'List of data\nThis data is a list',
            wrappingCollections: [UniversalCollections.list],
            name: 'list',
            isRequired: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(name: '', outputDirectory: ''),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';

part 'class_name.g.dart';

/// Test class
@JsonSerializable()
class ClassName {
  const ClassName({
    required this.stringType,
    required this.jsonKeyValue,
    required this.megaMind,
    required this.emptyDescription,
    required this.list,
    this.defaultType = 'str',
  });
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
  
  /// Some string
  final String stringType;

  /// Default value
  final String defaultType;

  /// JsonKey here
  @JsonKey(name: 'json_key_value')
  final String jsonKeyValue;

  /// Mega mind
  @JsonKey(name: 'mega_MIND')
  final String megaMind;
  final dynamic emptyDescription;

  /// List of data.
  /// This data is a list.
  final List<String> list;

  Map<String, Object?> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('dart + freezed', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        description: 'Test class',
        parameters: [
          UniversalType(
            type: 'string',
            description: 'Some string',
            name: 'stringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            description: 'Default value',
            name: 'defaultType',
            defaultValue: 'str',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            description: 'JsonKey here',
            name: 'jsonKeyValue',
            jsonKey: 'json_key_value',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            description: 'Mega mind',
            name: 'megaMind',
            jsonKey: 'mega_MIND',
            isRequired: true,
          ),
          UniversalType(
            type: 'object',
            description: '',
            name: 'emptyDescription',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            description: 'List of data\nThis data is a list',
            wrappingCollections: [UniversalCollections.list],
            name: 'list',
            isRequired: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          jsonSerializer: JsonSerializer.freezed,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

/// Test class
@Freezed()
class ClassName with _$ClassName {
  const factory ClassName({
    /// Some string
    required String stringType,

    /// JsonKey here
    @JsonKey(name: 'json_key_value')
    required String jsonKeyValue,

    /// Mega mind
    @JsonKey(name: 'mega_MIND')
    required String megaMind,
    required dynamic emptyDescription,

    /// List of data.
    /// This data is a list.
    required List<String> list,

    /// Default value
    @Default('str')
    String defaultType,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, Object?> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.content, expectedContents);
    });

    test('kotlin + moshi ', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        description: 'Test class',
        parameters: [
          UniversalType(
            type: 'string',
            description: 'Some string',
            name: 'stringType',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            description: 'Default value',
            name: 'defaultType',
            defaultValue: 'str',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            description: 'JsonKey here',
            name: 'jsonKeyValue',
            jsonKey: 'json_key_value',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            description: 'Mega mind',
            name: 'megaMind',
            jsonKey: 'mega_MIND',
            isRequired: true,
          ),
          UniversalType(
            type: 'object',
            description: '',
            name: 'emptyDescription',
            isRequired: true,
          ),
          UniversalType(
            type: 'string',
            description: 'List of data',
            wrappingCollections: [UniversalCollections.list],
            name: 'list',
            isRequired: true,
          ),
        ],
      );
      const fillController = FillController(
        config: GeneratorConfig(
          name: '',
          outputDirectory: '',
          language: ProgrammingLanguage.kotlin,
        ),
      );
      final filledContent = fillController.fillDtoContent(dataClass);
      const expectedContent = '''
import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

/// Test class
@JsonClass(generateAdapter = true)
data class ClassName(
    /// Some string
    var stringType: String,
    /// Default value
    var defaultType: String = "str",
    /// JsonKey here
    @Json("json_key_value")
    var jsonKeyValue: String,
    /// Mega mind
    @Json("mega_MIND")
    var megaMind: String,
    var emptyDescription: Any,
    /// List of data
    var list: List<String>,
)
''';
      expect(filledContent.content, expectedContent);
    });
  });
}
