import 'package:swagger_parser/src/generator/fill_controller.dart';
import 'package:swagger_parser/src/generator/models/programming_lang.dart';
import 'package:swagger_parser/src/generator/models/universal_data_class.dart';
import 'package:swagger_parser/src/generator/models/universal_type.dart';
import 'package:test/test.dart';

void main() {
  group('Empty data class', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalDataClass(
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
      const dataClass = UniversalDataClass(
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

@freezed
class ClassName with _$ClassName {
  const factory ClassName() = _ClassName;
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + moshi', () async {
      const dataClass = UniversalDataClass(
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
      const dataClass = UniversalDataClass(
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
      const dataClass = UniversalDataClass(
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

@freezed
class ClassName with _$ClassName {
  const factory ClassName() = _ClassName;
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    // Imports in Kotlin are not supported yet. You can always add PR
  });

  group('Parameters', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalDataClass(
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
          UniversalType(type: 'Another', name: 'anotherType'),
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
    required this.binaryStringType,
    required this.fileType,
    required this.boolType,
    required this.anotherType,
  });
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
  
  final int intType;
  final String stringType;
  final MultipartFile binaryStringType;
  final MultipartFile fileType;
  final bool boolType;
  final Another anotherType;

  Map<String, dynamic> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('dart + freezed', () async {
      const dataClass = UniversalDataClass(
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
          UniversalType(type: 'Another', name: 'anotherType'),
        ],
      );
      const fillController = FillController(freezed: true);
      final filledContent = await fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@freezed
class ClassName with _$ClassName {
  const factory ClassName({
    required int intType,
    required String stringType,
    required MultipartFile binaryStringType,
    required MultipartFile fileType,
    required bool boolType,
    required Another anotherType,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + moshi', () async {
      const dataClass = UniversalDataClass(
        name: 'ClassName',
        imports: {},
        parameters: [
          UniversalType(type: 'integer', name: 'intType'),
          UniversalType(type: 'string', name: 'stringType'),
          // UniversalType(type: 'string', format: 'binary', name: 'binaryStringType'),
          // UniversalType(type: 'file', name: 'fileType'),
          UniversalType(type: 'boolean', name: 'boolType'),
          UniversalType(type: 'Another', name: 'anotherType'),
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
    var boolType: Boolean,
    var anotherType: Another
)
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('Array type', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalDataClass(
        name: 'ClassName',
        imports: {'Another'},
        parameters: [
          UniversalType(type: 'integer', name: 'list0', arrayDepth: 1),
          UniversalType(type: 'string', name: 'list1', arrayDepth: 2),
          UniversalType(type: 'Another', name: 'list5', arrayDepth: 5),
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
      const dataClass = UniversalDataClass(
        name: 'ClassName',
        imports: {'Another'},
        parameters: [
          UniversalType(type: 'integer', name: 'list0', arrayDepth: 1),
          UniversalType(type: 'string', name: 'list1', arrayDepth: 2),
          UniversalType(type: 'Another', name: 'list5', arrayDepth: 5),
        ],
      );
      const fillController = FillController(freezed: true);
      final filledContent = await fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';
import 'another.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@freezed
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
      const dataClass = UniversalDataClass(
        name: 'ClassName',
        imports: {'Another'},
        parameters: [
          UniversalType(type: 'integer', name: 'list0', arrayDepth: 1),
          UniversalType(type: 'string', name: 'list1', arrayDepth: 2),
          UniversalType(type: 'Another', name: 'list5', arrayDepth: 5),
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
    var list5: List<List<List<List<List<Another>>>>>
)
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('JsonKey', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalDataClass(
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
          ),
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
      const dataClass = UniversalDataClass(
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
          ),
        ],
      );
      const fillController = FillController(freezed: true);
      final filledContent = await fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@freezed
class ClassName with _$ClassName {
  const factory ClassName({
    @JsonKey(name: 'int_type') required int intType,
    required String stringType,
    @JsonKey(name: 'bool-type') required bool boolType,
    @JsonKey(name: 'another') required Another anotherType,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + moshi', () async {
      const dataClass = UniversalDataClass(
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
          ),
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
    var anotherType: Another
)
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('Required parameters', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalDataClass(
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
          UniversalType(
            type: 'Another',
            name: 'another',
            isRequired: false,
          ),
          UniversalType(
            type: 'Another',
            arrayDepth: 2,
            name: 'anotherList',
            isRequired: false,
          ),
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
    this.intType,
    this.list,
    this.another,
    this.anotherList,
  });
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
  
  final int? intType;
  final List<String>? list;
  final Another? another;
  final List<List<Another>>? anotherList;

  Map<String, dynamic> toJson() => _$ClassNameToJson(this);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('dart + freezed', () async {
      const dataClass = UniversalDataClass(
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
          UniversalType(
            type: 'Another',
            name: 'another',
            isRequired: false,
          ),
          UniversalType(
            type: 'Another',
            arrayDepth: 2,
            name: 'anotherList',
            isRequired: false,
          ),
        ],
      );
      const fillController = FillController(freezed: true);
      final filledContent = await fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';
import 'another.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@freezed
class ClassName with _$ClassName {
  const factory ClassName({
    int? intType,
    List<String>? list,
    Another? another,
    List<List<Another>>? anotherList,
  }) = _ClassName;
  
  factory ClassName.fromJson(Map<String, dynamic> json) => _$ClassNameFromJson(json);
}
''';
      expect(filledContent.contents, expectedContents);
    });

    test('kotlin + moshi', () async {
      const dataClass = UniversalDataClass(
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
          UniversalType(
            type: 'Another',
            name: 'another',
            isRequired: false,
          ),
          UniversalType(
            type: 'Another',
            arrayDepth: 2,
            name: 'anotherList',
            isRequired: false,
          ),
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
    var anotherList: List<List<Another>>?
)
''';
      expect(filledContent.contents, expectedContents);
    });
  });

  group('Put required parameters first', () {
    test('dart + json_serializable', () async {
      const dataClass = UniversalDataClass(
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
          UniversalType(type: 'Another', name: 'list', arrayDepth: 1),
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
      const dataClass = UniversalDataClass(
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
          UniversalType(type: 'Another', name: 'list', arrayDepth: 1),
        ],
      );
      const fillController = FillController(freezed: true);
      final filledContent = await fillController.fillDtoContent(dataClass);
      const expectedContents = r'''
import 'package:freezed_annotation/freezed_annotation.dart';
import 'another.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@freezed
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
}
