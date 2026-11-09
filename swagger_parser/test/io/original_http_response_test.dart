@TestOn('vm')
library;

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:test/test.dart';

void main() {
  test('reads original response settings and input overrides', () async {
    const base = 'test/fixtures/original_http_response';
    for (final ext in ['json', 'yaml']) {
      expect(
        (await CliConfig.load(configPath: '$base/default.$ext'))
            .generation
            .originalHttpResponse,
        isFalse,
      );
      expect(
        (await CliConfig.load(configPath: '$base/enabled.$ext'))
            .generation
            .originalHttpResponse,
        isTrue,
      );
      final List<CliConfig> inputs = await CliConfig.loadAll(
        configPath: '$base/inputs.$ext',
      );
      expect(inputs.map((c) => c.generation.originalHttpResponse), [
        true,
        false,
      ]);
      await expectLater(
        CliConfig.load(configPath: '$base/invalid.$ext'),
        throwsA(isA<FormatException>()),
      );
    }
  });
}
