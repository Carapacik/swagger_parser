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
  ClassName();
  
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
  ClassName();
  
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
          UniversalType(type: 'file', name: 'fileType'),
          UniversalType(type: 'boolean', name: 'boolType'),
          UniversalType(type: 'object', name: 'objectType'),
          UniversalType(type: 'Another', name: 'anotherType')
        ],
      );
      const fillController = FillController();
      final filledContent = await fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:json_annotation/json_annotation.dart';

part 'class_name.g.dart';

@JsonSerializable()
class ClassName {
  ClassName({
    required this.intType,
    required this.numberType,
    required this.doubleNumberType,
    required this.floatNumberType,
    required this.stringType,
    required this.binaryStringType,
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
  final List<MultipartFile> binaryStringType;
  final List<MultipartFile> fileType;
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
          UniversalType(type: 'file', name: 'fileType'),
          UniversalType(type: 'boolean', name: 'boolType'),
          UniversalType(type: 'object', name: 'objectType'),
          UniversalType(type: 'Another', name: 'anotherType')
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
    required int intType,
    required num numberType,
    required double doubleNumberType,
    required double floatNumberType,
    required String stringType,
    required List<MultipartFile> binaryStringType,
    required List<MultipartFile> fileType,
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
          UniversalType(type: 'string', name: 'stringType'),
          UniversalType(
            type: 'string',
            format: 'binary',
            name: 'binaryStringType',
          ),
          UniversalType(type: 'file', name: 'fileType'),
          UniversalType(type: 'boolean', name: 'boolType'),
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
    var stringType: String,
    var binaryStringType: MultipartBody.Part,
    var fileType: MultipartBody.Part,
    var boolType: Boolean,
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
  ClassName({
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
  ClassName({
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
  ClassName({
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
    @JsonKey(defaultValue: 1)
    required int intType,
    @JsonKey(defaultValue: 'str')
    required String stringType,
    @JsonKey(defaultValue: false)
    required bool boolType,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + moshi', () async {
      // Default values in Kotlin are not supported yet. You can always add PR
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
  ClassName({
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
  ClassName({
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

    // In Kotlin this is optional
  });

  group('Enum', () {
    test('dart + json_serializable', () async {
      const dataClassed = [
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
      for (final enumClass in dataClassed) {
        files.add(await fillController.fillDtoContent(enumClass));
      }
      const expectedContent0 = r'''
import 'package:json_annotation/json_annotation.dart';

enum EnumName {
  value1,
  value2,
  value3;

  const EnumName();

  factory EnumName.fromJson(Map<String, dynamic> json) =>
      $enumDecode(_$EnumNameEnumMap, json);

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

enum EnumNameString {
  itemOne,
  itemTwo,
  itemThree,
  itemFour;

  const EnumNameString();

  factory EnumNameString.fromJson(Map<String, dynamic> json) =>
      $enumDecode(_$EnumNameStringEnumMap, json);

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
      const dataClassed = [
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
      for (final enumClass in dataClassed) {
        files.add(await fillController.fillDtoContent(enumClass));
      }
      const expectedContent0 = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

enum EnumName {
  value1,
  value2,
  value3;

  const EnumName();

  factory EnumName.fromJson(Map<String, dynamic> json) =>
      $enumDecode(_$EnumNameEnumMap, json);

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

enum EnumNameString {
  itemOne,
  itemTwo,
  itemThree,
  itemFour;

  const EnumNameString();

  factory EnumNameString.fromJson(Map<String, dynamic> json) =>
      $enumDecode(_$EnumNameStringEnumMap, json);

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
      // Enums in Kotlin are not supported yet. You can always add PR
    });
  });
}
