import 'dart:async';
import 'dart:convert';

typedef KeyBindingHandler = void Function(KeyEvent event);
typedef KeyEventDecoder = KeyEvent Function(String sequence);

/// Normalizes a user-provided key binding to canonical form.
///
/// Canonical bindings use the following modifier order:
/// `ctrl`, `meta`, `shift`, followed by a key token.
///
/// Example:
/// - `Shift + Ctrl + A` -> `ctrl+shift+a`
String normalizeKeyBinding(String binding) {
  final source = binding.trim();
  if (source.isEmpty) throw FormatException('Key binding cannot be empty.');

  bool ctrl = false, meta = false, shift = false;
  String? key;

  for (final rawPart in source.split('+')) {
    final part = rawPart.trim();
    if (part.isEmpty) continue;

    final lower = part.toLowerCase();
    switch (lower) {
      case 'ctrl':
      case 'control':
      case 'ctl':
        ctrl = true;
      case 'meta':
      case 'alt':
      case 'option':
      case 'command':
      case 'cmd':
        meta = true;
      case 'shift':
        shift = true;
      default:
        if (key != null) {
          throw FormatException(
            'Key binding must contain exactly one key token.',
          );
        }

        key = _normalizeKeyToken(lower);
        if (part.length == 1 && _isAsciiUpper(part.codeUnitAt(0))) {
          shift = true;
          key = key.toLowerCase();
        }
    }
  }

  if (key == null || key.isEmpty) {
    throw FormatException('Key binding must contain a key token.');
  }

  return _composeBinding(key: key, ctrl: ctrl, meta: meta, shift: shift);
}

/// A normalized key event used by [Keypass] dispatch.
class KeyEvent {
  KeyEvent({
    required this.sequence,
    required this.key,
    this.ctrl = false,
    this.meta = false,
    this.shift = false,
  });

  factory KeyEvent.fromSequence(String sequence) {
    final source = sequence;
    if (source.isEmpty) throw FormatException('Key sequence cannot be empty.');

    if (_simpleSequenceMap[source] case final decoded?) {
      return decoded.toEvent(source);
    }

    final csiDecoded = _decodeCsi(source);
    if (csiDecoded != null) return csiDecoded.toEvent(source);

    final ss3Decoded = _decodeSs3(source);
    if (ss3Decoded != null) return ss3Decoded.toEvent(source);

    if (source.startsWith('\u001b') && source.length > 1) {
      final nested = KeyEvent.fromSequence(source.substring(1));
      return KeyEvent(
        sequence: source,
        key: nested.key,
        ctrl: nested.ctrl,
        meta: true,
        shift: nested.shift,
      );
    }

    final runes = source.runes;
    if (runes.length != 1) {
      throw FormatException('Unsupported key sequence: $source');
    }

    final code = runes.first;
    if (code >= 1 && code <= 26) {
      return KeyEvent(
        sequence: source,
        key: String.fromCharCode(code + 96),
        ctrl: true,
      );
    }

    if (code == 0) {
      return KeyEvent(sequence: source, key: 'space', ctrl: true);
    }

    final char = String.fromCharCode(code);
    if (char == ' ') return KeyEvent(sequence: source, key: 'space');

    final shift = char.length == 1 && _isAsciiUpper(char.codeUnitAt(0));
    return KeyEvent(
      sequence: source,
      key: shift ? char.toLowerCase() : char,
      shift: shift,
    );
  }

  final String sequence;
  final String key;
  final bool ctrl;
  final bool meta;
  final bool shift;

  /// Canonical binding string used for handler matching.
  String get binding =>
      _composeBinding(key: key, ctrl: ctrl, meta: meta, shift: shift);

  bool matches(String pattern) => normalizeKeyBinding(pattern) == binding;

  @override
  String toString() => 'KeyEvent(binding: $binding, sequence: $sequence)';
}

