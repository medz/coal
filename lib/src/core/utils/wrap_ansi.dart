// This ref https://github.com/43081j/fast-wrap-ansi/blob/main/src/main.ts
import "package:unorm_dart/unorm_dart.dart" show nfc;
import 'package:characters/characters.dart';

import '../../_constants.dart';
import 'text_width.dart';

const _endCode = 39;
const _ansiEscapeBell = '\u0007';
const _ansiCSI = '[';
const _ansiOSC = ']';
const _ansiSGRTerminator = 'm';
const _ansiEscapeLink = '${_ansiOSC}8;;';
final _groupRegex = RegExp(
  '(?:\\$_ansiCSI(?<code>\\d+)m|\\$_ansiEscapeLink(?<uri>.*)$_ansiEscapeBell)',
);
final _crlfOrLf = RegExp(r'\r?\n');

int? _getClosingCode(num openingCode) {
  return switch (openingCode) {
    >= 30 && <= 37 => 39,
    >= 90 && <= 97 => 39,
    >= 40 && <= 47 => 49,
    >= 100 && <= 107 => 49,
    0 => 0,
    1 => 22,
    2 => 22,
    3 => 23,
    4 => 24,
    7 => 27,
    8 => 28,
    9 => 29,
    _ => null,
  };
}

String _wrapAnsiCode(int code) => '$esc$_ansiCSI$code$_ansiSGRTerminator';
String _wrapAnsiHyperlink(String url) =>
    '$esc$_ansiEscapeLink$url$_ansiEscapeBell';

void _wrapWord(List<String> rows, String word, int columns) {
  final chars = word.characters.iterator;
  var isInsideEscape = false,
      isInsideLinkEscape = false,
      lastRow = rows.lastOrNull,
      visible = lastRow == null ? 0 : getTextWidth(lastRow),
      character = chars.moveNext() ? chars.current : null,
      nextCharacter = chars.moveNext() ? chars.current : null,
      rawCharacterIndex = 0;
  while (character != null) {
    final characterLength = getTextWidth(character);
    if (visible + characterLength <= columns) {
      rows.last += character;
    } else {
      rows.add(character);
      visible = 0;
    }

    if (character == esc || character == csiSb) {
      isInsideEscape = true;
      isInsideLinkEscape = word.startsWith(
        _ansiEscapeLink,
        rawCharacterIndex + 1,
      );
    }

    if (isInsideEscape) {
      if (isInsideLinkEscape) {
        if (character == _ansiEscapeBell) {
          isInsideEscape = false;
          isInsideLinkEscape = false;
        }
      } else if (character == _ansiSGRTerminator) {
        isInsideEscape = false;
      }
    } else {
      visible += characterLength;
      if (visible == columns && nextCharacter != null) {
        rows.add('');
        visible = 0;
      }
    }

    rawCharacterIndex += character.length;
    character = nextCharacter;
    nextCharacter = chars.moveNext() ? chars.current : null;
  }

  lastRow = rows.lastOrNull;
  if (visible == 0 &&
      lastRow != null &&
      lastRow.isNotEmpty &&
      rows.isNotEmpty) {
    rows[rows.length - 2] += rows.removeLast();
  }
}

String _textVisibleTrimSpacesRight(String text) {
  final words = text.split(' '), length = words.length;
  int last = length;
  while (last > 0) {
    if (getTextWidth(words[last - 1]) > 0) {
      break;
    }
    last--;
  }

  if (last == length) return text;
  return words.sublist(0, last).join(' ') + words.sublist(last).join();
}

