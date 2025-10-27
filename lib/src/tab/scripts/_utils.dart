String nameForVar(String name) {
  return name.replaceAll(r'-', r'_').replaceAll(r':', r'_');
}
