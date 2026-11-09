String unionTitlesDriver(String directory) =>
    '''
import '$directory/api.dart';

void rejects(void Function() read) {
  try { read(); } catch (_) { return; }
  throw StateError('Expected rejection.');
}

void main() {
  final code = Identifier.fromJson('station-42');
  assert(code is IdentifierExternalCode && code.value == 'station-42');
  final id = Identifier.fromJson(42);
  assert(id is IdentifierInternalId && id.value == 42);
  assert(code.toJson() == 'station-42' && id.toJson() == 42);
  rejects(() => Identifier.fromJson(true));
  assert(Stop.fromJson({'platform':2}) is StopRail);
  assert(Stop.fromJson({'route':'B'}) is StopBus);
  rejects(() => Stop.fromJson({'platform':2,'route':'B'}));
  rejects(() => Stop.fromJson(<String,Object?>{}));

  final contact = Contact.fromJson({'id':'42','email':'user@example.com'});
  assert(contact.hasById && contact.hasByEmail);
  assert(contact.asById!.id == '42');
  assert(contact.asByEmail!.email == 'user@example.com');
  assert((contact.toJson() as Map)['id'] == '42');
  final single = Contact.fromJson({'email':'user@example.com'});
  assert(!single.hasById && single.asById == null && single.hasByEmail);
  rejects(() => Contact.fromJson(<String,Object?>{}));

  assert(NamedStop.fromJson({'platform':2}) is RailStop);
  assert(NamedStop.fromJson({'route':'B'}) is BusStop);
  final named = NamedContact.fromJson({'platform':2,'route':'B'});
  assert(named.hasRailStop && named.hasBusStop);
  assert(named.asRailStop!.platform == 2 && named.asBusStop!.route == 'B');

  final state = State.fromJson({'kind':'online','uptime':120});
  assert(state is StateOnline && state.uptime == 120);
  assert(state.toJson()['kind'] == 'online');
  assert(State.fromJson({'kind':'offline','delay':5}) is StateOffline);
  rejects(() => State.fromJson({'kind':'Online','uptime':120}));
  rejects(() => State.fromJson({'kind':'online'}));
  final ready = TaggedAny.fromJson({'kind':'ready','count':1});
  assert(ready is TaggedAnyReady && ready.toJson()['kind'] == 'ready');
  assert(TaggedAny.fromJson({'kind':'busy','count':2}) is TaggedAnyBusy);

  final merged = Merged.fromJson({'kind':'online','uptime':5,'trace':'request-1'});
  assert(merged is MergedOnline && merged.trace == 'request-1' && merged.uptime == 5);
  assert(merged.toJson()['trace'] == 'request-1');
  rejects(() => Merged.fromJson({'kind':'online','uptime':5}));
  final composed = Composed.fromJson({'base':'station','platform':2});
  assert(composed is ComposedRail && composed.base2 == 'station' && composed.platform == 2);
  assert(Composed.fromJson({'base':'station','route':'B'}) is ComposedBus);
  rejects(() => Composed.fromJson({'base':'station','platform':2,'route':'B'}));

  final status = Status.fromJson('on');
  assert(status is StatusEnabled && status.value.toJson() == 'on');
  assert(Status.fromJson('off') is StatusDisabled);
  rejects(() => Status.fromJson('Enabled'));
  rejects(() => Status.fromJson('other'));
  final views = StatusViews.fromJson('on');
  assert(views.hasEnabled && !views.hasDisabled);
  assert(views.asEnabled!.toJson() == 'on' && views.asDisabled == null);
  assert(views.toJson() == 'on');

  final text = Repeated.fromJson('text');
  assert(text.hasSameName && !text.hasSameName2 && text.asSameName == 'text');
  final number = Repeated.fromJson(2);
  assert(!number.hasSameName && number.hasSameName2 && number.asSameName2 == 2);
  assert(Repeated.fromJson(true).hasBoolean);
  assert(Repeated.fromJson(['text']).hasArray);
  assert(Choices.fromJson('text') is ChoicesSameName);
  assert(Choices.fromJson(2) is ChoicesSameName2);
  assert(GlobalChoice.fromJson('text') is GlobalChoiceBranch2);
  assert(Words.fromJson('text').hasClass);
  assert(Words.fromJson(2).asModel123Id == 2);
  assert(Fallback.fromJson('text') is FallbackString);
  assert(Fallback.fromJson(2) is FallbackInteger);

  final request = Directional\$Request.fromJson({'kind':'created'});
  assert(request is DirectionalCreated\$Request);
  assert(!(request.toJson() as Map).containsKey('id'));
  final response = Directional\$Response.fromJson({'kind':'created','id':7});
  assert(response is DirectionalCreated\$Response && response.id == 7);
  rejects(() => Directional\$Response.fromJson({'kind':'created'}));
}
''';
