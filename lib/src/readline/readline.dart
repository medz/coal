import 'dart:convert';
import 'dart:io';

typedef ReadlineReader =
    String? Function({Encoding encoding, bool retainNewlines});
typedef ReadlineWriter = void Function(Object? object);

/// Lightweight input handler for interactive terminal prompts.
class Readline {
  Readline({ReadlineReader? reader, ReadlineWriter? writer, Encoding? encoding})
    : _reader = reader ?? stdin.readLineSync,
      _writer = writer ?? stdout.write,
      encoding = encoding ?? systemEncoding;

  /// Creates a readline instance wired to process stdio.
  Readline.stdio({Encoding? encoding}) : this(encoding: encoding);

  final ReadlineReader _reader;
  final ReadlineWriter _writer;
  final Encoding encoding;

  /// Reads one line from stdin.
  ///
  /// When [prompt] is set, it is written before reading input.
  /// Returns `null` when stdin is closed.
  String? read({
    String prompt = '',
    bool trim = true,
    bool retainNewlines = false,
  }) {
    if (prompt.isNotEmpty) _writer(prompt);
    final value = _reader(encoding: encoding, retainNewlines: retainNewlines);
    if (value == null) return null;
    return trim ? value.trim() : value;
  }

  /// Reads input until a non-empty value is entered.
  ///
  /// Throws [StateError] when stdin closes before any valid value is read.
  String readRequired({
    String prompt = '',
    String? retryPrompt,
    bool trim = true,
    bool allowEmpty = false,
  }) {
    var activePrompt = prompt;
    while (true) {
      final value = read(prompt: activePrompt, trim: trim);
      if (value == null) {
        throw StateError('stdin closed while waiting for input');
      }
      if (allowEmpty || value.isNotEmpty) return value;
      if (retryPrompt != null && retryPrompt.isNotEmpty) {
        activePrompt = retryPrompt;
      }
    }
  }
}
