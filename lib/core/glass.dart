import 'dart:ui';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'theme.dart';

const _glassRadius = 28.0;
const _sheetRadius = 28.0;

/// Frosted panel used by dialogs and sheets.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(_glassRadius)),
  });

  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.82),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: const Color(0xF20A0C0E),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: const Color(0xCC050A0C),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, _, _) => Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Material(
              type: MaterialType.transparency,
              child: builder(context),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class GlassDialogFrame extends StatelessWidget {
  const GlassDialogFrame({
    super.key,
    required this.title,
    required this.child,
    this.kicker,
    this.actions = const [],
  });

  final String? kicker;
  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (kicker != null) ...[
                Text(
                  context.tr(kicker!).toUpperCase(),
                  style: monoStyle.copyWith(
                    color: HmColors.teal,
                    fontSize: 11,
                    letterSpacing: 2.6,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(context.tr(title), style: displayStyle.copyWith(fontSize: 26, letterSpacing: 1.1)),
              const SizedBox(height: 14),
              child,
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 22),
                ...actions,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool?> showGlassConfirm({
  required BuildContext context,
  required String title,
  required String body,
  String cancelLabel = 'Cancel',
  String confirmLabel = 'Confirm',
  bool destructive = false,
  String? kicker,
}) {
  return showGlassDialog<bool>(
    context: context,
    builder: (c) => GlassDialogFrame(
      kicker: kicker,
      title: title,
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(c.tr(cancelLabel)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                style: destructive
                    ? FilledButton.styleFrom(
                        backgroundColor: HmColors.danger,
                        foregroundColor: HmColors.text,
                      )
                    : null,
                onPressed: () => Navigator.pop(c, true),
                child: Text(c.tr(confirmLabel)),
              ),
            ),
          ],
        ),
      ],
      child: Text(
        c.tr(body),
        style: const TextStyle(color: HmColors.textDim, height: 1.5, fontSize: 15),
      ),
    ),
  );
}

Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xCC050A0C),
    isScrollControlled: true,
    builder: (c) {
      final media = MediaQuery.of(c);
      final maxHeight = (media.size.height - media.viewInsets.bottom) * 0.86;
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: GlassPanel(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(_sheetRadius)),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(child: builder(c)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Opening prompt for a new investigation.
Future<String?> showPlayerNameDialog(BuildContext context) {
  return showGlassDialog<String>(
    context: context,
    builder: (c) => const _PlayerNameDialog(),
  );
}

class _PlayerNameDialog extends StatefulWidget {
  const _PlayerNameDialog();

  @override
  State<_PlayerNameDialog> createState() => _PlayerNameDialogState();
}

class _PlayerNameDialogState extends State<_PlayerNameDialog> {
  late final _controller = TextEditingController(text: 'John');
  late final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    Navigator.pop(context, name.isEmpty ? 'John' : name);
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialogFrame(
      kicker: 'New investigation',
      title: 'Your name',
      actions: [
        FilledButton(
          onPressed: _submit,
            child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(context.tr('Begin')),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('How Wren has you saved. Fourteen characters. You can keep John.'),
            style: const TextStyle(color: HmColors.textDim, height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            maxLength: 14,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
            style: const TextStyle(
              color: HmColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              decoration: TextDecoration.none,
            ),
            cursorColor: HmColors.teal,
            decoration: InputDecoration(
              hintText: 'John',
              counterStyle: monoStyle.copyWith(fontSize: 10, color: HmColors.textDim),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.28),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: HmColors.teal, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
