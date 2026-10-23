import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hollowmere_files/l10n/l10n.dart';

void main() {
  late Map<String, String> es;
  late Map<String, String> pt;

  setUp(() {
    es = _load('assets/l10n/es.json');
    pt = _load('assets/l10n/pt_BR.json');
    L10nCatalog.debugReset();
  });

  tearDown(L10nCatalog.debugReset);

  test('Spanish and Brazilian Portuguese cover the same lines', () {
    expect(es.keys.toSet(), pt.keys.toSet());
    expect(es.length, greaterThan(1000));
    for (final key in es.keys) {
      expect(_slots(es[key]!), _slots(key), reason: key);
      expect(_slots(pt[key]!), _slots(key), reason: key);
    }
  });

  test('English stays the source copy', () {
    L10nCatalog.language = AppLanguage.en;
    expect(
      L10nCatalog.lookup('still up? come by, I\'ll leave the door open'),
      "still up? come by, I'll leave the door open",
    );
  });

  test('a saved line with the player name still translates', () {
    L10nCatalog.debugLoad(AppLanguage.es, es);
    L10nCatalog.language = AppLanguage.es;
    expect(
      L10nCatalog.lookup(
        'Hello John. This is Ardis Locke. I\'m so sorry to write so late. I saw your light on when I drove past.',
        playerName: 'John',
      ),
      es['Hello {player}. This is Ardis Locke. I\'m so sorry to write so late. I saw your light on when I drove past.'],
    );
  });

  test('journal patterns translate the name and the puzzle title', () {
    L10nCatalog.debugLoad(AppLanguage.ptBR, pt);
    L10nCatalog.language = AppLanguage.ptBR;
    expect(
      L10nCatalog.lookup('You accused Mara Ellison.'),
      'Você acusou Mara Ellison.',
    );
    expect(
      L10nCatalog.lookup('Skipped a puzzle: Wren\'s passcode.'),
      pt['Skipped a puzzle: {title}.']!.replaceAll(
        '{title}',
        pt["Wren's passcode"]!,
      ),
    );
    expect(
      L10nCatalog.lookup('Shaded cells read: 1986'),
      'As casas sombreadas dizem: 1986',
    );
  });

  test('the cipher stays in English and the cheat sheet keeps its letters', () {
    final decoded =
        es['LOCKER 14 IF I GO QUIET. She planned for going quiet.']!;
    expect(decoded, contains('LOCKER 14 IF I GO QUIET'));
    expect(decoded, isNot(contains('TAQUILLA')));
    const sheet =
        "here's the cheat sheet she gave me: 🌊=L 🔑=O 🌙=E 🌧=R 🦉=U 🐟=I. the rest you'd have to guess";
    for (final pair in ['🌊=L', '🔑=O', '🌙=E', '🌧=R', '🦉=U', '🐟=I']) {
      expect(es[sheet], contains(pair));
      expect(pt[sheet], contains(pair));
    }
    expect(
      es['"I_ I _O" - two short words. She is giving Tess an instruction.'],
      contains('I_ I _O'),
    );
  });

  test('menus, the phone, and the story each have a translation', () {
    const samples = [
      'Messages',
      'Calls',
      'Case Board',
      'A FOUND-PHONE MYSTERY',
      'THE\nHOLLOWMERE\nFILES',
      'Radio Silence',
      'still up? come by, I\'ll leave the door open',
      'THE WARDEN',
      "She's alive if you stop.",
      'You accused {name}.',
      "This phone is getting files from Wren's phone. Photos: {photos} synced. Messages: {threads} threads. Calls: {calls} entries.",
    ];
    for (final sample in samples) {
      expect(es[sample], isNotNull, reason: sample);
      expect(pt[sample], isNotNull, reason: sample);
      expect(es[sample], isNot(sample), reason: sample);
    }
    expect(es['THE WARDEN'], 'EL GUARDIÁN');
    expect(pt['THE WARDEN'], 'O GUARDIÃO');
    expect(es['Messages'], 'Mensajes');
    expect(pt['Messages'], 'Mensagens');
    expect(es['Case Board'], 'Tablero del caso');
    expect(pt['Case Board'], 'Quadro do caso');
  });
}

Map<String, String> _load(String path) {
  final raw = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return raw.map((k, v) => MapEntry(k, v as String));
}

Set<String> _slots(String value) =>
    RegExp(r'\{[a-zA-Z_]+\}').allMatches(value).map((m) => m.group(0)!).toSet();
