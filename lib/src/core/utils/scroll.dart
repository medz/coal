import '../_constants.dart';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
String scrollUp([int count = 1]) => '${csi}S' * count;

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
String scrollDown([int count = 1]) => '${csi}T' * count;

String scrollLeft([int count = 1]) => '${csi}Z' * count;

String scrollRight([int count = 1]) => '${csi}A' * count;
