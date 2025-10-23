import '_constants.dart';
import 'cursor.dart';

const eraseScreen = '${csi}2J';
const eraseLine = '${csi}2K';
const eraseLineStart = '${csi}K';
const eraseLineEnd = '${csi}1K';

String eraseUp([int count = 1]) => '${csi}1J' * count;
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
