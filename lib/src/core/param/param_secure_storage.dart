import 'package:equatable/equatable.dart';

final RegExp _allowedCharacters = RegExp(r'^[a-zA-Z0-9_]+$');

bool _isValidSegment(String value) =>
    value.isNotEmpty && _allowedCharacters.hasMatch(value.replaceAll(' ', '_'));

String _normalize(String value) => value.replaceAll(' ', '_').toLowerCase();

/// {@template storage_param}
/// Base for every parameter object addressing a single entry in storage.
///
/// Both segments are normalised on construction: spaces become underscores and
/// everything is lower cased. The stored [dataKey] is additionally namespaced
/// with the box name, so `ParamGetData(boxName: 'My Box', dataKey: 'Token')`
/// resolves to box `my_box` and key `my_box_token`. Two different boxes can
/// therefore reuse the same logical key without colliding.
///
/// In debug builds, empty segments and segments containing anything other than
/// letters, digits, spaces and underscores trip an assertion.
/// {@endtemplate}
abstract class StorageParam extends Equatable {
  /// {@macro storage_param}
  new({required String boxName, required String dataKey})
    : assert(
        boxName.isNotEmpty && dataKey.isNotEmpty,
        'boxName and dataKey must not be empty',
      ),
      assert(
        _isValidSegment(boxName),
        '''boxName must only contain alphanumeric characters and underscores after replacing spaces''',
      ),
      assert(
        _isValidSegment(dataKey),
        '''dataKey must only contain alphanumeric characters and underscores after replacing spaces''',
      ),
      boxName = _normalize(boxName),
      dataKey = '${_normalize(boxName)}_${_normalize(dataKey)}';

  /// Normalised name of the Hive box holding the entry.
  final String boxName;

  /// Normalised, box-namespaced key of the entry.
  final String dataKey;

  @override
  List<Object?> get props => [boxName, dataKey];
}

/// {@template param_check_data}
/// Addresses the entry to test for existence.
/// {@endtemplate}
class ParamCheckData extends StorageParam {
  /// {@macro param_check_data}
  new({required super.boxName, required super.dataKey});
}

/// {@template param_get_data}
/// Addresses the entry to read.
/// {@endtemplate}
class ParamGetData extends StorageParam {
  /// {@macro param_get_data}
  new({required super.boxName, required super.dataKey});
}

/// {@template param_store_data}
/// Addresses the entry to write, and how its box should be protected.
///
/// [encrypted] only takes effect the first time a box is created. Once a box
/// exists its encryption mode is fixed, and later writes reuse it — passing a
/// different value is ignored rather than silently re-encrypting the box.
/// {@endtemplate}
class ParamStoreData extends StorageParam {
  /// {@macro param_store_data}
  new({required super.boxName, required super.dataKey, this.encrypted = false});

  /// Whether a newly created box should be AES encrypted.
  final bool encrypted;

  @override
  List<Object?> get props => [boxName, dataKey, encrypted];
}

/// {@template param_delete_data}
/// Addresses the entry to delete.
///
/// Deleting the last entry of a box also deletes the box from disk and, for an
/// encrypted box, its key from the platform keystore.
/// {@endtemplate}
class ParamDeleteData extends StorageParam {
  /// {@macro param_delete_data}
  new({required super.boxName, required super.dataKey});
}
