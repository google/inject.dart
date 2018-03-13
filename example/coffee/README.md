This is an adaptation of the "Coffee"
[example from Dagger 2](https://github.com/google/dagger/tree/master/examples/simple/src/main/java/coffee).

Some features are missing or incomplete.

## To run the example

> **NOTE**: Our CLI story is a work-in-progress as work continues on the build
> system and testing package/infrastructure. For now this is a _workaround_.

```bash
$ pub run build_runner build -o build
$ cd build
$ dart bin/brew.dart
```

## To run the tests

> **NOTE**: Our test story is a work-in-progress as work continues on the build
> system and testing package/infrastructure. For now this is a _workaround_.

```bash
$ pub run build_runner build -o build
$ cd build
$ dart test/coffee_app_test.dart
```
