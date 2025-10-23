import '_constants.dart';
import '_fmt.dart';

String black(String text) => fmt(text, "${csi}30m", "${csi}39m");
String red(String text) => fmt(text, "${csi}31m", "${csi}39m");
String green(String text) => fmt(text, "${csi}32m", "${csi}39m");
String yellow(String text) => fmt(text, "${csi}33m", "${csi}39m");
String blue(String text) => fmt(text, "${csi}34m", "${csi}39m");
String magenta(String text) => fmt(text, "${csi}35m", "${csi}39m");
String cyan(String text) => fmt(text, "${csi}36m", "${csi}39m");
String white(String text) => fmt(text, "${csi}37m", "${csi}39m");
String gray(String text) => fmt(text, "${csi}90m", "${csi}39m");

String bgBlack(String text) => fmt(text, "${csi}40m", "${csi}49m");
String bgRed(String text) => fmt(text, "${csi}41m", "${csi}49m");
String bgGreen(String text) => fmt(text, "${csi}42m", "${csi}49m");
String bgYellow(String text) => fmt(text, "${csi}43m", "${csi}49m");
String bgBlue(String text) => fmt(text, "${csi}44m", "${csi}49m");
String bgMagenta(String text) => fmt(text, "${csi}45m", "${csi}49m");
String bgCyan(String text) => fmt(text, "${csi}46m", "${csi}49m");
String bgWhite(String text) => fmt(text, "${csi}47m", "${csi}49m");

String blackBright(String text) => fmt(text, "${csi}90m", "${csi}39m");
String redBright(String text) => fmt(text, "${csi}91m", "${csi}39m");
String greenBright(String text) => fmt(text, "${csi}92m", "${csi}39m");
String yellowBright(String text) => fmt(text, "${csi}93m", "${csi}39m");
String blueBright(String text) => fmt(text, "${csi}94m", "${csi}39m");
String magentaBright(String text) => fmt(text, "${csi}95m", "${csi}39m");
String cyanBright(String text) => fmt(text, "${csi}96m", "${csi}39m");
String whiteBright(String text) => fmt(text, "${csi}97m", "${csi}39m");

String bgBlackBright(String text) => fmt(text, "${csi}100m", "${csi}49m");
String bgRedBright(String text) => fmt(text, "${csi}101m", "${csi}49m");
String bgGreenBright(String text) => fmt(text, "${csi}102m", "${csi}49m");
String bgYellowBright(String text) => fmt(text, "${csi}103m", "${csi}49m");
String bgBlueBright(String text) => fmt(text, "${csi}104m", "${csi}49m");
String bgMagentaBright(String text) => fmt(text, "${csi}105m", "${csi}49m");
String bgCyanBright(String text) => fmt(text, "${csi}106m", "${csi}49m");
String bgWhiteBright(String text) => fmt(text, "${csi}107m", "${csi}49m");
