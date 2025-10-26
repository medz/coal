// This ref https://github.com/fabiospampinato/fast-string-truncated-width
import 'dart:math' as math show max, min;

final _ansiPattern = RegExp(
  r'[\u001b\u009b]'
  r'[[()#;?]*'
  r'(?:[0-9]{1,4}(?:;[0-9]{0,4})*)?'
  r'[0-9A-ORZcf-nqry=><]'
  r'|'
  r'\u001b\]8;[^;]*;.*?(?:\u0007|\u001b\u005c)',
);
final _controlPattern = RegExp(r'[\x00-\x08\x0A-\x1F\x7F-\x9F]{1,1000}');
final _cjktWidePattern = RegExp(
  r'('
  r'?:(?![\uFF61-\uFF9F\uFF00-\uFFEF])'
  r'[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Hangul}\p{Script=Tangut}]'
  r'){1,1000}',
  unicode: true,
);
final _tabPattern = RegExp(r'\t{1,1000}');
final _emojiPattern = RegExp(
  r'[\u{1F1E6}-\u{1F1FF}]{2}'
  r'|'
  r'\u{1F3F4}[\u{E0061}-\u{E007A}]{2}'
  r'[\u{E0030}-\u{E0039}\u{E0061}-\u{E007A}]{1,3}'
  r'\u{E007F}'
  r'|'
  r'(?:\p{Emoji}\uFE0F\u20E3?|\p{Emoji_Modifier_Base}\p{Emoji_Modifier}?|\p{Emoji_Presentation})(?:\u200D(?:\p{Emoji_Modifier_Base}\p{Emoji_Modifier}?|\p{Emoji_Presentation}|\p{Emoji}\uFE0F\u20E3?))*',
  unicode: true,
);
final _latinPattern = RegExp(r'(?:[\x20-\x7E\xA0-\xFF](?!\uFE0F)){1,1000}');
final _modifierPattern = RegExp(r'\p{M}+', unicode: true);
final _surrogatePairPattern = RegExp(r'[\uD800-\uDBFF][\uDC00-\uDFFF]');

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
int _getCodePointLength(String input) {
  final Iterable(:length) = _surrogatePairPattern.allMatches(input);
  return input.length - length;
}

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
bool _isWideNotCjktNoEmmoji(int x) {
  return x == 0x231B ||
      x == 0x2329 ||
      x >= 0x2FF0 && x <= 0x2FFF ||
      x >= 0x3001 && x <= 0x303E ||
      x >= 0x3099 && x <= 0x30FF ||
      x >= 0x3105 && x <= 0x312F ||
      x >= 0x3131 && x <= 0x318E ||
      x >= 0x3190 && x <= 0x31E3 ||
      x >= 0x31EF && x <= 0x321E ||
      x >= 0x3220 && x <= 0x3247 ||
      x >= 0x3250 && x <= 0x4DBF ||
      x >= 0xFE10 && x <= 0xFE19 ||
      x >= 0xFE30 && x <= 0xFE52 ||
      x >= 0xFE54 && x <= 0xFE66 ||
      x >= 0xFE68 && x <= 0xFE6B ||
      x >= 0x1F200 && x <= 0x1F202 ||
      x >= 0x1F210 && x <= 0x1F23B ||
      x >= 0x1F240 && x <= 0x1F248 ||
      x >= 0x20000 && x <= 0x2FFFD ||
      x >= 0x30000 && x <= 0x3FFFD;
}

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
bool _isFullWidth(int x) {
  return x == 0x3000 ||
      x >= 0xFF01 && x <= 0xFF60 ||
      x >= 0xFFE0 && x <= 0xFFE6;
}

extension on String {
  String safeSubstring(int start, [int? end]) {
    final clampedStart = start < 0
        ? (length + start).clamp(0, length)
        : start.clamp(0, length);
    final clampedEnd = end == null
        ? length
        : (end < 0 ? (length + end).clamp(0, length) : end.clamp(0, length));
    final actualStart = clampedStart.clamp(0, clampedEnd);
    if (actualStart >= clampedEnd) return '';
    return substring(actualStart, clampedEnd);
  }

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  int safeCodeUnitAt(int index) {
    try {
      return codeUnitAt(index);
    } catch (_) {
      return 0;
    }
  }
}

extension on num {
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  int safeFloor() {
    try {
      return floor();
    } catch (_) {
      return 0;
    }
  }
}

