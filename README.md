# The Hollowmere Files

A found-phone interactive mystery, built in Flutter.

Eleven days after Wren Calloway vanished, her phone starts copying itself onto yours. You are not a detective. You are the last person she texted. Every notification you get, someone else might be getting too.

The game is played as a phone: messages, calls, a gallery, notes, a town feed, a case board. Story is driven by JSON episode scripts. Headphones help. You never have to wait in real time.

Package name: `hollowmere_files` · version `0.1.0`

---

## Play

You are Sam (name is yours to change). Wren left an unread message. Her cloud backup is pairing with your device. Over six episodes you read, listen, dig through photos, and decide who to trust.

**On the home screen**

| App | What it is |
| --- | --- |
| Messages | Threads with Wren and the town. Some lines vanish unless you hold to save them. |
| Calls | Incoming calls, voicemails, voice memos. |
| Wren's Library | Photos that sync in as the backup catches up. |
| Browser | Hollowmere's public face: the dam, the town, the official story. |
| Cloud Backup | Pairing, sync events, the second viewer. |
| Notes | Wren's lists and the things she wanted to ask you. |
| Feed | Cached posts versus what still loads. |
| Case Board | Pins, connections, the accusation. |
| Evidence | What you have actually found. |
| Journal | Sam's running notes. |
| Settings | Typing speed, music, sound, erase progress. |

Progress is a single autosave slot. Resume from the menu, or jump back into completed episodes after you have finished them.

There are four endings. What you name, how much proof you have, and whether anyone stands with you all matter. The story bible in `docs/` is for authors; it contains spoilers.

---

## Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) with Dart SDK `^3.13.3`
- iOS Simulator, Android emulator, or a connected device

Portrait only.

```bash
flutter pub get
flutter test
flutter run
```

Useful targets:

```bash
flutter run -d ios
flutter run -d macos          # if you have desktop enabled
flutter analyze
python3 tools/fetch_audio.py   # licensed music + interstitial voices
```

---

## How it is put together

Story and UI are split on purpose. Episodes are data. The engine walks them. The phone is a shell that renders whatever the engine is waiting on.

```
lib/
  main.dart                 bootstrap, save, scripts, orientation
  app.dart                  menu / phone / ending
  engine/                   interpreter
    script.dart             JSON → graph, validation
    script_repository.dart  ep1–ep6 from assets
    reducer.dart            pure GameState transitions
    story_engine.dart       async walk, interactions, autosave
    game_state.dart         immutable snapshot
    save_store.dart         SharedPreferences, one slot
  features/                 phone apps and chrome
  minigames/                puzzle widgets + small solvers
  content/                  cast, photos, evidence, endings, voicemails
  core/                     theme, glass UI, audio, notices
assets/
  story/                    ep1.json … ep6.json
  img/                      portraits, locations, evidence, key art
  audio/                    licensed music/voices + synthesized SFX
                            (see assets/audio/ATTRIBUTION.md)
docs/story_bible.md         canon (spoilers)
test/                       graph checks, engine, playthroughs
```

`StoryEngine` applies a `Reducer` and pauses when the player is needed: a choice, a goal (“open this app / this photo”), a minigame, a call, a scene, an episode card. `GameState` is the only source of truth the UI reads.

---

## Episodes

Scripts live in `assets/story/`. If a script and the story bible disagree, the script wins.

| # | File | Title |
| - | ---- | ----- |
| 1 | `ep1.json` | Radio Silence |
| 2 | `ep2.json` | Dead Drop |
| 3 | `ep3.json` | The Old Town |
| 4 | `ep4.json` | Static |
| 5 | `ep5.json` | The Warden |
| 6 | `ep6.json` | Hollowmere |

A node is a typed step with an `id`, a `type`, and usually a `next`. Known types: `title`, `message`, `choice`, `notification`, `goal`, `minigame`, `call`, `scene`, `glitch`, `effects`, `branch`, `delay`, `end_episode`, `ending`.

Optional `voice` on a node plays one story line at that beat only. Unknown ids fail in `test/story_scripts_test.dart`.

Unknown types, broken edges, empty choices, and unknown minigame ids fail in tests, not mid-play.

Minigames the scripts may name: `passcode`, `photo_spot`, `order`, `cipher`, `sudoku`, `audio_tag`, `feed_scrub`, `board_connect`, `live_static`, `log_diff`, `voice_match`, `accuse`.

Static content (cast, photo catalog, evidence copy, voicemail transcripts, ending text) sits in `lib/content/` so scripts can refer to ids rather than paste prose twice.

---

## Tests

```bash
flutter test
```

| File | What it protects |
| --- | --- |
| `test/story_scripts_test.dart` | All six episodes load, validate, chain, and only reference real apps, games, photos, and endings. |
| `test/engine_test.dart` | Reducer and engine behaviour. |
| `test/playthrough_test.dart` | Headless runs of the real scripts under fake time; each ending is reachable. |
| `test/chrome_test.dart` | Shell / chrome widgets. |
| `test/audio_assets_test.dart` | Licensed music and voice files are present. |

Authoring a new beat: change JSON (and content tables if you add ids), then run `flutter test`. If the graph is wrong, the suite should say so before you play.

---

## Settings

- Typing speed from slow to instant; tap the screen to skip a typing indicator.
- Sound effects can be muted. Voicemails still play.
- Music intensity from off to high; the score ducks under a voicemail or voice.
- Mysterious voices can be muted separately. They only play at the story beat that owns that line.
- Back to menu keeps the save. Erase all progress wipes evidence, board, trust, and episode state.

---

## Authoring notes

Keep fair-play tells in the scripts themselves (messages, photos, logs). The bible is a map, not a second source of truth.

When you add a contact, photo, evidence item, ending, or interstitial voice, register it in `lib/content/` and use the same id from JSON. `test/story_scripts_test.dart` is the checklist for that contract.

Do not put secrets, tokens, or real-person data in assets. This is fiction.
