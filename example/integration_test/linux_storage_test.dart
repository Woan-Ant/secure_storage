import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:secure_storage/secure_storage.dart';

/// Exercises the package against the real platform pieces: the actual
/// flutter_secure_storage plugin and real Hive box files.
///
/// Run with `flutter test integration_test -d linux` (or `-d macos`,
/// `-d windows`, or an attached Android/iOS device).
///
/// On desktop Linux, flutter_secure_storage needs a Secret Service provider —
/// gnome-keyring, or KWallet via `ksecretd`. Where none is running, the
/// keystore-backed tests are skipped rather than reported as failures, because
/// there is nothing for the plugin to talk to.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late GetIt sl;
  late Directory tempDir;
  late SecureStorage storage;

  // Distinctive names so a stray keyring entry is obvious and cannot collide
  // with anything already on the machine.
  const secretBox = 'itsecretbox';
  const plainBox = 'itplainbox';

  /// Whether the platform keystore actually answers.
  ///
  /// Probed once rather than assumed, so the suite reports honestly on
  /// machines with no Secret Service.
  var keystoreAvailable = false;

  setUpAll(() async {
    try {
      await const FlutterSecureStorage().readAll();
      keystoreAvailable = true;
    } on Object {
      keystoreAvailable = false;
    }
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('ss_integration');
    sl = GetIt.asNewInstance();
    initSecureStorageFeature(sl: sl, storagePath: tempDir.path);
    storage = sl<SecureStorage>();
  });

  tearDown(() async {
    // Never leave test entries behind in a real keyring.
    if (keystoreAvailable) {
      for (final box in [secretBox, plainBox]) {
        try {
          await storage.deleteData<String>(
            param: ParamDeleteData(boxName: box, dataKey: 'k'),
          );
        } on Object {
          // Already gone.
        }
      }
    }
    await sl.reset();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// Runs on every platform: Hive alone, no keystore involved.
  group('no keystore required', () {
    testWidgets('a missing entry reports DataDoesNotExist', (tester) async {
      await expectLater(
        storage.getData<String>(
          param: ParamGetData(boxName: secretBox, dataKey: 'k'),
        ),
        throwsA(isA<DataDoesNotExistException>()),
      );
    });

    testWidgets('writing an unencrypted box creates a real file',
        (tester) async {
      await storage.storeData<String>(
        data: 'linux-plain',
        param: ParamStoreData(boxName: plainBox, dataKey: 'k'),
      );

      expect(
        File(
          '${tempDir.path}${Platform.pathSeparator}$plainBox.hive',
        ).existsSync(),
        isTrue,
      );
    });

  });

  group('keystore backed', () {
    testWidgets('stores and reads back an encrypted value', (tester) async {
      await storage.storeData<String>(
        data: 'linux-secret',
        param: ParamStoreData(
          boxName: secretBox,
          dataKey: 'k',
          encrypted: true,
        ),
      );

      expect(
        await storage.getData<String>(
          param: ParamGetData(boxName: secretBox, dataKey: 'k'),
        ),
        'linux-secret',
      );
    }, skip: !keystoreAvailable);

    testWidgets('the encrypted box file holds no plaintext', (tester) async {
      await storage.storeData<String>(
        data: 'linux-secret',
        param: ParamStoreData(
          boxName: secretBox,
          dataKey: 'k',
          encrypted: true,
        ),
      );

      final bytes = File(
        '${tempDir.path}${Platform.pathSeparator}$secretBox.hive',
      ).readAsBytesSync();
      expect(String.fromCharCodes(bytes), isNot(contains('linux-secret')));
    }, skip: !keystoreAvailable);

    testWidgets('lists encrypted and unencrypted boxes separately',
        (tester) async {
      await storage.storeData<String>(
        data: 'linux-secret',
        param: ParamStoreData(
          boxName: secretBox,
          dataKey: 'k',
          encrypted: true,
        ),
      );
      await storage.storeData<String>(
        data: 'linux-plain',
        param: ParamStoreData(boxName: plainBox, dataKey: 'k'),
      );

      // A real keyring may hold unrelated entries, so assert containment
      // rather than equality.
      expect(await storage.listEncryptedKeys(), contains(secretBox));
      expect(await storage.listUnencryptedKeys(), contains(plainBox));
      expect(await storage.listUnencryptedKeys(), isNot(contains(secretBox)));
    }, skip: !keystoreAvailable);

    // Reads consult the keystore even for unencrypted boxes, because that is
    // how the box's encryption mode is determined.
    testWidgets('reads back an unencrypted value', (tester) async {
      await storage.storeData<String>(
        data: 'linux-plain',
        param: ParamStoreData(boxName: plainBox, dataKey: 'k'),
      );

      expect(
        await storage.getData<String>(
          param: ParamGetData(boxName: plainBox, dataKey: 'k'),
        ),
        'linux-plain',
      );
    }, skip: !keystoreAvailable);

    testWidgets('deleting the last entry removes box and keyring entry',
        (tester) async {
      await storage.storeData<String>(
        data: 'linux-secret',
        param: ParamStoreData(
          boxName: secretBox,
          dataKey: 'k',
          encrypted: true,
        ),
      );

      await storage.deleteData<String>(
        param: ParamDeleteData(boxName: secretBox, dataKey: 'k'),
      );

      expect(
        File(
          '${tempDir.path}${Platform.pathSeparator}$secretBox.hive',
        ).existsSync(),
        isFalse,
      );
      expect(await storage.listEncryptedKeys(), isNot(contains(secretBox)));
    }, skip: !keystoreAvailable);
  });
}
