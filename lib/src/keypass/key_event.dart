import 'key_binding.dart';

part 'key_decoder.dart';

/// A decoded terminal key sequence.
///
/// [sequence] is the original terminal sequence that produced the event.
/// [binding] is the canonical key binding string used by [Keypass].
final class KeyEvent {
  /// Creates a key event.
  const KeyEvent({
    required this.sequence,
    required this.key,
    this.ctrl = false,
    this.meta = false,
    this.shift = false,
  });

  /// Decodes a complete terminal key sequence.
  factory KeyEvent.fromSequence(String sequence) => _decodeKeyEvent(sequence);

  /// The original terminal sequence.
  final String sequence;

  /// The normalized key token.
  final String key;

  /// Whether the Control modifier was pressed.
  final bool ctrl;

  /// Whether the Meta/Alt modifier was pressed.
  final bool meta;

  /// Whether the Shift modifier was pressed.
  final bool shift;

  /// Canonical key binding string.
  String get binding =>
      composeKeyBinding(key: key, ctrl: ctrl, meta: meta, shift: shift);

  @override
  bool operator ==(Object other) {
    return other is KeyEvent &&
        sequence == other.sequence &&
        key == other.key &&
        ctrl == other.ctrl &&
        meta == other.meta &&
        shift == other.shift;
  }

  @override
  int get hashCode => Object.hash(sequence, key, ctrl, meta, shift);

  @override
  String toString() {
    return 'KeyEvent(binding: $binding, sequence: $sequence)';
  }
}
