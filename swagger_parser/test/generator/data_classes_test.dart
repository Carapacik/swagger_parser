import 'package:swagger_parser/src/generator/fill_controller.dart';
import 'package:swagger_parser/src/generator/models/generated_file.dart';
import 'package:swagger_parser/src/generator/models/programming_lang.dart';
import 'package:swagger_parser/src/generator/models/universal_component_class.dart';
import 'package:swagger_parser/src/generator/models/universal_enum_class.dart';
import 'package:swagger_parser/src/generator/models/universal_type.dart';
import 'package:test/test.dart';

void main() {
  group('Empty data class', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [],
      );
      const fillController = FillController();
      final filledContent = await fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';

part 'class_name.g.dart';

@JsonSerializable()
class ClassName {
  const ClassName();
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
  
  Map<String, dynamic> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('dart + freezed', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [],
      );
      const fillController = FillController(freezed: true);
      final filledContent = await fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
class ClassName with _$ClassName {
  const factory ClassName() = _ClassName;
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + moshi', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [],
      );
      const fillController =
          FillController(programmingLanguage: ProgrammingLanguage.kotlin);
      final filledContent = await fillController.fillDtoContent(dataClass);
      const expectedContents = '''
import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class ClassName()
''';
      expect(filledContent.contents, expectedContents);
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
          'Space class'
        },
        parameters: [],
      );
      const fillController = FillController();
      final filledContent = await fillController.fillDtoContent(dataClass);
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
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
  
  Map<String, dynamic> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('dart + freezed', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {
          'camelClass',
          'snake_class',
          'kebab-class',
          'PascalClass',
          'Space class'
        },
        parameters: [],
      );
      const fillController = FillController(freezed: true);
      final filledContent = await fillController.fillDtoContent(dataClass);
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
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.contents, expectedContents);
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
          UniversalType(type: 'integer', name: 'intType'),
          UniversalType(type: 'number', name: 'numberType'),
          UniversalType(
            type: 'number',
            format: 'double',
            name: 'doubleNumberType',
          ),
          UniversalType(
            type: 'number',
            format: 'float',
            name: 'floatNumberType',
          ),
          UniversalType(type: 'string', name: 'stringType'),
          UniversalType(
            type: 'string',
            format: 'binary',
            name: 'binaryStringType',
          ),
          UniversalType(
            type: 'string',
            format: 'date',
            name: 'dateStringType',
          ),
          UniversalType(
            type: 'string',
            format: 'date-time',
            name: 'dateTimeStringType',
          ),
          UniversalType(type: 'file', name: 'fileType'),
          UniversalType(type: 'boolean', name: 'boolType'),
          UniversalType(type: 'object', name: 'objectType'),
          UniversalType(type: 'Another', name: 'anotherType')
        ],
      );
      const fillController = FillController();
      final filledContent = await fillController.fillDtoContent(dataClass);
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
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
  
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
  final Object objectType;
  final Another anotherType;

  Map<String, dynamic> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('dart + freezed', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(type: 'integer', name: 'intType'),
          UniversalType(type: 'number', name: 'numberType'),
          UniversalType(
            type: 'number',
            format: 'double',
            name: 'doubleNumberType',
          ),
          UniversalType(
            type: 'number',
            format: 'float',
            name: 'floatNumberType',
          ),
          UniversalType(type: 'string', name: 'stringType'),
          UniversalType(
            type: 'string',
            format: 'binary',
            name: 'binaryStringType',
          ),
          UniversalType(
            type: 'string',
            format: 'date',
            name: 'dateStringType',
          ),
          UniversalType(
            type: 'string',
            format: 'date-time',
            name: 'dateTimeStringType',
          ),
          UniversalType(type: 'file', name: 'fileType'),
          UniversalType(type: 'boolean', name: 'boolType'),
          UniversalType(type: 'object', name: 'objectType'),
          UniversalType(type: 'Another', name: 'anotherType')
        ],
      );
      const fillController = FillController(freezed: true);
      final filledContent = await fillController.fillDtoContent(dataClass);
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
    required Object objectType,
    required Another anotherType,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + moshi', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(type: 'integer', name: 'intType'),
          UniversalType(type: 'number', name: 'numberType'),
          UniversalType(
            type: 'number',
            format: 'double',
            name: 'doubleNumberType',
          ),
          UniversalType(
            type: 'number',
            format: 'float',
            name: 'floatNumberType',
          ),
          UniversalType(type: 'string', name: 'stringType'),
          UniversalType(
            type: 'string',
            format: 'binary',
            name: 'binaryStringType',
          ),
          UniversalType(
            type: 'string',
            format: 'date',
            name: 'dateStringType',
          ),
          UniversalType(
            type: 'string',
            format: 'date-time',
            name: 'dateTimeStringType',
          ),
          UniversalType(type: 'file', name: 'fileType'),
          UniversalType(type: 'boolean', name: 'boolType'),
          UniversalType(type: 'object', name: 'objectType'),
          UniversalType(type: 'Another', name: 'anotherType')
        ],
      );
      const fillController =
          FillController(programmingLanguage: ProgrammingLanguage.kotlin);
      final filledContent = await fillController.fillDtoContent(dataClass);
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
      expect(filledContent.contents, expectedContents);
    });
  });

  group('Array type', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {'Another'},
        parameters: [
          UniversalType(type: 'integer', name: 'list0', arrayDepth: 1),
          UniversalType(type: 'string', name: 'list1', arrayDepth: 2),
          UniversalType(type: 'Another', name: 'list5', arrayDepth: 5)
        ],
      );
      const fillController = FillController();
      final filledContent = await fillController.fillDtoContent(dataClass);
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
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
  
  final List<int> list0;
  final List<List<String>> list1;
  final List<List<List<List<List<Another>>>>> list5;

  Map<String, dynamic> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('dart + freezed', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {'Another'},
        parameters: [
          UniversalType(type: 'integer', name: 'list0', arrayDepth: 1),
          UniversalType(type: 'string', name: 'list1', arrayDepth: 2),
          UniversalType(type: 'Another', name: 'list5', arrayDepth: 5)
        ],
      );
      const fillController = FillController(freezed: true);
      final filledContent = await fillController.fillDtoContent(dataClass);
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
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + moshi', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {'Another'},
        parameters: [
          UniversalType(type: 'integer', name: 'list0', arrayDepth: 1),
          UniversalType(type: 'string', name: 'list1', arrayDepth: 2),
          UniversalType(type: 'Another', name: 'list5', arrayDepth: 5)
        ],
      );
      const fillController =
          FillController(programmingLanguage: ProgrammingLanguage.kotlin);
      final filledContent = await fillController.fillDtoContent(dataClass);
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
      expect(filledContent.contents, expectedContents);
    });
  });

  group('JsonKey name', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(type: 'integer', name: 'intType', jsonKey: 'int_type'),
          UniversalType(
            type: 'string',
            name: 'stringType',
            jsonKey: 'stringType',
          ),
          UniversalType(
            type: 'boolean',
            name: 'boolType',
            jsonKey: 'bool-type',
          ),
          UniversalType(
            type: 'Another',
            name: 'anotherType',
            jsonKey: 'another',
          )
        ],
      );
      const fillController = FillController();
      final filledContent = await fillController.fillDtoContent(dataClass);
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
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
  
  @JsonKey(name: 'int_type')
  final int intType;
  final String stringType;
  @JsonKey(name: 'bool-type')
  final bool boolType;
  @JsonKey(name: 'another')
  final Another anotherType;

  Map<String, dynamic> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('dart + freezed', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(type: 'integer', name: 'intType', jsonKey: 'int_type'),
          UniversalType(
            type: 'string',
            name: 'stringType',
            jsonKey: 'stringType',
          ),
          UniversalType(
            type: 'boolean',
            name: 'boolType',
            jsonKey: 'bool-type',
          ),
          UniversalType(
            type: 'Another',
            name: 'anotherType',
            jsonKey: 'another',
          )
        ],
      );
      const fillController = FillController(freezed: true);
      final filledContent = await fillController.fillDtoContent(dataClass);
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
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + moshi', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(type: 'integer', name: 'intType', jsonKey: 'int_type'),
          UniversalType(
            type: 'string',
            name: 'stringType',
            jsonKey: 'stringType',
          ),
          UniversalType(
            type: 'boolean',
            name: 'boolType',
            jsonKey: 'bool-type',
          ),
          UniversalType(
            type: 'Another',
            name: 'anotherType',
            jsonKey: 'another',
          )
        ],
      );
      const fillController =
          FillController(programmingLanguage: ProgrammingLanguage.kotlin);
      final filledContent = await fillController.fillDtoContent(dataClass);
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
      expect(filledContent.contents, expectedContents);
    });
  });

  group('JsonKey defaultValue', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(type: 'integer', name: 'intType', defaultValue: '1'),
          UniversalType(
            type: 'string',
            name: 'stringType',
            defaultValue: 'str',
          ),
          UniversalType(
            type: 'boolean',
            name: 'boolType',
            defaultValue: 'false',
          )
        ],
      );
      const fillController = FillController();
      final filledContent = await fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';

