@TestOn('vm')
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import '../support/extraction_fixtures_vm.dart';

Future<void> _runGenerated(List<GeneratedFile> files, String source) async {
  final Directory dir = await Directory.systemTemp.createTemp('swagger_json_');
  try {
    final Iterable<GeneratedFile> modelFiles = files.where(
      (f) => f.relativePath.split('/').contains('models'),
    );
    for (final model in modelFiles) {
      final target = File.fromUri(dir.uri.resolve(model.relativePath));
      await target.parent.create(recursive: true);
      await target.writeAsString(model.content);
    }
    await File.fromUri(dir.uri.resolve('models.dart')).writeAsString(
      modelFiles.map((f) => "export '${f.relativePath}';").join('\n'),
    );
    final ProcessResult analysis = await Process.run(
      Platform.resolvedExecutable,
      ['analyze', dir.path],
    );
    expect(
      analysis.exitCode,
      0,
      reason: '${analysis.stdout}\n${analysis.stderr}',
    );
    final main = File.fromUri(dir.uri.resolve('main.dart'));
    await main.writeAsString(source);
    final ProcessResult result = await Process.run(
      Platform.resolvedExecutable,
      ['--enable-asserts', main.path],
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  } finally {
    await dir.delete(recursive: true);
  }
}

Future<List<GeneratedFile>> _generatePair(String stem) async {
  Future<List<GeneratedFile>> generate(String extension) async {
    final GenerationResult result = await const SwaggerParserRunner().generate(
      await fixtureSource('$stem.$extension'),
      loader: fixtureLoader,
    );
    return result.files;
  }

  final List<GeneratedFile> json = await generate('json');
  final List<GeneratedFile> yaml = await generate('yaml');
  expect(
    {for (final f in json) f.relativePath: f.content},
    {for (final f in yaml) f.relativePath: f.content},
  );
  return json;
}

void main() {
  test('runs station DTOs from four pairs of JSON and YAML inputs', () async {
    final List<List<GeneratedFile>> families = [
      for (final name in [
        'swagger_v2',
        'open_api_v3_0',
        'open_api_v3_1',
        'open_api_v3_2',
      ])
        await _generatePair(name),
    ];
    for (final List<GeneratedFile> files in families.skip(1)) {
      expect(
        {
          for (final f in files)
            if (f.relativePath != 'api.dart') f.relativePath: f.content,
        },
        {
          for (final f in families.first)
            if (f.relativePath != 'api.dart') f.relativePath: f.content,
        },
      );
    }
    await _runGenerated(families.first, """
import 'dart:convert';
import 'models.dart';
void main() {
  const input = '{"id":"north","parent":{"id":"hub"}}';
  final station = Station.fromJson(jsonDecode(input) as Map<String, Object?>);
  assert(station.parent!.id == 'hub');
  for (final invalid in [<String, Object?>{}, {'id': null}, {'id': 42}]) {
    try {
      Station.fromJson(invalid);
      throw StateError('Expected a type error.');
    } on TypeError {}
  }
  assert(jsonEncode(station) == input);
  assert(Unused.fromJson(12).toJson() == 12);
  assert(Problem.fromJson({'detail': 'Invalid'}).detail == 'Invalid');
}
""");
  });

  test('runs nested codecs, wire names, allOf, and optional nulls', () async {
    final GenerationResult result = await const SwaggerParserRunner().generate(
      await fixtureSource('serialization.yaml'),
      config: const GenerationConfig(usePresenceRecords: true),
    );
    await _runGenerated(result.files, r"""
import 'dart:convert';
import 'models.dart';

bool rejects(void Function() read) {
  try { read(); return false; } catch (_) { return true; }
}

void main() {
  final data = <String, Object?>{
    'station-id': 1, 'station_id': 'A', 'state': 'on-line', 'reading': null,
    'children': [{'station-id': 2, 'state': 'off-line', 'reading': 5}],
    'note': null, 'unset': null, 'bool': true, 'labels': {'dock': 'west'}, r'price$': 3.2, 'future-field': 13,
  };
  final node = Node.fromJson(data);
  final encoded = jsonDecode(jsonEncode(node)) as Map<String, Object?>;
  assert(node.state == State.onLine && node.children!.single.state == State.offLine);
  assert(node.bool2 == true);
  assert(node.stationId == 1 && node.stationId2 == 'A');
  assert(encoded.length == data.length);
  for (final key in data.keys) {
    assert(jsonEncode(encoded[key]) == jsonEncode(data[key]));
  }
  data.remove('note');
  assert(!Node.fromJson(data).toJson().containsKey('note'));
  assert(rejects(() => Node.fromJson({...data, 'station_id': null})));
  assert(rejects(() => Node.fromJson({...data}..remove('reading'))));
  assert(rejects(() => Node.fromJson({...data, 'state': 'lost'})));
  assert(rejects(() => Closed.fromJson({'extra': true})));
  final readings = Readings.fromJson([{'id': 1, 'value': 1.5}]);
  assert(readings.value.single.id == 1);
  assert(jsonEncode(readings) == '[{"id":1,"value":1.5}]');
}
""");
  });

  test('generates inline request and response models in one pass', () async {
    final GenerationResult result = await const SwaggerParserRunner().generate(
      await fixtureSource('inline.json'),
    );

    await _runGenerated(result.files, """
import 'models.dart';

void main() {
  assert(PostStationsRequest.fromJson({'code': 2}).code == 2);
  assert(PostStationsResponse201Item(read: true).toJson()['read'] == true);
}
""");
  });

  test('generates a referenced schema from a second document', () async {
    final GenerationResult result = await const SwaggerParserRunner().generate(
      await fixtureSource('mounted.yaml'),
      loader: fixtureLoader,
    );
    await _runGenerated(result.files, """
import 'models.dart';
void main() {
  final station = Station.fromJson({'parent': <String, Object?>{}});
  assert(station.parent != null);
  assert(Archived.fromJson(null).toJson() == null);
}
""");
  });
  test(
    'retains Swagger 2.0 allOf fields and scalar tag restrictions',
    () async {
      final List<GeneratedFile> file = await _generatePair(
        'tagged_unions/tagged_v2',
      );
      await _runGenerated(file, """
import 'models.dart';
void main() {
  final dto = Thermal.fromJson({'kind': 'Thermal', 'station': 'A', 'degrees': 2});
  assert(dto.station == 'A' && dto.degrees == 2);
  assert(dto.toJson()['kind'] == 'Thermal');
  final base = Sample.fromJson({'kind': 'Sample', 'station': 'B'});
  assert(base is SampleValue && base.kind == 'Sample' && base.station == 'B');
  assert(Sample.fromJson(dto.toJson()) is Thermal);
  var rejected = false;
  try {
    Sample.fromJson({'kind': 'other', 'station': 'B'});
  } on FormatException {
    rejected = true;
  }
  assert(rejected);
}
""");
    },
  );
  test(
    'dispatches tagged DTOs and composes allOf fields in OpenAPI 3.0',
    () async {
      final List<GeneratedFile> file = await _generatePair(
        'tagged_unions/tagged_v3_0',
      );
      await _runGenerated(file, """
import 'models.dart';

bool rejects(void Function() read) {
  try { read(); return false; } on FormatException { return true; }
}

void main() {
  for (final tag in ['temperature', 'Thermal', 'air/backup~']) {
    final json = {'reading-kind': tag, 'station': 'A', 'degrees': 2.5};
    final reading = Reading.fromJson(json);
    assert(reading is Thermal && reading.degrees == 2.5 && reading.station == 'A');
    assert(reading.toJson()['reading-kind'] == tag);
  }
  final overlap = {'reading-kind': 'Thermal', 'station': 'B', 'degrees': 1};
  assert(Reading.fromJson(overlap) is Thermal);
  assert(ReportedReading.fromJson(overlap) is Probe);
  final Reading fresh = Thermal(station: 'B', readingKind: ThermalReadingKind.temperature, degrees: 3);
  assert(Reading.fromJson(fresh.toJson()) is Thermal);
  final source = switch (fresh) {
    Thermal(:final degrees) => degrees,
    Probe() => -1,
  };
  assert(source == 3);
  final batch = Batch.fromJson({
    'latest': {'reading-kind': 'Probe', 'station': 'C', 'readings': [fresh.toJson()]},
    'history': [fresh.toJson()],
  });
  assert((batch.latest as Probe).readings!.single is Thermal);
  assert(batch.history!.single is Thermal);
  assert(Batch.fromJson(batch.toJson()).history!.single is Thermal);
  for (final value in [null, 1, 'other']) {
    assert(rejects(() => Reading.fromJson({'reading-kind': value})));
  }
  assert(rejects(() => Reading.fromJson({})));
  try {
    Reading.fromJson({'reading-kind': 'temperature', 'station': 'A'});
    throw StateError('Expected a missing degrees field.');
  } on TypeError {}
  final payload = {'reading-kind': 'Probe', 'station': 'B'};
  assert(Probe.fromJson(payload).station == 'B');
  try {
    Recorded.fromJson(payload);
    throw StateError('Expected a missing serial field.');
  } on TypeError {}
  final recorded = Recorded.fromJson({...payload, 'serial': 7});
  assert(recorded is RecordedProbe && recorded.serial == 7);
  assert(recorded.toJson()['serial'] == 7);
}
""");
    },
  );

  test('resolves external and inline tagged variants in OpenAPI 3.1', () async {
    final List<GeneratedFile> file = await _generatePair(
      'tagged_unions/tagged_v3_1',
    );
    await _runGenerated(file, """
import 'models.dart';

void main() {
  final online = State.fromJson({'kind': 'sensor.v1', 'id': 9});
  assert(online is Sensor && online.id == 9);
  final offline = State.fromJson({'kind': 'offline', 'code': 42});
  assert(offline is StateVariant2 && offline.code == 42);
  assert(offline.toJson()['kind'] == 'offline');
  final envelope = Envelope.fromJson({'value': online.toJson()});
  assert(envelope.value is Sensor);
  assert((envelope.toJson()['value'] as Map)['kind'] == 'sensor.v1');
}
""");
  });

  test('preserves missing and unmapped default tags in OpenAPI 3.2', () async {
    final List<GeneratedFile> file = await _generatePair(
      'tagged_unions/tagged_v3_2',
    );
    await _runGenerated(file, """
import 'models.dart';

void main() {
  final start = Event.fromJson({'kind': 'begin', 'time': 17});
  assert(start is Start && start.time == 17);
  assert(start.toJson()['kind'] == 'begin');
  final missing = Event.fromJson({'version': 2});
  assert(missing is EventOther);
  assert(!missing.toJson().containsKey('kind'));
  assert(missing.toJson()['version'] == 2);
  final future = Event.fromJson({'kind': 'stop'});
  assert(future is EventOther && future.toJson()['kind'] == 'stop');
  try {
    Event.fromJson({'kind': 'begin'});
    throw StateError('Expected the selected decoder to reject a missing field.');
  } on TypeError {
    return;
  }
}
""");
  });
  test('counts structural matches and preserves anyOf input', () async {
    final List<GeneratedFile> file = await _generatePair(
      'structural_unions/structural_v3_1',
    );
    await _runGenerated(file, """
import 'models.dart';

bool rejects(void Function() decode) {
  try { decode(); return false; } on FormatException { return true; }
}

void main() {
  final id = Choice.fromJson({'id': 'n1'});
  final label = switch (id) {
    ById(:final id) => id,
    ByEmail(:final email) => email,
  };
  assert(label == 'n1');
  assert(Choice.fromJson({'email': 'a@b.co'}) is ByEmail);
  final both = <String, Object?>{'id': '42', 'email': 'a@b.co', 'extra': [1]};
  assert(rejects(() => Choice.fromJson(both)));
  assert(rejects(() => Choice.fromJson({})));
  assert(rejects(() => Contact.fromJson({'id': 'x', 'email': 'x'})));
  final contact = Contact.fromJson(both);
  assert(contact.asById!.id == '42' && contact.asByEmail!.email == 'a@b.co');
  (both['extra'] as List).add(2);
  (contact.asById!.additionalProperties['extra'] as List).add(3);
  ((contact.toJson() as Map)['extra'] as List).add(4);
  assert(((contact.toJson() as Map)['extra'] as List).length == 1);
  final single = Contact.fromJson({'email': 'a@b.co'});
  assert(!single.hasById && single.asById == null && single.hasByEmail);
  final child = ById.fromJson({'id': 'n1', 'parent': {'email': 'a@b.co'}});
  assert(child.parent is ByEmail);
  assert(Choice.fromJson(child.toJson()) is ById);
  assert(rejects(() => Contact.fromJson({'id': 'n1', 'parent': both})));
  final envelope = Envelope.fromJson({'contacts': [contact.toJson(), single.toJson()]});
  assert(envelope.contacts.first.hasById && !envelope.contacts.last.hasById);
  assert(Envelope.fromJson(envelope.toJson()).contacts.length == 2);

  assert(rejects(() => NumericChoice.fromJson(42)));
  assert(rejects(() => NumericChoice.fromJson(42.0)));
  assert(NumericChoice.fromJson(4.2) is NumericChoiceNumber);
  assert(rejects(() => NumericChoice.fromJson('42')));
  final views = NumericViews.fromJson(42.0);
  assert(views.asInteger == 42 && views.asNumber == 42.0);
  assert(views.toJson() is double && !views.hasNull);
  final empty = NumericViews.fromJson(null);
  assert(empty.hasNull && empty.toJson() == null);
  assert(State.fromJson('ready') is StateString);
  assert(State.fromJson('busy').toJson() == 'busy');
  assert(rejects(() => State.fromJson('new')));
  assert(ListChoice.fromJson([1, 2.0]) is ListChoiceArray);
  assert(ListChoice.fromJson(['a']) is ListChoiceArray2);
  assert(rejects(() => ListChoice.fromJson([])));
  assert(rejects(() => ListChoice.fromJson(['a', 1])));
  assert(PositiveOrZero.fromJson(2).toJson() == 2);
  assert(PositiveOrZero.fromJson(0).toJson() == 0);
  assert(rejects(() => PositiveOrZero.fromJson(-1)));
  final identified = Identified.fromJson({'site': 'N', 'id': 1});
  assert(identified is IdentifiedObject && identified.site == 'N' && identified.id == 1);
  assert(rejects(() => Identified.fromJson({'alias': 'a'})));
  assert(Bounded.fromJson(20).hasInteger && Bounded.fromJson(20).hasNumber);
  assert(rejects(() => Bounded.fromJson(10)));
  assert(rejects(() => Bounded.fromJson(26)));
  assert(Lookup.fromJson({'id': 1}).asObject!['id'] == 1);
  assert(Lookup.fromJson({'code': 'A'}).hasObject2);
  assert(rejects(() => Lookup.fromJson({'code': 'A', 'extra': 'x'})));
}
""");
  });

  for (final version in ['3_1', '3_2']) {
    test('selects dynamic targets in OpenAPI $version JSON and YAML', () async {
      final List<GeneratedFile> file = await _generatePair(
        'dynamic_references/dynamic_v$version',
      );
      await _runGenerated(file, """
import 'models.dart';

bool rejects(void Function() decode) {
  try { decode(); return false; } on FormatException { return true; }
}

void main() {
  final List<int> defaults = DefaultPacket.fromJson([2]).value.asArray!;
  assert(defaults.single == 2);
  final names = Names.fromJson({'next': ['A1']});
  final List<String> strings = names.value.asObject!.next.asArray!;
  assert(strings.single == 'A1');
  assert(rejects(() => Names.fromJson({'next': ['A']})));
  assert(rejects(() => DefaultPacket.fromJson(['A1'])));
  final imported = Imported.fromJson(['x1']).value.value;
  assert(imported.asArray!.single.value == 'x1');
  assert(rejects(() => Imported.fromJson(['A1'])));

  final choice = Choice.fromJson({'next': [true]}) as ChoiceNames;
  final List<bool> flags = choice.value.asObject!.next.asArray!;
  assert(flags.single);
  assert(Choice.fromJson(choice.toJson()) is ChoiceNames);
  assert(Choice.fromJson('off') is ChoiceString);
  assert(rejects(() => Choice.fromJson({'next': ['A1']})));

  final both = StaticFallback.fromJson(2);
  assert(both.hasInteger && both.hasInteger2 && !both.hasVariant3);
  assert(!StaticFallback.fromJson(1).hasInteger);
  assert(!StaticFallback.fromJson(4).hasInteger2);
  assert(rejects(() => StaticFallback.fromJson('A1')));
  final List<bool> flagsOnly = StaticFallback.fromJson([false]).asArray!;
  assert(!flagsOnly.single && rejects(() => StaticFallback.fromJson([])));
  assert(Combined.fromJson(2).hasInteger);
  assert(rejects(() => Combined.fromJson(3)));
  assert(rejects(() => Combined.fromJson(-2)));

  final tree = Tree.fromJson([['leaf']]) as TreeArray;
  assert((tree.value.single as TreeArray).value.single is TreeString);
  assert(rejects(() => Tree.fromJson([1])));
  final nested = NumberTree.fromJson([1]).asTree! as Tree2Array;
  assert(nested.value.single.asInteger == 1);
  assert(NumberTree.fromJson(nested.toJson()).hasTree);
}
""");
    });
  }

  for (final version in ['3_1', '3_2']) {
    test(
      'counts matching array items in OpenAPI $version JSON and YAML',
      () async {
        final List<GeneratedFile> file = await _generatePair(
          'array_contains/contains_v$version',
        );
        await _runGenerated(file, """
import 'models.dart';

bool rejects(void Function() decode) {
  try { decode(); return false; } on FormatException { return true; }
}

void main() {
  final alert = {'code': 'alert', 'details': {'priority': 1}};
  final other = {'code': 'alert', 'details': {'priority': 'low'}};
  final batch = Alerts.fromJson([alert, other, alert]);
  assert(batch.value.hasArray && batch.value.hasArray2);
  assert(batch.value.asArray!.length == 3);
  assert(Alerts.fromJson(batch.toJson()).value.hasArray);
  assert(!Alerts.fromJson([alert, other]).value.hasArray);
  assert(Alerts.fromJson([alert, alert, alert]).value.hasArray);
  assert(!Alerts.fromJson([alert, alert, alert, alert]).value.hasArray);
  assert(Tags.fromJson(['red', alert, 'red']).value.hasArray);
  assert(!Tags.fromJson([alert, alert]).value.hasArray);

  assert(Readings.fromJson([1]) is ReadingsArray);
  assert(Readings.fromJson([6.5, 7.5]) is ReadingsArray2);
  assert(rejects(() => Readings.fromJson([1, 6.5, 7.5])));
  assert(rejects(() => Readings.fromJson([-1])));
  assert(rejects(() => Readings.fromJson([1, 'tag'])));

  final empty = Limits.fromJson([]);
  assert(!empty.hasVariant1 && empty.hasVariant2 && empty.hasVariant3);
  assert(!empty.hasVariant4 && !empty.hasVariant5 && empty.hasVariant6);
  assert(!empty.hasVariant7);
  final hit = Limits.fromJson(['hit', 'hit']);
  assert(hit.hasVariant1 && hit.hasVariant2 && hit.hasVariant3);
  assert(!hit.hasVariant4 && !hit.hasVariant5 && !hit.hasVariant6);
  assert(hit.hasVariant7);
  final scalar = Limits.fromJson(null);
  assert(scalar.hasVariant1 && scalar.hasVariant4 && scalar.hasVariant5);

  assert(Tree.fromJson([false, ['leaf']]).hasArray);
  assert(rejects(() => Tree.fromJson([false, []])));
}
""");
      },
    );
  }

  for (final version in ['3_1', '3_2']) {
    test('runs tuple codecs from OpenAPI $version JSON and YAML', () async {
      final List<GeneratedFile> file = await _generatePair(
        'tuples/tuple_v$version',
      );
      await _runGenerated(file, """
import 'dart:convert';
import 'models.dart';

bool rejects(void Function() decode) {
  try { decode(); return false; } on FormatException { return true; }
}

void main() {
  final short = Reading.fromJson(['sensor']);
  final String name = short.item1;
  assert(name == 'sensor' && !short.hasItem2 && short.item2 == null);
  assert(short.rest.isEmpty && jsonEncode(short) == '["sensor"]');
  final full = Reading.fromJson(['sensor', null, true]);
  final List<bool> flags = full.rest;
  assert(full.hasItem2 && full.item2 == null && flags.single);
  flags.clear();
  assert(jsonEncode(full) == '["sensor",null,true]');
  final numeric = Reading.fromJson(['sensor', 2.0]);
  assert(numeric.item2 == 2 && numeric.toJson()[1] is double);
  assert(rejects(() => Reading.fromJson([])));
  assert(rejects(() => Reading.fromJson(null)));
  assert(rejects(() => Reading.fromJson([1])));
  assert(rejects(() => Reading.fromJson(['sensor', true])));
  assert(rejects(() => Reading.fromJson(['sensor', 1.5])));
  assert(rejects(() => Reading.fromJson(['sensor', 1, 'extra'])));
  assert(Pair.fromJson(['sensor', null]).item2 == null);
  assert(rejects(() => Pair.fromJson(['sensor'])));
  assert(rejects(() => Pair.fromJson(['sensor', 1, true])));
  assert(Verified.fromJson(['sensor', 2]).item2 == 2);
  assert(rejects(() => Verified.fromJson(['wrong', 2])));
  assert(rejects(() => Verified.fromJson(['sensor'])));
  assert(rejects(() => Verified.fromJson(['sensor', null, true])));

  final units = ['C'];
  final envelope = Envelope.fromJson({
    'data': [['sensor', 4], {'unit': 'C', 'aliases': units}],
  });
  units.clear();
  final dto = envelope.data.item2!;
  assert(dto.unit == 'C' && envelope.data.item1.item2 == 4);
  (dto.additionalProperties['aliases'] as List).clear();
  ((envelope.data.toJson()[1] as Map)['aliases'] as List).clear();
  assert((envelope.data.item2!.additionalProperties['aliases'] as List).single == 'C');
  assert(rejects(() => Envelope.fromJson({'data': [['sensor'], {}, false]})));
  assert(rejects(() => Envelope.fromJson({'data': [['sensor'], {'unit': 'C'}, false]})));
  assert(rejects(() => Envelope.fromJson({'data': [['sensor'], {}]})));
  final open = Loose.fromJson([null, {'key': 1}]);
  assert(open.hasItem1 && open.item1 == null && (open.rest.single as Map)['key'] == 1);
  assert(Loose.fromJson(5).toJson() == 5 && !Loose.fromJson(5).hasItem1);
  assert(Maybe.fromJson(null).toJson() == null && !Maybe.fromJson(null).hasItem1);
  assert(rejects(() => Maybe.fromJson([])));
  assert(Maybe.fromJson([true, 0]).rest.single == 0);
  assert(!Limited.fromJson([]).hasItem1 && !Limited.fromJson(['x']).hasItem2);
  assert(rejects(() => Limited.fromJson(['x', null])));

  assert((Choice.fromJson(['sensor']) as ChoiceReading).value.item1 == 'sensor');
  assert((Choice.fromJson([2]) as ChoiceArray).value.item1 == 2);
  assert(rejects(() => Choice.fromJson([2, true])));
  final views = Views.fromJson(['sensor', null, false]);
  assert(views.hasReading && views.hasArray && views.asReading!.hasItem2);
  assert(Views.fromJson(['x', 'sensor']).asArray!.rest.single == 'sensor');
  assert(!Views.fromJson(['x']).hasArray);
  assert(Node.fromJson(['a', ['b']]).item2!.item1 == 'b');
  assert(rejects(() => Node.fromJson(['a', true])));
  assert(Leaf.fromJson(['a', true]).asNode!.item2!.asBoolean!);
}
""");
    });
  }

  test('matches unique items and decimal multiples in JSON and YAML', () async {
    final List<GeneratedFile> file = await _generatePair(
      'structural_unions/structural_assertions',
    );
    await _runGenerated(file, """
import 'models.dart';

bool rejectsPrice(num value) {
  try {
    Price.fromJson(value);
    return false;
  } on FormatException {
    return true;
  }
}

void main() {
  assert(BigInt.fromJson('42').toJson() == '42');
  final first = {'id': 1, 'data': [null, false]};
  final same = {'data': [null, false], 'id': 1.0};
  final repeated = ListViews.fromJson([first, same]);
  assert(!repeated.hasArray && repeated.hasArray2);
  assert(repeated.asArray2!.length == 2);
  assert(ListViews.fromJson([]).hasArray);
  assert(ListViews.fromJson([false, 0, '0', null, 'n:0e0']).hasArray);
  assert(!ListViews.fromJson([null, null]).hasArray);
  assert(!ListViews.fromJson([0, -0.0]).hasArray);
  assert(ListViews.fromJson([[1, 2], [2, 1]]).hasArray);
  assert(ListViews.fromJson([{'a': null}, {'b': null}]).hasArray);
  assert(ListViews.fromJson([9007199254740993, 9007199254740992.0]).hasArray);

  assert(Price.fromJson(-0.3) is PriceNumber);
  assert(Price.fromJson(0.3).toJson() == 0.3);
  assert(Price.fromJson(0.25) is PriceNumber2);
  assert(rejectsPrice(0.30000000000000004));
  assert(rejectsPrice(0.5) && rejectsPrice(0));
  assert(Steps.fromJson(7.5e-7).hasNumber);
  assert(Steps.fromJson(3e100).asNumber == 3e100);
  assert(!Steps.fromJson(1e100).hasInteger);
  assert(Steps.fromJson(9007199254740993).hasInteger);
  assert(Steps.fromJson(0).hasInteger && Steps.fromJson(0).hasNumber);

  assert(Applicable.fromJson('text').hasVariant1);
  assert(Applicable.fromJson('text').hasVariant2);
  final odd = Applicable.fromJson(3);
  assert(!odd.hasVariant1 && odd.hasVariant2);
  final duplicates = Applicable.fromJson([1, 1]);
  assert(duplicates.hasVariant1 && !duplicates.hasVariant2);
}
""");
  });

  test('matches OpenAPI 3.0 nullable branches and exclusive limits', () async {
    final List<GeneratedFile> file = await _generatePair(
      'structural_unions/structural_v3_0',
    );
    await _runGenerated(file, """
import 'models.dart';
void main() {
  assert(Measurement.fromJson(6).asNumber == 6);
  assert(Measurement.fromJson(5.5).asNumber == 5.5);
  final empty = Measurement.fromJson(null);
  assert(empty.hasString && empty.asString == null && !empty.hasNumber);
  assert(empty.toJson() == null);
  for (final value in [5, 5.25]) {
    try {
      Measurement.fromJson(value);
    } on FormatException {
      continue;
    }
    throw StateError('Expected the number branch to reject the value.');
  }
}
""");
  });

  test('decodes inline OpenAPI 3.2 unions through their parent DTO', () async {
    final List<GeneratedFile> file = await _generatePair(
      'structural_unions/structural_v3_2',
    );
    await _runGenerated(file, """
import 'models.dart';
void main() {
  final dto = Readings.fromJson({'latest': 'idle', 'history': [1, 2]});
  assert(dto.latest is ReadingsLatestString);
  assert(dto.history!.asArray!.length == 2 && dto.history!.asArray2!.length == 2);
  final number = Readings.fromJson({'latest': 3, 'history': [0.5]});
  assert(number.latest is ReadingsLatestInteger);
  assert(!number.history!.hasArray && number.history!.hasArray2);
  final duplicates = Readings.fromJson({'history': [1, 1.0]});
  assert(!duplicates.history!.hasArray && duplicates.history!.hasArray2);
  assert(Readings.fromJson(number.toJson()).history!.asArray2!.single == 0.5);
}
""");
  });
}
