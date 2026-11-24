/// An outbound station.
class const CreateStation({
  /// Station name to send in the create request.
  required final String name,

  /// Optional secret to send with the station name.
  final String? secret,
}) {
  /// Creates a station request.
  this;
}

/// An inbound station.
class const Station({
  /// Station identifier from the response.
  required final String id,

  /// Station name from the response.
  required final String name,
}) {
  /// Creates a station response.
  this;
}

/// An outbound label.
class const DraftLabel(
  /// Label text to send in the request.
  final String name,
) {
  /// Creates a label request.
  this;
}

/// A shared label.
class const Label(
  /// Label text on the wire.
  final String name,
) {
  /// Creates a label.
  this;
}

/// One type with direction-specific codecs.
class const SharedType(
  /// Name used by both request and response codecs.
  final String name, [

  /// Optional identifier used by the response codec.
  final String? id,
]) {
  /// Creates a shared value.
  this;
}

/// Outbound preferences.
class const PreferenceDraft(
  /// Preference name to send in the request.
  final String name,
) {
  /// Creates request preferences.
  this;
}

/// Inbound preferences.
class const PreferenceView(
  /// Preference name from the response.
  final String name, [

  /// Preference identifier, if present in the response.
  final String? id,
]) {
  /// Creates response preferences.
  this;
}

/// The request default.
const defaultDraft = PreferenceDraft('North');

/// The response default.
const defaultView = PreferenceView('North');
