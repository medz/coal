import '../../readline.dart';

/// Basic prompt flow built on top of [Readline].
final class Prompt {
  /// Creates a prompt instance from an existing readline.
  Prompt({required Readline readline}) : _readline = readline;

  /// Creates a prompt instance backed by process stdio.
  factory Prompt.stdio() {
    return Prompt(readline: Readline.stdio());
  }

  final Readline _readline;
  bool _closed = false;
  bool _asking = false;

  /// Asks for one line of text.
  ///
  /// Returns `null` when the prompt is cancelled or the input stream ends.
  /// When [defaultValue] is provided, an empty submitted line returns it.
  Future<String?> text(String message, {String? defaultValue}) async {
    if (_closed) {
      throw StateError('Prompt is closed.');
    }
    if (_asking) {
      throw StateError('Prompt is already asking.');
    }

    _asking = true;
    try {
      final answer = await _readline.readLine(
        prompt: _formatPrompt(message, defaultValue: defaultValue),
      );
      if (answer == null) return null;
      if (answer.isEmpty && defaultValue != null) {
        return defaultValue;
      }
      return answer;
    } finally {
      _asking = false;
    }
  }

  /// Closes resources owned by this prompt.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _readline.close();
  }
}

String _formatPrompt(String message, {String? defaultValue}) {
  final defaultLabel = defaultValue == null || defaultValue.isEmpty
      ? ''
      : ' ($defaultValue)';
  return '$message$defaultLabel: ';
}
