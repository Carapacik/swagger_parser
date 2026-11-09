String enumNamesDriver(String dir) =>
    r'''
import 'IMPORT/api.dart';

void rejects(void Function() run) {
  try { run(); } catch (_) { return; }
  throw StateError('Expected rejection.');
}

void main() {
  final input = <String, Object?>{
    'status': 1,
    'mode': 'r',
    'priority': 20,
    'ignoredLabels': 'ok',
    'fallback': 0,
    'special': 'line\n"\$quote',
    'replacement': 'wire',
    'flag': true,
    'fraction': 1.5,
    'nullableChoice': null,
  };
  final dto = Envelope.fromJson(input);
  assert(dto.status == Status.active && dto.mode == Mode.running);
  assert(dto.priority == Priority.preferredHigh);
  assert(dto.ignoredLabels == IgnoredLabels.selected);
  assert(dto.fallback == Fallback.field0);
  assert(dto.special == Special.spacedName);
  assert(dto.replacement == Replacement.ready);
  assert(dto.flag == Flag.enabled && dto.fraction == Fraction.low);
  assert(dto.nullableChoice == null);
  final encoded = dto.toJson();
  assert(encoded.length == input.length);
  for (final entry in input.entries) {
    assert(encoded.containsKey(entry.key) && encoded[entry.key] == entry.value);
    if (entry.value != null) assert(encoded[entry.key].runtimeType == entry.value.runtimeType);
  }
  assert(Special.default2.toJson() == 'a');
  assert(Special.values2.toJson() == 'b');
  assert(Special.inProgress.toJson() == 'c');
  assert(Special.inProgress2.toJson() == 'd');
  assert(Special.field123start.toJson() == 'e');
  assert(NullableChoice.values.length == 2);
  assert(Envelope.fromJson({...input, 'nullableChoice':'last'}).nullableChoice == NullableChoice.last);
  assert(NullableChoice.first.toJson() == 'first');
  assert(Status.fromJson(0) == Status.pending);
  assert(Flag.fromJson(false) == Flag.disabled);
  assert(Fraction.fromJson(2.5) == Fraction.high);
  rejects(() => Status.fromJson(99));
  rejects(() => Envelope.fromJson({...input, 'status':99}));
  rejects(() => Envelope.fromJson({...input, 'mode':'unknown'}));
}
'''
        .replaceAll('IMPORT', dir);
