- ### Put your schema file from swagger and add the path to it in pubspec.yaml
- ### Set the output directory in pubspec.yaml
- ### Run command below to generate rest clients and data classes:
```shell
flutter pub run swagger_parser:generate
```
- ### Run code generation with `build_runner` for `json_seializable`(`freezed`) and `retrofit` with command:
```shell
flutter pub run build_runner build
```
- ### Clients and models are generated!
