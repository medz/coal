import 'dart:convert';

import 'argv.dart';

final quotedRegex = RegExp(
  r'^('
  r"'"
  r'|").*\1$',
);

enum ValueType { bool, string, list }

bool isBoolean(String value) => value == 'true' || value == 'false';
bool isQuoted(String value) => value.startsWith(r'"') || value.startsWith(r"'");

void dotNestedSet<T>(
  Argv<Map<String, Argv>> argv,
  String key,
  T value, [
  ValueType? type,
]) {
  if (key.contains('.')) {
    final parts = key.split('.');
    for (final part in parts) {
      final nested = Argv(<String, Argv>{});
      dotNestedSet(argv, part, nested);
      argv = nested;
    }
    key = parts.last;
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
  if (num.tryParse(value.substring(1)) case final num value) {
    return switch (value) {
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
