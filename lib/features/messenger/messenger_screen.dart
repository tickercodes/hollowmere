import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/characters.dart';
import '../../content/photos.dart';
import '../../core/notice.dart';
import '../../core/theme.dart';
import '../../engine/game_state.dart';
import '../../engine/story_engine.dart';
import '../shell/phone_shell.dart';
import '../shell/widgets.dart';

/// Thread list, or a single thread when [initialThread] is given.
class MessengerScreen extends ConsumerStatefulWidget {
  const MessengerScreen({super.key, this.initialThread});
  final String? initialThread;

  @override
  ConsumerState<MessengerScreen> createState() => _MessengerScreenState();
}

class _MessengerScreenState extends ConsumerState<MessengerScreen> {
  String? _open;

  @override
  void initState() {
    super.initState();
    _open = widget.initialThread;
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportOpen());
  }

  void _reportOpen() {
    final engine = ref.read(storyEngineProvider.notifier);
    final t = _open;
    if (t != null) {
      engine.openThread(t);
      engine.report({'app': 'messages', 'thread': t});
    } else {
      engine.report({'app': 'messages'});
    }
  }

  void _select(String? thread) {
    setState(() => _open = thread);
    _reportOpen();
  }

  @override
  Widget build(BuildContext context) {
    final open = _open;
    if (open != null) {
      return ThreadView(thread: open, onBack: () => _select(null));
    }
    return _ThreadList(onOpen: _select);
  }
}

class _ThreadList extends ConsumerWidget {
  const _ThreadList({required this.onOpen});
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(storyEngineProvider.select((s) => s.game));
    final ids = game.threads.keys.toList()
      ..sort((a, b) {
        final ua = game.unreadThreads.contains(a) ? 0 : 1;
        final ub = game.unreadThreads.contains(b) ? 0 : 1;
        return ua != ub ? ua.compareTo(ub) : a.compareTo(b);
      });
    return AppScaffold(
      title: 'Messages',
      body: ids.isEmpty
          ? const EmptyHint('No conversations yet.')
          : ListView.separated(
              itemCount: ids.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (context, i) {
                final id = ids[i];
                final msgs = game.threads[id]!;
                final last = msgs.isEmpty ? null : msgs.last;
                final unread = game.unreadThreads.contains(id);
                final preview = last == null
                    ? ''
                    : last.image != null && last.text.isEmpty
                        ? 'Photo'
                        : fillPlayer(last.text, game.playerName);
                return ListTile(
                  onTap: () => onOpen(id),
                  leading: Avatar(id, size: 46),
                  title: Text(displayName(ref, id),
                      style: TextStyle(
                          fontWeight: unread ? FontWeight.w700 : FontWeight.w500)),
                  subtitle: Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: unread ? HmColors.text : HmColors.textDim),
                  ),
                  trailing: unread
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: HmColors.teal))
                      : null,
                );
              },
            ),
    );
  }
}

class ThreadView extends ConsumerWidget {
  const ThreadView({super.key, required this.thread, required this.onBack});
  final String thread;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(storyEngineProvider);
    final engine = ref.read(storyEngineProvider.notifier);
    final msgs = session.game.threads[thread] ?? const <ChatMessage>[];
    final it = session.interaction;
    final typing = it is TypingInteraction && it.thread == thread;
    final choice = it is ChoiceInteraction && it.thread == thread ? it : null;

    final c = characterOf(thread);
    final portrait = c.portrait;
    return AppScaffold(
      title: displayName(ref, thread),
      subtitle: c.subtitle.isEmpty ? null : c.subtitle,
      leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: onBack),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Avatar(thread, size: 36),
        ),
      ],
      body: Column(
        children: [
          Expanded(
            // reverse: newest at offset 0 so a new bubble grows under the
            // last line in the same layout pass — no post-frame jumpTo.
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: HmColors.bg),
                if (portrait != null)
                  IgnorePointer(
                    child: Opacity(
                      opacity: 0.22,
                      child: Image.asset(
                        portrait,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.25),
                      ),
                    ),
                  ),
                ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  itemCount: msgs.length + (typing ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (typing && i == 0) return const _TypingBubble();
                    final msgIndex = typing ? msgs.length - i : msgs.length - 1 - i;
                    final m = msgs[msgIndex];
                    final showTail = msgIndex == msgs.length - 1 ||
                        msgs[msgIndex + 1].from != m.from;
                    return _Bubble(
                      key: ValueKey(m.id),
                      thread: thread,
                      message: m,
                      tail: showTail,
                    );
                  },
                ),
              ],
            ),
          ),
          if (choice != null)
            _ChoiceBar(choice: choice, engine: engine, playerName: session.game.playerName)
          else
            _Composer(thread: thread, typing: typing),
        ],
      ),
    );
  }
}

