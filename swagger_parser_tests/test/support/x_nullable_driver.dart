String xNullableDriver(String dir) =>
    '''
import '$dir/api.dart';

void rejects(void Function() run) {
  try { run(); } catch (_) { return; }
  throw StateError('Expected rejection.');
}

void main() {
  final input = <String, Object?>{
    'name': null,
    'strict': 's',
    'absent': 'a',
    'station': null,
    'original': {'id': 'original'},
    'narrowed': {'id': 'narrowed'},
    'inherited': null,
    'list': null,
    'items': [null, 'item'],
    'choice': null,
    'closed_choice': 'north',
    'composed': {'id': 'composed'},
    'nullable_composed': null,
    'counts': {'east': null, 'west': 2},
  };
  final dto = Payload.fromJson(input);
  assert(dto.name == null && dto.station == null && dto.inherited == null);
  assert(dto.original.id == 'original' && dto.narrowed.id == 'narrowed');
  assert(dto.list == null && dto.items.first == null && dto.items.last == 'item');
  assert(dto.choice == null && dto.composed.id == 'composed');
  assert(dto.nullableComposed == null && dto.counts['east'] == null);
  assert(dto.counts['west'] == 2);
  assert(dto.label == 'North' && !dto.toJson().containsKey('note'));
  assert(dto.toJson().containsKey('name') && dto.toJson()['name'] == null);
  final explicit = Payload.fromJson({...input, 'note': null, 'label': null});
  assert(explicit.note != null && explicit.note!.value == null && explicit.label == null);
  assert(explicit.toJson().containsKey('note') && explicit.toJson()['note'] == null);
  assert(explicit.toJson().containsKey('label') && explicit.toJson()['label'] == null);
  final valued = Payload.fromJson({...input, 'name': 'Central', 'note': 'Express',
    'label': 'South', 'station': {'id':'s'}, 'inherited': {'id':'i'},
    'list': ['a'], 'choice': 'north', 'nullable_composed': {'id':'c'}});
  assert(valued.name == 'Central' && valued.note!.value == 'Express');
  assert(valued.label == 'South' && valued.station!.id == 's');
  assert(valued.inherited!.id == 'i' && valued.list!.single == 'a');
  assert(valued.nullableComposed!.id == 'c');
  for (final key in ['strict', 'absent', 'original', 'narrowed', 'items',
    'closed_choice', 'composed', 'counts', 'optional_strict']) {
    rejects(() => Payload.fromJson({...input, key: null}));
  }
  for (final key in input.keys) {
    rejects(() => Payload.fromJson({...input}..remove(key)));
  }
  rejects(() => Payload.fromJson({...input, 'list': [null]}));
  final constructed = Payload(name:null, strict:'s', absent:'a', station:null,
    original:dto.original, narrowed:dto.narrowed, inherited:null, list:null,
    items:[null], choice:null, closedChoice:dto.closedChoice,
    composed:dto.composed, nullableComposed:null, counts:dto.counts);
  assert(constructed.label == 'North' && constructed.note == null);
  assert(Payload.fromJson(constructed.toJson()).items.single == null);
}
''';
