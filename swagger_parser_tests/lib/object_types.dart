/// A domain coordinate without a JSON API.
class const GeoPoint({
  /// Latitude in degrees.
  required final double latitude,

  /// Longitude in degrees.
  required final double longitude,
}) {
  /// Stores the coordinate.
  this;
}

/// A domain station identifier.
final class const StationId(
  /// Identifier value.
  final String value,
) {
  /// Stores the identifier.
  this;
}

/// A domain object with nested coordinates.
final class const Envelope(
  /// Nested value owned by this object's codec.
  final GeoPoint point,
) {
  /// Stores the coordinate.
  this;
}

/// An external tagged coordinate.
final class const TaggedCoordinate(
  /// Source tag.
  final String kind,

  /// Coordinate value.
  final GeoPoint point,
) {
  /// Stores the tag and coordinate.
  this;
}
