@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/default_driver.dart';
import 'support/direction_driver.dart';
import 'support/enum_names_driver.dart';
import 'support/fixed_discriminator_driver.dart';
import 'support/test_platforms.dart';
import 'support/union_titles_driver.dart';
import 'support/unknown_values_driver.dart';
import 'support/x_nullable_driver.dart';

void main() {
  test('maps tuple fixtures equally in OpenAPI 3.1 and 3.2', () async {
    const loader = FileSchemaSourceLoader();
    for (final DtoSerializer serializer in DtoSerializer.values) {
      Map<String, String>? expected;
      for (final version in ['v3_1', 'v3_2']) {
        for (final ext in ['json', 'yaml']) {
          final SchemaSource source = await loader.loadPath(
            '../swagger_parser/test/fixtures/extraction/tuples/tuple_$version.$ext',
          );
          final GenerationResult result = await const SwaggerParserRunner()
              .generate(
                source,
                config: GenerationConfig(
                  usePresenceRecords: true,
                  serializer: serializer,
                ),
              );
          expect(result.diagnostics, isEmpty);
          final Map<String, String> output = {
            for (final f in result.files)
              if (f.relativePath != 'api.dart') f.relativePath: f.content,
          };
          expected ??= output;
          expect(output, expected);
        }
      }
    }
  });

  test('builds serializers and sends PATCH with each HTTP backend', () async {
    final Directory dirRoot = await Directory('test')
        .createTemp('generated_serializers_');
    addTearDown(() => dirRoot.delete(recursive: true));
    Future<void> write(String path, String content) async {
      final file = File('${dirRoot.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
    }

    Future<void> dart(List<String> args) async {
      final watch = Stopwatch()..start();
      stdout.writeln('Start: ${args.join(' ')}');
      final ProcessResult run = await Process.run(
        Platform.resolvedExecutable,
        args,
      );
      stdout.writeln(
        '${args.join(' ')} (${watch.elapsed.inSeconds}s): '
        '${(run.stdout as String).trim().split('\n').last}',
      );
      expect(
        run.exitCode,
        0,
        reason: '${args.join(' ')}\n${run.stdout}\n${run.stderr}',
      );
    }

    await write(
      'analysis_options.yaml',
      'analyzer:\n  language:\n    strict-casts: true\n',
    );
    const loader = FileSchemaSourceLoader();
    final List<SchemaSource> sources = [
      for (final ext in ['json', 'yaml'])
        await loader.loadPath(
          'test/fixtures/dto/serializers/dto_serializers.$ext',
        ),
    ];
    final SchemaSource namingSource = await loader.loadPath(
      '../swagger_parser/test/fixtures/naming/naming_v3_2.yaml',
    );
    final SchemaSource directionSource = await loader.loadPath(
      '../swagger_parser/test/fixtures/directions/directions_v3_2.yaml',
    );
    final SchemaSource defaultSource = await loader.loadPath(
      '../swagger_parser/test/fixtures/defaults/defaults_v3_2.yaml',
    );
    final SchemaSource nullableSource = await loader.loadPath(
      '../swagger_parser/test/fixtures/x_nullable/nullable_v2_0.yaml',
    );
    final String keywords = await File(
      '../swagger_parser/test/fixtures/directions/keyword_values.json',
    ).readAsString();
    for (final DtoSerializer serializer in DtoSerializer.values) {
      for (final HttpClientBackend transport in HttpClientBackend.values) {
        final config = GenerationConfig(
          usePresenceRecords: true,
          rootApiClassName: 'TransitApi',
          serializer: serializer,
          httpClient: transport,
        );
        final dir = '${serializer.name}_${transport.name}';
        final outputs = <Map<String, String>>[];
        for (final source in sources) {
          final GenerationResult result = await const SwaggerParserRunner()
              .generate(source, config: config);
          expect(result.diagnostics, isEmpty);
          outputs.add({
            for (final file in result.files) file.relativePath: file.content,
          });
        }
        expect(outputs.first, outputs.last);
        expect(
          outputs.first.keys.where((path) => path.endsWith('/schedule.dart')),
          ['stations/models/schedule.dart'],
        );
        for (final MapEntry<String, String> file in outputs.first.entries) {
          await write('$dir/${file.key}', file.value);
        }
        await write('$dir.dart', _driver(serializer, transport, dir));
        final GenerationResult renamed = await const SwaggerParserRunner()
            .generate(
              namingSource,
              config: GenerationConfig(
                usePresenceRecords: true,
                rootApiClassName: 'TransitApi',
                fallbackClientName: 'CommonClient',
                naming: _naming,
                serializer: serializer,
                httpClient: transport,
                responseMode: ResponseMode.allStatuses,
              ),
            );
        expect(renamed.diagnostics, isEmpty);
        for (final GeneratedFile file in renamed.files) {
          await write('naming_$dir/${file.relativePath}', file.content);
        }
        await write(
          'naming_$dir.dart',
          _namingDriver(transport, 'naming_$dir'),
        );
        final GenerationResult directional = await const SwaggerParserRunner()
            .generate(
              directionSource,
              config: GenerationConfig(
                usePresenceRecords: true,
                serializer: serializer,
                httpClient: transport,
              ),
            );
        expect(directional.diagnostics, isEmpty);
        for (final GeneratedFile file in directional.files) {
          await write('directions_$dir/${file.relativePath}', file.content);
        }
        await write(
          'directions_$dir.dart',
          directionDriver(transport, 'directions_$dir', keywords),
        );
        final GenerationResult defaults = await const SwaggerParserRunner()
            .generate(
              defaultSource,
              config: GenerationConfig(
                usePresenceRecords: true,
                serializer: serializer,
                httpClient: transport,
              ),
            );
        expect(defaults.diagnostics, isEmpty);
        for (final GeneratedFile file in defaults.files) {
          await write('defaults_$dir/${file.relativePath}', file.content);
        }
        await write(
          'defaults_$dir.dart',
          defaultDriver(transport, 'defaults_$dir', serializer),
        );
        for (final version
            in transport == HttpClientBackend.dio
                ? ['2_0', '3_0', '3_1', '3_2']
                : ['3_2']) {
          final SchemaSource unknownSource = await loader.loadPath(
            '../swagger_parser/test/fixtures/unknown_values/unknown_v$version.yaml',
          );
          for (final UnknownValueMode mode
              in version == '3_2'
                  ? UnknownValueMode.values
                  : [UnknownValueMode.preserve]) {
            final GenerationResult result = await const SwaggerParserRunner()
                .generate(
                  unknownSource,
                  config: GenerationConfig(
                    usePresenceRecords: true,
                    serializer: serializer,
                    httpClient: transport,
                    unknownEnumValues: mode,
                    unknownDiscriminatorValues: mode,
                  ),
                );
            expect(result.diagnostics, isEmpty);
            final output = 'unknown_${version}_${mode.name}_$dir';
            for (final GeneratedFile file in result.files) {
              await write('$output/${file.relativePath}', file.content);
            }
            await write(
              '$output.dart',
              unknownValuesDriver(
                output,
                version,
                serializer,
                transport,
                preserve: mode == UnknownValueMode.preserve,
              ),
            );
          }
        }
        if (transport == HttpClientBackend.dio) {
          for (final version in ['3_0', '3_1', '3_2']) {
            final SchemaSource titleSource = await loader.loadPath(
              '../swagger_parser/test/fixtures/union_titles/titles_v$version.yaml',
            );
            final GenerationResult titled = await const SwaggerParserRunner()
                .generate(
                  titleSource,
                  config: GenerationConfig(
                    usePresenceRecords: true,
                    serializer: serializer,
                  ),
                );
            expect(titled.diagnostics, isEmpty);
            final titleDir = 'titles_${version}_$dir';
            for (final GeneratedFile file in titled.files) {
              await write('$titleDir/${file.relativePath}', file.content);
            }
            await write('$titleDir.dart', unionTitlesDriver(titleDir));
          }
          for (final version in ['2_0', '3_0', '3_1', '3_2']) {
            final SchemaSource fixedSource = await loader.loadPath(
              '../swagger_parser/test/fixtures/fixed_discriminators/fixed_v$version.yaml',
            );
            final GenerationResult fixed = await const SwaggerParserRunner()
                .generate(
                  fixedSource,
                  config: GenerationConfig(
                    usePresenceRecords: true,
                    serializer: serializer,
                    httpClient: transport,
                  ),
                );
            expect(fixed.diagnostics, isEmpty);
            final fixedDir = 'fixed_${version}_$dir';
            for (final GeneratedFile file in fixed.files) {
              await write('$fixedDir/${file.relativePath}', file.content);
            }
            await write(
              '$fixedDir.dart',
              fixedDiscriminatorDriver(fixedDir, version, serializer),
            );
            final SchemaSource source = await loader.loadPath(
              '../swagger_parser/test/fixtures/enum_names/names_v$version.yaml',
            );
            final GenerationResult result = await const SwaggerParserRunner()
                .generate(
                  source,
                  config: GenerationConfig(
                    usePresenceRecords: true,
                    serializer: serializer,
                    httpClient: transport,
                    naming: const NamingConfig(
                      replaceRules: [
                        NameReplacementRule(
                          target: NamingTarget.enumValues,
                          pattern: '^LEGACY_',
                          replacement: '',
                        ),
                      ],
                    ),
                  ),
                );
            expect(result.diagnostics, isEmpty);
            final output = 'enum_${version}_$dir';
            for (final GeneratedFile file in result.files) {
              await write('$output/${file.relativePath}', file.content);
            }
            await write('$output.dart', enumNamesDriver(output));
          }
          final GenerationResult nullable = await const SwaggerParserRunner()
              .generate(
                nullableSource,
                config: GenerationConfig(
                  usePresenceRecords: true,
                  serializer: serializer,
                  httpClient: transport,
                ),
              );
          for (final GeneratedFile file in nullable.files) {
            await write('nullable_$dir/${file.relativePath}', file.content);
          }
          await write('nullable_$dir.dart', xNullableDriver('nullable_$dir'));
          final GenerationResult remapped = await const SwaggerParserRunner()
              .generate(
                directionSource,
                config: GenerationConfig(
                  usePresenceRecords: true,
                  serializer: serializer,
                  httpClient: transport,
                  naming: const NamingConfig(
                    replaceRules: [
                      NameReplacementRule(
                        target: NamingTarget.models,
                        pattern: r'^Station$',
                        replacement: 'StationRequest',
                      ),
                    ],
                  ),
                ),
              );
          for (final GeneratedFile file in remapped.files) {
            await write('remapped_$dir/${file.relativePath}', file.content);
          }
          final String driver =
              directionDriver(
                transport,
                'remapped_$dir',
                keywords,
              ).replaceAllMapped(
                RegExp(r'\bStation(?:\$(?:Request|Response)|Request2?)\b'),
                (match) => switch (match[0]) {
                  r'Station$Request' => r'StationRequest$Request',
                  r'Station$Response' => r'StationRequest$Response',
                  'StationRequest' => 'StationRequest2',
                  _ => 'StationRequest3',
                },
              );
          await write('remapped_$dir.dart', driver);
        }
      }
    }
    final List<String> drivers = await dirRoot
        .list()
        .where((file) => file is File && file.path.endsWith('.dart'))
        .map((file) => file.uri.pathSegments.last)
        .toList();
    drivers.sort();
    expect(drivers, hasLength(136));
    await write(
      'checks_test.dart',
      [
        "import 'package:test/test.dart';",
        for (final (i, driver) in drivers.indexed)
          "import '$driver' as check$i;",
        'void main() {',
        '  var assertionsEnabled = false;',
        '  assert(assertionsEnabled = true);',
        "  if (!assertionsEnabled) throw StateError('Enable driver assertions.');",
        for (final (i, driver) in drivers.indexed)
          "  test('$driver', check$i.main);",
        '}',
      ].join('\n'),
    );
    await dart(['run', 'build_runner', 'build']);
    await dart(['analyze', dirRoot.path]);
    await dart(['test', '${dirRoot.path}/checks_test.dart']);
    if (runChromeTests) {
      await dart([
        'test',
        '--platform=chrome',
        '${dirRoot.path}/checks_test.dart',
      ]);
    }
  });
}

const _naming = NamingConfig(
  preserveSchemaCasing: true,
  replaceRules: [
    NameReplacementRule(
      target: NamingTarget.models,
      pattern: r'Dto$',
      replacement: '',
    ),
    NameReplacementRule(
      target: NamingTarget.models,
      pattern: r'^Aboba$',
      replacement: 'Station',
    ),
    NameReplacementRule(
      target: NamingTarget.clients,
      pattern: '^(Internal|Public)',
      replacement: '',
    ),
    NameReplacementRule(
      target: NamingTarget.methods,
      pattern: '^lookup',
      replacement: 'get',
    ),
    NameReplacementRule(
      target: NamingTarget.enumValues,
      pattern: '^status_',
      replacement: '',
    ),
  ],
);

String _namingDriver(HttpClientBackend transport, String dir) {
  final http = transport == HttpClientBackend.http;
  return '''
import 'dart:convert';
import '$dir/transit_api.dart';
${http ? "import 'package:http/http.dart';\nimport 'package:http/testing.dart';" : "import 'package:dio/dio.dart';"}

Future<void> main() async {
  const wire = {
    'station_name': 'North',
    'status': 'status_active',
    'checkpoint': {'station_code': 'N'},
  };
  final Station station = Station.fromJson(wire);
  assert(station.stationName == 'North' && station.status == Status.active);
  assert(jsonEncode(station.toJson()) == jsonEncode(wire));
  assert(Status.values2.toJson() == 'status_values');
  assert(Status.fromJson2.toJson() == 'status_fromJson');
  assert(kUserStatus.fromJson('status_active') == kUserStatus.active);
  assert(XMLHttpRequest.fromJson({'url': 'x'}).url == 'x');
  assert(XmlHttpRequest.fromJson({'url': 'y'}).url == 'y');
  final class2 keyword = class2.fromJson({'id': 'k'});
  final private hidden = private.fromJson({'id': 'p'});
  assert(keyword.id == 'k' && hidden.id == 'p');
  var code = 200;
  ${http ? """
  final client = TransitApi(MockClient((req) async {
    assert(['/stations/s', '/other'].contains(req.url.path));
    return Response(code == 204 ? '' : jsonEncode(code == 200 ? wire : {'message':'Missing'}),
      code, headers: {'content-type': 'application/json'});
  }), baseUrl: Uri.parse('https://station.test'));
""" : """
  final dio = Dio(BaseOptions(baseUrl: 'https://station.test'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (opts, handler) {
    assert(['/stations/s', '/other'].contains(opts.uri.path));
    handler.resolve(Response(requestOptions: opts, statusCode: code,
      data: code == 204 ? null : code == 200 ? wire : {'message': 'Missing'}));
  }));
  final client = TransitApi(dio);
"""}
  final CommonClient common = client.common;
  assert(identical(common, client.common));
  final StationsClient stations = client.stations;
  assert(identical(stations, client.stations));
  final other = await stations.getStationOther();
  assert(other is GetStationOther200 && other.value.stationName == 'North');
  final GetStationResult ok = await client.stations.getStation(stationId: 's');
  final message = switch (ok) {
    GetStation200(:final value) => value.stationName,
    GetStation204() => 'Empty',
    GetStation404(:final value) => value.message,
  };
  assert(message == 'North');
  code = 204;
  assert(await client.stations.getStation(stationId: 's') is GetStation204);
  code = 404;
  final missing = await client.stations.getStation(stationId: 's');
  assert(missing is GetStation404 && missing.value.message == 'Missing');
}
''';
}

String _driver(
  DtoSerializer serializer,
  HttpClientBackend transport,
  String dir,
) {
  final http = transport == HttpClientBackend.http;
  return """
import 'dart:convert';
import '$dir/transit_api.dart';
${http ? "import 'package:http/http.dart';\nimport 'package:http/testing.dart';" : "import 'package:dio/dio.dart';"}

void rejects(void Function() run) {
  try {run();} catch (_) {return;}
  throw StateError('Expected invalid input.');
}

Future<void> main() async {
  const directory = {
    'station-id': 's', 'additionalProperties': 'published', 'north': {'number': 2},
  };
  const scheduleWire = {
    'serviceDay': '2024-02-29', 'departure': '2024-03-01T00:30:45.123456+02:00',
    'attachment': 'AP8=', 'encoded': '/w==',
  };
  final schedule = Schedule.fromJson(scheduleWire);
  final DateTime departure = schedule.departure;
  assert(departure.isUtc && departure == DateTime.utc(2024, 2, 29, 22, 30, 45, 123, 456));
  const utc = '2024-02-29T22:30:45.123456Z';
  final stamp = DepartureStamp.fromJson(scheduleWire['departure']);
  assert(stamp.value.isUtc && stamp.value == departure && stamp.toJson() == utc);
  assert(schedule.serviceDay == '2024-02-29' && schedule.toJson()['departure'] == utc);
  assert(schedule.attachment == 'AP8=' && schedule.encoded == '/w==');
  rejects(() => Schedule.fromJson({...scheduleWire, 'departure': 'invalid'}));
  assert(PlatformCode.fromJson(1).toJson() == 1);
  rejects(() => PlatformCode.fromJson(3));
  rejects(() => PlatformCode.fromJson('1'));
  const wire = {'station_id':'s', 'state':'in-service', 'platforms':[{'number':2}], 'directory': directory, 'schedule': scheduleWire, 'slot': ['north', null, true]};
  final sent = <Object?>[];
  final labels = StationPatch(labels: (value: ['A']), name: (value: null));
  assert((labels.toJson()['labels'] as List).single == 'A' && labels.toJson().containsKey('name'));
  assert(StationPatch.fromJson({'labels':null}).labels!.value == null);
  assert(!StationPatch.fromJson({}).toJson().containsKey('platform'));
  assert(StationPatch.fromJson({'platform':null}).platform!.value == null);
  assert(StationPatch(platform:(value:null)).toJson().containsKey('platform'));
  rejects(() => StationPatch.fromJson({'sequence':null}));
  ${http ? """
  final client = TransitApi(MockClient((req) async {
    if (req.method == 'GET') return Response(jsonEncode(scheduleWire), 200, headers: {'content-type':'application/json'});
    if (req.method == 'PUT') {
      assert(req.url.queryParameters['since'] == utc);
      assert((jsonDecode(req.body) as List).single == utc);
      return Response(jsonEncode(scheduleWire['departure']), 200, headers: {'content-type':'application/json'});
    }
    assert(req.method == 'PATCH');
    sent.add(jsonDecode(req.body));
    return Response(jsonEncode(wire), 200, headers: {'content-type':'application/json'});
  }), baseUrl: Uri.parse('https://station.test'));
""" : """
  final dio = Dio(BaseOptions(baseUrl:'https://station.test'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (opts,handler) {
    if (opts.method == 'GET') {
      handler.resolve(Response(requestOptions: opts, data: scheduleWire, statusCode:200));
      return;
    }
    if (opts.method == 'PUT') {
      assert(opts.uri.queryParameters['since'] == utc);
      assert((jsonDecode(opts.data as String) as List).single == utc);
      handler.resolve(Response(requestOptions: opts, data: scheduleWire['departure'], statusCode: 200));
      return;
    }
    assert(opts.method == 'PATCH');
    sent.add(opts.data is String ? jsonDecode(opts.data as String) : opts.data);
    handler.resolve(Response(requestOptions: opts, data: wire, statusCode:200));
  }));
  final client = TransitApi(dio);
"""}
  final Schedule shared = await client.departures.getSchedule();
  assert(shared.departure == schedule.departure && identical(client.stations, client.stations));
  final patches = [StationPatch(), StationPatch(name:(value:null)), StationPatch(name:(value:'North'))];
  for (final patch in patches) {
    final result = await client.stations.patchStation(body:patch);
    assert(result.platforms.single.number == 2 && result.state == StationState.inService);
    assert(result.schedule!.departure == departure);
    final StationSlot slot = result.slot!;
    final List<bool> tail = slot.rest;
    assert(slot.item1 == 'north' && slot.hasItem2 && slot.item2 == null && tail.single);
    tail.clear();
    assert(jsonEncode(result.toJson()['slot']) == '["north",null,true]');
    final PlatformDirectory catalog = result.directory!;
    final Map<String, Platform> entries = catalog.additionalProperties;
    assert(catalog.stationId == 's' && catalog.additionalProperties2 == 'published');
    assert(entries.length == 1 && entries['north']!.number == 2);
    final json = catalog.toJson();
    assert((json['north'] as Map)['number'] == 2 && json.length == 3);
    assert(json['station-id'] == 's' && json['additionalProperties'] == 'published');
    final output = patch.toJson();
    assert(jsonEncode(StationPatch.fromJson(output).toJson()) == jsonEncode(output));
  }
  assert(jsonEncode(sent) == '[{},{"name":null},{"name":"North"}]');
  await client.stations.patchStation(body: StationPatch(schedule: schedule));
  final posted = (sent.last as Map)['schedule'] as Map;
  assert(posted['departure'] == utc && posted['serviceDay'] == '2024-02-29');
  assert(posted['attachment'] == 'AP8=' && posted['encoded'] == '/w==');
  final DateTime echoed = await client.departures.putDepartures(body: [departure.toLocal()], since: utc);
  assert(echoed.isUtc && echoed == departure);
  final short = StationSlot.fromJson(['north']);
  assert(!short.hasItem2 && short.item2 == null && short.rest.isEmpty);
  assert(jsonEncode(short.toJson()) == '["north"]');
  final occupied = StationSlot.fromJson(['north', 2, true, false]);
  assert(occupied.hasItem2 && occupied.item2 == 2 && occupied.rest.length == 2);
  for (final invalid in [[], [true], ['north', '2'], ['north', 1, 3]]) {
    rejects(() => StationSlot.fromJson(invalid));
  }
  final supplied = PlatformDirectory(stationId: 'real', additionalProperties: {
    'station-id': Platform(number: 9),
    'additionalProperties': Platform(number: 10),
    'east': Platform(number: 3),
  }).toJson();
  assert(supplied['station-id'] == 'real' && !supplied.containsKey('additionalProperties'));
  assert((supplied['east'] as Map)['number'] == 3);
  for (final invalid in <Object?>[null, 1, {'number': '2'}]) {
    rejects(() => PlatformDirectory.fromJson({...directory, 'north': invalid}));
  }
  assert(Stop.fromJson({'kind':'rail-stop','track':'A'}) is RailStop);
  final bus = Stop.fromJson({'kind':'bus-stop','bay':2});
  assert(bus is BusStop && bus.toJson()['kind']=='bus-stop');
  assert(Stop.fromJson({'kind':'shuttle','bay':2}).toJson()['kind']=='shuttle');
  rejects(() => Stop.fromJson({'kind':'unknown'}));
  rejects(() => Stop.fromJson({'track':'A'}));
  rejects(() => Station.fromJson({...wire,'station_id':12}));
  rejects(() => Station.fromJson({...wire,'platforms':[{'number':2.5}]}));
  rejects(() => Station.fromJson({...wire,'state':'unknown'}));
  rejects(() => ExactReading.fromJson(2));
  rejects(() => ExactReading.fromJson('2'));
  assert(ExactReading.fromJson(2.5) is ExactReadingNumber);
  final views = Reading.fromJson(2);
  assert(views.hasNumber && views.hasInteger && views.toJson()==2);
  rejects(() => Reading.fromJson('2'));
  final extra = NamedIdentity.fromJson({'id':'s','name':'n','extra':42});
  assert(extra.additionalProperties['extra']==42 && extra.toJson()['extra']==42);
  rejects(() => NamedIdentity.fromJson({'id':'s'}));
  ${serializer == DtoSerializer.dartMappable ? """
  final mapped = StationPatchMapper.fromMap({'name':null});
  assert(mapped.name != null && mapped.copyWith(name:(value:'N')).toMap()['name']=='N');
  assert(StopMapper.fromMap({'kind':'bus-stop','bay':2}) is BusStop);
  assert(StopMapper.fromMap({'kind':'shuttle','bay':2}).toJson()['kind']=='shuttle');
  rejects(() => StationMapper.fromMap({...wire,'station_id':12}));
""" : ''}
  ${serializer == DtoSerializer.freezed ? """
  final patch = StationPatch(name:(value:'N'));
  assert(!patch.copyWith(name:null).toJson().containsKey('name'));
  assert(patch.copyWith(name:(value:null)).toJson().containsKey('name'));
  final mutable = Station.fromJson(wire);
  mutable.platforms.clear();
  assert(mutable.platforms.isEmpty);
""" : ''}
}
""";
}
