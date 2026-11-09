import 'package:swagger_parser_tests/object_types.dart';

/// Number of coordinate decoder calls.
int pointReads = 0;

/// Number of coordinate encoder calls.
int pointWrites = 0;

/// Reads a non-null coordinate.
GeoPoint geoPointFromJson(Map<String, Object?> value) {
  pointReads++;
  return GeoPoint(
    latitude: (value['latitude']! as num).toDouble(),
    longitude: (value['longitude']! as num).toDouble(),
  );
}

/// Writes a coordinate.
Map<String, Object?> geoPointToJson(GeoPoint value) {
  pointWrites++;
  return {'latitude': value.latitude, 'longitude': value.longitude};
}

/// Reads an identifier.
StationId stationIdFromJson(String value) => StationId(value);

/// Writes an identifier.
String stationIdToJson(StationId value) => value.value;

/// Reads nested coordinates without the standalone coordinate codec.
Envelope envelopeFromJson(Map<String, Object?> value) {
  final point = value['point']! as Map<String, Object?>;
  return Envelope(
    GeoPoint(
      latitude: (point['latitude']! as num).toDouble(),
      longitude: (point['longitude']! as num).toDouble(),
    ),
  );
}

/// Writes nested coordinates without the standalone coordinate codec.
Map<String, Object?> envelopeToJson(Envelope value) => {
  'point': {
    'latitude': value.point.latitude,
    'longitude': value.point.longitude,
  },
};

/// Reads a tagged coordinate.
TaggedCoordinate taggedFromJson(Map<String, Object?> value) => TaggedCoordinate(
  value['kind']! as String,
  geoPointFromJson({
    'latitude': value['latitude'],
    'longitude': value['longitude'],
  }),
);

/// Writes a tagged coordinate.
Map<String, Object?> taggedToJson(TaggedCoordinate value) => {
  'kind': value.kind,
  ...geoPointToJson(value.point),
};
