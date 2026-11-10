import 'package:swagger_parser/swagger_parser.dart';

String fixedDiscriminatorDriver(
  String dir,
  String version,
  DtoSerializer serializer,
) =>
    '''
import '$dir/api.dart';

void rejects(void Function() run) {
  try { run(); } catch (_) { return; }
  throw StateError('Expected rejection.');
}

void main() {
  const typed = TypedRailStop(kind:'express');
  assert(typed.type == TypedRailStopType.rail && typed.kind == 'express');
  assert(typed.toJson().length == 2);
  assert(typed.toJson()['type'] == 'rail' && typed.toJson()['kind'] == 'express');
  final decodedTyped = TypedRailStop.fromJson({'type':'rail','kind':'bus'});
  assert(decodedTyped.kind == 'bus' && decodedTyped.type == TypedRailStopType.rail);
  assert(decodedTyped.toJson()['kind'] == 'bus');
  rejects(() => TypedRailStop.fromJson({'kind':'rail'}));
  rejects(() => TypedRailStop.fromJson({'type':'bus','kind':'rail'}));
  rejects(() => TypedRailStop.fromJson({'type':'rail'}));
  rejects(() => TypedRailStop.fromJson({'type':'rail','kind':null}));
  final typedExtras = TypedRailStop(kind:'local',additionalProperties:{'type':'bus','kind':'extra'});
  assert(typedExtras.toJson()['type'] == 'rail' && typedExtras.toJson()['kind'] == 'local');
  const rail = RailStop(platform:2);
  assert(rail.kind == RailStopKind.rail);
  assert(rail.toJson()['kind'] == 'rail');
  assert(RailStop.fromJson({'kind':'rail','platform':2}).kind == rail.kind);
  rejects(() => RailStop.fromJson({'platform':2}));
  rejects(() => RailStop.fromJson({'kind':null,'platform':2}));
  rejects(() => RailStop.fromJson({'kind':'bus','platform':2}));
  rejects(() => RailStop.fromJson({'kind':1,'platform':2}));
  final masked = RailStop(platform:2,additionalProperties:{'kind':'wrong','extra':1});
  assert(masked.toJson()['kind'] == 'rail' && masked.toJson()['extra'] == 1);
  assert(RailStop.fromJson(masked.toJson()).additionalProperties['extra'] == 1);
  assert(!RailStop.fromJson(masked.toJson()).additionalProperties.containsKey('kind'));
  const inherited = Inherited(platform:3);
  assert(inherited.toJson()['kind'] == 'inherited');
  rejects(() => Inherited.fromJson({'platform':3}));
  const wrapped = Wrapped(platform:4);
  assert(wrapped.kind.value == Kind.wrapped && wrapped.toJson()['kind'] == 'wrapped');
  assert(Wrapped.fromJson(wrapped.toJson()).kind.value == Kind.wrapped);
  const only = TagOnly();
  assert(only.toJson().length == 1 && only.toJson()['kind'] == 'only');
  assert(TagOnly.fromJson(only.toJson()).kind == only.kind);
  rejects(() => TagOnly.fromJson({}));
  const reserved = ReservedTag();
  assert(ReservedTag.fromJson(reserved.toJson()).class2 == reserved.class2);
  assert(reserved.toJson().containsKey('class'));
  const closed = Closed(platform:5);
  assert(Closed.fromJson(closed.toJson()).platform == 5);
  rejects(() => Closed.fromJson({'kind':'closed','platform':5,'extra':1}));
  const alias = AliasStop(kind:AliasStopKind.train,platform:6);
  assert(alias.toJson()['kind'] == 'train');
  assert(AliasStop.fromJson(alias.toJson()).kind == AliasStopKind.train);
  const optional = OptionalStop(platform:7);
  assert(!optional.toJson().containsKey('kind'));
  assert(OptionalStop.fromJson({'platform':7}).kind == null);
  const unmarked = Unmarked(kind:UnmarkedKind.unmarked,platform:8);
  assert(unmarked.toJson()['kind'] == 'unmarked');
  const loose = LooseStop(kind:'anything',platform:9);
  assert(loose.kind == 'anything');
  const nullable = NullableStop(kind:null,platform:10);
  assert(nullable.toJson().containsKey('kind') && nullable.toJson()['kind'] == null);
  final envelope = Envelope.fromJson({});
  assert(envelope.stop.platform == 4 && envelope.stop.kind == RailStopKind.rail);
  assert((envelope.toJson()['stop'] as Map)['kind'] == 'rail');
  ${version == '2_0' ? '' : '''
  final typedUnion = TypedStop.fromJson({'type':'rail','kind':'bus'});
  assert(typedUnion is TypedRailStop && typedUnion.kind == 'bus');
  final busUnion = TypedStop.fromJson({'type':'bus','kind':'rail'});
  assert(busUnion is TypedBusStop && busUnion.kind == 'rail');
  final stop = Stop.fromJson({'kind':'rail','platform':2});
  assert(stop is RailStop && stop.platform == 2);
  assert(Stop.fromJson({'kind':'bus','platform':2}) is BusStop);
  rejects(() => Stop.fromJson({'platform':2}));
  rejects(() => Stop.fromJson({'kind':'unknown','platform':2}));
  for (final tag in ['rail','train']) {
    final result = Aliases.fromJson({'kind':tag,'platform':6});
    assert(result is AliasStop && result.toJson()['kind'] == tag);
  }
  assert(AnyStop.fromJson({'kind':'inherited','platform':3}) is Inherited);
  assert(AnyStop.fromJson({'kind':'wrapped','platform':4}) is Wrapped);
  ${serializer == DtoSerializer.freezed ? "const factory = Stop.asRailStop(platform:11); assert(factory.toJson()['kind']=='rail');" : ''}
'''}
  ${serializer == DtoSerializer.freezed || serializer == DtoSerializer.dartMappable ? '''
  final changedKind = typed.copyWith(kind:'local');
  assert(changedKind.kind == 'local' && changedKind.type == TypedRailStopType.rail);
  assert(changedKind.toJson()['type'] == 'rail' && changedKind.toJson()['kind'] == 'local');
  rejects(() => (typed as dynamic).copyWith(type: TypedRailStopType.rail));
  final changed = rail.copyWith(platform:12);
  assert(changed.platform == 12 && changed.kind == RailStopKind.rail);
  rejects(() => (rail as dynamic).copyWith(kind: RailStopKind.rail));
''' : ''}
}
''';