({num width, int index, bool truncated, bool ellipsed}) getTextTruncatedWidth(
  String input, {
  /*------------- Truncation ----------------*/
  num limit = double.infinity,
  String ellipsis = '',
  num? ellipsisWidth,
  /*------------- Special Width ----------------*/
  num controlWidth = 0,
  num tabWidth = 8,
  /*------------- Other Width ----------------*/
  num emojiWidth = 2,
  num regularWidth = 1,
  num? wideWidth,
}) {
  ellipsisWidth ??= ellipsis.isNotEmpty
      ? getTextTruncatedWidth(
          ellipsis,
          controlWidth: controlWidth,
          tabWidth: tabWidth,
          emojiWidth: emojiWidth,
          regularWidth: regularWidth,
          wideWidth: wideWidth,
        ).width
      : 0;
  const ansiWidth = 0, fullWideWidth = 2;
  wideWidth ??= fullWideWidth;

  final blocks = [
    (_latinPattern, regularWidth),
    (_ansiPattern, ansiWidth),
    (_controlPattern, controlWidth),
    (_tabPattern, tabWidth),
    (_emojiPattern, emojiWidth),
    (_cjktWidePattern, wideWidth),
  ];
  int indexPrev = 0,
      index = 0,
      length = input.length,
      lengthExtra = 0,
      unmatchedStart = 0,
      unmatchedEnd = 0,
      truncationIndex = length;
  num truncationLimit = math.max(0, limit - ellipsisWidth),
      width = 0,
      widthExtra = 0;
  bool truncationEnabled = false;

  parser:
  while (true) {
    if (unmatchedEnd > unmatchedStart ||
        (index >= length && index > indexPrev)) {
      String unmatched = input.safeSubstring(unmatchedStart, unmatchedEnd);
      if (unmatched.isEmpty) unmatched = input.safeSubstring(indexPrev, index);

      lengthExtra = 0;
      for (final char in unmatched.replaceAll(_modifierPattern, '').split('')) {
        final charCode = char.safeCodeUnitAt(0);
        // dart format off
        // ignore: curly_braces_in_flow_control_structures
        if (_isFullWidth(charCode)) widthExtra = fullWideWidth;
        // ignore: curly_braces_in_flow_control_structures
        else if (_isWideNotCjktNoEmmoji(charCode)) widthExtra = wideWidth;
        // ignore: curly_braces_in_flow_control_structures
        else widthExtra = regularWidth;
        // dart format on
        if ((width + widthExtra) > truncationLimit) {
          truncationIndex = math.min(
            truncationIndex,
            math.max(unmatchedStart, indexPrev) + lengthExtra,
          );
        }

        if ((width + widthExtra) > limit) {
          truncationEnabled = true;
          break parser;
        }

        lengthExtra += char.length;
        width += widthExtra;
      }

      unmatchedStart = unmatchedEnd = 0;
    }

    if (index >= length) break parser;
    for (final (blockPattern, blockWidth) in blocks) {
      if (blockPattern.matchAsPrefix(input, index) case final Match match) {
        lengthExtra = blockPattern == _cjktWidePattern
            ? _getCodePointLength(input.safeSubstring(index, match.end))
            : blockPattern == _emojiPattern
            ? 1
            : match.end - index;
        widthExtra = lengthExtra * blockWidth;

        if ((width + widthExtra) > truncationLimit) {
          truncationIndex = math.min(
            truncationIndex,
            index + ((truncationLimit - width) / blockWidth).safeFloor(),
          );
        }

        if ((width + widthExtra) > limit) {
          truncationEnabled = true;
          break parser;
        }

        width += widthExtra;
        unmatchedStart = indexPrev;
        unmatchedEnd = index;
        index = indexPrev = match.end;

        continue parser;
      }
    }

    index += 1;
  }

  return (
    width: (truncationEnabled ? truncationLimit : width),
    index: truncationEnabled ? truncationIndex : length,
    truncated: truncationEnabled,
    ellipsed: truncationEnabled && limit >= ellipsisWidth,
  );
}

num getTextWidth(
  String input, {
  /*------------- Special Width ----------------*/
  num controlWidth = 0,
  num tabWidth = 8,
  /*------------- Other Width ----------------*/
  num emojiWidth = 2,
  num regularWidth = 1,
  num? wideWidth,
}) {
  final result = getTextTruncatedWidth(
    input,
    limit: double.infinity,
    ellipsis: r'',
    ellipsisWidth: 0,
    controlWidth: controlWidth,
    tabWidth: tabWidth,
    emojiWidth: emojiWidth,
    regularWidth: regularWidth,
    wideWidth: wideWidth,
  );
  return result.width;
}
