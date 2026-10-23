import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'theme.dart';

/// A leaked caption that appears when an interstitial voice plays.
class WhisperEvent {
  const WhisperEvent(this.caption);
  final String caption;
}

final whisperListenable = ValueNotifier<WhisperEvent?>(null);

/// Faint italic line over the phone — the backup leaking someone else's voice.
class WhisperOverlay extends StatelessWidget {
  const WhisperOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WhisperEvent?>(
      valueListenable: whisperListenable,
      builder: (context, event, _) {
        final bottom = MediaQuery.paddingOf(context).bottom;
        return Positioned(
          left: 20,
          right: 20,
          bottom: bottom + 28,
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: event == null
                  ? const SizedBox.shrink(key: ValueKey('whisper-off'))
                  : DecoratedBox(
                      key: ValueKey(event.caption),
                      decoration: BoxDecoration(
                        color: HmColors.bg.withValues(alpha: 0.72),
                        border: Border.all(color: HmColors.hairline.withValues(alpha: 0.7)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        child: Text(
                          context.tr(event.caption),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            fontStyle: FontStyle.italic,
                            color: HmColors.teal,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
