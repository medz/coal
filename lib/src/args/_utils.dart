import 'dart:convert';
import 'argv.dart';

enum ValueType { bool, string, list }

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
bool isBoolean(String value) => value == 'true' || value == 'false';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
bool isQuoted(String value) => value.startsWith(r'"') || value.startsWith(r"'");

void dotNestedSet<T>(
  Argv<Map<String, Argv>> argv,
  String key,
  T value, [
  ValueType? type,
]) {
  if (key.contains('.')) {
    final parts = key.split('.'), last = parts.last;
    for (final part in parts) {
      if (part == last) break;
      final nested = Argv(<String, Argv>{});
      dotNestedSet(argv, part, nested);
      argv = nested;
    }
    key = last;
  }

  if (type == ValueType.list && argv.value.containsKey(key)) {
    if (argv.value[key]?.value case final List list) {
      list.add(Argv(value));
    } else {
      argv.value[key] = Argv([Argv(value)]);
    }
  } else if (type == ValueType.list) {
    argv.value[key] = Argv([Argv(value)]);
  } else {
    argv.value[key] = Argv(value);
  }
}

ValueType? typeof(String key, Map<ValueType, Iterable<String>> types) {
  for (final MapEntry(key: type, :value) in types.entries) {
    if (value.contains(key)) return type;
  }

  return null;
}

dynamic defaultValue(ValueType? type) => switch (type) {
  ValueType.list => [],
  ValueType.string => '',
  _ => true,
};

Object? coerce(String? value, [ValueType? type]) {
  if (type == ValueType.string) return value;
  if (type == ValueType.bool) return value == null ? true : value == 'true';

  if (value == null || value.isEmpty) return value;
  if (value.length > 3 && isBoolean(value)) return value == 'true';
  if (value.length > 2 && isQuoted(value)) return value.unquoted;
  if ((value[0] == '.' && num.tryParse(value[1]) != null) ||
      num.tryParse(value[0]) != null) {
    return switch (num.parse(value)) {
      int value => value,
      double value => value,
    };
  }

  return value;
}

Argv wrapValue<T>(T value) {
  return switch (value) {
    Iterable(:final map) => Argv([...map(wrapValue)]),
    Map(:final map) => Argv(map((k, v) => MapEntry(k, wrapValue(v)))),
    _ => Argv(value),
  };
}

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
Map<String, Argv> wrapDefaults(Map<String, Object?> value) {
  return value.map((key, value) => MapEntry(key, wrapValue(value)));
}

JsonEncoder? _prettyJson;
String prettyJson(Object? value) {
  final json = _prettyJson ??= JsonEncoder.withIndent('  ');
  return json.convert(value);
}

extension on String {
  String get unquoted {
    if (isQuoted(this)) return substring(1).unquoted;
    if (endsWith('"') || endsWith("'")) {
      return substring(0, length - 1).unquoted;
    }
    return this;
  }
}
