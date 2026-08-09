import 'package:flutter_test/flutter_test.dart';
import 'package:secure_storage/secure_storage.dart';

void main() {
  group('exception to failure mapping', () {
    final cases = <String, (AppException, Type)>{
      'HiveWriteException': (HiveWriteException(), HiveWriteFailure),
      'HiveWipeException': (HiveWipeException(), HiveWipeFailure),
      'HiveReadException': (HiveReadException(), HiveReadFailure),
      'HiveOpenBoxException': (HiveOpenBoxException(), OpenFailure),
      'HiveCloseBoxException': (HiveCloseBoxException(), CloseFailure),
      'HiveDeleteBoxException': (
        HiveDeleteBoxException(),
        HiveDeleteBoxFailure,
      ),
      'HiveDeleteDataException': (
        HiveDeleteDataException(),
        HiveDeleteDataFailure,
      ),
      'HiveBoxNotEmptyException': (
        HiveBoxNotEmptyException(),
        HiveBoxNotEmptyFailure,
      ),
      'BoxEncryptedException': (BoxEncryptedException(), BoxEncryptedFailure),
      'DataDoesNotExistException': (
        DataDoesNotExistException(),
        DataDoesNotExistFailure,
      ),
      'FSSWriteException': (FSSWriteException(), FSSWriteFailure),
      'FSSReadException': (FSSReadException(), FSSReadFailure),
      'FSSNotFoundException': (FSSNotFoundException(), FSSNotFoundFailure),
      'FSSDeleteException': (FSSDeleteException(), FSSDeleteFailure),
      'UnhandledException': (UnhandledException(), UnhandledFailure),
    };

    for (final entry in cases.entries) {
      final name = entry.key;
      final (exception, expectedFailure) = entry.value;
      test(
        '$name maps to $expectedFailure carrying prefix, code and message',
        () {
          final failure = exception.toFailure();
          expect(failure.runtimeType, expectedFailure);
          expect(failure.message, exception.message);
          if (expectedFailure != UnhandledFailure) {
            expect(failure.prefix, exception.prefix);
            expect(failure.code, exception.code);
          }
        },
      );
    }

    test('every hive exception carries the HIVE prefix', () {
      expect(HiveWriteException().prefix, 'HIVE');
      expect(HiveDeleteBoxException().prefix, 'HIVE');
    });

    test('every flutter secure storage exception carries the FSS prefix', () {
      expect(FSSWriteException().prefix, 'FLUTTER SECURE STORAGE');
      expect(FSSDeleteException().prefix, 'FLUTTER SECURE STORAGE');
    });

    test('exception codes are unique within the hive prefix', () {
      final codes = <AppException>[
        HiveWriteException(),
        HiveWipeException(),
        HiveReadException(),
        HiveOpenBoxException(),
        HiveCloseBoxException(),
        HiveDeleteBoxException(),
        HiveDeleteDataException(),
        HiveBoxNotEmptyException(),
        BoxEncryptedException(),
      ].map((e) => e.code).toList();
      expect(codes.toSet(), hasLength(codes.length));
    });
  });

  group('Failure', () {
    test('updateMessage keeps the type, prefix and code', () {
      const original = HiveWriteFailure(
        prefix: 'HIVE',
        code: '001',
        message: 'original',
      );
      final updated = original.updateMessage(message: 'localised');

      expect(updated, isA<HiveWriteFailure>());
      expect(updated.prefix, 'HIVE');
      expect(updated.code, '001');
      expect(updated.message, 'localised');
    });

    test('compares by value', () {
      expect(
        const FSSReadFailure(prefix: 'A', code: '1', message: 'm'),
        const FSSReadFailure(prefix: 'A', code: '1', message: 'm'),
      );
      expect(
        const FSSReadFailure(prefix: 'A', code: '1', message: 'm'),
        isNot(const FSSReadFailure(prefix: 'A', code: '2', message: 'm')),
      );
    });

    test('renders as prefix-code: message', () {
      expect(
        const OpenFailure(
          prefix: 'HIVE',
          code: '004',
          message: 'nope',
        ).toString(),
        'HIVE-004: nope',
      );
    });
  });

  group('AppException', () {
    test('renders as prefix-code: message', () {
      expect(
        DataDoesNotExistException().toString(),
        'SECURE STORAGE-001: Data does not exist.',
      );
    });

    test('accepts an overridden message', () {
      final exception = HiveReadException(message: 'custom');
      expect(exception.message, 'custom');
      expect(exception.toFailure().message, 'custom');
    });

    test('UnhandledException wraps arbitrary error text', () {
      final failure = UnhandledException(message: 'boom').toFailure();
      expect(failure, isA<UnhandledFailure>());
      expect(failure.message, 'boom');
      expect(failure.prefix, 'UNHANDLED');
    });

    test('UnhandledFailure.updateMessage returns an UnhandledFailure', () {
      const failure = UnhandledFailure(message: 'a');
      expect(failure.updateMessage(message: 'b').message, 'b');
      expect(failure.updateMessage(message: 'b'), isA<UnhandledFailure>());
    });
  });
}
