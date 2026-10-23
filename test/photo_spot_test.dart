import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hollowmere_files/core/theme.dart';
import 'package:hollowmere_files/engine/game_state.dart';
import 'package:hollowmere_files/engine/save_store.dart';
import 'package:hollowmere_files/engine/script.dart';
import 'package:hollowmere_files/engine/script_repository.dart';
import 'package:hollowmere_files/engine/story_engine.dart';
import 'package:hollowmere_files/minigames/photo_spot_game.dart';

void main() {
  testWidgets('finding a detail does not move the photo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final node = StoryNode('mg_dock', {
      'type': 'minigame',
      'game': 'photo_spot',
      'title': 'Marina, north dock - 11:31 PM',
      'config': {
        'photo': 'dock_night',
        'required': ['locker', 'siren', 'badge'],
      },
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scriptRepositoryProvider.overrideWithValue(ScriptRepository({})),
          saveStoreProvider.overrideWithValue(MemorySaveStore()),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: PhotoSpotGame(interaction: MinigameInteraction(node)),
        ),
      ),
    );
    await tester.pump();

    final frame = find.byKey(const ValueKey('photo-spot-frame'));
    final before = tester.getRect(frame);

    Future<void> findSpot(double dx, double dy) async {
      final rect = tester.getRect(frame);
      await tester.tapAt(
        rect.topLeft + Offset(rect.width * dx, rect.height * dy),
      );
      await tester.pump();
    }

    await findSpot(0.17, 0.29);
    expect(find.textContaining('Locker 14:'), findsOneWidget);
    expect(tester.getRect(frame), before);

    // The caption sits on the photo. A spot under that text still receives the tap.
    await findSpot(0.9, 0.84);
    expect(find.textContaining('Car reflection:'), findsOneWidget);
    expect(tester.getRect(frame), before);
    expect(find.text('Complete'), findsNothing);
  });

  testWidgets('a second visit with every spot already found can complete', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = MemorySaveStore();
    await store.save(
      GameState(
        flags: {
          'spot_inspection_report_stamp',
          'spot_inspection_report_signature',
        },
      ),
    );
    final node = StoryNode('mg_report', {
      'type': 'minigame',
      'game': 'photo_spot',
      'title': 'IMG_4471 - the original',
      'config': {
        'photo': 'inspection_report',
        'required': ['stamp', 'signature'],
      },
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scriptRepositoryProvider.overrideWithValue(ScriptRepository({})),
          saveStoreProvider.overrideWithValue(store),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: PhotoSpotGame(interaction: MinigameInteraction(node)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Complete'), findsOneWidget);
    expect(find.text('FAIL'), findsOneWidget);
    expect(find.text('Signature'), findsOneWidget);
  });
}
