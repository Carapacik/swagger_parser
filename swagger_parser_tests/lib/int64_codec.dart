/// Reads an exact decimal-string integer.
BigInt readInt64(String value) => BigInt.parse(value);

/// Writes an integer as decimal digits.
String writeInt64(BigInt value) => value.toString();
