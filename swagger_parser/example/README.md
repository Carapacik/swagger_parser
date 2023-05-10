- ### Put your schema file from swagger and add the path to it in pubspec.yaml
- ### Set the output directory in pubspec.yaml
- ### Run command below to generate rest clients and data classes:
```shell
dart run swagger_parser:generate
```
- ### Run code generation with `build_runner` for `json_seializable`(`freezed`) and `retrofit` with command:
```shell
dart run build_runner build
```
- ### Clients and models are generated!
