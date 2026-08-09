import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_storage/secure_storage.dart';

void main() {
  group('SilentSecureStorageLogger', () {
    test('swallows every level', () {
      const logger = SilentSecureStorageLogger();

      expect(() {
        logger
          ..d('debug')
          ..i('info')
          ..w('warn')
          ..e('error', error: Exception('boom'));
      }, returnsNormally);
    });

    test('is const constructible so it can be a default', () {
      expect(
        identical(
          const SilentSecureStorageLogger(),
          const SilentSecureStorageLogger(),
        ),
        isTrue,
      );
    });
  });

  group('DebugPrintSecureStorageLogger', () {
    late List<String> printed;
    late DebugPrintCallback originalDebugPrint;

    setUp(() {
      printed = [];
      originalDebugPrint = debugPrint;
      debugPrint = (message, {wrapWidth}) {
        if (message != null) printed.add(message);
      };
    });

    tearDown(() => debugPrint = originalDebugPrint);

    test('tags every message with the package name and level', () {
      const DebugPrintSecureStorageLogger()
        ..d('opening box')
        ..i('stored')
        ..w('unsupported on web');

      expect(printed, hasLength(3));
      expect(printed[0], '[secure_storage] DEBUG opening box');
      expect(printed[1], '[secure_storage] INFO  stored');
      expect(printed[2], '[secure_storage] WARN  unsupported on web');
    });

    test('appends the cause to an error message', () {
      const DebugPrintSecureStorageLogger().e('failed', error: 'disk full');

      expect(printed.single, '[secure_storage] ERROR failed => disk full');
    });

    test('omits the arrow when there is no cause', () {
      const DebugPrintSecureStorageLogger().e('failed');

      expect(printed.single, '[secure_storage] ERROR failed');
    });
  });
}
