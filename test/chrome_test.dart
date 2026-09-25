import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hollowmere_files/core/theme.dart';
import 'package:hollowmere_files/core/whisper.dart';
import 'package:hollowmere_files/features/shell/widgets.dart';

void main() {
  testWidgets('app bars with subtitles do not overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: const AppScaffold(
        title: 'Messages',
        subtitle: "Wren's phone · mirrored · a long subtitle",
        body: SizedBox.expand(),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('text is not the debug yellow-underline style', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      builder: (context, child) => DefaultTextStyle(
        style: const TextStyle(
          inherit: false,
          color: HmColors.text,
          fontSize: 15,
          decoration: TextDecoration.none,
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      home: const AppScaffold(
        title: 'Gallery',
        subtitle: '40 items synced',
        body: Center(child: Text('body copy')),
      ),
    ));
    await tester.pump();

    final paragraphs = tester.renderObjectList<RenderParagraph>(find.byType(RichText));
    expect(paragraphs, isNotEmpty);
    for (final p in paragraphs) {
      final style = p.text.style;
      expect(style?.decoration, isNot(TextDecoration.underline));
      expect(style?.decorationColor, isNot(const Color(0xFFFFFF00)));
    }
  });

  test('fillPlayer substitutes the player name', () {
    expect(fillPlayer('This is {player}. Wren\'s friend.', 'Sam'),
        "This is Sam. Wren's friend.");
    expect(fillPlayer('already filled', 'Sam'), 'already filled');
  });

  testWidgets('scene overlay fade does not put Positioned inside FadeTransition', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: const Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Colors.black),
          Positioned.fill(child: _SafeSwitcher()),
        ],
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.takeException(), isNull);
    expect(find.text('Your front door.'), findsOneWidget);
  });

  testWidgets('whisper overlay shows a leaked caption', (tester) async {
    addTearDown(() => whisperListenable.value = null);
    await tester.pumpWidget(const MaterialApp(
      home: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Colors.black),
          WhisperOverlay(),
        ],
      ),
    ));
    expect(find.text('still up?'), findsNothing);
    whisperListenable.value = const WhisperEvent('still up?');
    await tester.pumpAndSettle();
    expect(find.text('still up?'), findsOneWidget);
  });
}

class _SafeSwitcher extends StatelessWidget {
  const _SafeSwitcher();

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: const SizedBox.expand(
        key: ValueKey('scene'),
        child: Material(
          color: Colors.transparent,
          child: Center(child: Text('Your front door.')),
        ),
      ),
    );
  }
}
