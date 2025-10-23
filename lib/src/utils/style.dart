import '_constants.dart';
import '_fmt.dart';

String reset(String text) => fmt(text, '${csi}0m', '${csi}0m');
String bold(String text) =>
    fmt(text, '${csi}1m', '${csi}22m', '${csi}22m${csi}1m"');
String dim(String text) =>
    fmt(text, '${csi}2m', '${csi}22m', '${csi}22m${csi}2m');
String italic(String text) => fmt(text, '${csi}3m', '${csi}23m');
String underline(String text) => fmt(text, '${csi}4m', '${csi}24m');
String inverse(String text) => fmt(text, '${csi}7m', '${csi}27m');
String hidden(String text) => fmt(text, '${csi}8m', '${csi}28m');
String strikethrough(String text) => fmt(text, '${csi}9m', '${csi}29m');
