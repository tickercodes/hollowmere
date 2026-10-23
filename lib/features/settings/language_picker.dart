import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/glass.dart';
import '../../core/theme.dart';
import '../../l10n/l10n.dart';

Future<void> showLanguagePicker(BuildContext context, WidgetRef ref) {
  return showGlassSheet(
    context: context,
    builder: (c) => Consumer(
      builder: (context, ref, _) {
        final current = ref.watch(localeProvider);
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  context.tr('LANGUAGE'),
                  style: monoStyle.copyWith(
                    color: HmColors.teal,
                    letterSpacing: 2.4,
                    fontSize: 11,
                  ),
                ),
              ),
              for (final lang in AppLanguage.values)
                ListTile(
                  title: Text(lang.label),
                  trailing: lang == current
                      ? const Icon(Icons.check_rounded, color: HmColors.teal)
                      : null,
                  onTap: () async {
                    await ref.read(localeProvider.notifier).setLanguage(lang);
                    if (c.mounted) Navigator.pop(c);
                  },
                ),
            ],
          ),
        );
      },
    ),
  );
}
