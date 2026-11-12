import 'package:dart_mappable/dart_mappable.dart';

enum StringCode {
  padded("0007", label: "padded-sample"),
  plain("7", label: "plain-sample");

  const StringCode(String this.wireValue, {required String this.label});

  factory StringCode.fromJson(Object? json) {
    if (json is! String) {
      throw ArgumentError.value(json, "StringCode");
    }
    return values.firstWhere(
      (item) => item.wireValue == json,
      orElse: () => throw ArgumentError.value(json, "StringCode"),
    );
  }

  final String wireValue;

  final String label;

  String toJson() => wireValue;

  static StringCode? tryFromJson(Object? json) {
    if (json is! String) return null;
    for (final value in values) {
      if (value.wireValue == json) return value;
    }
    return null;
  }
}

class StringCodeMapper extends EnumMapper<StringCode> {
  StringCodeMapper._();

  static StringCodeMapper? _instance;
  static StringCodeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = StringCodeMapper._());
    }
    return _instance!;
  }

  static StringCode fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  StringCode decode(dynamic value) => StringCode.fromJson(value);

  @override
  dynamic encode(StringCode self) => self.wireValue;
}

extension StringCodeMapperExtension on StringCode {
  dynamic toValue() {
    StringCodeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<StringCode>(this);
  }
}