class _Bubble extends ConsumerWidget {
  const _Bubble({
    super.key,
    required this.thread,
    required this.message,
    required this.tail,
  });
  final String thread;
  final ChatMessage message;
  final bool tail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = message.isPlayer;
    final playerName = ref.watch(storyEngineProvider.select((s) => s.game.playerName));
    final body = fillPlayer(message.text, playerName);
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(mine || !tail ? 18 : 4),
      bottomRight: Radius.circular(!mine || !tail ? 18 : 4),
    );
    final color = message.saved
        ? HmColors.teal.withValues(alpha: 0.18)
        : message.deleted
            ? HmColors.glitchMagenta.withValues(alpha: 0.12)
            : message.vanishing
                ? HmColors.glitchCyan.withValues(alpha: 0.12)
                : mine
                    ? HmColors.bubbleOut
                    : HmColors.bubbleIn;
    final photo = message.image == null ? null : photoOf(message.image!);
    final holdable = message.vanishing || message.deleted;

    return Padding(
      padding: EdgeInsets.only(
        top: 2,
        bottom: tail ? 12 : 3,
        left: mine ? 28 : 0,
        right: mine ? 0 : 28,
      ),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          child: GestureDetector(
            onLongPress: holdable
                ? () {
                    final engine = ref.read(storyEngineProvider.notifier);
                    final ok = engine.saveVanishing(thread, message.id);
                    final remain = GameState.ghostSaveCap -
                        engine.game.ghostsSavedThisEpisode;
                    showAppNotice(ok
                        ? 'Saved. $remain left this episode.'
                        : message.saved
                            ? 'Already saved.'
                            : 'You can only save five vanishing messages per episode.');
                  }
                : null,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: radius,
                border: message.vanishing || message.deleted
                    ? Border.all(
                        color: message.saved
                            ? HmColors.teal
                            : HmColors.glitchMagenta.withValues(alpha: 0.5))
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (photo != null)
                    GestureDetector(
                      onTap: () => openApp('gallery', arguments: photo.id),
                      child: AspectRatio(
                        aspectRatio: photo.aspect,
                        child: Image.asset(photo.asset, fit: BoxFit.cover),
                      ),
                    ),
                  if (body.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Text(
                        body,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: message.deleted && !message.saved
                              ? HmColors.textDim
                              : HmColors.text,
                          decoration: message.deleted && !message.saved
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: HmColors.glitchMagenta,
                        ),
                      ),
                    ),
                  if (message.vanishing && !message.saved)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                      child: Text('hold to save  ·  ${GameState.ghostSaveCap - ref.watch(storyEngineProvider.select((s) => s.game.ghostsSavedThisEpisode))} left',
                          style: monoStyle.copyWith(
                              fontSize: 10, color: HmColors.glitchCyan)),
                    ),
                  if (message.saved)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                      child: Text('saved from the mirror',
                          style: monoStyle.copyWith(
                              fontSize: 10, color: HmColors.teal)),
                    )
                  else if (message.deleted)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                      child: Text('message unavailable · hold to save',
                          style: monoStyle.copyWith(
                              fontSize: 10, color: HmColors.glitchMagenta)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: HmColors.bubbleIn,
            borderRadius: BorderRadius.circular(18),
          ),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: HmColors.textDim.withValues(
                          alpha: 0.35 +
                              0.65 *
                                  ((1 + (_ctrl.value * 3 - i).clamp(-1, 1)) / 2)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceBar extends StatelessWidget {
  const _ChoiceBar({
    required this.choice,
    required this.engine,
    required this.playerName,
  });
  final ChoiceInteraction choice;
  final StoryEngine engine;
  final String playerName;

  @override
  Widget build(BuildContext context) {
    final visible = engine.visibleOptions(choice);
    final prompt = choice.node['prompt'] as String?;
    return Material(
      color: HmColors.surface,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        decoration: const BoxDecoration(
          color: HmColors.surface,
          border: Border(top: BorderSide(color: HmColors.hairline)),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.36,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, left: 2),
                    child: Text(
                      prompt ?? 'Choose a reply',
                      style: monoStyle.copyWith(
                          fontSize: 11, color: HmColors.textDim, letterSpacing: 0.6),
                    ),
                  ),
                  for (final i in visible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OptionButton(
                        text: fillPlayer(
                            choice.node.options[i]['text'] as String, playerName),
                        tag: choice.node.options[i]['tag'] as String?,
                        onTap: () => engine.choose(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({required this.text, required this.onTap, this.tag});
  final String text;
  final String? tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: HmColors.bubbleOut.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HmColors.teal.withValues(alpha: 0.45)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(text,
                      style: const TextStyle(fontSize: 15, height: 1.35)),
                ),
                if (tag != null) ...[
                  const SizedBox(width: 8),
                  Pill(tag!, color: HmColors.textDim),
                ],
              ],
            ),
          ),
        ),
      );
}

class _Composer extends StatelessWidget {
  const _Composer({required this.thread, required this.typing});
  final String thread;
  final bool typing;

  @override
  Widget build(BuildContext context) {
    final hint = typing
        ? 'tap anywhere to skip'
        : thread == 'wren'
            ? 'Your last message was never read'
            : 'Waiting…';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: const BoxDecoration(
        color: HmColors.surface,
        border: Border(top: BorderSide(color: HmColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: HmColors.surfaceRaised,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: HmColors.hairline),
          ),
          child: Text(hint,
              style: monoStyle.copyWith(fontSize: 12, color: HmColors.textDim)),
        ),
      ),
    );
  }
}
