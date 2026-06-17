import '../../prompt.dart';

/// Reusable prompt helpers built on top of [Prompt].
extension PromptUtils on Prompt {
  /// Asks a yes/no question.
  ///
  /// Returns `null` when cancelled. Empty input uses [defaultValue] when set.
  Future<bool?> confirm(String message, {bool? defaultValue}) async {
    while (true) {
      final answer = await text(_confirmMessage(message, defaultValue));
      if (answer == null) return null;

      final normalized = answer.trim().toLowerCase();
      if (normalized.isEmpty && defaultValue != null) {
        return defaultValue;
      }
      if (normalized == 'y' || normalized == 'yes') return true;
      if (normalized == 'n' || normalized == 'no') return false;

      message = 'Please answer yes or no';
    }
  }
}

String _confirmMessage(String message, bool? defaultValue) {
  final label = _defaultConfirmLabel(defaultValue);
  return label == null ? message : '$message ($label)';
}

String? _defaultConfirmLabel(bool? value) {
  return switch (value) {
    true => 'Y/n',
    false => 'y/N',
    null => null,
  };
}
