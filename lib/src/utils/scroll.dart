import '../_constants.dart';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
String scrollUp([int count = 1]) => count <= 0 ? '' : '$csi${count}S';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
String scrollDown([int count = 1]) => count <= 0 ? '' : '$csi${count}T';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
String scrollLeft([int count = 1]) => count <= 0 ? '' : '$csi$count @';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
String scrollRight([int count = 1]) => count <= 0 ? '' : '$csi$count A';
