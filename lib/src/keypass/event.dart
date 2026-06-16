import 'package:characters/characters.dart';

/// Input decoded from terminal key bytes.
sealed class KeyInput {
  const KeyInput();
}

/// Printable text input.
final class TextInput extends KeyInput {
  const TextInput(this.text);

  final String text;

  @override
  bool operator ==(Object other) {
    return other is TextInput && other.text == text;
  }

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'TextInput($text)';
}

/// Unsupported terminal control sequence that should not be inserted as text.
final class ControlSequenceInput extends KeyInput {
  const ControlSequenceInput(this.sequence);

  final String sequence;

  @override
  bool operator ==(Object other) {
    return other is ControlSequenceInput && other.sequence == sequence;
  }

  @override
  int get hashCode => sequence.hashCode;

  @override
  String toString() => 'ControlSequenceInput($sequence)';
}

/// Non-text key input such as arrows, enter, or control chords.
final class KeyEvent extends KeyInput {
  KeyEvent(
    String key, {
    this.ctrl = false,
    this.meta = false,
    this.shift = false,
    this.sequence,
  }) : key = normalizeKeyToken(key);

  final String key;
  final bool ctrl;
  final bool meta;
  final bool shift;
  final String? sequence;

  String get binding =>
      composeKeyBinding(key: key, ctrl: ctrl, meta: meta, shift: shift);

  bool matches(String binding) => normalizeKeyBinding(binding) == this.binding;

  KeyEvent copyWith({bool? ctrl, bool? meta, bool? shift, String? sequence}) {
    return KeyEvent(
      key,
      ctrl: ctrl ?? this.ctrl,
      meta: meta ?? this.meta,
      shift: shift ?? this.shift,
      sequence: sequence ?? this.sequence,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is KeyEvent &&
        other.key == key &&
        other.ctrl == ctrl &&
        other.meta == meta &&
        other.shift == shift;
  }

  @override
  int get hashCode => Object.hash(key, ctrl, meta, shift);

  @override
  String toString() => 'KeyEvent($binding)';
}

/// Normalizes a binding such as `Shift + Ctrl + A` to `ctrl+shift+a`.
String normalizeKeyBinding(String binding) {
  final source = binding.trim();
  if (source.isEmpty) throw FormatException('Key binding cannot be empty.');

  var ctrl = false;
  var meta = false;
  var shift = false;
  String? key;

  final rawParts = source.split('+');
  for (final (index, rawPart) in rawParts.indexed) {
    var part = rawPart.trim();
    if (part.isEmpty && index == rawParts.length - 1 && source.endsWith('+')) {
      part = '+';
    }
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
        if (part.characters.length == 1 && _isAsciiUpper(part.codeUnitAt(0))) {
          shift = true;
        }
        key = normalizeKeyToken(lower);
    }
  }

  if (key == null) {
    throw FormatException('Key binding must contain a key token.');
  }

  return composeKeyBinding(key: key, ctrl: ctrl, meta: meta, shift: shift);
}

String composeKeyBinding({
  required String key,
  required bool ctrl,
  required bool meta,
  required bool shift,
}) {
  final parts = <String>[
    if (ctrl) 'ctrl',
    if (meta) 'meta',
    if (shift) 'shift',
    normalizeKeyToken(key),
  ];
  return parts.join('+');
}

String normalizeKeyToken(String key) {
  final normalized = key.trim().toLowerCase();
  if (normalized.isEmpty) {
    throw FormatException('Key token cannot be empty.');
  }

  return switch (normalized) {
    'esc' || 'escape' => 'escape',
    'return' || 'enter' => 'enter',
    'space' || 'spacebar' => 'space',
    'pgup' || 'pageup' || 'page-up' => 'pageup',
    'pgdown' || 'pagedown' || 'page-down' => 'pagedown',
    'del' || 'delete' => 'delete',
    'ins' || 'insert' => 'insert',
    'arrowup' || 'up' => 'up',
    'arrowdown' || 'down' => 'down',
    'arrowleft' || 'left' => 'left',
    'arrowright' || 'right' => 'right',
    '+' || 'plus' => 'plus',
    _ => normalized,
  };
}

bool isAsciiControl(int codeUnit) {
  return codeUnit < 0x20 || codeUnit == 0x7f;
}

bool _isAsciiUpper(int codeUnit) {
  return codeUnit >= 0x41 && codeUnit <= 0x5a;
}
