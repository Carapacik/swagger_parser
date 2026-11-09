import 'package:swagger_parser_tests/custom_types.dart';

/// Reads a StationId wire value.
StationId stationIdFromJson(String value) => StationId(value);

/// Writes a StationId wire value.
String stationIdToJson(StationId value) => value.value;

/// Reads a ExternalId wire value.
ExternalId externalIdFromJson(String value) => ExternalId(value);

/// Writes a ExternalId wire value.
String externalIdToJson(ExternalId value) => value.value;

/// Reads a CalendarDate wire value.
CalendarDate calendarDateFromJson(String value) => CalendarDate(value);

/// Writes a CalendarDate wire value.
String calendarDateToJson(CalendarDate value) => value.value;

/// Reads a Count wire value.
Count countFromJson(int value) => Count(value);

/// Writes a Count wire value.
int countToJson(Count value) => value.value;

/// Reads a Ratio wire value.
Ratio ratioFromJson(num value) => Ratio(value);

/// Writes a Ratio wire value.
num ratioToJson(Ratio value) => value.value;

/// Reads a Enabled wire value.
// ignore: avoid_positional_boolean_parameters
Enabled enabledFromJson(bool value) => Enabled(value: value);

/// Writes a Enabled wire value.
bool enabledToJson(Enabled value) => value.value;

/// Reads the prefixed identifier.
StationId wireIdFromJson(String value) => StationId(value.substring(5));

/// Writes the prefixed identifier.
String wireIdToJson(StationId value) => 'wire:${value.value}';
