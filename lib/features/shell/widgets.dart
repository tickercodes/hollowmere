import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/characters.dart';
import '../../core/theme.dart';
import '../../engine/story_engine.dart';
import '../../l10n/l10n.dart';

/// Substitutes `{player}` in script copy. Safe to call on already-filled text.
String fillPlayer(String text, String playerName) =>
    text.replaceAll('{player}', playerName);

/// Contact display name honouring per-save overrides (unknown numbers etc.).
String displayName(WidgetRef ref, String characterId) {
  ref.watch(localeProvider);
  final names = ref.watch(storyEngineProvider.select((s) => s.game.contactNames));
  final c = characterOf(characterId);
  return L10nCatalog.lookup(names[characterId] ?? c.defaultLabel ?? c.name);
}

class Avatar extends ConsumerWidget {
  const Avatar(this.characterId, {super.key, this.size = 40, this.revealed});

  final String characterId;
  final double size;

  /// Force portrait visibility; defaults to "known contact" logic.
  final bool? revealed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = characterOf(characterId);
    final names = ref.watch(storyEngineProvider.select((s) => s.game.contactNames));
    final known = revealed ?? (c.defaultLabel == null || names.containsKey(characterId));
    ref.watch(localeProvider);
    final label = L10nCatalog.lookup(names[characterId] ?? c.defaultLabel ?? c.name);
    final monogram = label.isEmpty ? '?' : label.characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: HmColors.surfaceRaised,
        border: Border.all(color: HmColors.hairline),
        image: known && c.portrait != null
            ? DecorationImage(image: AssetImage(c.portrait!), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: known && c.portrait != null
          ? null
          : Text(monogram,
              style: TextStyle(
                  color: HmColors.textDim,
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w600)),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.accent = false,
    this.margin,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool accent;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: HmColors.surface.withValues(alpha: 0.92),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent ? HmColors.teal : HmColors.hairline),
      ),
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(
              onTap: onTap,
              child: Padding(padding: padding, child: child),
            ),
    );
    if (margin == null) return card;
    return Padding(padding: margin!, child: card);
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(context.tr(text).toUpperCase(),
            style: const TextStyle(
                color: HmColors.teal,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w600)),
      );
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color = HmColors.amber});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Text(context.tr(text),
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

/// Standard app chrome inside the phone.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: HmColors.bg,
          foregroundColor: HmColors.text,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
          flexibleSpace: const ColoredBox(color: HmColors.bg),
          leading: leading,
          toolbarHeight: subtitle == null ? kToolbarHeight : 68,
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr(title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: HmColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
              if (subtitle != null)
                Text(
                  context.tr(subtitle!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HmColors.textDim,
                    fontSize: 12,
                    decoration: TextDecoration.none,
                  ),
                ),
            ],
          ),
          actions: actions,
        ),
        body: body,
      );
}

class EmptyHint extends StatelessWidget {
  const EmptyHint(this.text, {super.key, this.icon = Icons.blur_on});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: HmColors.textDim, size: 40),
              const SizedBox(height: 12),
              Text(context.tr(text),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: HmColors.textDim)),
            ],
          ),
        ),
      );
}

/// Small outlined chip used by Skip / Next and minigame actions.
class ShellChipButton extends StatelessWidget {
  const ShellChipButton({super.key, required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: HmColors.surfaceRaised.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: HmColors.teal.withValues(alpha: 0.6)),
            ),
            child: Text(
              context.tr(label),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: HmColors.text,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

