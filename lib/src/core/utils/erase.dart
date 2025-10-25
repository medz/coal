import '_constants.dart';
import 'cursor.dart';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
const eraseScreen = '${csi}2J';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
const eraseLine = '${csi}2K';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
const eraseLineStart = '${csi}K';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
const eraseLineEnd = '${csi}1K';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
String eraseUp([int count = 1]) => '${csi}1J' * count;

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
String eraseDown([int count = 1]) => '${csi}J' * count;

String eraseLines(int count) {
  final erase = StringBuffer(), end = count - 1;
  for (int i = 0; i < count; i++) {
    erase.write(eraseLine);
    if (i < end) erase.write(cursorUp());
  }
  if (count != 0) erase.write(cursorLeft);
  return erase.toString();
}
