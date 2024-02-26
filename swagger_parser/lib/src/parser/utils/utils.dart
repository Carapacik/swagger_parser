/// Return map[2xx] if code 2xx contains in map
Map<String, Object?>? code2xxMap(Map<String, Object?> map) {
  const codes2xx = {
    '200',
    '201',
    '202',
    '203',
    '204',
    '205',
    '206',
    '207',
    '208',
    '226',
  };
  final key = map.keys.where(codes2xx.contains).firstOrNull;
  if (key == null) {
    return null;
  }
  return map[key] as Map<String, Object?>?;
}
