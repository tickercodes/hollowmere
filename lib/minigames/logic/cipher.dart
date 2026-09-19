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
