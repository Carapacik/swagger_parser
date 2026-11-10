/// Exercises shared union dispatch and immutable JSON snapshots.
String unmatchedUnionsDriver(
  String folder, {
  required bool preserve,
  bool validate = false,
}) =>
    '''
import 'package:test/test.dart';
import '$folder/api.dart';

void main() {
  test('selects known branches and rejects ambiguous oneOf values', () {
    expect(Message.fromJson({'text': 'hello'}), isA<UserMessage>());
    expect(Message.fromJson({'action': 'ping'}), isA<Ping>());
    expect(() => Message.fromJson({'text': 'hi', 'action': 'ping'}), throwsFormatException);
    expect(Message.fromJson({'text': 'hi', 'action': 'pong'}), isA<UserMessage>());
    final views = Views.fromJson({'text': 'hi', 'action': 'ping'});
    expect(views.hasUserMessage, isTrue);
    expect(views.hasPing, isTrue);
    expect(views.asUserMessage!.text, 'hi');
    expect(views.asPing!.action.toJson(), 'ping');
    final one = Views.fromJson({'text': 'hi'});
    expect(one.hasUserMessage, isTrue);
    expect(one.hasPing, isFalse);
    expect(one.asPing, isNull);
  });
  test('keeps common constraints before fallback', () {
    for (final input in [null, 7, [], <String, Object?>{}, {'context': ''}, {'context': 7}, {'context': 'ok', 'server': 7}]) {
      expect(() => DirectionalMessage\$Response.fromJson(input), throwsFormatException);
      expect(() => DirectionalViews\$Response.fromJson(input), throwsFormatException);
    }
  });
  test('keeps tagged dispatch and enum checks independent', () {
    expect(() => Tagged.fromJson({'kind': 'future', 'action': 'ping'}), throwsA(anything));
    expect(() => Tagged.fromJson({'kind': 'ping', 'action': 'pong'}), throwsA(anything));
    expect(() => PingAction.fromJson('pong'), throwsA(anything));
  });
  test('propagates selected custom codec failures', () {
    expect(() => CodecMessage.fromJson('not-a-date'), throwsFormatException);
    final views = CodecViews.fromJson('not-a-date');
    expect(views.hasTimestamp, isTrue);
    expect(() => views.asTimestamp, throwsFormatException);
    expect(CodecMessage.fromJson('2026-11-11T12:30:00Z').toJson(), '2026-11-11T12:30:00Z');
  });
  test('retains matching null views', () {
    final views = NullableViews.fromJson(null);
    expect(views.hasString, isTrue);
    expect(views.asString, isNull);
    expect(views.hasInteger, isFalse);
    expect(views.toJson(), isNull);
  });
  ${preserve && validate ? r'''
  test('keeps explicit validators strict for preserved values', () {
    final unknown = Message.fromJson({'action': 'pong'});
    expect(unknown.validate().map((error) => error.keyword), contains('oneOf'));
    final views = Views.fromJson({'action': 'pong'});
    expect(views.validate().map((error) => error.keyword), contains('anyOf'));
    final projected = DirectionalViews$Response.fromJson({'context': 'ok', 'action': 'pong'});
    expect(projected.validate().map((error) => error.keyword), contains('anyOf'));
    expect(Message.fromJson({'text': 'hello'}).validate(), isEmpty);
  });
''' : ''}
  ${preserve ? _preserveChecks : _rejectChecks}
}
''';

const _rejectChecks = r'''
  test('rejects unmatched JSON with the default policy', () {
    for (final input in [null, true, 7, [], <String, Object?>{}, {'action': 'pong'}, {'action': 7}]) {
      expect(() => Message.fromJson(input), throwsFormatException);
      expect(() => Views.fromJson(input), throwsFormatException);
    }
    expect(() => History.fromJson({'messages': [{'action': 'pong'}]}), throwsA(anything));
    expect(() => History.fromJson({'messages': [], 'message': null}), throwsA(anything));
    expect(() => DirectionalMessage$Request.fromJson({'context': 'ok', 'action': 'pong'}), throwsFormatException);
    expect(() => DirectionalViews$Response.fromJson({'context': 'ok', 'action': 'pong'}), throwsFormatException);
  });
''';

