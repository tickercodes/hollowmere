import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Host-side driver: receives screenshots from the on-device test and writes
/// them to docs/screens so the visual draft lives with the story bible.
Future<void> main() => integrationDriver(
      onScreenshot: (name, bytes, [args]) async {
        final file = File('docs/screens/$name.png');
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(bytes);
        return true;
      },
    );
