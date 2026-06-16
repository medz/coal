/// In-memory line history for editor navigation.
final class LineHistory {
  LineHistory({this.limit = 100, this.ignoreEmpty = true}) {
    if (limit < 0) {
      throw ArgumentError.value(limit, 'limit', 'must not be negative');
    }
  }

  final int limit;
  final bool ignoreEmpty;
  final _entries = <String>[];

  List<String> get entries => List<String>.unmodifiable(_entries);

  int get length => _entries.length;

  bool get isEmpty => _entries.isEmpty;

  String operator [](int index) => _entries[index];

  void add(String entry) {
    if (ignoreEmpty && entry.isEmpty) return;
    if (_entries.isNotEmpty && _entries.last == entry) return;

    _entries.add(entry);
    while (_entries.length > limit) {
      _entries.removeAt(0);
    }
  }

  void clear() => _entries.clear();
}