const _preserveChecks = r'''
  test('preserves unmatched objects, scalars, lists, and null', () {
    for (final input in [null, true, 7, 'future', [], <String, Object?>{}, {'action': 'pong'}, {'action': 7}]) {
      final message = Message.fromJson(input);
      expect(message, isA<MessageUnknown2>());
      expect((message as MessageUnknown2).rawJson, input);
      expect(message.toJson(), input);
      final views = Views.fromJson(input);
      expect(views, isA<ViewsUnknown>());
      expect(views.hasUserMessage, isFalse);
      expect(views.hasPing, isFalse);
      expect(views.asUserMessage, isNull);
      expect(views.asPing, isNull);
      expect((views as ViewsUnknown).rawJson, input);
      expect(views.toJson(), input);
    }
    for (final input in [null, true, [], <String, Object?>{}]) {
      expect(Scalar.fromJson(input), isA<ScalarUnknown>());
      expect(ScalarViews.fromJson(input), isA<ScalarViewsUnknown>());
    }
  });
  test('round trips mixed histories and explicit null fields', () {
    final json = <String, Object?>{
      'messages': [{'text': 'hello'}, {'action': 'pong'}, {'action': 'ping'}, null],
      'views': [{'text': 'hello', 'action': 'ping'}, {'action': 'pong'}, null],
      'message': null,
      'view': null,
    };
    final history = History.fromJson(json);
    expect(history.messages[0], isA<UserMessage>());
    expect(history.messages[1], isA<HistoryMessagesItemUnknown>());
    expect(history.messages[2], isA<Ping>());
    expect(history.messages[3], isA<HistoryMessagesItemUnknown>());
    expect(history.message, isA<MessageUnknown2>());
    expect(history.view, isA<ViewsUnknown>());
    expect(history.toJson(), json);
    expect(History.fromJson({'messages': []}).toJson(), {'messages': []});
    expect(() => History.fromJson({}), throwsA(anything));
    expect(() => Envelope.fromJson({}), throwsA(anything));
    expect(Envelope.fromJson({'message': null}).toJson(), {'message': null});
  });
  test('freezes nested input and returns detached JSON copies', () {
    for (final decode in <Object? Function(Object?)>[Message.fromJson, Views.fromJson]) {
      final input = <String, Object?>{'action': 'pong', 'items': <Object?>[<String, Object?>{'x': 1}]};
      final dynamic value = decode(input);
      (input['items'] as List<Object?>).clear();
      final raw = value.rawJson as Map<String, Object?>;
      expect(raw['items'], [{'x': 1}]);
      expect(() => raw['new'] = true, throwsUnsupportedError);
      expect(() => (raw['items'] as List<Object?>).clear(), throwsUnsupportedError);
      expect(() => ((raw['items'] as List<Object?>).single as Map<String, Object?>)['x'] = 2, throwsUnsupportedError);
      final output = value.toJson() as Map<String, Object?>;
      ((output['items'] as List<Object?>).single as Map<String, Object?>)['x'] = 3;
      expect(value.toJson(), {'action': 'pong', 'items': [{'x': 1}]});
    }
    for (final input in [Object(), double.nan, double.infinity, {'value': Object()}]) {
      expect(() => Message.fromJson(input), throwsA(anything));
      expect(() => Views.fromJson(input), throwsA(anything));
    }
  });
  test('projects directional snapshots before preserving them', () {
    final input = {'context': 'ok', 'action': 'pong', 'server': 'id', 'secret': 'key'};
    final request = DirectionalMessage$Request.fromJson(input);
    expect(request, isA<DirectionalMessageRequestUnknown>());
    expect(request.toJson(), {'context': 'ok', 'action': 'pong', 'secret': 'key'});
    final response = DirectionalViews$Response.fromJson(input);
    expect(response, isA<DirectionalViewsResponseUnknown>());
    expect(response.toJson(), {'context': 'ok', 'action': 'pong', 'server': 'id'});
    expect(DirectionalMessage$Response.fromJson(input).toJson(), response.toJson());
    expect(DirectionalViews$Request.fromJson(input).toJson(), request.toJson());
    final known = {...input, 'text': 'hello'};
    expect(DirectionalViews$Response.fromJson(known).hasUserMessage, isTrue);
    expect(DirectionalViews$Response.fromJson(known).toJson(), {'context': 'ok', 'action': 'pong', 'server': 'id', 'text': 'hello'});
  });
  test('keeps nested predicates strict while nested decoders can preserve', () {
    final input = {'message': {'action': 'pong'}};
    expect(Envelope.fromJson(input).message, isA<MessageUnknown2>());
    expect(Nested.fromJson(input), isA<NestedUnknown>());
    expect(Nested.fromJson(input).toJson(), input);
    expect(Nested.fromJson({'message': {'text': 'hello'}}), isA<Envelope>());
  });
''';
