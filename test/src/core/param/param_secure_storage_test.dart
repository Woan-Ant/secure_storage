import 'package:flutter_test/flutter_test.dart';
import 'package:secure_storage/secure_storage.dart';

void main() {
  group('StorageParam normalisation', () {
    test('lower cases and replaces spaces in the box name', () {
      final param = ParamGetData(boxName: 'My Box', dataKey: 'Token');
      expect(param.boxName, 'my_box');
    });

    test('namespaces the data key with the box name', () {
      final param = ParamGetData(boxName: 'My Box', dataKey: 'Access Token');
      expect(param.dataKey, 'my_box_access_token');
    });

    test('keeps the same key distinct across two boxes', () {
      final a = ParamGetData(boxName: 'auth', dataKey: 'token');
      final b = ParamGetData(boxName: 'profile', dataKey: 'token');
      expect(a.dataKey, isNot(b.dataKey));
    });

    test('accepts digits and underscores', () {
      final param = ParamGetData(boxName: 'box_1', dataKey: 'key_2');
      expect(param.boxName, 'box_1');
      expect(param.dataKey, 'box_1_key_2');
    });
  });

  group('StorageParam assertions', () {
    test('rejects an empty box name', () {
      expect(
        () => ParamGetData(boxName: '', dataKey: 'token'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects an empty data key', () {
      expect(
        () => ParamGetData(boxName: 'auth', dataKey: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects punctuation in the box name', () {
      expect(
        () => ParamGetData(boxName: 'auth-box', dataKey: 'token'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects punctuation in the data key', () {
      expect(
        () => ParamGetData(boxName: 'auth', dataKey: 'to.ken'),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('equality', () {
    test('two params addressing the same entry are equal', () {
      expect(
        ParamCheckData(boxName: 'Auth', dataKey: 'Token'),
        ParamCheckData(boxName: 'auth', dataKey: 'token'),
      );
    });

    test('params of different types are not equal', () {
      expect(
        ParamCheckData(boxName: 'auth', dataKey: 'token'),
        isNot(ParamGetData(boxName: 'auth', dataKey: 'token')),
      );
    });

    test('ParamStoreData distinguishes the encrypted flag', () {
      expect(
        ParamStoreData(boxName: 'auth', dataKey: 'token', encrypted: true),
        isNot(ParamStoreData(boxName: 'auth', dataKey: 'token')),
      );
    });

    test('ParamStoreData defaults to unencrypted', () {
      expect(ParamStoreData(boxName: 'auth', dataKey: 'token').encrypted,
          isFalse);
    });

    test('ParamDeleteData compares by box and key', () {
      expect(
        ParamDeleteData(boxName: 'auth', dataKey: 'token'),
        ParamDeleteData(boxName: 'auth', dataKey: 'token'),
      );
    });
  });
}
