import 'package:flutter_test/flutter_test.dart';
import 'package:secure_storage/secure_storage.dart';

void main() {
  const prefix = 'PREFIX';
  const code = '123';

  final failures = <Failure>[
    const HiveWriteFailure(prefix: prefix, code: code, message: 'a'),
    const HiveWipeFailure(prefix: prefix, code: code, message: 'a'),
    const HiveReadFailure(prefix: prefix, code: code, message: 'a'),
    const OpenFailure(prefix: prefix, code: code, message: 'a'),
    const CloseFailure(prefix: prefix, code: code, message: 'a'),
    const HiveDeleteBoxFailure(prefix: prefix, code: code, message: 'a'),
    const HiveDeleteDataFailure(prefix: prefix, code: code, message: 'a'),
    const HiveBoxNotEmptyFailure(prefix: prefix, code: code, message: 'a'),
    const BoxEncryptedFailure(prefix: prefix, code: code, message: 'a'),
    const DataDoesNotExistFailure(prefix: prefix, code: code, message: 'a'),
    const FSSWriteFailure(prefix: prefix, code: code, message: 'a'),
    const FSSReadFailure(prefix: prefix, code: code, message: 'a'),
    const FSSNotFoundFailure(prefix: prefix, code: code, message: 'a'),
    const FSSDeleteFailure(prefix: prefix, code: code, message: 'a'),
    const UnhandledFailure(message: 'a'),
  ];

  group('updateMessage', () {
    for (final failure in failures) {
      test('${failure.runtimeType} keeps its own type', () {
        final updated = failure.updateMessage(message: 'replaced');

        expect(updated.runtimeType, failure.runtimeType);
        expect(updated.message, 'replaced');
        expect(updated.prefix, failure.prefix);
        expect(updated.code, failure.code);
      });
    }

    test('leaves the original untouched', () {
      const original = HiveReadFailure(
        prefix: prefix,
        code: code,
        message: 'a',
      );

      expect(original.updateMessage(message: 'b').message, 'b');
      expect(original.message, 'a');
    });
  });
}
