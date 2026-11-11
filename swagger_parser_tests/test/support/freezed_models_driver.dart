/// Checks Freezed models with custom codecs and protected JSON snapshots.
String freezedModelsDriver(String folder) =>
    '''
import 'package:test/test.dart';
import '$folder/api.dart';

void main() {
  void sameValue(Object first, Object second) {
    expect(identical(first, second), isFalse);
    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(<Object>{first, second}, hasLength(1));
    expect(<Object, String>{first: 'found'}[second], 'found');
  }

  test('compares validated tuples without exposing their stored list', () {
    final input = <Object?>[1, 'value'];
    final first = Position.fromJson(input);
    sameValue(first, Position.fromJson([1, 'value']));
    expect(first, isNot(Position.fromJson([2, 'value'])));
    expect(Position.fromJson([1]), isNot(first));
    input[0] = 2;
    first.toJson()[0] = 3;
    expect(first.item1, 1);
    expect(first.item2, 'value');
    expect(first.toString(), contains('Position'));
    expect(Position.fromJson(first.toJson()), first);
    expect(() => Position.fromJson(['wrong']), throwsFormatException);
    expect(() => Position.fromJson([1, 'value', true]), throwsFormatException);
  });

  test('compares anyOf snapshots and keeps all matching views', () {
    final input = <String, Object?>{'title': 'name', 'count': 1};
    final first = Views.fromJson(input);
    sameValue(first, Views.fromJson({'count': 1, 'title': 'name'}));
    expect(first, isNot(Views.fromJson({'title': 'other', 'count': 1})));
    expect(first.hasObject, isTrue);
    expect(first.hasObject2, isTrue);
    expect(first.asObject!.title, 'name');
    expect(first.asObject2!.count, 1);
    input['title'] = 'changed';
    (first.toJson() as Map<String, Object?>)['title'] = 'changed';
    expect(first.asObject!.title, 'name');
    expect(Views.fromJson(first.toJson()), first);
  });

  test('compares unknown union values by immutable JSON content', () {
    for (final input in [null, 'future', 3, <Object?>['future'], <String, Object?>{'future': [1, 2]}]) {
      final choice = Choice.fromJson(input);
      final views = Views.fromJson(input);
      expect(choice, isA<ChoiceUnknown>());
      expect(views, isA<ViewsUnknown>());
      sameValue(choice, Choice.fromJson(input));
      sameValue(views, Views.fromJson(input));
      expect(choice, isNot(Choice.fromJson(false)));
      expect(views, isNot(Views.fromJson({'title': 'known'})));
      expect(Choice.fromJson(choice.toJson()), choice);
      expect(Views.fromJson(views.toJson()), views);
    }
    expect(ChoiceUnknown({'future': 1}), isNot(ChoiceUnknown({'future': 2})));
    expect(ViewsUnknown({'future': 1}), isNot(ViewsUnknown({'future': 2})));
    final input = <String, Object?>{'future': <Object?>[1]};
    final first = ViewsUnknown(input);
    (input['future'] as List<Object?>).add(2);
    expect(first.rawJson, {'future': [1]});
    expect(() => ((first.rawJson as Map<String, Object?>)['future'] as List<Object?>).add(3), throwsUnsupportedError);
    (first.toJson() as Map<String, Object?>)['future'] = [];
    expect(first.rawJson, {'future': [1]});
  });

  test('compares known and unknown tags and enum values with Freezed', () {
    sameValue(Tagged.fromJson({'kind': 'cat', 'name': 'name'}), Tagged.fromJson({'kind': 'cat', 'name': 'name'}));
    final input = <String, Object?>{'kind': 'future', 'data': <Object?>[1]};
    final first = Tagged.fromJson(input) as TaggedUnknown;
    sameValue(first, Tagged.fromJson({'data': [1], 'kind': 'future'}));
    expect(first, isNot(Tagged.fromJson({'data': [2], 'kind': 'future'})));
    (input['data'] as List<Object?>).add(2);
    expect(first.rawJson['data'], [1]);
    expect(() => (first.rawJson['data'] as List<Object?>).add(3), throwsUnsupportedError);
    expect(() => Tagged.fromJson({'kind': 1}), throwsArgumentError);
    sameValue(StatusKnown(StatusValue.active), StatusKnown(StatusValue.active));
    sameValue(StatusUnknown('future'), StatusUnknown('future'));
    expect(StatusUnknown('future'), isNot(StatusUnknown('other')));
    expect(StatusUnknown('active'), isNot(StatusKnown(StatusValue.active)));
    expect(StatusUnknown('future').copyWith(rawValue: 'other'), StatusUnknown('other'));
    expect(StatusKnown(StatusValue.active).copyWith(value: StatusValue.inactive), Status.inactive);
    expect(Status.fromJson('future').toJson(), 'future');
  });

  test('compares model graphs and typed HTTP results', () {
    final json = <String, Object?>{
      'tuple': [1, 'value'], 'choice': [1, 2],
      'views': {'title': 'name'}, 'tagged': {'kind': 'future', 'data': [1]},
      'status': 'future',
    };
    final first = Envelope.fromJson(json);
    final second = Envelope.fromJson(first.toJson());
    sameValue(first, second);
    sameValue(ReadModels200(first), ReadModels200(second));
    sameValue(ReadModels204(), ReadModels204());
    sameValue(ReadModelsDefault(500, 'error'), ReadModelsDefault(500, 'error'));
    expect(ReadModelsDefault(500, 'error'), isNot(ReadModelsDefault(501, 'error')));
    expect(ReadModelsDefault(500, 'error'), isNot(ReadModelsDefault(500, 'other')));
    expect(ReadModelsDefault(500, 'error').copyWith(statusCode: 501), ReadModelsDefault(501, 'error'));
    expect(ReadModels200(first).copyWith(value: Envelope()), ReadModels200(Envelope()));
  });
}
''';
