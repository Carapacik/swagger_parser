import 'package:swagger_parser/src/generator/fill_controller.dart';
import 'package:swagger_parser/src/generator/models/programming_lang.dart';
import 'package:swagger_parser/src/generator/models/universal_data_class.dart';
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
}
