import 'dart:async';

import 'package:flutter/material.dart';

import 'theme.dart';

enum AppNoticeTone { info, error, success }

class AppNotice {
  const AppNotice(
    this.message, {
    this.tone = AppNoticeTone.info,
    this.duration = const Duration(milliseconds: 1600),
  });

  final String message;
  final AppNoticeTone tone;
  final Duration duration;
}

final appNoticeListenable = ValueNotifier<AppNotice?>(null);

Timer? _hideNotice;

/// Thin top strip for snackbar-style info. Does not affect bottom sheets.
void showAppNotice(
  String message, {
  AppNoticeTone tone = AppNoticeTone.info,
  Duration? duration,
}) {
  _hideNotice?.cancel();
  final notice = AppNotice(
    message,
    tone: tone,
    duration: duration ??
        Duration(milliseconds: tone == AppNoticeTone.error ? 1400 : 1600),
  );
  appNoticeListenable.value = notice;
  _hideNotice = Timer(notice.duration, () {
    if (appNoticeListenable.value == notice) {
      appNoticeListenable.value = null;
    }
  });
}

/// Full-width strip just below the status bar.
class TopNoticeStrip extends StatelessWidget {
  const TopNoticeStrip({super.key});

  Color _color(AppNoticeTone? tone) => switch (tone) {
        AppNoticeTone.error => HmColors.danger,
        AppNoticeTone.success => HmColors.tealDim,
        AppNoticeTone.info || null => HmColors.surfaceRaised,
      };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppNotice?>(
      valueListenable: appNoticeListenable,
      builder: (context, notice, _) {
        final top = MediaQuery.paddingOf(context).top;
        return Positioned(
          top: top,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, if (current != null) current],
              ),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: notice == null
                  ? const SizedBox.shrink(key: ValueKey('off'))
                  : SizedBox(
                      key: ValueKey(notice.message),
                      width: double.infinity,
                      child: Material(
                        color: _color(notice.tone),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
                          child: Text(
                            notice.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                              color: HmColors.text,
                              decoration: TextDecoration.none,
                            ),
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
