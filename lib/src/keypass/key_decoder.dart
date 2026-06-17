part of 'key_event.dart';

KeyEvent _decodeKeyEvent(String sequence) {
  if (sequence.isEmpty) {
    throw const FormatException('Key sequence cannot be empty.');
  }

  if (_simpleSequenceMap[sequence] case final key?) {
    return key.toEvent(sequence);
  }

  if (sequence.startsWith('\x1b[') && sequence.length > 2) {
    final decoded = _decodeCsi(sequence);
    if (decoded == null) {
      throw FormatException('Unsupported CSI key sequence: $sequence');
    }
    return decoded.toEvent(sequence);
  }

  if (sequence.startsWith('\x1bO') && sequence.length > 2) {
    final decoded = _decodeSs3(sequence);
    if (decoded == null) {
      throw FormatException('Unsupported SS3 key sequence: $sequence');
    }
    return decoded.toEvent(sequence);
  }

  if (sequence.startsWith('\x1b') && sequence.length > 1) {
    final nested = _decodeKeyEvent(sequence.substring(1));
    return KeyEvent(
      sequence: sequence,
      key: nested.key,
      ctrl: nested.ctrl,
      meta: true,
      shift: nested.shift,
    );
  }

  if (sequence.runes.length != 1) {
    throw FormatException('Unsupported key sequence: $sequence');
  }

  final codePoint = sequence.runes.single;
  if (codePoint == 0) {
    return const KeyEvent(sequence: '\x00', key: 'space', ctrl: true);
  }
  if (codePoint >= 1 && codePoint <= 26) {
    return KeyEvent(
      sequence: sequence,
      key: String.fromCharCode(codePoint + 96),
      ctrl: true,
    );
  }

  final char = String.fromCharCode(codePoint);
  if (char == '+') return KeyEvent(sequence: sequence, key: 'plus');
  // Only single-code-unit ASCII uppercase letters imply Shift; supplementary
  // characters stay literal text input.
  final shift = char.length == 1 && isAsciiUpper(char.codeUnitAt(0));
  return KeyEvent(
    sequence: sequence,
    key: shift ? char.toLowerCase() : char,
    shift: shift,
  );
}

_DecodedKey? _decodeCsi(String sequence) {
  if (!sequence.startsWith('\x1b[') || sequence.length < 3) return null;

  final payload = sequence.substring(2);
  final finalChar = payload.substring(payload.length - 1);
  final paramsRaw = payload.substring(0, payload.length - 1);
  if (paramsRaw.isNotEmpty && !RegExp(r'^[0-9;]+$').hasMatch(paramsRaw)) {
    return null;
  }

  final params = <int>[];
  if (paramsRaw.isNotEmpty) {
    for (final part in paramsRaw.split(';')) {
      if (part.isEmpty) return null;
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

  var modifier = 1;
  if (params.length > 1) {
    modifier = params[1];
  } else if (params.length == 1 && params.single > 1) {
    modifier = params.single;
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
  if (!sequence.startsWith('\x1bO') || sequence.length != 3) return null;
  return _ss3FinalMap[sequence.substring(2)];
}

({bool ctrl, bool meta, bool shift}) _decodeModifier(int value) {
  if (value < 1 || value > 8) {
    throw FormatException('Unsupported CSI modifier value: $value');
  }
  if (value <= 1) return (ctrl: false, meta: false, shift: false);
  final bits = value - 1;
  return (ctrl: bits & 4 != 0, meta: bits & 2 != 0, shift: bits & 1 != 0);
}

final class _DecodedKey {
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
  '\n': _DecodedKey('enter'),
  '\r': _DecodedKey('enter'),
  ' ': _DecodedKey('space'),
  '\x1b': _DecodedKey('escape'),
  '\x7f': _DecodedKey('backspace'),
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
