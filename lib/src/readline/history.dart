final class LineHistory {
  LineHistory({int limit = 100, Iterable<String> entries = const <String>[]})
    : _limit = limit {
    if (limit < 0) {
      throw ArgumentError.value(
        limit,
        'limit',
        'History limit cannot be negative.',
      );
    }
    for (final entry in entries) {
      add(entry);
    }
  }

  final int _limit;
  final List<String> _entries = <String>[];
  int? _cursor;
  String? _draft;

  void add(String line) {
    if (_limit == 0 || line.isEmpty) return;
    if (_entries.isNotEmpty && _entries.last == line) return;

    _entries.add(line);
    while (_entries.length > _limit) {
      _entries.removeAt(0);
    }
    resetNavigation();
  }

  String? previous(String currentLine) {
    if (_entries.isEmpty) return null;

    if (_cursor == null) {
      _draft = currentLine;
      _cursor = _entries.length - 1;
    } else if (_cursor! > 0) {
      _cursor = _cursor! - 1;
    }

    return _entries[_cursor!];
  }

  String? next() {
    final cursor = _cursor;
    if (cursor == null) return null;

    if (cursor < _entries.length - 1) {
      _cursor = cursor + 1;
      return _entries[_cursor!];
    }

    final draft = _draft ?? '';
    resetNavigation();
    return draft;
  }

  void resetNavigation() {
    _cursor = null;
    _draft = null;
  }
}