String _exec(
  String text,
  int columns, {
  bool? trim,
  bool? wordWrap,
  bool? hard,
}) {
  if (trim != false && text.trim() == '') {
    return '';
  }

  final result = StringBuffer();
  int? escapeCode;
  String? escapeUrl;

  final words = text.split(' ');
  List<String> rows = [''];
  num rowLength = 0;

  for (int index = 0; index < words.length; index++) {
    final word = words[index];
    if (trim != false) {
      final row = rows.lastOrNull ?? '', trimmed = row.trimLeft();
      if (row.length != trimmed.length) {
        rows.last = trimmed;
        rowLength = getTextWidth(trimmed);
      }
    }

    if (index != 0) {
      if (rowLength >= columns && (wordWrap == false || trim == false)) {
        rows.add('');
        rowLength = 0;
      }

      if (rowLength != 0 || trim == false) {
        rows.last += ' ';
        rowLength++;
      }
    }

    final wordLength = getTextWidth(word);
    if (hard == true && wordLength > columns) {
      final remainingColumns = columns - rowLength,
          breaksStartingThisLine =
              1 + ((wordLength - remainingColumns - 1) / columns).floor(),
          breaksStartingNextLine = ((wordLength - 1) / columns).floor();
      if (breaksStartingNextLine < breaksStartingThisLine) {
        rows.add('');
      }

      _wrapWord(rows, word, columns);
      rowLength = getTextWidth(rows.lastOrNull ?? '');
      continue;
    }

    if (rowLength + wordLength > columns && rowLength > 0 && wordLength > 0) {
      if (wordWrap == false && rowLength < columns) {
        _wrapWord(rows, word, columns);
        rowLength = getTextWidth(rows.lastOrNull ?? '');
        continue;
      }

      rows.add('');
      rowLength = 0;
    }

    if (rowLength + wordLength > columns && wordWrap == false) {
      _wrapWord(rows, word, columns);
      rowLength = getTextWidth(rows.lastOrNull ?? '');
      continue;
    }

    rows.last += word;
    rowLength += wordLength;
  }

  if (trim != false) {
    rows = [...rows.map((row) => _textVisibleTrimSpacesRight(row))];
  }

  final preString = rows.join('\n');
  final chars = preString.characters;
  final charList = chars.toList();
  var codeUnitIndex = 0;

  for (int i = 0; i < charList.length; i++) {
    final character = charList[i];
    result.write(character);

    // Check for escape sequences using the first code unit
    final firstCodeUnit = character.isEmpty ? null : character[0];
    if (firstCodeUnit == esc || firstCodeUnit == csiSb) {
      final match = _groupRegex.firstMatch(
        preString.substring(codeUnitIndex + 1),
      );
      if (match != null) {
        if (match.namedGroup('code') case final String code) {
          final parsedCode = int.tryParse(code);
          escapeCode = parsedCode == _endCode ? null : parsedCode;
        } else if (match.namedGroup('uri') case final String uri) {
          escapeUrl = uri.isEmpty ? null : uri;
        }
      }
    }

    final nextCharacter = i + 1 < charList.length ? charList[i + 1] : null;

    if (nextCharacter == '\n') {
      if (escapeUrl?.isNotEmpty == true) {
        result.write(_wrapAnsiHyperlink(''));
      }

      final closingCode = escapeCode != null && escapeCode != 0
          ? _getClosingCode(escapeCode)
          : null;
      if (escapeCode != null &&
          escapeCode != 0 &&
          closingCode != null &&
          closingCode != 0) {
        result.write(_wrapAnsiCode(closingCode));
      }
    } else if (character == '\n') {
      if (escapeCode != null &&
          escapeCode != 0 &&
          _getClosingCode(escapeCode) != 0) {
        result.write(_wrapAnsiCode(escapeCode));
      }

      if (escapeUrl != null && escapeUrl.isNotEmpty == true) {
        result.write(_wrapAnsiHyperlink(escapeUrl));
      }
    }

    codeUnitIndex += character.length;
  }

  return result.toString();
}

String wrapAnsi(
  String text,
  int columns, {
  bool? trim,
  bool? wordWrap,
  bool? hard,
}) {
  String exec(String text) =>
      _exec(text, columns, trim: trim, wordWrap: wordWrap, hard: hard);
  return nfc(text).split(_crlfOrLf).map(exec).join('\n');
}
