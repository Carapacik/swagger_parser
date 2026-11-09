# Contributing to Swagger Parser

## Prepare a pull request

Open an issue before a public API or large implementation change. Bug fixes can
start with a PR. Use the issue and PR templates. Report vulnerabilities through
[SECURITY.md](SECURITY.md).

1. Fork the repository and create a branch from `main`.
2. Install Dart, OpenSSL, and Chrome. Run `dart pub get` from the repository root.
3. Keep changes focused. Add regression tests and update affected docs and changelogs.
4. Run the checks below. Explain the problem, new behavior, and validation in the PR.
5. Link related issues and check CI before requesting review.

## Write code and documentation

- Write comments, docs, test names, and generated text in English.
- Apply ASD-STE100 principles: short sentences, active voice, and consistent terms.
- Document public APIs with `///`. State defaults, units, and failure conditions when needed.
- Preserve source identifiers, descriptions, examples, and wire values.
- Use snake_case for config and normal Dart casing for Dart APIs.

Keep READMEs short. Put config variants, generated results, and option conflicts
in [CONFIGURATION.md](swagger_parser/CONFIGURATION.md). Put API usage in
[GUIDE.md](swagger_parser/GUIDE.md). Do not link public docs to local `docs/` notes.

Follow the [Flutter changelog style][changelog-style]: use present-tense verbs
(`Adds`, `Fixes`, `Removes`), final periods, and backticks for identifiers.
Mark incompatible changes with `**BREAKING CHANGE**:` and include migration steps.
Use `**BREAKING CHANGES**:` for a list. Limit lines to 100 characters.
Preserve historical versions and source examples.

[changelog-style]: https://github.com/flutter/flutter/blob/master/docs/ecosystem/contributing/README.md#changelog-style

## Add tests

- Name tests by behavior. Use real JSON and YAML files under `test/fixtures/`.
- Group related cases. Keep external refs, CLI configs, and location-sensitive errors separate.
- Use block YAML. Use `{}` and `[]` only for empty collections.
- Cover Swagger 2.0 and OpenAPI 3.0, 3.1, and 3.2 where applicable.
- Check equivalent JSON/YAML output and error cases.
- Check codec changes with plain, json_serializable, Freezed, and dart_mappable.
- Check client changes with Retrofit, Dio, and package:http.

Core and generator tests check parsing, mapping, and emitted source.
Keep fixture-to-files e2e tests in `swagger_parser`, without build_runner.
See the [e2e fixture guide](swagger_parser/test/fixtures/e2e/README.md).
`swagger_parser_tests` builds generated parts and checks VM and Chrome behavior.
Run its tests sequentially because they share build_runner.
Keep full schema matrices in core and generator tests. Consumer tests use a full
serializer/client baseline and focused feature matrices.
Review expected output. Do not commit `.g.dart`, `.freezed.dart`, `.mapper.dart`,
or temporary consumer directories.

## Run checks

From the repository root:

```sh
dart pub get
dart format .
(cd swagger_parser_tests && dart run build_runner build)
dart analyze
(cd swagger_parser_core && dart test)
(cd swagger_parser && dart test)
(cd swagger_parser_templates && dart test)
(cd swagger_parser_tests && dart test --concurrency=1)
(cd swagger_parser_pages && dart test test/editor_config_test.dart test/generation_test.dart test/template_generation_test.dart)
```

Run affected browser checks:

```sh
(cd swagger_parser_core && dart test --platform chrome)
(cd swagger_parser && dart test --platform chrome)
(cd swagger_parser_templates && dart test --platform chrome)
(cd swagger_parser_pages && dart run tool/build.dart && dart test --platform chrome test/app_test.dart)
```

Set `SWAGGER_PARSER_TEST_CHROME=false` for local VM-only consumer checks.
Use `dart format --output=none --set-exit-if-changed .` to check without edits.

CI runs on PRs and pushes to `main`. New runs cancel older runs for the same
PR or branch. Group small changes and run affected checks locally before pushing.
VM package checks use Dart 3.13.7 and stable. Format, analyze, Chrome, and generated
code use stable. Generated code builds and tests in one step, without sharding.
The separate `pages.yml` publishes the tested commit after successful main-push
Tests. Set the repository's Pages source to GitHub Actions.

## Name commits and PRs

Use `type(scope): description`, for example `fix(core): retain reference locations`.
Start the description with a lowercase verb. Omit the final period. Aim for
72 characters or fewer. Use the matching Conventional Commit type and a scope
such as `core`, `generator`, `cli`, `templates`, or `pages`.
Mark breaking changes with `!` and a `BREAKING CHANGE:` footer with migration steps.

## Contact and license

Contact carapacik@gmail.com. Contributions use the [MIT license](LICENSE).
