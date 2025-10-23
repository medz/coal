import '_constants.dart';

String scrollUp([int count = 1]) => '${csi}S' * count;
String scrollDown([int count = 1]) => '${csi}T' * count;
