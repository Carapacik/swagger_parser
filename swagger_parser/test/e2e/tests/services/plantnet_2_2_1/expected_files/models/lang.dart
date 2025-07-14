// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// i18n (default: en)
@JsonEnum()
enum Lang {
  @JsonValue('en')
  en('en'),
  @JsonValue('fr')
  fr('fr'),
  @JsonValue('es')
  es('es'),
  @JsonValue('pt')
  pt('pt'),
  @JsonValue('de')
  de('de'),
  @JsonValue('it')
  it('it'),
  @JsonValue('ar')
  ar('ar'),
  @JsonValue('cs')
  cs('cs'),
  @JsonValue('nl')
  nl('nl'),
  @JsonValue('sk')
  sk('sk'),
  @JsonValue('zh')
  zh('zh'),
  @JsonValue('ru')
  ru('ru'),
  @JsonValue('tr')
  tr('tr'),
  @JsonValue('pl')
  pl('pl'),
  @JsonValue('uk')
  uk('uk'),
  @JsonValue('he')
  he('he'),
  @JsonValue('el')
  el('el'),
  @JsonValue('fi')
  fi('fi'),
  @JsonValue('id')
  id('id'),
  @JsonValue('ms')
  ms('ms'),
  @JsonValue('ca')
  ca('ca'),
  @JsonValue('ja')
  ja('ja'),
  @JsonValue('hu')
  hu('hu'),
  @JsonValue('hr')
  hr('hr'),
  @JsonValue('da')
  da('da'),
  @JsonValue('ro')
  ro('ro'),
  @JsonValue('bg')
  bg('bg'),
  @JsonValue('nb')
  nb('nb'),
  @JsonValue('sl')
  sl('sl'),
  @JsonValue('sv')
  sv('sv'),
  @JsonValue('et')
  et('et'),
  @JsonValue('eu')
  eu('eu'),
  @JsonValue('ur')
  ur('ur'),
  @JsonValue('ml')
  ml('ml'),
  @JsonValue('cy')
  cy('cy'),
  @JsonValue('ku')
  ku('ku'),
  @JsonValue('gl')
  gl('gl'),
  @JsonValue('eo')
  eo('eo'),
  @JsonValue('sat')
  sat('sat'),
  @JsonValue('zh-tw')
  zhTw('zh-tw'),
  @JsonValue('pt-br')
  ptBr('pt-br'),
  @JsonValue('hi')
  hi('hi'),
  @JsonValue('de-at')
  deAt('de-at'),
  @JsonValue('sr')
  sr('sr'),
  @JsonValue('zh-hant')
  zhHant('zh-hant'),
  @JsonValue('bn')
  bn('bn'),
  @JsonValue('fa')
  fa('fa'),
  @JsonValue('be')
  be('be'),
  @JsonValue('oc')
  oc('oc'),
  @JsonValue('lt')
  lt('lt'),
  @JsonValue('en-au')
  enAu('en-au'),
  @JsonValue('br')
  br('br'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const Lang(this.json);

  factory Lang.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;
}
