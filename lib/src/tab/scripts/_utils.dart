String nameForVar(String name) {
  final normalized = name.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  if (normalized.isEmpty) return '_';
  if (RegExp(r'^[0-9]').hasMatch(normalized)) return '_$normalized';
  return normalized;
}
