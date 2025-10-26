import '_utils.dart';

class Argv<T> {
  const Argv(this.value);

  final T value;

  R as<R>() => value as R;

  // ignore: unnecessary_this
  R? safeAs<R>() => value is R ? this.as<R>() : null;

  @override
  String toString() {
    return switch (value) {
      Iterable() || Map() => prettyJson(toJson()),
      _ => value.toString(),
    };
  }
}

extension<T> on Argv<T> {
  Object? toJson() => nestedToJson(value);

  static Object? nestedToJson(Object? value) => switch (value) {
    Iterable(:final map) => map((e) => nestedToJson(e)),
    Map(:final map) => map((k, v) => MapEntry(k, nestedToJson(v))),
    Argv(:final value) => nestedToJson(value),
    _ => value,
  };
}