part 'class_name.g.dart';

@JsonSerializable()
class ClassName {
  const ClassName({
    required this.intType,
    required this.stringType,
    required this.boolType,
  });
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
  
  @JsonKey(defaultValue: 1)
  final int intType;
  @JsonKey(defaultValue: 'str')
  final String stringType;
  @JsonKey(defaultValue: false)
  final bool boolType;

  Map<String, dynamic> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('dart + freezed', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(type: 'integer', name: 'intType', defaultValue: '1'),
          UniversalType(
            type: 'string',
            name: 'stringType',
            defaultValue: 'str',
          ),
          UniversalType(
            type: 'boolean',
            name: 'boolType',
            defaultValue: 'false',
          )
        ],
      );
      const fillController = FillController(freezed: true);
      final filledContent = await fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
class ClassName with _$ClassName {
  const factory ClassName({
    @Default(1)
    required int intType,
    @Default('str')
    required String stringType,
    @Default(false)
    required bool boolType,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + moshi', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(type: 'integer', name: 'intType', defaultValue: '1'),
          UniversalType(
            type: 'string',
            name: 'stringType',
            defaultValue: 'str',
          ),
          UniversalType(
            type: 'boolean',
            name: 'boolType',
            defaultValue: 'false',
          )
        ],
      );
      const fillController =
          FillController(programmingLanguage: ProgrammingLanguage.kotlin);
      final filledContent = await fillController.fillDtoContent(dataClass);
      const expectedContents = '''
import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class ClassName(
    var intType: Int = 1,
    var stringType: String = "str",
    var boolType: Boolean = false,
)
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('Required parameters', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {'Another'},
        parameters: [
          UniversalType(type: 'integer', name: 'intType', isRequired: false),
          UniversalType(
            type: 'string',
            arrayDepth: 1,
            name: 'list',
            isRequired: false,
          ),
          UniversalType(type: 'Another', name: 'another', isRequired: false),
          UniversalType(
            type: 'Another',
            arrayDepth: 2,
            name: 'anotherList',
            // ignore: avoid_redundant_argument_values
            isRequired: true,
          )
        ],
      );
      const fillController = FillController();
      final filledContent = await fillController.fillDtoContent(dataClass);
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
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
  
  final int? intType;
  final List<String>? list;
  final Another? another;
  final List<List<Another>> anotherList;

  Map<String, dynamic> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('dart + freezed', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {'Another'},
        parameters: [
          UniversalType(type: 'integer', name: 'intType', isRequired: false),
          UniversalType(
            type: 'string',
            arrayDepth: 1,
            name: 'list',
            isRequired: false,
          ),
          UniversalType(type: 'Another', name: 'another', isRequired: false),
          UniversalType(
            type: 'Another',
            arrayDepth: 2,
            name: 'anotherList',
            // ignore: avoid_redundant_argument_values
            isRequired: true,
          )
        ],
      );
      const fillController = FillController(freezed: true);
      final filledContent = await fillController.fillDtoContent(dataClass);
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
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + moshi', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {'Another'},
        parameters: [
          UniversalType(type: 'integer', name: 'intType', isRequired: false),
          UniversalType(
            type: 'string',
            arrayDepth: 1,
            name: 'list',
            isRequired: false,
          ),
          UniversalType(type: 'Another', name: 'another', isRequired: false),
          UniversalType(
            type: 'Another',
            arrayDepth: 2,
            name: 'anotherList',
            // ignore: avoid_redundant_argument_values
            isRequired: true,
          )
        ],
      );
      const fillController =
          FillController(programmingLanguage: ProgrammingLanguage.kotlin);
      final filledContent = await fillController.fillDtoContent(dataClass);
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
      expect(filledContent.contents, expectedContents);
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
          UniversalType(type: 'integer', name: 'intRequired'),
          UniversalType(
            type: 'Another',
            name: 'anotherNotRequired',
            isRequired: false,
          ),
          UniversalType(type: 'Another', name: 'list', arrayDepth: 1)
        ],
      );
      const fillController = FillController();
      final filledContent = await fillController.fillDtoContent(dataClass);
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
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
  
  final int? intNotRequired;
  final int intRequired;
  final Another? anotherNotRequired;
  final List<Another> list;

  Map<String, dynamic> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.contents, expectedContents);
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
          UniversalType(type: 'integer', name: 'intRequired'),
          UniversalType(
            type: 'Another',
            name: 'anotherNotRequired',
            isRequired: false,
          ),
          UniversalType(type: 'Another', name: 'list', arrayDepth: 1)
        ],
      );
      const fillController = FillController(freezed: true);
      final filledContent = await fillController.fillDtoContent(dataClass);
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
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + moshi', () async {
      // In Kotlin this is optional
    });
  });

  group('Enum', () {
    test('dart + json_serializable', () async {
      const dataClasses = [
        UniversalEnumClass(
          name: 'EnumName',
          type: 'int',
          items: {'1', '2', '3'},
        ),
        UniversalEnumClass(
          name: 'EnumNameString',
          type: 'string',
          items: {'itemOne', 'ItemTwo', 'item_three', 'ITEM-FOUR'},
        )
      ];

      const fillController = FillController();
      final files = <GeneratedFile>[];
      for (final enumClass in dataClasses) {
        files.add(await fillController.fillDtoContent(enumClass));
      }
      const expectedContent0 = r'''
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum EnumName {
  @JsonValue(1)
  value1,
  @JsonValue(2)
  value2,
  @JsonValue(3)
  value3;

  int toJson() => _$EnumNameEnumMap[this]!;
}

const _$EnumNameEnumMap = {
  EnumName.value1: 1,
  EnumName.value2: 2,
  EnumName.value3: 3,
};
''';

      const expectedContent1 = r'''
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
  itemFour;

