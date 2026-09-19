import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hollowmere_files/app.dart';
import 'package:hollowmere_files/engine/save_store.dart';
import 'package:hollowmere_files/engine/script_repository.dart';
import 'package:hollowmere_files/engine/story_engine.dart';
import 'package:hollowmere_files/features/shell/phone_shell.dart';
import 'package:integration_test/integration_test.dart';

/// Plays the real app on a device through the opening of Episode 1 and into
/// Episode 2, capturing screenshots of every signature screen. Run with:
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/screens_test.dart -d `<device>`
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture signature screens', (tester) async {
    final scripts = await ScriptRepository.loadFromAssets();
    final container = ProviderContainer(overrides: [
      scriptRepositoryProvider.overrideWithValue(scripts),
      saveStoreProvider.overrideWithValue(MemorySaveStore()),
    ]);
    addTearDown(container.dispose);
    final engine = container.read(storyEngineProvider.notifier);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const HollowmereApp(),
    ));
    await tester.pump(const Duration(milliseconds: 900));
    await _shot(binding, tester, '01_menu');

    Interaction it() => container.read(storyEngineProvider).interaction;

    /// Pumps real time until [done] is true, skipping typing waits.
    Future<void> until(bool Function(Interaction) done, {int maxTicks = 400}) async {
      for (var i = 0; i < maxTicks; i++) {
        if (done(it())) return;
        final cur = it();
        if (cur is TypingInteraction || cur is IdleInteraction) engine.skip();
        await tester.pump(const Duration(milliseconds: 250));
      }
      fail('Timed out waiting; interaction is ${it().runtimeType}');
    }

    Future<void> settle() async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
    }

    void popToHome() => shellNavigatorKey.currentState?.popUntil((r) => r.isFirst);

    // ---------------------------------------------------------------- Ep 1
    engine.newGame(playerName: 'Sam');
    await until((i) => i is TitleInteraction);
    await settle();
    await _shot(binding, tester, '02_cold_open_title');
    engine.dismissOverlay();

    await until((i) => i is ChoiceInteraction);
    openApp('messages', arguments: 'wren');
    await settle();
    await _shot(binding, tester, '03_cold_open_chat_choice');
    engine.choose(1);

    await until((i) => i is ChoiceInteraction);
    engine.choose(0);
    await until((i) => i is SceneInteraction);
    await settle();
    await _shot(binding, tester, '04_never_read');
    engine.dismissOverlay();
    await until((i) => i is TitleInteraction);
    engine.dismissOverlay();

    // Present day: notification + goal to open the gallery.
    await until((i) => i is GoalInteraction);
    popToHome();
    await tester.pump(const Duration(milliseconds: 600));
    await _shot(binding, tester, '05_home_mirror_notification');
    openApp('gallery');
    await settle();
    await _shot(binding, tester, '06_wrens_library');
    engine.report({'app': 'gallery', 'photo': 'sams_street'});
    await until((i) => i is SceneInteraction);
    await settle();
    await _shot(binding, tester, '07_scene_ferry_street');
    engine.dismissOverlay();

    // Dock photo -> photo spot minigame (auto-pushed by the shell).
    await until((i) => i is GoalInteraction);
    engine.report({'app': 'gallery', 'photo': 'dock_night'});
    await until((i) => i is MinigameInteraction);
    await tester.pump(const Duration(milliseconds: 700));
    await _shot(binding, tester, '08_minigame_photo_spot');
    engine.completeMinigame();
    popToHome();

    // Call log.
    await until((i) => i is GoalInteraction);
    openApp('calls');
    await settle();
    await _shot(binding, tester, '09_call_log');
    engine.report({'app': 'calls'});
    await until((i) => i is SceneInteraction);
    engine.dismissOverlay();

    // Mara's first message -> choice with moral weight.
    await until((i) => i is ChoiceInteraction);
    openApp('messages', arguments: 'mara');
    await settle();
    await _shot(binding, tester, '10_mara_choice');
    engine.choose(0);

    // News push -> board goal.
    await until((i) => i is GoalInteraction);
    openApp('board');
    await settle();
    await _shot(binding, tester, '11_case_board_first_pin');
    engine.report({'app': 'board'});
    await until((i) => i is SceneInteraction);
    engine.dismissOverlay();
    await until((i) => i is SceneInteraction);
    engine.dismissOverlay();

    // Passcode.
    await until((i) => i is GoalInteraction);
    engine.report({'app': 'gallery', 'photo': 'birthday_cake'});
    await until((i) => i is MinigameInteraction);
    await tester.pump(const Duration(milliseconds: 700));
    await _shot(binding, tester, '12_minigame_passcode');
    engine.completeMinigame();
    popToHome();

    // J. thread.
    await until((i) => i is GoalInteraction);
    openApp('messages', arguments: 'j_mirror');
    await settle();
    await _shot(binding, tester, '13_mirrored_thread_j');
    engine.report({'app': 'messages', 'thread': 'j_mirror'});
    await until((i) => i is SceneInteraction);
    engine.dismissOverlay();

    // Ardis.
    await until((i) => i is ChoiceInteraction);
    openApp('messages', arguments: 'ardis');
    await settle();
    await _shot(binding, tester, '14_ardis_first_contact');
    engine.choose(2);

    // Recording -> audio forensics.
    await until((i) => i is GoalInteraction);
    engine.report({'app': 'calls', 'voicemail': 'vm_wren_47s'});
    await until((i) => i is MinigameInteraction);
    await tester.pump(const Duration(milliseconds: 900));
    await _shot(binding, tester, '15_minigame_audio_forensics');
    engine.completeMinigame();
    popToHome();
    await until((i) => i is SceneInteraction);
    await settle();
    await _shot(binding, tester, '16_scene_recording');
    engine.dismissOverlay();

    // Glitch + ghost message, then title card + episode end.
    await until((i) => i is SceneInteraction);
    openApp('messages', arguments: 'wren');
    await settle();
    await _shot(binding, tester, '17_ghost_message_struck');
    engine.dismissOverlay();
    await until((i) => i is TitleInteraction);
    await settle();
    await _shot(binding, tester, '18_episode1_title_card');
    engine.dismissOverlay();
    await until((i) => i is EpisodeEndInteraction);
    await settle();
    await _shot(binding, tester, '19_episode_end');
    engine.dismissOverlay();

    // ---------------------------------------------------------------- Ep 2
    await until((i) => i is TitleInteraction);
    engine.dismissOverlay();
    await until((i) => i is ChoiceInteraction);
    engine.choose(2);
    await until((i) => i is GoalInteraction);
    engine.report({'app': 'messages', 'thread': 'tess'});
    await until((i) => i is MinigameInteraction);
    await tester.pump(const Duration(milliseconds: 800));
    await _shot(binding, tester, '20_minigame_cipher');
    engine.completeMinigame();
    popToHome();

    // Browser goals.
    await until((i) => i is GoalInteraction);
    openApp('browser', arguments: 'locker_rental');
    await settle();
    await _shot(binding, tester, '21_browser_page');
    engine.report({'app': 'browser', 'page': 'locker_rental'});
    await until((i) => i is SceneInteraction);
    engine.dismissOverlay();
    await until((i) => i is GoalInteraction);
    engine.report({'app': 'browser', 'page': 'courier_2006_runaway'});
    await until((i) => i is SceneInteraction);
    engine.dismissOverlay();

    // Jonah text + call.
    await until((i) => i is ChoiceInteraction);
    engine.choose(1);
    await until((i) => i is ChoiceInteraction);
    engine.choose(0);
    await until((i) => i is CallInteraction);
    await tester.pump(const Duration(milliseconds: 2500));
    await _shot(binding, tester, '22_incoming_call_jonah');
    engine.finishCall();
    popToHome();

    // Marina scene -> sudoku.
    await until((i) => i is SceneInteraction);
    await settle();
    await _shot(binding, tester, '23_scene_marina');
    engine.dismissOverlay();
    await until((i) => i is MinigameInteraction);
    await tester.pump(const Duration(milliseconds: 900));
    await _shot(binding, tester, '24_minigame_sudoku_grid');
    engine.completeMinigame();
    popToHome();

    // Evidence + journal apps for completeness.
    openApp('evidence');
    await settle();
    await _shot(binding, tester, '25_evidence_folder');
    openApp('journal');
    await settle();
    await _shot(binding, tester, '26_journal');
    popToHome();
  }, timeout: Timeout.none);
}

Future<void> _shot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await tester.pump(const Duration(milliseconds: 200));
  await binding.takeScreenshot(name);
}
