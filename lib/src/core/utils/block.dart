import 'dart:io';

import 'cursor.dart';

void setRawMode(Stream<List<int>>? input, bool value) {
  if (input is Stdin) {
    input.lineMode = !value;
  }
}

block({
  Stream<List<int>>? input,
  IOSink? output,
  bool overwrite = true,
  bool hideCursor = true,
}) {
  input ??= stdin;
  output ??= stdout;

  setRawMode(input, true);
  if (hideCursor) output.write(cursorHide);
}
