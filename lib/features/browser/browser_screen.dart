import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/browser_pages.dart';
import '../../content/photos.dart';
import '../../core/theme.dart';
import '../../engine/story_engine.dart';
import '../../l10n/l10n.dart';
import '../shell/phone_shell.dart';
import '../shell/widgets.dart';

/// The in-game web: a search box over the fake index, result list, and a
/// reader view. Wren's mirrored search history seeds the first queries.
class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({super.key, this.initialPage});
  final String? initialPage;

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  final _query = TextEditingController();
  String? _page;
  List<WebPage> _results = const [];
  final _history = <String>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storyEngineProvider.notifier).report({'app': 'browser'});
      if (widget.initialPage != null) _openPage(widget.initialPage!);
    });
  }

  void _search([String? q]) {
    final text = q ?? _query.text;
    if (q != null) _query.text = q;
    final discovered = ref.read(storyEngineProvider).game.pages;
    setState(() {
      _page = null;
      _results = searchPages(text, discovered);
    });
    FocusScope.of(context).unfocus();
  }

  void _openPage(String id) {
    final engine = ref.read(storyEngineProvider.notifier);
    if (!engine.game.pages.contains(id)) {
      engine.applyEffects({'pages': [id]});
    }
    setState(() {
      if (_page != null) _history.add(_page!);
      _page = id;
    });
    engine.report({'app': 'browser', 'page': id});
  }

  void _back() {
    setState(() => _page = _history.isEmpty ? null : _history.removeLast());
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(storyEngineProvider.select((s) => s.game));
    final page = _page == null ? null : webPages[_page!];
    final searchHistory = [
      for (final n in game.notes)
        if (n.id.startsWith('search_')) n.body
    ];

    return AppScaffold(
      title: 'Browser',
      leading: page != null
          ? IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: _back)
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: TextField(
              controller: _query,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              style: const TextStyle(
                fontSize: 15,
                color: HmColors.text,
                decoration: TextDecoration.none,
              ),
              decoration: InputDecoration(
                hintText: page?.url ?? context.tr('Search or type a term'),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    onPressed: _search),
                filled: true,
                fillColor: HmColors.surfaceRaised,
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: page != null
                ? _Reader(page: page, onLink: _openPage)
                : _results.isNotEmpty || _query.text.isNotEmpty
                    ? _Results(results: _results, onOpen: _openPage, query: _query.text)
                    : _Start(
                        history: searchHistory,
                        visited: [for (final id in game.pages) if (webPages[id] != null) webPages[id]!],
                        onSearch: _search,
                        onOpen: _openPage,
                      ),
          ),
        ],
      ),
    );
  }
}

class _Start extends StatelessWidget {
  const _Start({
    required this.history,
    required this.visited,
    required this.onSearch,
    required this.onOpen,
  });
  final List<String> history;
  final List<WebPage> visited;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (history.isNotEmpty) ...[
            const SectionLabel("Wren's recent searches · mirrored"),
            for (final h in history)
              ListTile(
                dense: true,
                leading: const Icon(Icons.history_rounded, size: 18, color: HmColors.textDim),
                title: Text(context.tr(h), style: monoStyle),
                onTap: () => onSearch(h),
              ),
          ],
          if (visited.isNotEmpty) ...[
            const SectionLabel('Pages you have opened'),
            for (final p in visited)
              ListTile(
                dense: true,
                leading: const Icon(Icons.public_rounded, size: 18, color: HmColors.teal),
                title: Text(context.tr(p.title), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(p.url,
                    style: monoStyle.copyWith(fontSize: 11, color: HmColors.textDim)),
                onTap: () => onOpen(p.id),
              ),
          ],
          if (history.isEmpty && visited.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: EmptyHint('Search for a name, a place, a year.', icon: Icons.explore_rounded),
            ),
        ],
      );
}

class _Results extends StatelessWidget {
  const _Results({required this.results, required this.onOpen, required this.query});
  final List<WebPage> results;
  final ValueChanged<String> onOpen;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return EmptyHint(context.fmt('No results for "{query}".\nTry fewer or different words.', {'query': query}));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: results.length,
      itemBuilder: (context, i) {
        final p = results[i];
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          onTap: () => onOpen(p.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr(p.site), style: monoStyle.copyWith(fontSize: 11, color: HmColors.teal)),
              const SizedBox(height: 4),
              Text(context.tr(p.title), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(context.tr(p.body.first).replaceFirst(RegExp(r'^# '), ''),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: HmColors.textDim, fontSize: 13)),
            ],
          ),
        );
      },
    );
  }
}

class _Reader extends StatelessWidget {
  const _Reader({required this.page, required this.onLink});
  final WebPage page;
  final ValueChanged<String> onLink;

  @override
  Widget build(BuildContext context) {
    final image = page.image == null ? null : photoOf(page.image!);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        Text(context.tr(page.site).toUpperCase(),
            style: monoStyle.copyWith(fontSize: 11, color: HmColors.teal, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text(context.tr(page.title), style: displayStyle.copyWith(fontSize: 22, letterSpacing: 0.2)),
        const SizedBox(height: 4),
        Text(page.url, style: monoStyle.copyWith(fontSize: 11, color: HmColors.textDim)),
        const Divider(height: 28),
        if (image != null) ...[
          GestureDetector(
            onTap: () => openApp('gallery', arguments: image.id),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                  aspectRatio: image.aspect, child: Image.asset(image.asset, fit: BoxFit.cover)),
            ),
          ),
          const SizedBox(height: 16),
        ],
        for (final para in page.body)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: para.startsWith('# ')
                ? Text(context.tr(para).replaceFirst(RegExp(r'^# '), ''),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))
                : Text(context.tr(para), style: const TextStyle(fontSize: 15.5, height: 1.55)),
          ),
        if (page.links.isNotEmpty) ...[
          const Divider(height: 28),
          const SectionLabel('Related'),
          for (final l in page.links)
            if (webPages[l] != null)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.link_rounded, size: 18, color: HmColors.teal),
                title: Text(context.tr(webPages[l]!.title),
                    style: const TextStyle(color: HmColors.teal)),
                onTap: () => onLink(l),
              ),
        ],
      ],
    );
  }
}
