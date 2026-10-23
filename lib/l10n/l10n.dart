import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Player-facing languages. English is the source copy; the others are
/// overlays keyed by that exact English string.
enum AppLanguage {
  en('en', 'English', Locale('en')),
  es('es', 'Español', Locale('es')),
  ptBR('pt_BR', 'Português (Brasil)', Locale('pt', 'BR'));

  const AppLanguage(this.code, this.label, this.locale);

  final String code;

  /// Name shown in the language picker, in that language.
  final String label;
  final Locale locale;

  static AppLanguage fromCode(String? code) {
    for (final lang in values) {
      if (lang.code == code) return lang;
    }
    return AppLanguage.en;
  }
}

/// In-memory catalogs. English is identity, so a missing key always falls
/// back to the authored string.
class L10nCatalog {
  L10nCatalog._();

  static AppLanguage language = AppLanguage.en;
  static final Map<String, Map<String, String>> _tables = {};

  static Future<void> loadAssets(
    Future<String> Function(String asset) load,
  ) async {
    for (final lang in AppLanguage.values) {
      if (lang == AppLanguage.en) continue;
      final raw = jsonDecode(
        await load('assets/l10n/${lang.code}.json'),
      ) as Map<String, dynamic>;
      _tables[lang.code] = raw.map((k, v) => MapEntry(k, v as String));
    }
  }

  /// Visible only to tests.
  static void debugLoad(AppLanguage lang, Map<String, String> table) {
    _tables[lang.code] = table;
  }

  static void debugReset() {
    language = AppLanguage.en;
    _tables.clear();
  }

  /// Returns the translation of [source], or [source] when this language has
  /// no entry. When [playerName] is set, a saved line that already has the
  /// name filled in is matched back to its `{player}` template.
  static String lookup(String source, {String? playerName}) {
    if (source.isEmpty || language == AppLanguage.en) return source;
    final table = _tables[language.code];
    if (table == null || table.isEmpty) return source;
    final direct = table[source];
    if (direct != null) return direct;
    if (playerName != null &&
        playerName.length >= 2 &&
        source.contains(playerName)) {
      final key = source.replaceAll(playerName, '{player}');
      final hit = table[key];
      if (hit != null) return hit;
    }
    return _pattern(source, table) ?? source;
  }

  /// Journal lines built in code: "You accused Mara Ellison."
  static String? _pattern(String source, Map<String, String> table) {
    String? fill(String template, String slot, String value) {
      final tmpl = table[template];
      if (tmpl == null) return null;
      return tmpl.replaceAll(slot, table[value] ?? value);
    }

    final accused = RegExp(r'^You accused (.+)\.$').firstMatch(source);
    if (accused != null) {
      return fill('You accused {name}.', '{name}', accused.group(1)!);
    }
    final skipped = RegExp(r'^Skipped a puzzle: (.+)\.$').firstMatch(source);
    if (skipped != null) {
      return fill('Skipped a puzzle: {title}.', '{title}', skipped.group(1)!);
    }
    final shaded = RegExp(r'^Shaded cells read: (.+)$').firstMatch(source);
    if (shaded != null) {
      final tmpl = table['Shaded cells read: {code}'];
      if (tmpl == null) return null;
      return tmpl.replaceAll('{code}', shaded.group(1)!);
    }
    return null;
  }

  /// Translates [template] then substitutes `{name}` style slots. Slot values
  /// are translated on their own when they are known English copy.
  static String format(String template, Map<String, Object?> vars) {
    var out = lookup(template);
    for (final entry in vars.entries) {
      final raw = entry.value?.toString() ?? '';
      out = out.replaceAll('{${entry.key}}', lookup(raw));
    }
    return out;
  }
}

class L10nScope extends InheritedWidget {
  const L10nScope({super.key, required this.language, required super.child});

  final AppLanguage language;

  static AppLanguage of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<L10nScope>();
    return scope?.language ?? L10nCatalog.language;
  }

  @override
  bool updateShouldNotify(L10nScope oldWidget) =>
      language != oldWidget.language;
}

extension L10nContext on BuildContext {
  /// Subscribes this widget to language changes and returns the translation.
  String tr(String source, {String? playerName}) {
    L10nScope.of(this);
    final looked = L10nCatalog.lookup(source, playerName: playerName);
    if (playerName == null) return looked;
    return looked.replaceAll('{player}', playerName);
  }

  String fmt(String template, Map<String, Object?> vars, {String? playerName}) {
    L10nScope.of(this);
    final out = L10nCatalog.format(template, vars);
    if (playerName == null) return out;
    return out.replaceAll('{player}', playerName);
  }
}

/// Persists the language separately from the story save so a reset does not
/// forget it.
class LocaleController extends Notifier<AppLanguage> {
  static const prefKey = 'hollowmere.locale.v1';

  @override
  AppLanguage build() => L10nCatalog.language;

  Future<void> setLanguage(AppLanguage lang) async {
    L10nCatalog.language = lang;
    state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKey, lang.code);
  }
}

final localeProvider = NotifierProvider<LocaleController, AppLanguage>(
  LocaleController.new,
);

/// Restores the saved language before the first frame.
Future<void> restoreLanguage(SharedPreferences prefs) async {
  final lang = AppLanguage.fromCode(prefs.getString(LocaleController.prefKey));
  L10nCatalog.language = lang;
}
