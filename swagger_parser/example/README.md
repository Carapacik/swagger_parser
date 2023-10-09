- ### Put your schema file from swagger and add the path to it in pubspec.yaml
- ### Set the output directory in pubspec.yaml
- ### Run command below to generate rest clients and data classes:
```shell
dart run swagger_parser
```
- ### For `freezed` with `retrofit` use build.yaml file with this content:
```yaml
global_options:
  freezed:
    runs_before:
      - json_serializable
  json_serializable:
    runs_before:
      - retrofit_generator
```
- ### Run code generation with `build_runner` for `json_seializable`(`freezed`) and `retrofit` with command:
```shell
dart run build_runner build
```
- ### Clients and models are generated!
