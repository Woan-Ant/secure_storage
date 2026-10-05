import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:secure_storage/secure_storage.dart';

class MockHive extends Mock implements HiveInterface;

class MockFSS extends Mock implements FlutterSecureStorage;

class MockBox<T> extends Mock implements Box<T>;

class FakeHiveCipher extends Fake implements HiveCipher;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const boxName = 'auth';
  const dataKey = 'auth_token';
  final secureKey = Uint8List.fromList(List<int>.filled(32, 7));
  final encodedKey = base64UrlEncode(secureKey);

  late MockHive hive;
  late MockFSS fss;
  late MockBox<dynamic> dynamicBox;
  late MockBox<String> stringBox;
  late SecureStorageImpl storage;

  setUpAll(() {
    registerFallbackValue(FakeHiveCipher());
  });

  setUp(() {
    hive = MockHive();
    fss = MockFSS();
    dynamicBox = MockBox<dynamic>();
    stringBox = MockBox<String>();
    storage = SecureStorageImpl(hiveInterface: hive, fSS: fss);

    for (final box in <Box<dynamic>>[dynamicBox, stringBox]) {
      when(() => box.name).thenReturn(boxName);
      when(() => box.isOpen).thenReturn(true);
      when(box.close).thenAnswer((_) async {});
      when(() => box.isNotEmpty).thenReturn(false);
    }
    when(() => hive.generateSecureKey()).thenReturn(secureKey);
    when(
      () => fss.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => fss.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    when(() => fss.read(key: any(named: 'key')))
        .thenAnswer((_) async => encodedKey);
  });

  /// Stubs the box-exists / key-exists probe that every operation starts with.
  void stubCheckData({
    required bool boxExists,
    bool keyExists = false,
    bool encrypted = false,
  }) {
    when(() => hive.boxExists(boxName)).thenAnswer((_) async => boxExists);
    when(() => fss.containsKey(key: boxName))
        .thenAnswer((_) async => encrypted);
    when(() => dynamicBox.containsKey(dataKey)).thenReturn(keyExists);
    if (encrypted) {
      when(
        () => hive.openBox<dynamic>(
          boxName,
          encryptionCipher: any(named: 'encryptionCipher'),
        ),
      ).thenAnswer((_) async => dynamicBox);
      when(
        () => hive.openBox<String>(
          boxName,
          encryptionCipher: any(named: 'encryptionCipher'),
        ),
      ).thenAnswer((_) async => stringBox);
    } else {
      when(() => hive.openBox<dynamic>(boxName))
          .thenAnswer((_) async => dynamicBox);
      when(() => hive.openBox<String>(boxName))
          .thenAnswer((_) async => stringBox);
    }
  }

  group('isDataExist', () {
    test('reports encrypted as null when the box does not exist', () async {
      stubCheckData(boxExists: false);

      final result = await storage.isDataExist(
        param: ParamCheckData(boxName: boxName, dataKey: 'token'),
      );

      expect(result.exist, isFalse);
      expect(result.encrypted, isNull);
      verifyNever(() => hive.openBox<dynamic>(any()));
    });

    test(
      'reports the key and the encryption mode when the box exists',
      () async {
        stubCheckData(boxExists: true, keyExists: true, encrypted: true);

        final result = await storage.isDataExist(
          param: ParamCheckData(boxName: boxName, dataKey: 'token'),
        );

        expect(result.exist, isTrue);
        expect(result.encrypted, isTrue);
        verify(dynamicBox.close).called(1);
      },
    );

    test('reports a missing key inside an existing box', () async {
      stubCheckData(boxExists: true);

      final result = await storage.isDataExist(
        param: ParamCheckData(boxName: boxName, dataKey: 'token'),
      );

      expect(result.exist, isFalse);
      expect(result.encrypted, isFalse);
    });
  });

  group('storeData on a new box', () {
    test(
      'generates a key, stores it in the keystore and encrypts the box',
      () async {
        stubCheckData(boxExists: false);
        when(
          () => hive.openBox<String>(
            boxName,
            encryptionCipher: any(named: 'encryptionCipher'),
          ),
        ).thenAnswer((_) async => stringBox);
        when(() => stringBox.put(dataKey, 'value')).thenAnswer((_) async {});

        await storage.storeData<String>(
          data: 'value',
          param: ParamStoreData(
            boxName: boxName,
            dataKey: 'token',
            encrypted: true,
          ),
        );

        verify(() => hive.generateSecureKey()).called(1);
        verify(() => fss.write(key: boxName, value: encodedKey)).called(1);
        verify(() => stringBox.put(dataKey, 'value')).called(1);
        verify(stringBox.close).called(1);
      },
    );

    test(
      'skips key generation when the caller asks for no encryption',
      () async {
        stubCheckData(boxExists: false);
        when(() => stringBox.put(dataKey, 'value')).thenAnswer((_) async {});

        await storage.storeData<String>(
          data: 'value',
          param: ParamStoreData(boxName: boxName, dataKey: 'token'),
        );

        verifyNever(() => hive.generateSecureKey());
        verifyNever(
          () => fss.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        );
        verify(() => hive.openBox<String>(boxName)).called(1);
      },
    );

    test('throws FSSWriteException when the keystore write fails', () async {
      stubCheckData(boxExists: false);
      when(
        () => fss.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenThrow(Exception('keystore unavailable'));

      await expectLater(
        storage.storeData<String>(
          data: 'value',
          param: ParamStoreData(
            boxName: boxName,
            dataKey: 'token',
            encrypted: true,
          ),
        ),
        throwsA(isA<FSSWriteException>()),
      );
    });
  });

  group('storeData on an existing box', () {
    test(
      'keeps the box encrypted even when the param says otherwise',
      () async {
        stubCheckData(boxExists: true, keyExists: true, encrypted: true);
        when(() => stringBox.put(dataKey, 'value')).thenAnswer((_) async {});

        await storage.storeData<String>(
          data: 'value',
          param: ParamStoreData(boxName: boxName, dataKey: 'token'),
        );

        verifyNever(() => hive.generateSecureKey());
        verify(
          () => hive.openBox<String>(
            boxName,
            encryptionCipher: any(named: 'encryptionCipher'),
          ),
        ).called(1);
      },
    );

    test(
      'throws HiveWriteException and still closes the box on put failure',
      () async {
        stubCheckData(boxExists: true, keyExists: true);
        when(() => stringBox.put(dataKey, 'value'))
            .thenThrow(Exception('disk full'));

        await expectLater(
          storage.storeData<String>(
            data: 'value',
            param: ParamStoreData(boxName: boxName, dataKey: 'token'),
          ),
          throwsA(isA<HiveWriteException>()),
        );
        verify(stringBox.close).called(1);
      },
    );
  });

  group('getData', () {
    test('returns the stored value and closes the box', () async {
      stubCheckData(boxExists: true, keyExists: true);
      when(() => stringBox.get(dataKey)).thenReturn('value');

      final result = await storage.getData<String>(
        param: ParamGetData(boxName: boxName, dataKey: 'token'),
      );

      expect(result, 'value');
      verify(stringBox.close).called(1);
    });

    test('throws DataDoesNotExistException when the box is absent', () async {
      stubCheckData(boxExists: false);

      await expectLater(
        storage.getData<String>(
          param: ParamGetData(boxName: boxName, dataKey: 'token'),
        ),
        throwsA(isA<DataDoesNotExistException>()),
      );
    });

    test('throws DataDoesNotExistException when the key is absent', () async {
      stubCheckData(boxExists: true);

      await expectLater(
        storage.getData<String>(
          param: ParamGetData(boxName: boxName, dataKey: 'token'),
        ),
        throwsA(isA<DataDoesNotExistException>()),
      );
    });

    test('throws HiveReadException when the read fails', () async {
      stubCheckData(boxExists: true, keyExists: true);
      when(() => stringBox.get(dataKey)).thenThrow(Exception('corrupt'));

      await expectLater(
        storage.getData<String>(
          param: ParamGetData(boxName: boxName, dataKey: 'token'),
        ),
        throwsA(isA<HiveReadException>()),
      );
      verify(stringBox.close).called(1);
    });
  });

  group('deleteData', () {
    test('keeps the box when other entries remain', () async {
      stubCheckData(boxExists: true, keyExists: true);
      when(() => stringBox.delete(dataKey)).thenAnswer((_) async {});
      when(() => stringBox.isNotEmpty).thenReturn(true);

      await storage.deleteData<String>(
        param: ParamDeleteData(boxName: boxName, dataKey: 'token'),
      );

      verify(() => stringBox.delete(dataKey)).called(1);
      verifyNever(stringBox.deleteFromDisk);
      verifyNever(() => fss.delete(key: any(named: 'key')));
      verify(stringBox.close).called(1);
    });

    test('deletes the emptied box from disk', () async {
      stubCheckData(boxExists: true, keyExists: true);
      when(() => stringBox.delete(dataKey)).thenAnswer((_) async {});
      when(stringBox.deleteFromDisk).thenAnswer((_) async {});

      await storage.deleteData<String>(
        param: ParamDeleteData(boxName: boxName, dataKey: 'token'),
      );

      verify(stringBox.deleteFromDisk).called(1);
      verifyNever(() => fss.delete(key: any(named: 'key')));
    });

    test(
      'also removes the keystore entry for an emptied encrypted box',
      () async {
        stubCheckData(boxExists: true, keyExists: true, encrypted: true);
        when(() => stringBox.delete(dataKey)).thenAnswer((_) async {});
        when(stringBox.deleteFromDisk).thenAnswer((_) async {});

        await storage.deleteData<String>(
          param: ParamDeleteData(boxName: boxName, dataKey: 'token'),
        );

        verify(stringBox.deleteFromDisk).called(1);
        verify(() => fss.delete(key: boxName)).called(1);
      },
    );

    test(
      'throws DataDoesNotExistException when there is nothing to delete',
      () async {
        stubCheckData(boxExists: false);

        await expectLater(
          storage.deleteData<String>(
            param: ParamDeleteData(boxName: boxName, dataKey: 'token'),
          ),
          throwsA(isA<DataDoesNotExistException>()),
        );
      },
    );

    test('throws HiveDeleteDataException when the delete fails', () async {
      stubCheckData(boxExists: true, keyExists: true);
      when(() => stringBox.delete(dataKey)).thenThrow(Exception('locked'));

      await expectLater(
        storage.deleteData<String>(
          param: ParamDeleteData(boxName: boxName, dataKey: 'token'),
        ),
        throwsA(isA<HiveDeleteDataException>()),
      );
    });

    test(
      'throws HiveDeleteBoxException when the box cannot be removed',
      () async {
        stubCheckData(boxExists: true, keyExists: true);
        when(() => stringBox.delete(dataKey)).thenAnswer((_) async {});
        when(stringBox.deleteFromDisk).thenThrow(Exception('read only'));

        await expectLater(
          storage.deleteData<String>(
            param: ParamDeleteData(boxName: boxName, dataKey: 'token'),
          ),
          throwsA(isA<HiveDeleteBoxException>()),
        );
      },
    );

    test(
      'throws FSSDeleteException when the keystore entry cannot be removed',
      () async {
        stubCheckData(boxExists: true, keyExists: true, encrypted: true);
        when(() => stringBox.delete(dataKey)).thenAnswer((_) async {});
        when(stringBox.deleteFromDisk).thenAnswer((_) async {});
        when(() => fss.delete(key: any(named: 'key')))
            .thenThrow(Exception('keystore locked'));

        await expectLater(
          storage.deleteData<String>(
            param: ParamDeleteData(boxName: boxName, dataKey: 'token'),
          ),
          throwsA(isA<FSSDeleteException>()),
        );
      },
    );
  });

  group('opening boxes', () {
    test(
      'throws FSSReadException when the encryption key is missing',
      () async {
        stubCheckData(boxExists: true, keyExists: true, encrypted: true);
        when(() => fss.read(key: boxName)).thenAnswer((_) async => null);

        await expectLater(
          storage.getData<String>(
            param: ParamGetData(boxName: boxName, dataKey: 'token'),
          ),
          throwsA(isA<FSSReadException>()),
        );
      },
    );

    test('throws FSSReadException when the encryption key is empty', () async {
      stubCheckData(boxExists: true, keyExists: true, encrypted: true);
      when(() => fss.read(key: boxName)).thenAnswer((_) async => '');

      await expectLater(
        storage.getData<String>(
          param: ParamGetData(boxName: boxName, dataKey: 'token'),
        ),
        throwsA(isA<FSSReadException>()),
      );
    });

    test(
      'throws FSSReadException when the keystore itself is unavailable',
      () async {
        // Reproduces desktop Linux with no Secret Service running: the plugin
        // throws from containsKey, and it must not escape untyped.
        when(() => hive.boxExists(boxName)).thenAnswer((_) async => true);
        when(() => fss.containsKey(key: boxName))
            .thenThrow(Exception('Libsecret error: name is not activatable'));

        await expectLater(
          storage.isDataExist(
            param: ParamCheckData(boxName: boxName, dataKey: 'token'),
          ),
          throwsA(isA<FSSReadException>()),
        );
      },
    );

    test(
      'throws HiveOpenBoxException when hive refuses to open the box',
      () async {
        when(() => hive.boxExists(boxName)).thenAnswer((_) async => true);
        when(() => fss.containsKey(key: boxName))
            .thenAnswer((_) async => false);
        when(() => hive.openBox<dynamic>(boxName))
            .thenThrow(Exception('locked by another isolate'));

        await expectLater(
          storage.isDataExist(
            param: ParamCheckData(boxName: boxName, dataKey: 'token'),
          ),
          throwsA(isA<HiveOpenBoxException>()),
        );
      },
    );

    test(
      'throws HiveOpenBoxException when the cipher does not match',
      () async {
        when(() => hive.boxExists(boxName)).thenAnswer((_) async => true);
        when(() => fss.containsKey(key: boxName)).thenAnswer((_) async => true);
        when(
          () => hive.openBox<dynamic>(
            boxName,
            encryptionCipher: any(named: 'encryptionCipher'),
          ),
        ).thenThrow(Exception('wrong key'));

        await expectLater(
          storage.isDataExist(
            param: ParamCheckData(boxName: boxName, dataKey: 'token'),
          ),
          throwsA(isA<HiveOpenBoxException>()),
        );
      },
    );
  });

  group('listEncryptedKeys', () {
    test('returns everything held in the keystore', () async {
      when(fss.readAll)
          .thenAnswer((_) async => {'auth': 'k1', 'profile': 'k2'});

      expect(await storage.listEncryptedKeys(), {
        'auth': 'k1',
        'profile': 'k2',
      });
    });

    test('throws FSSReadException when the keystore cannot be read', () async {
      when(fss.readAll).thenThrow(Exception('keystore unavailable'));

      await expectLater(
        storage.listEncryptedKeys(),
        throwsA(isA<FSSReadException>()),
      );
    });
  });

  group('listUnencryptedKeys', () {
    late Directory tempDir;
    late SecureStorageImpl scanning;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('secure_storage_test');
      for (final name in ['auth.hive', 'profile.hive', 'notes.txt']) {
        File('${tempDir.path}${Platform.pathSeparator}$name')
            .writeAsStringSync('');
      }
      scanning = SecureStorageImpl(
        hiveInterface: hive,
        fSS: fss,
        boxDirectoryPath: tempDir.path,
      );
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('returns the boxes that have no key in the keystore', () async {
      when(fss.readAll).thenAnswer((_) async => {'auth': encodedKey});

      expect(await scanning.listUnencryptedKeys(), ['profile']);
    });

    test('ignores files that are not hive boxes', () async {
      when(fss.readAll).thenAnswer((_) async => <String, String>{});

      expect(
        await scanning.listUnencryptedKeys(),
        unorderedEquals(<String>['auth', 'profile']),
      );
    });

    test('returns an empty list when the directory does not exist', () async {
      when(fss.readAll).thenAnswer((_) async => <String, String>{});
      final missing = SecureStorageImpl(
        hiveInterface: hive,
        fSS: fss,
        boxDirectoryPath: '${tempDir.path}${Platform.pathSeparator}missing',
      );

      expect(await missing.listUnencryptedKeys(), isEmpty);
    });

    test('returns an empty list when no directory was configured', () async {
      when(fss.readAll).thenAnswer((_) async => <String, String>{});

      // There is nothing to scan, so no box can be reported as unencrypted.
      expect(await storage.listUnencryptedKeys(), isEmpty);
    });

    test('propagates a keystore failure rather than masking it', () async {
      when(fss.readAll).thenThrow(Exception('keystore unavailable'));

      await expectLater(
        scanning.listUnencryptedKeys(),
        throwsA(isA<FSSReadException>()),
      );
    });
  });

  group('logging', () {
    test('accepts a custom logger without changing behaviour', () async {
      final logged = <String>[];
      final logging = SecureStorageImpl(
        hiveInterface: hive,
        fSS: fss,
        logger: _RecordingLogger(logged),
      );
      stubCheckData(boxExists: false);

      final result = await logging.isDataExist(
        param: ParamCheckData(boxName: boxName, dataKey: 'token'),
      );

      expect(result.exist, isFalse);
      expect(logged, isNotEmpty);
    });

    test('never logs the generated encryption key', () async {
      final logged = <String>[];
      final logging = SecureStorageImpl(
        hiveInterface: hive,
        fSS: fss,
        logger: _RecordingLogger(logged),
      );
      stubCheckData(boxExists: false);
      when(
        () => hive.openBox<String>(
          boxName,
          encryptionCipher: any(named: 'encryptionCipher'),
        ),
      ).thenAnswer((_) async => stringBox);
      when(() => stringBox.put(dataKey, 'value')).thenAnswer((_) async {});

      await logging.storeData<String>(
        data: 'value',
        param: ParamStoreData(
          boxName: boxName,
          dataKey: 'token',
          encrypted: true,
        ),
      );

      expect(logged.join('\n'), isNot(contains(encodedKey)));
      expect(logged.join('\n'), isNot(contains(secureKey.toString())));
    });
  });
}

class _RecordingLogger extends SecureStorageLogger {
  const new(this.messages);

  final List<String> messages;

  @override
  void d(String message) => messages.add(message);

  @override
  void i(String message) => messages.add(message);

  @override
  void w(String message) => messages.add(message);

  @override
  void e(String message, {Object? error}) => messages.add('$message $error');
}
