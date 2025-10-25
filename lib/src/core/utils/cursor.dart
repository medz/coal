import '_constants.dart';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
const cursorLeft = '${csi}G';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
const cursorHide = '$csi?25l';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
const cursorShow = '$csi?25h';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
const cursorSave = '${esc}7';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
const cursorRestore = '${esc}8';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
String cursorUp([int count = 1]) => '$csi${count}A';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
String cursorDown([int count = 1]) => '$csi${count}B';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
String cursorForward([int count = 1]) => '$csi${count}C';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
String cursorBackward([int count = 1]) => '$csi${count}D';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
String cursorNextLine([int count = 1]) => '${csi}E' * count;

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
String cursorPrevLine([int count = 1]) => '${csi}F' * count;

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
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
