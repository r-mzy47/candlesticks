import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUpAll(() async {
    final fontFile = File('test/fonts/Roboto-Regular.ttf');

    if (!fontFile.existsSync()) {
      throw Exception(
        'Missing test font: test/fonts/Roboto-Regular.ttf\n'
        'Add a .ttf font file there, then run the test again.',
      );
    }

    final fontBytes = fontFile.readAsBytesSync();
    final fontLoader = FontLoader('Roboto')
      ..addFont(
        Future.value(
          ByteData.view(Uint8List.fromList(fontBytes).buffer),
        ),
      );

    await fontLoader.load();
  });

  await testMain();
}
