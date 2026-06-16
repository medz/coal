import 'package:characters/characters.dart';
import 'package:coal/src/args/_utils.dart';

import 'argv.dart';

/// Parsed CLI arguments with structured access to options and positionals.
abstract interface class Args implements Argv<Map<String, Argv>> {
  /// Parses raw CLI input into a structured argument tree.
  ///
  /// Use [defaults] to seed option values, [aliases] to map short flags to full
  /// names, and [bool]/[string]/[list] to hint the expected types.
  factory Args.parse(
    Iterable<String> input, {
    Map<String, Object?>? defaults,
    Map<String, String>? aliases,
    Iterable<String>? bool,
    Iterable<String>? string,
    Iterable<String>? list,
  }) => _parse(
    input,
    defaults: defaults,
    aliases: aliases,
    bool: bool,
    string: string,
    list: list,
  );

  /// Positional arguments that were not parsed as options.
  Iterable<String> get rest;

  /// Positional arguments with basic type coercion applied.
  Iterable<Object?> get args;

  /// Returns a JSON-friendly map representation.
  @override
  Map<String, Object> toJson();

  /// Looks up an option by name.
  Argv? at(String name);

  /// Shorthand for [at].
  Argv? operator [](String name);
}

class _ArgsImpl extends Argv<Map<String, Argv>> implements Args {
  const _ArgsImpl(super.value, [this.rest = const [], this.args = const []]);

  @override
  final Iterable<String> rest;

  @override
  final Iterable<Object?> args;

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  @override
  Argv? at(String name) => value[name];

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  @override
  Argv? operator [](String name) => at(name);

  @override
  Map<String, Object> toJson() => (super.toJson() as Map).cast();

  @override
  String toString() =>
      '\n\rcoal.Args\n\r'
      '- rest: $rest\n\r'
      '- args: $args\n\r'
      '${super.toString()}\n\r';
}

Args _parse(
  Iterable<String> input, {
  Map<String, Object?>? defaults,
  Map<String, String>? aliases,
  Iterable<String>? bool,
  Iterable<String>? string,
  Iterable<String>? list,
}) {
  final wrappedDefaults = defaults != null && defaults.isNotEmpty
      ? wrapDefaults(defaults)
      : <String, Argv>{};
  if (input.isEmpty) return _ArgsImpl(wrappedDefaults);
  final rest = <String>[],
      coerceRest = [],
      args = _ArgsImpl(wrappedDefaults, rest, coerceRest),
      length = input.length,
      types = {
        ValueType.bool: [...?bool],
        ValueType.string: [...?string],
        ValueType.list: [...?list],
      };
  String resolveAlias(String key) => aliases?[key] ?? key;

  for (int index = 0; index < length; index++) {
    final curr = input.elementAt(index),
        next = input.elementAtOrNull(index + 1);
    ValueType? type;
    String key = '';
    String? negatedKey;
    String? value;

    if (curr.length > 1 && curr.startsWith('-')) {
      if (!curr.startsWith('--') && curr.length > 2 && !curr.contains('=')) {
        if (curr.contains('.')) {
          key = resolveAlias(curr.substring(1, 2));
          type = typeof(key, types);
          value = curr.substring(2);
        } else {
          final keys = curr.substring(1, curr.length - 1);
          for (String key in keys.characters) {
            key = resolveAlias(key);
            final keyType = typeof(key, types);
            dotNestedSet(args, key, defaultValue(keyType), keyType);
          }

          key = resolveAlias(curr.substring(curr.length - 1));
          type = typeof(key, types);
          if (next != null && !next.startsWith('-') && type != ValueType.bool) {
            value = next;
            index++;
          }
        }
      } else if (!curr.contains('=') && next != null && !next.startsWith('-')) {
        key = switch (curr) {
          String curr when curr.startsWith('--') => curr.substring(2),
          String curr when curr.startsWith('-') => curr.substring(1),
          _ => curr,
        };
        if (key.length > 3 && key.startsWith('no-')) {
          negatedKey = key.substring(3);
        }
        key = resolveAlias(key);
        type = typeof(key, types);
        if (type == ValueType.bool) {
          value = 'true';
        } else {
          value = next;
          index++;
        }
      } else {
        final eq = curr.indexOf('=');
        if (eq == -1) {
          key = switch (curr) {
            String curr when curr.startsWith('--') => curr.substring(2),
            String curr when curr.startsWith('-') => curr.substring(1),
            _ => curr,
          };
        } else {
          key = switch (curr.substring(0, eq)) {
            String curr when curr.startsWith('--') => curr.substring(2),
            String curr when curr.startsWith('-') => curr.substring(1),
            _ => curr,
          };
          value = curr.substring(eq + 1);
        }
        if (key.length > 3 && key.startsWith('no-')) {
          negatedKey = key.substring(3);
        }
        key = resolveAlias(key);
        type = typeof(key, types);
      }

      if ((type == null || type == ValueType.bool) && negatedKey != null) {
        dotNestedSet(args, negatedKey, false);
      } else {
        dotNestedSet(
          args,
          key,
          coerce(value, type) ?? defaultValue(type),
          type,
        );
      }
    } else if (curr.isNotEmpty) {
      rest.add(curr);
      coerceRest.add(coerce(curr));
    }
  }

  return args;
}
