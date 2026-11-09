import 'package:swagger_parser_tests/directional_types.dart';

/// Reads a request object.
CreateStation createStationFromJson(Map<String, Object?> json) => CreateStation(
  name: json['name']! as String,
  secret: json['secret'] as String?,
);

/// Writes a request object.
Map<String, Object?> createStationToJson(CreateStation value) => {
  'name': value.name,
  if (value.secret != null) 'secret': value.secret,
};

/// Reads a Swagger request object.
CreateStation createStationV2FromJson(Map<String, Object?> json) =>
    CreateStation(name: json['name']! as String);

/// Writes a Swagger request object.
Map<String, Object?> createStationV2ToJson(CreateStation value) => {
  'name': value.name,
};

/// Reads a response object.
Station stationFromJson(Map<String, Object?> json) =>
    Station(id: json['id']! as String, name: json['name']! as String);

/// Writes a response object.
Map<String, Object?> stationToJson(Station value) => {
  'id': value.id,
  'name': value.name,
};

/// Reads a request label.
DraftLabel draftLabelFromJson(Map<String, Object?> json) =>
    DraftLabel(json['name']! as String);

/// Writes a request label.
Map<String, Object?> draftLabelToJson(DraftLabel value) => {'name': value.name};

/// Reads a shared label.
Label labelFromJson(Map<String, Object?> json) =>
    Label(json['name']! as String);

/// Writes a shared label.
Map<String, Object?> labelToJson(Label value) => {'name': value.name};

/// Reads the shared request type.
SharedType sharedRequestFromJson(Map<String, Object?> json) =>
    SharedType(json['name']! as String);

/// Writes the shared request type.
Map<String, Object?> sharedRequestToJson(SharedType value) => {
  'name': value.name,
};

/// Reads the shared response type.
SharedType sharedResponseFromJson(Map<String, Object?> json) =>
    SharedType(json['name']! as String, json['id'] as String?);

/// Writes the shared response type.
Map<String, Object?> sharedResponseToJson(SharedType value) => {
  'name': value.name,
  if (value.id != null) 'id': value.id,
};

/// Reads request preferences.
PreferenceDraft preferenceDraftFromJson(Map<String, Object?> json) =>
    PreferenceDraft(json['name']! as String);

/// Writes request preferences.
Map<String, Object?> preferenceDraftToJson(PreferenceDraft value) => {
  'name': value.name,
};

/// Reads response preferences.
PreferenceView preferenceViewFromJson(Map<String, Object?> json) =>
    PreferenceView(json['name']! as String, json['id'] as String?);

/// Writes response preferences.
Map<String, Object?> preferenceViewToJson(PreferenceView value) => {
  'name': value.name,
  if (value.id != null) 'id': value.id,
};

/// Reads a request identifier.
DraftLabel draftIdFromJson(String value) => DraftLabel(value);

/// Writes a request identifier.
String draftIdToJson(DraftLabel value) => value.name;

/// Reads a response identifier.
Label labelIdFromJson(String value) => Label(value);

/// Writes a response identifier.
String labelIdToJson(Label value) => value.name;
