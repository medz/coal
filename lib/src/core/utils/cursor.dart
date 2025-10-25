import '_constants.dart';

const cursorLeft = '${csi}G';
const cursorHide = '$csi?25l';
const cursorShow = '$csi?25h';
const cursorSave = '${esc}7';
const cursorRestore = '${esc}8';

String cursorUp([int count = 1]) => '$csi${count}A';
String cursorDown([int count = 1]) => '$csi${count}B';
String cursorForward([int count = 1]) => '$csi${count}C';
String cursorBackward([int count = 1]) => '$csi${count}D';
String cursorNextLine([int count = 1]) => '${csi}E' * count;
String cursorPrevLine([int count = 1]) => '${csi}F' * count;

String cursorTo(int x, [int? y]) {
  return y == null || y == 0 ? '$csi${x + 1}G' : '$csi${y + 1};${x + 1}H';
}

String cursorMove(int x, int y) {
  final move = StringBuffer();
  // dart format off
  // ignore: curly_braces_in_flow_control_structures
  if (x < 0) move.write(cursorBackward(-x));
  // ignore: curly_braces_in_flow_control_structures
  else if (x > 0) move.write(cursorForward(x));
  // ignore: curly_braces_in_flow_control_structures
  if (y < 0) move.write(cursorUp(-y));
  // ignore: curly_braces_in_flow_control_structures
  else if (y > 0) move.write(cursorDown(y));
  // dart format on
  return move.toString();
}
