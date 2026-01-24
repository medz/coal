import '_utils.dart';

/// Wrapper for a parsed argument value with typed helpers.
class Argv<T> {
  const Argv(this.value);

  /// The wrapped value.
  final T value;

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  /// Casts [value] to [R].
  R as<R>() => value as R;

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  /// Casts [value] to [R] if possible, otherwise returns null.
  R? safeAs<R>() {
    // ignore: unnecessary_this
    return value is R ? this.as<R>() : null;
  }

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  /// Converts nested values into JSON-friendly types.
  Object? toJson() => nestedToJson(value);

  @override
  String toString() {
    return switch (value) {
      Iterable() || Map() => prettyJson(toJson()),
      _ => value.toString(),
    };
  }
}

extension<T> on Argv<T> {
  Object? nestedToJson(Object? value) => switch (value) {
    Iterable(:final map) => [...map((e) => nestedToJson(e))],
    Map(:final map) => map((k, v) => MapEntry(k, nestedToJson(v))),
    Argv(:final value) => nestedToJson(value),
    _ => value,
  };
}
