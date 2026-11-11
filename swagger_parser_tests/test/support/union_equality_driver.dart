/// Checks value equality for known oneOf wrappers and containing Freezed DTOs.
String unionEqualityDriver(String folder, {required bool freezed}) =>
    '''
import 'package:test/test.dart';
import '$folder/api.dart';

class OtherBoolean extends ScalarChoiceBoolean {
  const OtherBoolean(super.value);
}

void main() {
  test('compares scalar wrappers with the selected serializer policy', () {
    final first = UnionHolderFlagBoolean(true);
    final second = UnionHolderFlagBoolean(true);
    expect(identical(first, second), isFalse);
    expect(first == second, $freezed);
    expect(first == UnionHolderFlagBoolean(false), isFalse);
    expect(ScalarChoiceBoolean(true) == OtherBoolean(true), isFalse);
    expect(OtherBoolean(true) == ScalarChoiceBoolean(true), isFalse);
    expect(ScalarChoiceBoolean(true) == OtherChoiceBoolean(true), isFalse);
    expect(first.toJson(), isTrue);
    ${freezed ? '''
    expect(first.copyWith(value: false), UnionHolderFlagBoolean(false));
    expect(first.toString(), contains('true'));
    expect(first.hashCode, second.hashCode);
    expect(<Object>{first, second}, hasLength(1));
    expect(<Object, String>{first: 'found'}[second], 'found');
    for (final input in [true, false, 'text', 3.5]) {
      final a = ScalarChoice.fromJson(input);
      final b = ScalarChoice.fromJson(input);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(ScalarChoice.fromJson(a.toJson()), a);
    }
    expect(NullableChoice.fromJson(null), NullableChoice.fromJson(null));
    expect(NullableChoice.fromJson(null).hashCode, NullableChoice.fromJson(null).hashCode);
    expect(NullableChoice.fromJson(null), isNot(NullableChoice.fromJson('text')));
''' : ''}
  });
  ${freezed ? _freezedChecks : ''}
}
''';

const _freezedChecks = '''
  test('compares primitive and object variants inside Freezed models', () {
    final primitive = UnionHolder(flag: UnionHolderFlagBoolean(true));
    final object = UnionHolder(flag: Toggles(enabled: true));
    expect(Toggles(enabled: true), Toggles(enabled: true));
    expect(primitive, UnionHolder(flag: UnionHolderFlagBoolean(true)));
    expect(object, UnionHolder(flag: Toggles(enabled: true)));
    for (final value in [primitive, object]) {
      final decoded = UnionHolder.fromJson(value.toJson());
      expect(decoded, value);
      expect(decoded.hashCode, value.hashCode);
      expect(<UnionHolder>{value, decoded}, hasLength(1));
    }
    expect(primitive, isNot(UnionHolder(flag: UnionHolderFlagBoolean(false))));
  });
  test('compares named scalar aliases inside union wrappers', () {
    final first = NamedChoice.fromJson(true);
    final second = NamedChoice.fromJson(true);
    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(first, isNot(NamedChoice.fromJson(false)));
    expect(NamedChoice.fromJson(first.toJson()), first);
    expect(DeepCollectionEquality2('value'), DeepCollectionEquality2('value'));
  });
  test('compares nested collections by content and hashes them consistently', () {
    final first = CollectionChoice.fromJson([{'items': [1, 2]}]);
    final second = CollectionChoice.fromJson([{'items': [1, 2]}]);
    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(<Object>{first, second}, hasLength(1));
    expect(first, isNot(CollectionChoice.fromJson([{'items': [2, 1]}])));
    expect(CollectionChoice.fromJson(first.toJson()), first);
    final map = MapChoice.fromJson({'first': [1], 'second': [2]});
    final reversed = MapChoice.fromJson({'second': [2], 'first': [1]});
    expect(map, reversed);
    expect(map.hashCode, reversed.hashCode);
    expect(map, isNot(MapChoice.fromJson({'first': [1], 'second': [3]})));
    expect(MapChoice.fromJson(map.toJson()), map);
  });
''';
