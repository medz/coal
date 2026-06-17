import 'dart:async';
import 'dart:convert';

import '../keypass/key_event.dart';

sealed class ReadlineInput {
  const ReadlineInput();
}

final class ReadlineTextInput extends ReadlineInput {
  const ReadlineTextInput(this.text);

  final String text;
}

final class ReadlineKeyInput extends ReadlineInput {
  const ReadlineKeyInput(this.event);

  final KeyEvent event;
}

final class ReadlineInputParser {
  ReadlineInputParser({
    required void Function(ReadlineInput input) emit,
    Duration escapeTimeout = const Duration(milliseconds: 80),
  }) : _emit = emit,
       _escapeTimeout = escapeTimeout {
    _textSink = const Utf8Decoder().startChunkedConversion(
      _DecodedTextSink(_emitText),
    );
  }

  final void Function(ReadlineInput input) _emit;
  final Duration _escapeTimeout;
  late final ByteConversionSink _textSink;
  final List<int> _escape = <int>[];
  Timer? _escapeTimer;
  bool _closed = false;

  void add(List<int> bytes) {
    if (_closed) {
      throw StateError('Readline input parser is closed.');
    }

    for (final byte in bytes) {
      _addByte(byte);
    }
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _flushEscape();
    try {
      _textSink.close();
    } on FormatException {
      // Drop an incomplete trailing UTF-8 scalar instead of failing after EOF.
    }
  }

  void _startEscape() {
    _escape.add(0x1b);
    _resetEscapeTimer();
  }

  void _addByte(int byte) {
    if (_escape.isNotEmpty) {
      _addEscapeByte(byte);
      return;
    }

    if (byte == 0x1b) {
      _startEscape();
    } else if (_isControlByte(byte)) {
      _emitKey(String.fromCharCode(byte));
    } else {
      _textSink.add(<int>[byte]);
    }
  }

  void _addEscapeByte(int byte) {
    if (_isTerminalControlPrefix(_escape) &&
        !_canContinueTerminalControl(_escape, byte)) {
      _flushEscape();
      _addByte(byte);
      return;
    }

    _escape.add(byte);
    if (_isCompleteEscape(_escape)) {
      _flushEscape();
    } else if (_isTerminalControlPrefix(_escape)) {
      _escapeTimer?.cancel();
      _escapeTimer = null;
    } else {
      _resetEscapeTimer();
    }
  }

  void _resetEscapeTimer() {
    _escapeTimer?.cancel();
    _escapeTimer = Timer(_escapeTimeout, _flushEscape);
  }

  void _flushEscape() {
    if (_escape.isEmpty) return;
    _escapeTimer?.cancel();
    _escapeTimer = null;

    final sequence = String.fromCharCodes(_escape);
    _escape.clear();
    _emitKey(sequence);
  }

  void _emitText(String text) {
    if (text.isNotEmpty) {
      _emit(ReadlineTextInput(text));
    }
  }

  void _emitKey(String sequence) {
    try {
      _emit(ReadlineKeyInput(KeyEvent.fromSequence(sequence)));
    } on FormatException {
      // Ignore terminal sequences that Keypass does not model yet.
    }
  }
}

bool _isControlByte(int byte) => byte < 0x20 || byte == 0x7f;

bool _isCompleteEscape(List<int> bytes) {
  if (bytes.length < 2) return false;

  final second = bytes[1];
  if (second == 0x5b) {
    if (bytes.length == 2) return false;
    final finalByte = bytes.last;
    return finalByte >= 0x40 && finalByte <= 0x7e;
  }

  if (second == 0x4f) {
    return bytes.length == 3;
  }

  return bytes.length == 2;
}

bool _isTerminalControlPrefix(List<int> bytes) {
  return bytes.length >= 2 && (bytes[1] == 0x5b || bytes[1] == 0x4f);
}

bool _canContinueTerminalControl(List<int> bytes, int byte) {
  final second = bytes[1];
  if (second == 0x5b) {
    return byte >= 0x20 && byte <= 0x7e;
  }
  if (second == 0x4f) {
    return bytes.length == 2 && byte >= 0x40 && byte <= 0x7e;
  }
  return false;
}

final class _DecodedTextSink extends StringConversionSink {
  _DecodedTextSink(this._emit);

  final void Function(String text) _emit;

  @override
  void add(String str) {
    _emit(str);
  }

  @override
  void addSlice(String str, int start, int end, bool isLast) {
    if (start < end) {
      add(str.substring(start, end));
    }
    if (isLast) close();
  }

  @override
  void close() {}
}
