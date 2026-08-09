import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive.dart';
import 'package:secure_storage/src/core/error/app_exception.dart';
import 'package:secure_storage/src/core/error/exception/secure_storage_exception.dart';
import 'package:secure_storage/src/core/logger/secure_storage_logger.dart';
import 'package:secure_storage/src/core/param/param_secure_storage.dart';
import 'package:secure_storage/src/services/box_scanner/box_scanner.dart';
import 'package:secure_storage/src/services/secure_storage.dart';
import 'package:synchronized/synchronized.dart';

/// {@template secure_storage_impl}
/// The default [SecureStorage], combining Hive CE for the data and Flutter
/// Secure Storage for the per-box encryption keys.
///
/// All public operations are serialised through a single lock, because a Hive
/// box cannot be opened twice concurrently and every operation here opens and
/// closes the box it touches.
///
/// `boxDirectoryPath` should be the same path `hiveInterface` was initialised
/// with; it is what [listUnencryptedKeys] scans. Leave it unset on web.
/// {@endtemplate}
class SecureStorageImpl implements SecureStorage {
  /// {@macro secure_storage_impl}
  SecureStorageImpl({
    required HiveInterface hiveInterface,
    required FlutterSecureStorage fSS,
    String? boxDirectoryPath,
    SecureStorageLogger logger = const SilentSecureStorageLogger(),
  }) : _hive = hiveInterface,
       _fSS = fSS,
       _boxDirectoryPath = boxDirectoryPath,
       _logger = logger;

  final HiveInterface _hive;
  final FlutterSecureStorage _fSS;
  final String? _boxDirectoryPath;
  final SecureStorageLogger _logger;
  final Lock _lock = Lock();

  @override
  Future<void> storeData<T>({
    required T data,
    required ParamStoreData param,
  }) async {
    await _lock.synchronized(() async {
      _logger.d(
        '''[storeData] => param: 📦 box: [${param.boxName}] & 🔑 dataKey: [${param.dataKey}] & encrypted: ${param.encrypted} & data type: ${data.runtimeType}''',
      );
      final dataChecker = await _checkData(
        boxName: param.boxName,
        dataKey: param.dataKey,
      );
      if (!dataChecker.exist && dataChecker.encrypted == null) {
        // Neither the box nor the key exists, so this is the first write and
        // the caller's `encrypted` preference decides how the box is created.
        await _storeNewData(
          boxName: param.boxName,
          dataKey: param.dataKey,
          data: data,
          encrypted: param.encrypted,
        );
      } else {
        // The box exists, so its own encryption mode wins over the param.
        await _addOrUpdateDataInBox(
          boxName: param.boxName,
          dataKey: param.dataKey,
          data: data,
          encrypted: dataChecker.encrypted!,
        );
      }
    });
  }

  Future<void> _storeNewData<T>({
    required String boxName,
    required String dataKey,
    required T data,
    required bool encrypted,
  }) async {
    _logger.d(
      '''🆕 Process storing new data with 🔑 dataKey: [$dataKey] in to 📦 box: [$boxName]''',
    );
    // Only generate a key when the box is meant to be encrypted.
    if (encrypted) {
      final generateKey = _hive.generateSecureKey();
      _logger.d(
        '''[hive.generateSecureKey] => generated a ${generateKey.length}-byte key for 📦 box: [$boxName]''',
      );
      try {
        // Hold the generated key in the platform keystore rather than on disk
        // next to the box it protects.
        await _fSS.write(key: boxName, value: base64UrlEncode(generateKey));
      } on Exception catch (e) {
        _logger.e('🛡️ [flutterSecureStorage.write]', error: e);
        throw FSSWriteException();
      }
    }

    final box = await _openBox<T>(
      boxName: boxName,
      dataKey: dataKey,
      encrypted: encrypted,
    );

    await _storeData(key: dataKey, box: box, data: data);
  }

  Future<void> _addOrUpdateDataInBox<T>({
    required String boxName,
    required String dataKey,
    required T data,
    required bool encrypted,
  }) async {
    _logger.d(
      '''🔄 Process add new data / update data with 🔑 dataKey: [$dataKey] in to 📦 box: [$boxName]''',
    );
    final box = await _openBox<T>(
      boxName: boxName,
      dataKey: dataKey,
      encrypted: encrypted,
    );
    await _storeData(key: dataKey, box: box, data: data);
  }

