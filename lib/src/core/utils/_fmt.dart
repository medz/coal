String fmt(
  final String text,
  final String open,
  final String close, [
  String? replace,
]) {
  replace ??= open;
  final index = text.indexOf(close, open.length);
  return ~index != 0
      ? open + _repc(text, close, replace, index) + close
      : open + text + close;
}

String _repc(
  final String text,
  final String close,
  final String replace,
  int index,
) {
  final buf = StringBuffer();
  int cursor = 0;

  do {
    buf.write(text.substring(cursor, index));
    buf.write(replace);

    cursor = index + close.length;
    index = text.indexOf(close, cursor);
  } while (~index != 0);

  buf.write(text.substring(cursor));
  return buf.toString();
}
