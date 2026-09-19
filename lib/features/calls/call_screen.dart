import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/characters.dart';
import '../../core/notice.dart';
import '../../core/theme.dart';
import '../../engine/story_engine.dart';
import '../shell/widgets.dart';

/// A live phone call rendered as an animated transcript.
///
/// Script items are either lines `{"from": "ardis", "text": "..."}`, choices
/// `{"choice": [{"text", "goto"?, "effects"?, "default"?}], "timer"?: 12}`,
/// or `{"end": true}`. Lines advance on tap or automatically after a beat.
/// A choice with a `timer` that expires picks the option marked `default`
/// (else the last one) - the Episode 6 finale uses this to keep pressure on.
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key, required this.interaction});
  final CallInteraction interaction;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  bool _accepted = false;
  int _index = -1;
  final _shown = <Map<String, dynamic>>[];
  Timer? _auto;
  Timer? _choiceTimer;
  int _secondsLeft = 0;
  int _elapsed = 0;
  Timer? _clock;

  List<Map<String, dynamic>> get script => widget.interaction.script;
  String get contact => widget.interaction.contact;

  @override
  void initState() {
    super.initState();
    if (!widget.interaction.incoming) _accept();
  }

  void _accept() {
    setState(() => _accepted = true);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
    _advance();
  }

  void _advance({int? to}) {
    _auto?.cancel();
    _choiceTimer?.cancel();
    final next = to ?? _index + 1;
    if (next >= script.length) {
      _end();
      return;
    }
    final item = script[next];
    setState(() => _index = next);
    if (item['end'] == true) {
      _end();
      return;
    }
    if (item.containsKey('choice')) {
      final timer = item['timer'] as int?;
      if (timer != null) {
        _secondsLeft = timer;
        _choiceTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) return;
          setState(() => _secondsLeft--);
          if (_secondsLeft <= 0) {
            t.cancel();
            _pickDefault(item);
          }
        });
      }
      return;
    }
    setState(() => _shown.add(item));
    final text = item['text'] as String;
    final beat = 1.2 + (text.length / 45).clamp(0, 3.5);
    _auto = Timer(Duration(milliseconds: (beat * 1000).round()), _advance);
  }

  void _pickDefault(Map<String, dynamic> item) {
    final options = (item['choice'] as List).cast<Map<String, dynamic>>();
    final idx = options.indexWhere((o) => o['default'] == true);
    _choose(options, idx < 0 ? options.length - 1 : idx, timedOut: true);
  }

  void _choose(List<Map<String, dynamic>> options, int i, {bool timedOut = false}) {
    _choiceTimer?.cancel();
    final o = options[i];
    final engine = ref.read(storyEngineProvider.notifier);
    final effects = o['effects'] as Map<String, dynamic>?;
    if (effects != null) engine.applyEffects(effects);
    final spoken = timedOut ? '…' : (o['say'] as String? ?? o['text'] as String);
    setState(() => _shown.add({
          'from': 'player',
          'text': fillPlayer(spoken, ref.read(storyEngineProvider).game.playerName),
        }));
    final goto = o['goto'] as int?;
    _advance(to: goto);
  }

  void _end() {
    _auto?.cancel();
    _choiceTimer?.cancel();
    _clock?.cancel();
    // Let the last line land before the screen closes.
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      Navigator.of(context).maybePop();
      ref.read(storyEngineProvider.notifier).finishCall();
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _choiceTimer?.cancel();
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = characterOf(contact);
    final current = _index >= 0 && _index < script.length ? script[_index] : null;
    final choice = current != null && current.containsKey('choice')
        ? (current['choice'] as List).cast<Map<String, dynamic>>()
        : null;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (c.portrait != null)
              Image.asset(c.portrait!, fit: BoxFit.cover,
                  color: Colors.black.withValues(alpha: 0.72),
                  colorBlendMode: BlendMode.darken),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33000000), HmColors.bg],
                  stops: [0.2, 0.75],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  Avatar(contact, size: 96),
                  const SizedBox(height: 14),
                  Text(displayName(ref, contact),
                      style: displayStyle.copyWith(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(
                    !_accepted
                        ? 'incoming call'
                        : '${_elapsed ~/ 60}:${(_elapsed % 60).toString().padLeft(2, '0')}',
                    style: monoStyle.copyWith(color: HmColors.textDim),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _accepted
                        ? GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: choice == null ? _advance : null,
                            child: ListView.builder(
                              reverse: true,
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                              itemCount: _shown.length +
                                  (choice != null && current!['timer'] != null
                                      ? 1
                                      : 0),
                              itemBuilder: (context, i) {
                                final timed = choice != null &&
                                    current!['timer'] != null;
                                if (timed && i == 0) {
                                  return _TimerBar(
                                    secondsLeft: _secondsLeft,
                                    total: current['timer'] as int,
                                  );
                                }
                                final lineIndex =
                                    timed ? _shown.length - i : _shown.length - 1 - i;
                                return _Line(
                                  key: ValueKey(lineIndex),
                                  line: _shown[lineIndex],
                                  contact: contact,
                                );
                              },
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (!_accepted)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(40, 0, 40, 48),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _RoundButton(
                            color: HmColors.danger,
                            icon: Icons.call_end_rounded,
                            label: 'Decline',
                            onTap: () {
                              // Declining is not an option in the story; the caller
                              // simply rings back. Keep pressure without a fail state.
                              showAppNotice('They will only call again.');
                            },
                          ),
                          _RoundButton(
                            color: HmColors.ok,
                            icon: Icons.call_rounded,
                            label: 'Accept',
                            onTap: _accept,
                          ),
                        ],
                      ),
                    )
                  else if (choice != null)
                    Material(
                      color: HmColors.surface.withValues(alpha: 0.92),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: SafeArea(
                          top: false,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.sizeOf(context).height * 0.34,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10, left: 2),
                                    child: Text(
                                      current!['timer'] != null
                                          ? 'say something · $_secondsLeft'
                                          : 'Choose a reply',
                                      style: monoStyle.copyWith(
                                          fontSize: 11, color: HmColors.textDim),
                                    ),
                                  ),
                                  for (var i = 0; i < choice.length; i++)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: OutlinedButton(
                                        onPressed: () => _choose(choice, i),
                                        child: Text(
                                          fillPlayer(
                                              choice[i]['text'] as String,
                                              ref.read(storyEngineProvider).game.playerName),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: Text('tap to continue',
                          style: monoStyle.copyWith(fontSize: 11, color: HmColors.textDim)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends ConsumerWidget {
  const _Line({super.key, required this.line, required this.contact});
  final Map<String, dynamic> line;
  final String contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final from = line['from'] as String? ?? contact;
    final mine = from == 'player';
    final name = mine ? 'You' : displayName(ref, from);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(name.toUpperCase(),
              style: monoStyle.copyWith(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: mine ? HmColors.teal : HmColors.amber)),
          const SizedBox(height: 3),
          Text(fillPlayer(line['text'] as String, ref.watch(storyEngineProvider.select((s) => s.game.playerName))),
              textAlign: mine ? TextAlign.right : TextAlign.left,
              style: const TextStyle(fontSize: 17, height: 1.45)),
        ],
      ),
    );
  }
}

class _TimerBar extends StatelessWidget {
  const _TimerBar({required this.secondsLeft, required this.total});
  final int secondsLeft;
  final int total;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (secondsLeft / total).clamp(0, 1),
              color: secondsLeft <= 4 ? HmColors.danger : HmColors.amber,
              backgroundColor: HmColors.hairline,
            ),
            const SizedBox(height: 6),
            Text('say something · $secondsLeft',
                style: monoStyle.copyWith(fontSize: 11, color: HmColors.textDim)),
          ],
        ),
      );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: color,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 72,
                height: 72,
                child: Icon(icon, color: Colors.white, size: 32),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: HmColors.textDim)),
        ],
      );
}
