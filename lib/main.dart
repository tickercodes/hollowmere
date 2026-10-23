import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'engine/save_store.dart';
import 'engine/script_repository.dart';
import 'engine/story_engine.dart';
import 'l10n/l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  final results = await Future.wait([
    ScriptRepository.loadFromAssets(),
    PrefsSaveStore.open(),
  ]);
  await restoreLanguage(await SharedPreferences.getInstance());
  await L10nCatalog.loadAssets(rootBundle.loadString);

  runApp(ProviderScope(
    overrides: [
      scriptRepositoryProvider.overrideWithValue(results[0] as ScriptRepository),
      saveStoreProvider.overrideWithValue(results[1] as SaveStore),
    ],
    child: const HollowmereApp(),
  ));
}