  String toJson() => _$EnumNameStringEnumMap[this]!;
}

const _$EnumNameStringEnumMap = {
  EnumNameString.itemOne: 'itemOne',
  EnumNameString.itemTwo: 'ItemTwo',
  EnumNameString.itemThree: 'item_three',
  EnumNameString.itemFour: 'ITEM-FOUR',
};
''';
      expect(files[0].contents, expectedContent0);
      expect(files[1].contents, expectedContent1);
    });

    test('dart + freezed', () async {
      const dataClasses = [
        UniversalEnumClass(
          name: 'EnumName',
          type: 'int',
          items: {'1', '2', '3'},
        ),
        UniversalEnumClass(
          name: 'EnumNameString',
          type: 'string',
          items: {'itemOne', 'ItemTwo', 'item_three', 'ITEM-FOUR'},
        )
      ];
      const fillController = FillController(freezed: true);
      final files = <GeneratedFile>[];
      for (final enumClass in dataClasses) {
        files.add(await fillController.fillDtoContent(enumClass));
      }
      const expectedContent0 = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum EnumName {
  @JsonValue(1)
  value1,
  @JsonValue(2)
  value2,
  @JsonValue(3)
  value3;

  int toJson() => _$EnumNameEnumMap[this]!;
}

const _$EnumNameEnumMap = {
  EnumName.value1: 1,
  EnumName.value2: 2,
  EnumName.value3: 3,
};
''';

      const expectedContent1 = r'''
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

  String toJson() => _$EnumNameStringEnumMap[this]!;
}

const _$EnumNameStringEnumMap = {
  EnumNameString.itemOne: 'itemOne',
  EnumNameString.itemTwo: 'ItemTwo',
  EnumNameString.itemThree: 'item_three',
  EnumNameString.itemFour: 'ITEM-FOUR',
};
''';
      expect(files[0].contents, expectedContent0);
      expect(files[1].contents, expectedContent1);
    });

    test('kotlin + moshi', () async {
      const dataClasses = [
        UniversalEnumClass(
          name: 'EnumName',
          type: 'int',
          items: {'1', '2', '3'},
        ),
        UniversalEnumClass(
          name: 'EnumNameString',
          type: 'string',
          items: {'itemOne', 'ItemTwo', 'item_three', 'ITEM-FOUR'},
        ),
      ];
      const fillController =
          FillController(programmingLanguage: ProgrammingLanguage.kotlin);
      final files = <GeneratedFile>[];
      for (final enumClass in dataClasses) {
        files.add(await fillController.fillDtoContent(enumClass));
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
      expect(files[0].contents, expectedContent0);
      expect(files[1].contents, expectedContent1);
    });
  });

  group('Typedef data class', () {
    test('dart', () async {
      const dataClasses = [
        UniversalComponentClass(
          name: 'Date',
          imports: {},
          parameters: [
            UniversalType(type: 'string', format: 'date'),
          ],
          typeDef: true,
        ),
        UniversalComponentClass(
          name: 'BooleanList',
          imports: {},
          parameters: [
            UniversalType(type: 'boolean', arrayDepth: 1),
          ],
          typeDef: true,
        ),
        UniversalComponentClass(
          name: 'AnotherValue',
          imports: {'Another'},
          parameters: [
            UniversalType(type: 'Another'),
          ],
          typeDef: true,
        ),
      ];
      const fillController = FillController();
      final files = <GeneratedFile>[];
      for (final enumClass in dataClasses) {
        files.add(await fillController.fillDtoContent(enumClass));
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
      expect(files[0].contents, expectedContent0);
      expect(files[1].contents, expectedContent1);
      expect(files[2].contents, expectedContent2);
    });

    test('kotlin', () async {
      const dataClasses = [
        UniversalComponentClass(
          name: 'Date',
          imports: {},
          parameters: [
            UniversalType(type: 'string', format: 'date'),
          ],
          typeDef: true,
        ),
        UniversalComponentClass(
          name: 'BooleanList',
          imports: {},
          parameters: [
            UniversalType(type: 'boolean', arrayDepth: 1),
          ],
          typeDef: true,
        ),
        UniversalComponentClass(
          name: 'AnotherValue',
          imports: {'Another'},
          parameters: [
            UniversalType(type: 'Another'),
          ],
          typeDef: true,
        ),
      ];
      const fillController = FillController(
        programmingLanguage: ProgrammingLanguage.kotlin,
      );
      final files = <GeneratedFile>[];
      for (final enumClass in dataClasses) {
        files.add(await fillController.fillDtoContent(enumClass));
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
      expect(files[0].contents, expectedContent0);
      expect(files[1].contents, expectedContent1);
      expect(files[2].contents, expectedContent2);
    });
  });

  group('Nullable', () {
    test('dart + json_serializable data class parameters nullability',
        () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {
          'camelClass',
          'snake_class',
          'kebab-class',
          'PascalClass',
          'Space class'
        },
        parameters: [
          UniversalType(
            type: 'string',
            arrayDepth: 4,
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
            // ignore: avoid_redundant_argument_values
            isRequired: true,
            // ignore: avoid_redundant_argument_values
            nullable: false,
          ),
          UniversalType(
            type: 'string',
            name: 'list4',
            isRequired: false,
            // ignore: avoid_redundant_argument_values
            nullable: false,
          ),
          UniversalType(
            type: 'string',
            name: 'list5',
            // ignore: avoid_redundant_argument_values
            isRequired: true,
            nullable: true,
          ),
        ],
      );
      const fillController = FillController();
      final filledContent = await fillController.fillDtoContent(dataClass);
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
  const ClassName({
    required this.list3,
    required this.list5,
    this.list1,
    this.list2,
    this.list4,
  });
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
  
  final List<List<List<List<String>>>>? list1;
  final String? list2;
  final String list3;
  final String? list4;
  final String? list5;

  Map<String, dynamic> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('dart + freezed data class parameters nullability', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {
          'camelClass',
          'snake_class',
          'kebab-class',
          'PascalClass',
          'Space class'
        },
        parameters: [
          UniversalType(
            type: 'string',
            arrayDepth: 4,
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
            // ignore: avoid_redundant_argument_values
            isRequired: true,
            // ignore: avoid_redundant_argument_values
            nullable: false,
          ),
          UniversalType(
            type: 'string',
            name: 'list4',
            isRequired: false,
            // ignore: avoid_redundant_argument_values
            nullable: false,
          ),
          UniversalType(
            type: 'string',
            name: 'list5',
            // ignore: avoid_redundant_argument_values
            isRequired: true,
            nullable: true,
          ),
        ],
      );
      const fillController = FillController(freezed: true);
      final filledContent = await fillController.fillDtoContent(dataClass);
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
  const factory ClassName({
    required String list3,
    required String? list5,
    List<List<List<List<String>>>>? list1,
    String? list2,
    String? list4,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + moshi data class parameters nullability', () async {
      const dataClass = UniversalComponentClass(
        name: 'ClassName',
        imports: {
          'camelClass',
          'snake_class',
          'kebab-class',
          'PascalClass',
          'Space class'
        },
        parameters: [
          UniversalType(
            type: 'string',
            arrayDepth: 4,
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
            // ignore: avoid_redundant_argument_values
            isRequired: true,
            // ignore: avoid_redundant_argument_values
            nullable: false,
          ),
          UniversalType(
            type: 'string',
            name: 'list4',
            isRequired: false,
            // ignore: avoid_redundant_argument_values
            nullable: false,
          ),
          UniversalType(
            type: 'string',
            name: 'list5',
            // ignore: avoid_redundant_argument_values
            isRequired: true,
            nullable: true,
          ),
        ],
      );
      const fillController =
          FillController(programmingLanguage: ProgrammingLanguage.kotlin);
      final filledContent = await fillController.fillDtoContent(dataClass);
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
      expect(filledContent.contents, expectedContent);
    });
  });
}