  Future<void> _storeData<T>({
    required String key,
    required Box<T> box,
    required T data,
  }) async {
    try {
      await box.put(key, data);
      _logger.i(
        '''Data with 🔑 dataKey: [$key] successfully stored in 📦 box: [${box.name}]''',
      );
    } on Exception catch (e) {
      _logger.e(
        '''Error storing data with 🔑 dataKey: [$key] in 📦 box: [${box.name}] => [box.put]''',
        error: e,
      );
      throw HiveWriteException();
    } finally {
      await box.close();
      _logger.d(
        '''📦 [box.close] => SUCCESSFULLY CLOSED => box open status: ${box.isOpen}''',
      );
    }
  }

  @override
  Future<({bool exist, bool? encrypted})> isDataExist({
    required ParamCheckData param,
  }) async {
    return _lock.synchronized(
      () => _checkData(boxName: param.boxName, dataKey: param.dataKey),
    );
  }

  Future<({bool exist, bool? encrypted})> _checkData({
    required String boxName,
    required String dataKey,
  }) async {
    _logger.d('[_checkData] 📦 box: [$boxName] & 🔑 dataKey: [$dataKey]');
    final boxExists = await _hive.boxExists(boxName);
    if (!boxExists) {
      _logger.d(
        '''[_checkData] => 📦 [_hive.boxExists($boxName)] => 📦 boxExists: $boxExists 🔑 encrypted: null''',
      );
      // `encrypted: null` marks "no box yet", which storeData reads as a
      // first write.
      return (exist: boxExists, encrypted: null);
    }
    // A key held for this box name is what makes the box an encrypted one.
    final fssKey = await _fSS.containsKey(key: boxName);
    final box = await _openBox<dynamic>(
      boxName: boxName,
      dataKey: dataKey,
      encrypted: fssKey,
    );
    final keyExists = box.containsKey(dataKey);
    _logger.d(
      '''[_checkData] => 📦 box: [$boxName] & 🔑 dataKey: [$dataKey] => key exists: $keyExists encrypted: $fssKey''',
    );
    await box.close();
    return (exist: keyExists, encrypted: fssKey);
  }

  @override
  Future<T?> getData<T>({required ParamGetData param}) async {
    return _lock.synchronized(() async {
      _logger.d(
        '''[getData] => param: 📦 box: [${param.boxName}] & 🔑 dataKey: [${param.dataKey}]''',
      );
      final dataChecker = await _checkData(
        boxName: param.boxName,
        dataKey: param.dataKey,
      );
      if (!dataChecker.exist) {
        _logger.e(
          '''[getData] => 📦 box: [${param.boxName}] & 🔑 dataKey: [${param.dataKey}] => exist: ${dataChecker.exist}, encrypted: ${dataChecker.encrypted}''',
        );
        throw DataDoesNotExistException();
      }
      final box = await _openBox<T>(
        boxName: param.boxName,
        dataKey: param.dataKey,
        encrypted: dataChecker.encrypted!,
      );
      return _getData<T>(dataKey: param.dataKey, box: box);
    });
  }

  Future<T?> _getData<T>({required String dataKey, required Box<T> box}) async {
    try {
      _logger.d(
        '[_getData] => 📦 box: [${box.name}] & 🔑 dataKey: [$dataKey].',
      );
      return box.get(dataKey);
    } on Exception catch (e) {
      _logger.e(
        '[_getData] => 📦 box: [${box.name}] & 🔑 dataKey: [$dataKey]',
        error: e,
      );
      throw HiveReadException();
    } finally {
      await box.close();
      _logger.d(
        '''[_getData] => [box.close] => 📦 box: [${box.name}] SUCCESSFULLY CLOSED.''',
      );
    }
  }

  @override
  Future<void> deleteData<T>({required ParamDeleteData param}) async {
    await _lock.synchronized(() async {
      _logger.d(
        '''[deleteData] => param: 📦 box: [${param.boxName}] & 🔑 dataKey: [${param.dataKey}].''',
      );
      final dataChecker = await _checkData(
        boxName: param.boxName,
        dataKey: param.dataKey,
      );
      if (!dataChecker.exist) {
        _logger.e(
          '''[deleteData] => 📦 box: [${param.boxName}] & 🔑 dataKey: [${param.dataKey}] => exist: ${dataChecker.exist}, encrypted: ${dataChecker.encrypted}''',
        );
        throw DataDoesNotExistException();
      }
      final box = await _openBox<T>(
        boxName: param.boxName,
        dataKey: param.dataKey,
        encrypted: dataChecker.encrypted!,
      );
      await _deleteData(
        box: box,
        dataKey: param.dataKey,
        encrypted: dataChecker.encrypted!,
      );
    });
  }

