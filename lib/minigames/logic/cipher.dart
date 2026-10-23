/// Helpers for the Messenger Decode puzzle and answer checking in general.
class Cipher {
  const Cipher._();

  /// Case/space/punctuation-insensitive comparison for typed answers.
  static String normalize(String s) =>
      s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static bool matches(String attempt, String answer) =>
      normalize(attempt) == normalize(answer);

  /// Encodes plaintext with a symbol map (letter -> symbol). Unknown letters
  /// pass through so authors can leave numbers readable.
  static String encode(String plain, Map<String, String> letterToSymbol) {
    final buf = StringBuffer();
    for (final ch in plain.toUpperCase().split('')) {
      buf.write(letterToSymbol[ch] ?? ch);
    }
    return buf.toString();
  }

  /// Caesar shift. Positive [shift] encodes (A+n); decode with `-n`.
  static String caesar(String text, int shift) {
    final buf = StringBuffer();
    for (final unit in text.codeUnits) {
      if (unit >= 65 && unit <= 90) {
        buf.writeCharCode(65 + _mod26(unit - 65 + shift));
      } else if (unit >= 97 && unit <= 122) {
        buf.writeCharCode(97 + _mod26(unit - 97 + shift));
      } else {
        buf.writeCharCode(unit);
      }
    }
    return buf.toString();
  }

  static int _mod26(int n) => ((n % 26) + 26) % 26;

  /// Repeating-key cipher. [key] cycles across the letters.
  /// Decode with [encode] false.
  static String vigenere(String text, String key, {bool encode = false}) {
    final k = key.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    if (k.isEmpty) return text;
    final buf = StringBuffer();
    var ki = 0;
    for (final unit in text.codeUnits) {
      final base = unit >= 65 && unit <= 90
          ? 65
          : unit >= 97 && unit <= 122
              ? 97
              : null;
      if (base == null) {
        buf.writeCharCode(unit);
        continue;
      }
      final shift = k.codeUnitAt(ki % k.length) - 65;
      buf.writeCharCode(base + _mod26(unit - base + (encode ? shift : -shift)));
      ki++;
    }
    return buf.toString();
  }

  /// Decodes using symbol -> letter. Emoji are multi-code-unit, so we walk
  /// by grapheme via [Runes] joining, matching the longest symbol first.
  static String decode(String cipher, Map<String, String> symbolToLetter) {
    final symbols = symbolToLetter.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final buf = StringBuffer();
    var i = 0;
    while (i < cipher.length) {
      String? hit;
      for (final s in symbols) {
        if (cipher.startsWith(s, i)) {
          hit = s;
          break;
        }
      }
      if (hit != null) {
        buf.write(symbolToLetter[hit]);
        i += hit.length;
      } else {
        buf.write(cipher[i]);
        i++;
      }
    }
    return buf.toString();
  }
}
