part of 'dart_model_mapper.dart';

extension on _Mapping {
  void _applyUnknownValues() {
    String allocate(String hint) => _identifier(
      hint,
      usedNames,
      type: true,
      preserveCase: true,
      suffixes: _typeSuffixes,
    );
    if (config.unknownEnumValues == UnknownValueMode.preserve) {
      for (var i = 0; i < enums.length; i++) {
        final DartEnumModel model = enums[i];
        final String rawType = switch (model.types.toList()) {
          ['string'] => 'String',
          ['integer'] => 'int',
          ['number'] => 'num',
          ['boolean'] => 'bool',
          _ => 'Object',
        };
        enums[i] = DartEnumModel(
          model.name,
          model.values,
          types: model.types,
          openNames: DartOpenEnumNames(
            allocate('${model.name}Value'),
            allocate('${model.name}Known'),
            allocate('${model.name}Unknown'),
            rawType,
          ),
        );
      }
    }
    if (config.unknownDiscriminatorValues == UnknownValueMode.preserve) {
      for (var i = 0; i < unions.length; i++) {
        final DartUnionModel model = unions[i];
        unions[i] = DartUnionModel(
          model.name,
          model.propertyName,
          model.mapping,
          defaultType: model.defaultType,
          unknownType: allocate('${model.name}Unknown'),
        );
      }
    }
  }
}