/// Key binding dispatcher for terminal key sequences.
class Keypass {
  Keypass({KeyEventDecoder? decoder})
    : _decoder = decoder ?? KeyEvent.fromSequence;

  final KeyEventDecoder _decoder;
  final Map<String, List<KeyBindingHandler>> _bindings = {};

  int get bindingCount =>
      _bindings.values.fold(0, (count, handlers) => count + handlers.length);

  void bind(
    String keyBinding,
    KeyBindingHandler handler, {
    bool replace = false,
  }) {
    final normalized = normalizeKeyBinding(keyBinding);
    final handlers = _bindings.putIfAbsent(
      normalized,
      () => <KeyBindingHandler>[],
    );
    if (replace) handlers.clear();
    handlers.add(handler);
  }

  bool unbind(String keyBinding, [KeyBindingHandler? handler]) {
    final normalized = normalizeKeyBinding(keyBinding);
    final handlers = _bindings[normalized];
    if (handlers == null || handlers.isEmpty) return false;

    if (handler == null) {
      _bindings.remove(normalized);
      return true;
    }

    final removed = handlers.remove(handler);
    if (handlers.isEmpty) _bindings.remove(normalized);
    return removed;
  }

  void clear() => _bindings.clear();

  bool isBound(String keyBinding) {
    final normalized = normalizeKeyBinding(keyBinding);
    return _bindings[normalized]?.isNotEmpty == true;
  }

  bool dispatch(KeyEvent event) {
    final handlers = _bindings[event.binding];
    if (handlers == null || handlers.isEmpty) return false;

    for (final handler in List<KeyBindingHandler>.from(handlers)) {
      handler(event);
    }
    return true;
  }

  bool handleSequence(String sequence) => dispatch(_decoder(sequence));

