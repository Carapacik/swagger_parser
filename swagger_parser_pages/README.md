# Web interface for swagger_parser

[https://carapacik.github.io/swagger_parser](https://carapacik.github.io/swagger_parser)

The application generates Dart and Kotlin clients entirely in the browser. Its
configuration form mirrors every `SWPConfig` generation option.

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Create the same WebAssembly release used by GitHub Pages:

```sh
flutter build web --wasm --release --base-href /swagger_parser/
```

Application code follows the standard Flutter package layout: `lib/main.dart`
is the bootstrap entry point and implementation details live under `lib/src/`.
