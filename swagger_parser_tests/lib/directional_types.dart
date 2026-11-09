/// An outbound station.
class const CreateStation({required final String name, final String? secret}) {
  /// Creates a station request.
  this;
}

/// An inbound station.
class const Station({required final String id, required final String name}) {
  /// Creates a station response.
  this;
}

/// An outbound label.
class const DraftLabel(final String name) {
  /// Creates a label request.
  this;
}

/// A shared label.
class const Label(final String name) {
  /// Creates a label.
  this;
}

/// One type with direction-specific codecs.
class const SharedType(final String name, [final String? id]) {
  /// Creates a shared value.
  this;
}

/// Outbound preferences.
class const PreferenceDraft(final String name) {
  /// Creates request preferences.
  this;
}

/// Inbound preferences.
class const PreferenceView(final String name, [final String? id]) {
  /// Creates response preferences.
  this;
}

/// The request default.
const defaultDraft = PreferenceDraft('North');

/// The response default.
const defaultView = PreferenceView('North');
