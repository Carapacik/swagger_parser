import 'dart:async';

/// Date-time text with its source offset and decoder context.
final class const OffsetTimestamp(
  /// Original date-time text.
  final String value,

  /// Zone marker used to verify worker execution.
  final String context,
) {
  /// Stores validated date-time text.
  this;
}

/// Validates date-time text without changing its offset.
OffsetTimestamp readOffsetTimestamp(String value) {
  DateTime.parse(value);
  return OffsetTimestamp(
    value,
    Zone.current[#decoderMarker] as String? ?? 'worker',
  );
}

/// Writes the original date-time text.
String writeOffsetTimestamp(OffsetTimestamp value) => value.value;
