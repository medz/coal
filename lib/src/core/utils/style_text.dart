import '../../_constants.dart';

enum TextStyle {
  /*------------------------- Modifier -------------------------*/
  reset(0, 0),
  bold(1, 22),
  dim(2, 22),
  italic(3, 23),
  underline(4, 24),
  blink(5, 25),
  inverse(7, 27),
  hidden(8, 28),
  strikethrough(9, 29),

  /*--------------------- Extensions Modifier ------------------*/
  doubleunderline(21, 24),
  overlined(53, 55),
  framed(51, 54),
  encircled(52, 54),
  // none(0, 0) // Equivalents to reset

  /*--------------------- Foreground Colors --------------------*/
  black(30, 39),
  red(31, 39),
  green(32, 39),
  yellow(33, 39),
  blue(34, 39),
  magenta(35, 39),
  cyan(36, 39),
  white(37, 39),

  /*--------------------- Background Colors --------------------*/
  bgBlack(40, 49),
  bgRed(41, 49),
  bgGreen(42, 49),
  bgYellow(43, 49),
  bgBlue(44, 49),
  bgMagenta(45, 49),
  bgCyan(46, 49),
  bgWhite(47, 49),

  /*----------------- Bright Foreground Colors -----------------*/
  blackBright(90, 39),
  redBright(91, 39),
  greenBright(92, 39),
  yellowBright(93, 39),
  blueBright(94, 39),
  magentaBright(95, 39),
  cyanBright(96, 39),
  whiteBright(97, 39),

  /*----------------- Bright Background Colors -----------------*/
  bgBlackBright(100, 49),
  bgRedBright(101, 49),
  bgGreenBright(102, 49),
  bgYellowBright(103, 49),
  bgBlueBright(104, 49),
  bgMagentaBright(105, 49),
  bgCyanBright(106, 49),
  bgWhiteBright(107, 49),

  /*------------------------- Aliases -------------------------*/
  gray(90, 39), // blackBright
  grey(90, 39), // blackBright
  bgGray(100, 49), // bgBlackBright
  bgGrey(100, 49), // bgBlackBright
  faint(2, 22), // dim
  crossedout(9, 29), // strikethrough
  strikeThrough(9, 29), // strikethrough
  crossedOut(9, 29), // strikethrough
  conceal(8, 28), // hidden
  swapColors(7, 27), // inverse
  swapcolors(7, 27), // inverse
  doubleUnderline(21, 24) // doubleunderline
  // dart format off
  ; const TextStyle(this.open, this.close); // dart format on

  final int open;
  final int close;
}

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
String _escape(int code) => '$csi${code}m';

String styleText(String text, Iterable<TextStyle> styles) {
  if (text.isEmpty || styles.isEmpty) {
    return text;
  }

  final open = StringBuffer(),
      close = StringBuffer(),
      processedText = styles.fold(text, (text, style) {
        final escapedOpen = _escape(style.open),
            escapedClose = _escape(style.close),
            pattern = RegExp(RegExp.escape(escapedClose));

        open.write(escapedOpen);
        close.write(escapedClose);

        return text.replaceAllMapped(pattern, (match) {
          final matchedText = match.group(0)!;
          if (match.start + matchedText.length < text.length) {
            if (style.open == TextStyle.dim.open ||
                style.open == TextStyle.bold.open) {
              print(1);
              return '$matchedText$escapedOpen';
            }

            return escapedOpen;
          }

          return matchedText;
        });
      });

  return open.toString() + processedText + close.toString();
}
