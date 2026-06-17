import 'dart:io' as io;

abstract interface class TerminalMode {
  void enterRawMode();

  void restore();
}

final class StdinTerminalMode implements TerminalMode {
  StdinTerminalMode(this._stdin);

  final io.Stdin _stdin;
  bool? _lineMode;
  bool? _echoMode;
  bool _active = false;

  @override
  void enterRawMode() {
    if (_active || !_stdin.hasTerminal) return;

    _lineMode = _stdin.lineMode;
    _echoMode = _stdin.echoMode;
    try {
      _stdin
        ..lineMode = false
        ..echoMode = false;
      _active = true;
    } catch (_) {
      _restoreSavedModes();
      rethrow;
    }
  }

  @override
  void restore() {
    if (!_active) return;

    _restoreSavedModes();
    _active = false;
  }

  void _restoreSavedModes() {
    final lineMode = _lineMode;
    final echoMode = _echoMode;
    if (lineMode != null) {
      _stdin.lineMode = lineMode;
    }
    if (echoMode != null) {
      _stdin.echoMode = echoMode;
    }

    _lineMode = null;
    _echoMode = null;
  }
}
