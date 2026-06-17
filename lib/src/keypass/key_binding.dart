String normalizeKeyBinding(String binding) {
  final source = binding.trim();
  if (source.isEmpty) {
    throw const FormatException('Key binding cannot be empty.');
  }

  var ctrl = false;
  var meta = false;
  var shift = false;
  String? key;

  for (final part in splitKeyBinding(source)) {
    final lower = part.toLowerCase();
    switch (lower) {
      case 'ctrl':
      case 'control':
      case 'ctl':
        ctrl = true;
      case 'meta':
      case 'alt':
      case 'option':
      case 'cmd':
      case 'command':
        meta = true;
      case 'shift':
        shift = true;
      default:
        if (key != null) {
          throw const FormatException(
            'Key binding must contain exactly one key token.',
          );
        }
        key = normalizeKeyToken(part);
        if (part.length == 1 && isAsciiUpper(part.codeUnitAt(0))) {
          shift = true;
        }
    }
  }

  if (key == null) {
    throw const FormatException('Key binding must contain a key token.');
  }

  return composeKeyBinding(key: key, ctrl: ctrl, meta: meta, shift: shift);
}

List<String> splitKeyBinding(String source) {
  if (source == '+') return const ['+'];

  final parts = source.split('+').map((part) => part.trim()).toList();
  if (parts.length > 2 &&
      parts.last.isEmpty &&
      parts[parts.length - 2].isEmpty) {
    return [...parts.take(parts.length - 2), '+'];
  }

  if (parts.any((part) => part.isEmpty)) {
    throw const FormatException('Key binding contains an empty token.');
  }
  return parts;
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
    throw const FormatException('Key token cannot be empty.');
  }

  final aliased = switch (normalized) {
    '+' || 'plus' => 'plus',
    'esc' || 'escape' => 'escape',
    'return' || 'enter' => 'enter',
    'space' || 'spacebar' => 'space',
    'backspace' || 'bs' => 'backspace',
    'del' || 'delete' => 'delete',
    'ins' || 'insert' => 'insert',
    'pgup' || 'pageup' => 'pageup',
    'pgdn' || 'pgdown' || 'pagedown' => 'pagedown',
    'arrowup' || 'up' => 'up',
    'arrowdown' || 'down' => 'down',
    'arrowleft' || 'left' => 'left',
    'arrowright' || 'right' => 'right',
    _ => normalized,
  };

  if (isKnownKeyName(aliased) || aliased.runes.length == 1) {
    return aliased;
  }
  throw FormatException('Unsupported key token: $key');
}

bool isKnownKeyName(String key) {
  if (_knownKeyNames.contains(key)) return true;
  if (!key.startsWith('f')) return false;
  final number = int.tryParse(key.substring(1));
  return number != null && number >= 1 && number <= 12;
}

bool isAsciiUpper(int unit) => unit >= 65 && unit <= 90;

const _knownKeyNames = <String>{
  'backspace',
  'delete',
  'down',
  'end',
  'enter',
  'escape',
  'home',
  'insert',
  'left',
  'pagedown',
  'pageup',
  'plus',
  'right',
  'space',
  'tab',
  'up',
};
