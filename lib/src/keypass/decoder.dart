import 'dart:convert';

import 'package:characters/characters.dart';

import 'event.dart';

/// Decodes complete terminal key sequences.
abstract final class KeyDecoder {
  static KeyInput decodeSequence(String sequence) {
    final input = tryDecodeSequence(sequence);
    if (input == null) {
      throw FormatException('Unsupported key sequence: $sequence');
    }
    return input;
  }

  static KeyInput? tryDecodeSequence(String sequence) {
    if (sequence.isEmpty) {
      throw FormatException('Key sequence cannot be empty.');
    }

    if (sequence.codeUnitAt(0) != _escape) {
      if (sequence.length == 1 && isAsciiControl(sequence.codeUnitAt(0))) {
        return _decodeControl(sequence);
      }
      return TextInput(sequence);
    }

    if (sequence == _escapeChar) {
      return KeyEvent('escape', sequence: sequence);
    }

    final csi = _decodeCsi(sequence);
    if (csi != null) return csi;

    final ss3 = _decodeSs3(sequence);
    if (ss3 != null) return ss3;

    if (sequence.startsWith(_csiPrefix)) {
      final end = _findCsiEnd(sequence);
      if (end == sequence.length - 1) return ControlSequenceInput(sequence);
      return null;
    }

    if (sequence.startsWith(_ss3Prefix)) {
      if (sequence.length == 3) return ControlSequenceInput(sequence);
      return null;
    }

    final nested = tryDecodeSequence(sequence.substring(1));
    if (nested is KeyEvent) {
      return nested.copyWith(meta: true, sequence: sequence);
    }
    if (nested is TextInput) {
      final event = _eventFromText(nested.text, sequence: sequence);
      if (event == null) return null;
      return event.copyWith(meta: true, sequence: sequence);
    }

    return null;
  }
}

/// Stateful byte parser for terminal input.
final class KeyParser {
  KeyParser({Encoding encoding = utf8}) : _stringSink = _DecodedStringSink() {
    _byteSink = encoding.decoder.startChunkedConversion(_stringSink);
  }

  final _DecodedStringSink _stringSink;
  late final Sink<List<int>> _byteSink;
  var _pending = '';
  var _closed = false;

  List<KeyInput> addBytes(List<int> bytes) {
    if (_closed) throw StateError('Cannot add bytes after close().');
    _byteSink.add(bytes);
    return addString(_stringSink.take());
  }

  List<KeyInput> addString(String input) {
    if (_closed) throw StateError('Cannot add input after close().');
    if (input.isEmpty) return const <KeyInput>[];
    _pending += input;
    return _drain(flush: false);
  }

  /// Emits pending ambiguous key prefixes such as a lone escape byte.
  List<KeyInput> flush() {
    return _drain(flush: true);
  }

  /// Closes the UTF-8 byte decoder and emits any pending key prefix.
  List<KeyInput> close() {
    if (!_closed) {
      _byteSink.close();
      _closed = true;
      _pending += _stringSink.take();
    }
    return _drain(flush: true);
  }

  List<KeyInput> _drain({required bool flush}) {
    final inputs = <KeyInput>[];

    while (_pending.isNotEmpty) {
      final input = _takeNext(flush: flush);
      if (input == null) break;
      inputs.add(input);
    }

    return inputs;
  }

  KeyInput? _takeNext({required bool flush}) {
    final first = _pending.codeUnitAt(0);

    if (first == _escape) {
      return _takeEscape(flush: flush);
    }

    if (isAsciiControl(first)) {
      final sequence = _pending.substring(0, 1);
      _pending = _pending.substring(1);
      return KeyDecoder.decodeSequence(sequence);
    }

    var end = 1;
    while (end < _pending.length) {
      final unit = _pending.codeUnitAt(end);
      if (unit == _escape || isAsciiControl(unit)) break;
      end++;
    }

    final text = _pending.substring(0, end);
    _pending = _pending.substring(end);
    return TextInput(text);
  }

  KeyInput? _takeEscape({required bool flush}) {
    if (_pending.length == 1) {
      if (!flush) return null;
      _pending = '';
      return KeyEvent('escape', sequence: _escapeChar);
    }

    final second = _pending.codeUnitAt(1);
    if (second == _csiStart) {
      final end = _findCsiEnd(_pending);
      if (end == null) {
        if (!flush) return null;
        final sequence = _pending;
        _pending = '';
        return ControlSequenceInput(sequence);
      }

      final sequence = _pending.substring(0, end + 1);
      final decoded = KeyDecoder.tryDecodeSequence(sequence);
      if (decoded != null) {
        _pending = _pending.substring(end + 1);
        return decoded;
      }

      _pending = _pending.substring(end + 1);
      return ControlSequenceInput(sequence);
    }

    if (second == _ss3Start) {
      if (_pending.length < 3) {
        if (!flush) return null;
        final sequence = _pending;
        _pending = '';
        return ControlSequenceInput(sequence);
      }

      final sequence = _pending.substring(0, 3);
      final decoded = KeyDecoder.tryDecodeSequence(sequence);
      if (decoded != null) {
        _pending = _pending.substring(3);
        return decoded;
      }

      _pending = _pending.substring(3);
      return ControlSequenceInput(sequence);
    }

    final next = _pending.substring(1).characters.first;
    final sequence = _pending.substring(0, next.length + 1);
    final decoded = KeyDecoder.tryDecodeSequence(sequence);
    if (decoded == null) {
      _pending = _pending.substring(1);
      return KeyEvent('escape', sequence: _escapeChar);
    }

    _pending = _pending.substring(sequence.length);
    return decoded;
  }
}