  Future<Box<T>> _openBox<T>({
    required String boxName,
    required String dataKey,
    required bool encrypted,
  }) async {
    _logger.d(
      '''[_openBox] => 📦 box: [$boxName] & 🔑 dataKey: [$dataKey] & encrypted: $encrypted''',
    );
    if (!encrypted) {
      try {
        return await _hive.openBox<T>(boxName);
      } on Exception catch (e) {
        _logger.e(
          '[_hive.openBox] => 📦 box: [$boxName] & 🔑 dataKey: [$dataKey]',
          error: e,
        );
        throw HiveOpenBoxException();
      }
    }

    // The box key is stored in the keystore under the box name.
    final boxSecureKey = await _fSS.read(key: boxName);
    if (boxSecureKey == null || boxSecureKey.isEmpty) {
      _logger.e(
        '''🛡️ [flutterSecureStorage.read] => boxSecureKey is null or empty for 📦 box: [$boxName]''',
      );
      throw FSSReadException();
    }
    try {
      final encryptionKey = base64Url.decode(boxSecureKey);
      return await _hive.openBox<T>(
        boxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } on Exception catch (e) {
      _logger.e(
        '[_hive.openBox] => 📦 box: [$boxName] & 🔑 dataKey: [$dataKey]',
        error: e,
      );
      throw HiveOpenBoxException();
    }
  }

  Future<void> _deleteData<T>({
    required Box<T> box,
    required String dataKey,
    required bool encrypted,
  }) async {
    try {
      await box.delete(dataKey);
      _logger.i(
        '''[_deleteData] => [box.delete] => data with 🔑 dataKey: [$dataKey] SUCCESSFULLY DELETED from 📦 box: [${box.name}].''',
      );
    } on Exception catch (e) {
      _logger.e(
        '''[_deleteData] => error deleting data with 🔑 dataKey: [$dataKey] from 📦 box: [${box.name}]''',
        error: e,
      );
      throw HiveDeleteDataException();
    }

    if (box.isNotEmpty) {
      // Other entries still live here, so the box and its key stay.
      _logger.d(
        '''[_deleteData] => 📦 box: [${box.name}] still holds entries, keeping the box.''',
      );
      await box.close();
      _logger.i(
        '''[_deleteData] => [box.close] => 📦 box: [${box.name}] => SUCCESSFULLY CLOSED => box open status: ${box.isOpen}.''',
      );
      return;
    }

    try {
      // deleteFromDisk also closes the box, so no explicit close is needed.
      await box.deleteFromDisk();
      _logger.i(
        '''[_deleteData] => [box.deleteFromDisk] => 📦 box: [${box.name}] SUCCESSFULLY DELETED => box open status: ${box.isOpen}.''',
      );
    } on Exception catch (e) {
      _logger.e(
        '''🔑 dataKey: [$dataKey] => [_deleteData] => [box.deleteFromDisk]''',
        error: e,
      );
      throw HiveDeleteBoxException();
    }

    if (encrypted) {
      try {
        // The box is gone, so its key would otherwise be orphaned.
        await _fSS.delete(key: box.name);
        _logger.i(
          '''[_deleteData] => [flutterSecureStorage.delete] => 📦🔑 box key [${box.name}] SUCCESSFULLY DELETED from flutter secure storage.''',
        );
      } on Exception catch (e) {
        _logger.e(
          '''🔑 dataKey: [$dataKey] => [_deleteData] => [flutterSecureStorage.delete]''',
          error: e,
        );
        throw FSSDeleteException();
      }
    }
  }

  @override
  Future<Map<String, String>> listEncryptedKeys() => _listEncryptedKeys();

  Future<Map<String, String>> _listEncryptedKeys() async {
    try {
      final keys = await _fSS.readAll();
      _logger.d(
        '[listEncryptedKeys] => found ${keys.length} encrypted box(es)',
      );
      return keys;
    } on Exception catch (e) {
      _logger.e('🛡️ [flutterSecureStorage.readAll]', error: e);
      throw FSSReadException();
    }
  }

  @override
  Future<List<dynamic>> listUnencryptedKeys() async {
    final path = _boxDirectoryPath;
    if (path == null) {
      // Also the web case: boxes live in IndexedDB, so there is nothing to
      // scan and callers pass no directory.
      _logger.w('listUnencryptedKeys needs a boxDirectoryPath to scan');
      return [];
    }
    try {
      final allBoxNames = listBoxFileNames(path);

      // A box with no key in the keystore is an unencrypted one.
      final encryptedKeys = await _listEncryptedKeys();
      final unencryptedBoxNames = allBoxNames
          .where((boxName) => !encryptedKeys.containsKey(boxName))
          .toList();

      _logger.d('Unencrypted hive box names: $unencryptedBoxNames');
      return unencryptedBoxNames;
    } on AppException {
      rethrow;
    } on Exception catch (e) {
      _logger.e('[listUnencryptedKeys]', error: e);
      throw HiveReadException();
    }
  }
}
