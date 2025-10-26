import 'package:characters/characters.dart';
import 'package:coal/src/args/_utils.dart';

import 'argv.dart';

abstract interface class Args implements Argv<Map<String, Argv>> {
  factory Args.parse(
    Iterable<String> argv, {
    Map<String, Object?>? defaults,
    Map<String, String>? aliases,
    Iterable<String>? bool,
    Iterable<String>? string,
    Iterable<String>? list,
  }) => _parse(
    argv,
    defaults: defaults,
    aliases: aliases,
    bool: bool,
    string: string,
    list: list,
  );

  Iterable<String> get rest;
  Iterable<Object?> get coerceRest;
}

class _ArgsImpl extends Argv<Map<String, Argv>> implements Args {
  const _ArgsImpl(
    super.value, [
    this.rest = const [],
    this.coerceRest = const [],
  ]);

  @override
  final Iterable<String> rest;

  @override
  final Iterable<Object?> coerceRest;

  @override
  String toString() =>
      '\n\rcoal.Args\n\r'
      '- rest: $rest\n\r'
      '- coerceRest: $coerceRest\n\r'
      '${super.toString()}\n\r';
}

Args _parse(
  Iterable<String> argv, {
  Map<String, Object?>? defaults,
  Map<String, String>? aliases,
  Iterable<String>? bool,
  Iterable<String>? string,
  Iterable<String>? list,
}) {
  final wrappedDefaults = defaults != null && defaults.isNotEmpty
      ? wrapDefaults(defaults)
      : <String, Argv>{};
  if (argv.isEmpty) return _ArgsImpl(wrapDefaults(wrappedDefaults));
  final rest = <String>[],
      coerceRest = [],
      args = _ArgsImpl(wrappedDefaults, rest, coerceRest),
      length = argv.length,
      types = {
        ValueType.bool: [...?bool],
        ValueType.string: [...?string],
        ValueType.list: [...?list],
      };

  for (int index = 0; index < length; index++) {
    final curr = argv.elementAt(index), next = argv.elementAtOrNull(index + 1);
    ValueType? type;
    String key = '';
    String? value;

    if (curr.length > 1 && curr.startsWith('-')) {
      if (!curr.startsWith('--') && curr.length > 2 && !curr.contains('=')) {
        if (curr.contains('.')) {
          key = curr.substring(1, 2);
          value = curr.substring(2);
        } else {
          final keys = curr.substring(1, curr.length - 1);
          for (String key in keys.characters) {
            if (aliases?[key] case String fullKey) key = fullKey;
            dotNestedSet(args, key, defaultValue(type), type);
          }

          key = curr.substring(curr.length - 1);
          if (next != null && !next.startsWith('-')) {
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
        type = typeof(key, types);
      }

      if ((type == null || type == ValueType.bool) &&
          key.length > 3 &&
          key.startsWith('no-')) {
        dotNestedSet(args, key.substring(3), false);
      } else {
        if (aliases?[key] case final String fullKey) key = fullKey;
        // dart format off
        dotNestedSet(args, key, coerce(value, type) ?? defaultValue(type), type); // dart format on
      }
    } else if (curr.isNotEmpty) {
      rest.add(curr);
      coerceRest.add(coerce(curr));
    }
  }

  return args;
}