final class _DecodedStringSink extends StringConversionSinkBase {
  final _chunks = StringBuffer();

  @override
  void add(String str) {
    _chunks.write(str);
  }

  @override
  void addSlice(String str, int start, int end, bool isLast) {
    _chunks.write(str.substring(start, end));
    if (isLast) close();
  }

  @override
  void close() {}

  String take() {
    final value = _chunks.toString();
    _chunks.clear();
    return value;
  }
}

final class _DecodedKey {
  const _DecodedKey(this.key, {this.shift = false});

  final String key;
  final bool shift;

  KeyEvent toEvent(String sequence) {
    return KeyEvent(key, shift: shift, sequence: sequence);
  }
}

KeyEvent _decodeControl(String sequence) {
  final code = sequence.codeUnitAt(0);
  final key = _controlKeyMap[code];
  if (key != null) return KeyEvent(key, sequence: sequence);

  if (code == 0) {
    return KeyEvent('space', ctrl: true, sequence: sequence);
  }
  if (code >= 1 && code <= 26) {
    return KeyEvent(
      String.fromCharCode(code + 0x60),
      ctrl: true,
      sequence: sequence,
    );
  }

  return KeyEvent('control-$code', ctrl: true, sequence: sequence);
}

KeyEvent? _decodeCsi(String sequence) {
  if (!sequence.startsWith(_csiPrefix) || sequence.length < 3) return null;

  final payload = sequence.substring(2);
  final finalChar = payload.substring(payload.length - 1);
  final finalUnit = finalChar.codeUnitAt(0);
  if (!_isCsiFinal(finalUnit)) return null;

  final paramsRaw = payload.substring(0, payload.length - 1);
  if (paramsRaw.isNotEmpty && !RegExp(r'^[0-9;]+$').hasMatch(paramsRaw)) {
    return null;
  }

  final params = <int>[];
  for (final part in paramsRaw.split(';')) {
    if (part.isEmpty) continue;
    final value = int.tryParse(part);
    if (value == null) return null;
    params.add(value);
  }

  if (finalChar == '~') {
    if (params.isEmpty) return null;
    final key = _tildeKeyCodes[params.first];
    if (key == null) return null;
    final modifier = params.length > 1 ? params[1] : 1;
    final flags = _decodeModifier(modifier);
    return KeyEvent(
      key,
      ctrl: flags.ctrl,
      meta: flags.meta,
      shift: flags.shift,
      sequence: sequence,
    );
  }

  final base = _csiFinalMap[finalChar];
  if (base == null) return null;

  var modifier = 1;
  if (params.length > 1) {
    modifier = params[1];
  } else if (params.length == 1 && params.first > 1) {
    modifier = params.first;
  }

  final flags = _decodeModifier(modifier);
  return KeyEvent(
    base.key,
    ctrl: flags.ctrl,
    meta: flags.meta,
    shift: base.shift || flags.shift,
    sequence: sequence,
  );
}

KeyEvent? _decodeSs3(String sequence) {
  if (!sequence.startsWith(_ss3Prefix) || sequence.length != 3) return null;
  return _ss3FinalMap[sequence.substring(2)]?.toEvent(sequence);
}

KeyEvent? _eventFromText(String text, {required String sequence}) {
  if (text.characters.length != 1) return null;

  final char = text.characters.first;
  final unit = char.codeUnitAt(0);
  final shift = unit >= 0x41 && unit <= 0x5a;
  final key = switch (char) {
    ' ' => 'space',
    '+' => 'plus',
    _ => shift ? char.toLowerCase() : char,
  };

  return KeyEvent(key, shift: shift, sequence: sequence);
}

({bool ctrl, bool meta, bool shift}) _decodeModifier(int value) {
  if (value <= 1) return (ctrl: false, meta: false, shift: false);
  final bits = value - 1;
  return (ctrl: bits & 4 != 0, meta: bits & 2 != 0, shift: bits & 1 != 0);
}

int? _findCsiEnd(String input) {
  for (var index = 2; index < input.length; index++) {
    if (_isCsiFinal(input.codeUnitAt(index))) return index;
  }
  return null;
}

bool _isCsiFinal(int unit) => unit >= 0x40 && unit <= 0x7e;

const _escape = 0x1b;
const _csiStart = 0x5b;
const _ss3Start = 0x4f;
const _escapeChar = '\u001b';
const _csiPrefix = '\u001b[';
const _ss3Prefix = '\u001bO';

const _controlKeyMap = <int, String>{
  8: 'backspace',
  9: 'tab',
  10: 'enter',
  13: 'enter',
  27: 'escape',
  127: 'backspace',
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