  StreamSubscription<String> listen(
    Stream<String> input, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return input.listen(
      (sequence) => handleSequence(sequence),
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  StreamSubscription<List<int>> listenBytes(
    Stream<List<int>> input, {
    Encoding encoding = utf8,
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return input.listen(
      (chunk) {
        final decoded = encoding.decode(chunk);
        if (decoded.isEmpty) return;

        if (decoded.startsWith('\u001b') || decoded.runes.length == 1) {
          handleSequence(decoded);
          return;
        }

        for (final rune in decoded.runes) {
          handleSequence(String.fromCharCode(rune));
        }
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _DecodedKey {
  const _DecodedKey(
    this.key, {
    this.ctrl = false,
    this.meta = false,
    this.shift = false,
  });

  final String key;
  final bool ctrl;
  final bool meta;
  final bool shift;

  KeyEvent toEvent(String sequence) {
    return KeyEvent(
      sequence: sequence,
      key: key,
      ctrl: ctrl,
      meta: meta,
      shift: shift,
    );
  }
}

const _simpleSequenceMap = <String, _DecodedKey>{
  '\b': _DecodedKey('backspace'),
  '\t': _DecodedKey('tab'),
  '\r': _DecodedKey('enter'),
  '\n': _DecodedKey('enter'),
  '\u007f': _DecodedKey('backspace'),
  '\u001b': _DecodedKey('escape'),
};

const _tildeKeyCodes = <int, String>{
  1: 'home',
  2: 'insert',
  3: 'delete',
  4: 'end',
  5: 'pageup',
  6: 'pagedown',
  15: 'f5',
  17: 'f6',
  18: 'f7',
  19: 'f8',
  20: 'f9',
  21: 'f10',
  23: 'f11',
  24: 'f12',
};

const _csiFinalMap = <String, _DecodedKey>{
  'A': _DecodedKey('up'),
  'B': _DecodedKey('down'),
  'C': _DecodedKey('right'),
  'D': _DecodedKey('left'),
  'F': _DecodedKey('end'),
  'H': _DecodedKey('home'),
  'P': _DecodedKey('f1'),
  'Q': _DecodedKey('f2'),
  'R': _DecodedKey('f3'),
  'S': _DecodedKey('f4'),
  'Z': _DecodedKey('tab', shift: true),
};

const _ss3FinalMap = <String, _DecodedKey>{
  'A': _DecodedKey('up'),
  'B': _DecodedKey('down'),
  'C': _DecodedKey('right'),
  'D': _DecodedKey('left'),
  'F': _DecodedKey('end'),
  'H': _DecodedKey('home'),
  'P': _DecodedKey('f1'),
  'Q': _DecodedKey('f2'),
  'R': _DecodedKey('f3'),
  'S': _DecodedKey('f4'),
};

_DecodedKey? _decodeCsi(String sequence) {
  if (!sequence.startsWith('\u001b[') || sequence.length < 3) return null;

  final payload = sequence.substring(2);
  final finalChar = payload.substring(payload.length - 1);
  final paramsRaw = payload.substring(0, payload.length - 1);
  if (paramsRaw.isNotEmpty && !RegExp(r'^[0-9;]+$').hasMatch(paramsRaw)) {
    return null;
  }

  final params = <int>[];
  if (paramsRaw.isNotEmpty) {
    for (final part in paramsRaw.split(';')) {
      if (part.isEmpty) continue;
      final value = int.tryParse(part);
      if (value == null) return null;
      params.add(value);
    }
  }

  if (finalChar == '~') {
    if (params.isEmpty) return null;
    final key = _tildeKeyCodes[params.first];
    if (key == null) return null;

    final modifier = params.length > 1 ? params[1] : 1;
    final flags = _decodeModifier(modifier);
    return _DecodedKey(
      key,
      ctrl: flags.ctrl,
      meta: flags.meta,
      shift: flags.shift,
    );
  }

  final base = _csiFinalMap[finalChar];
  if (base == null) return null;

  int modifier = 1;
  if (params.length > 1) {
    modifier = params[1];
  } else if (params.length == 1 && params.first > 1) {
    modifier = params.first;
  }

  final flags = _decodeModifier(modifier);
  return _DecodedKey(
    base.key,
    ctrl: base.ctrl || flags.ctrl,
    meta: base.meta || flags.meta,
    shift: base.shift || flags.shift,
  );
}

_DecodedKey? _decodeSs3(String sequence) {
  if (!sequence.startsWith('\u001bO') || sequence.length != 3) return null;
  final finalChar = sequence.substring(2);
  return _ss3FinalMap[finalChar];
}

({bool ctrl, bool meta, bool shift}) _decodeModifier(int value) {
  if (value <= 1) return (ctrl: false, meta: false, shift: false);
  final bits = value - 1;
  return (ctrl: bits & 4 != 0, meta: bits & 2 != 0, shift: bits & 1 != 0);
}

String _normalizeKeyToken(String key) {
  final normalized = key.toLowerCase();
  return switch (normalized) {
    'esc' || 'escape' => 'escape',
    'return' || 'enter' => 'enter',
    'space' || 'spacebar' => 'space',
    'pgup' || 'pageup' => 'pageup',
    'pgdown' || 'pagedown' => 'pagedown',
    'del' || 'delete' => 'delete',
    'ins' || 'insert' => 'insert',
    'arrowup' => 'up',
    'arrowdown' => 'down',
    'arrowleft' => 'left',
    'arrowright' => 'right',
    '+' => 'plus',
    'plus' => 'plus',
    _ => normalized,
  };
}

String _composeBinding({
  required String key,
  required bool ctrl,
  required bool meta,
  required bool shift,
}) {
  final normalizedKey = _normalizeKeyToken(key);
  final parts = <String>[
    if (ctrl) 'ctrl',
    if (meta) 'meta',
    if (shift) 'shift',
    normalizedKey,
  ];
  return parts.join('+');
}

bool _isAsciiUpper(int unit) => unit >= 65 && unit <= 90;
