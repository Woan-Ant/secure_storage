@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/src/hive_impl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:secure_storage/secure_storage.dart';

/// A [FlutterSecureStorage] mock backed by a real map.
///
/// The plugin itself needs a platform channel, but every call this package
/// makes is plain key-value access, so a map preserves the behaviour under
/// test while letting real Hive do the actual work.
class InMemoryFSS extends Mock implements FlutterSecureStorage {
  final Map<String, String> store = {};
}

InMemoryFSS buildFss() {
  final fss = InMemoryFSS();
  when(
    () => fss.write(
      key: any(named: 'key'),
      value: any(named: 'value'),
    ),
  ).thenAnswer((i) async {
    final key = i.namedArguments[#key] as String;
    final value = i.namedArguments[#value] as String?;
    if (value == null) {
      fss.store.remove(key);
    } else {
      fss.store[key] = value;
    }
  });
  when(() => fss.read(key: any(named: 'key'))).thenAnswer(
    (i) async => fss.store[i.namedArguments[#key] as String],
  );
  when(() => fss.containsKey(key: any(named: 'key'))).thenAnswer(
    (i) async => fss.store.containsKey(i.namedArguments[#key] as String),
  );
  when(() => fss.delete(key: any(named: 'key'))).thenAnswer(
    (i) async => fss.store.remove(i.namedArguments[#key] as String),
  );
  when(
    fss.readAll,
  ).thenAnswer((_) async => Map<String, String>.from(fss.store));
  return fss;
}

void main() {
  late Directory tempDir;
  late HiveImpl hive;
  late InMemoryFSS fss;
  late SecureStorageImpl storage;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('ss_real_hive');
    hive = HiveImpl()..init(tempDir.path);
    fss = buildFss();
    storage = SecureStorageImpl(
      hiveInterface: hive,
      fSS: fss,
      boxDirectoryPath: tempDir.path,
    );
  });

  tearDown(() async {
    await hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// The exact scenario reported: one encrypted box and one unencrypted box.
  group('one encrypted box and one unencrypted box', () {
    setUp(() async {
      await storage.storeData<String>(
        data: 'secret-value',
        param: ParamStoreData(
          boxName: 'secretbox',
          dataKey: 'token',
          encrypted: true,
        ),
      );
      await storage.storeData<String>(
        data: 'plain-value',
        param: ParamStoreData(boxName: 'plainbox', dataKey: 'note'),
      );
    });

    test('both values read back correctly', () async {
      expect(
        await storage.getData<String>(
          param: ParamGetData(boxName: 'secretbox', dataKey: 'token'),
        ),
        'secret-value',
      );
      expect(
        await storage.getData<String>(
          param: ParamGetData(boxName: 'plainbox', dataKey: 'note'),
        ),
        'plain-value',
      );
    });

    test('both boxes exist on disk as .hive files', () {
      final files = tempDir
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .toList();
      expect(files, contains('secretbox.hive'));
      expect(files, contains('plainbox.hive'));
    });

    test('listEncryptedKeys returns only the encrypted box', () async {
      final encrypted = await storage.listEncryptedKeys();
      expect(encrypted.keys, ['secretbox']);
    });

    test('listUnencryptedKeys returns only the unencrypted box', () async {
      final unencrypted = await storage.listUnencryptedKeys();
      expect(unencrypted, ['plainbox']);
    });

    test('the encrypted box file is not readable as plaintext', () {
      final bytes = File(
        '${tempDir.path}${Platform.pathSeparator}secretbox.hive',
      ).readAsBytesSync();
      expect(String.fromCharCodes(bytes), isNot(contains('secret-value')));
    });

    test('the unencrypted box file does contain plaintext', () {
      final bytes = File(
        '${tempDir.path}${Platform.pathSeparator}plainbox.hive',
      ).readAsBytesSync();
      expect(String.fromCharCodes(bytes), contains('plain-value'));
    });
  });

  group('encryption mode is sticky', () {
    test('a second write to an encrypted box stays encrypted', () async {
      await storage.storeData<String>(
        data: 'first',
        param: ParamStoreData(
          boxName: 'stickybox',
          dataKey: 'a',
          encrypted: true,
        ),
      );
      // encrypted defaults to false here, but the box already exists.
      await storage.storeData<String>(
        data: 'second',
        param: ParamStoreData(boxName: 'stickybox', dataKey: 'b'),
      );

      expect(await storage.listUnencryptedKeys(), isEmpty);
      expect((await storage.listEncryptedKeys()).keys, ['stickybox']);
      expect(
        await storage.getData<String>(
          param: ParamGetData(boxName: 'stickybox', dataKey: 'b'),
        ),
        'second',
      );
    });
  });

  group('delete', () {
    test('removing the last entry deletes the box and its key', () async {
      await storage.storeData<String>(
        data: 'v',
        param: ParamStoreData(
          boxName: 'goingaway',
          dataKey: 'only',
          encrypted: true,
        ),
      );
      expect(fss.store.containsKey('goingaway'), isTrue);

      await storage.deleteData<String>(
        param: ParamDeleteData(boxName: 'goingaway', dataKey: 'only'),
      );

      expect(fss.store.containsKey('goingaway'), isFalse);
      expect(
        File(
          '${tempDir.path}${Platform.pathSeparator}goingaway.hive',
        ).existsSync(),
        isFalse,
      );
      expect(await storage.listEncryptedKeys(), isEmpty);
      expect(await storage.listUnencryptedKeys(), isEmpty);
    });

    test('removing one of two entries keeps the box', () async {
      final param = ParamStoreData(boxName: 'staying', dataKey: 'a');
      await storage.storeData<String>(data: 'a', param: param);
      await storage.storeData<String>(
        data: 'b',
        param: ParamStoreData(boxName: 'staying', dataKey: 'b'),
      );

      await storage.deleteData<String>(
        param: ParamDeleteData(boxName: 'staying', dataKey: 'a'),
      );

      expect(await storage.listUnencryptedKeys(), ['staying']);
      expect(
        await storage.getData<String>(
          param: ParamGetData(boxName: 'staying', dataKey: 'b'),
        ),
        'b',
      );
    });
  });
}
