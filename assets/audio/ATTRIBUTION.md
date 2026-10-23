# Audio credits

Music and radio static are downloaded from the public internet
(`python3 tools/fetch_audio.py`). Synthesized UI beeps, placeholder
voicemails, and story whispers come from `tools/build_audio.py`.

## Music

| In-game | Track | Author | License | Source |
|---|---|---|---|---|
| `music_menu` | Solo Piano 4 | Tozan | CC0 | https://opengameart.org/content/solo-piano-4 |
| `music_play` | Piano Horror | Francisco Alvear | Mixkit License | https://mixkit.co/free-stock-music/tag/mystery/ |
| `music_scene` | GoshtPiano2 | Kilua Boy | CC0 | https://opengameart.org/content/dark-environment-horror-games |
| `music_echoes` | Echoes | Andrew Ev | Mixkit License | https://mixkit.co/free-stock-music/tag/mystery/ |

The previous bed, *Lost in a bad place* by congusbongus (CC0 drone loop),
was removed.

## Voices

Spoken interstitials are **canon lines** from the scripts, rendered with the
same macOS `say` voices as the placeholder voicemails
(`python3 tools/build_audio.py --whispers`). They play only when a story node
sets `"voice"`, at the beat where that line is already in play.

| In-game | Line | Who, in-story |
|---|---|---|
| `voice_still_up` | still up? | Wren's last message |
| `voice_found_it` | I found it. | Wren's 47-second recording |
| `voice_here` | Someone's here. | Wren's 47-second recording |
| `voice_hearing` | If you're hearing this | Wren's first voice memo |
| `voice_stop` | Stop looking. | The hidden-number / Warden voicemail |
| `voice_alive` | She's alive if you stop. | The hidden-number / Warden voicemail |
| `voice_marina` | Stay away from the marina. | Jonah's voicemail |
| `voice_quiet` | Don't tell anyone. | Deacon's voicemail |

Radio texture only (no words):

| In-game | Line | Author | License | Source |
|---|---|---|---|---|
| `voice_radio` | Terror radio frequency (trimmed) | Mixkit | Mixkit License | https://mixkit.co/free-sound-effects/horror/ |
| `voice_static` | Broken radio frequency signal | Mixkit | Mixkit License | https://mixkit.co/free-sound-effects/horror/ |

Mixkit terms: https://mixkit.co/license/ (commercial use allowed; attribution optional).
CC0: public domain dedication, credit not required.
