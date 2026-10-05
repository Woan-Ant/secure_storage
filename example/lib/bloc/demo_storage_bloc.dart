import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:secure_storage/secure_storage.dart';

part 'demo_storage_event.dart';
part 'demo_storage_state.dart';

/// Drives the demo page by delegating to the package's use cases.
///
/// Every handler follows the same shape: emit [DemoStorageLoading], await the
/// use case, then fold the `Either` into either [DemoStorageError] or the
/// matching success state. Nothing here needs a try/catch, because the use
/// cases never throw.
class DemoStorageBloc extends Bloc<DemoStorageEvent, DemoStorageState> {
  /// Creates a [DemoStorageBloc] from the use cases registered by
  /// [initSecureStorageFeature].
  new({
    required CheckDataUseCase checkDataUseCase,
    required StoreDataUseCase storeDataUseCase,
    required GetDataUseCase getDataUseCase,
    required DeleteDataUseCase deleteDataUseCase,
    required ListEncryptedKeysUseCase listEncryptedKeysUseCase,
    required ListUnencryptedKeysUseCase listUnencryptedKeysUseCase,
  }) : _checkDataUseCase = checkDataUseCase,
       _storeDataUseCase = storeDataUseCase,
       _getDataUseCase = getDataUseCase,
       _deleteDataUseCase = deleteDataUseCase,
       _listEncryptedKeysUseCase = listEncryptedKeysUseCase,
       _listUnencryptedKeysUseCase = listUnencryptedKeysUseCase,
       super(const DemoStorageInitial()) {
    on<DemoCheckDataEvent>((event, emit) async {
      emit(const DemoStorageLoading());
      final result = await _checkDataUseCase(param: event.param);
      emit(
        result.fold<DemoStorageState>(
          DemoStorageError.new,
          (checker) => DemoCheckDataSuccess(checker: checker),
        ),
      );
    });

    on<DemoStoreDataEvent>((event, emit) async {
      emit(const DemoStorageLoading());
      final result = await _storeDataUseCase(
        param: (param: event.param, data: event.data),
      );
      emit(
        result.fold<DemoStorageState>(
          DemoStorageError.new,
          (message) => DemoStoreDataSuccess(message: message),
        ),
      );
    });

    on<DemoGetDataEvent>((event, emit) async {
      emit(const DemoStorageLoading());
      final result = await _getDataUseCase(param: event.param);
      emit(
        result.fold<DemoStorageState>(
          DemoStorageError.new,
          (data) => DemoGetDataSuccess(data: data),
        ),
      );
    });

    on<DemoDeleteDataEvent>((event, emit) async {
      emit(const DemoStorageLoading());
      final result = await _deleteDataUseCase(param: event.param);
      emit(
        result.fold<DemoStorageState>(
          DemoStorageError.new,
          (message) => DemoDeleteDataSuccess(message: message),
        ),
      );
    });

    on<DemoListEncryptedKeysEvent>((event, emit) async {
      emit(const DemoStorageLoading());
      final result = await _listEncryptedKeysUseCase();
      emit(
        result.fold<DemoStorageState>(
          DemoStorageError.new,
          (keys) => DemoListEncryptedKeysSuccess(keys: keys),
        ),
      );
    });

    on<DemoListUnencryptedKeysEvent>((event, emit) async {
      emit(const DemoStorageLoading());
      final result = await _listUnencryptedKeysUseCase();
      emit(
        result.fold<DemoStorageState>(
          DemoStorageError.new,
          (keys) => DemoListUnencryptedKeysSuccess(keys: keys),
        ),
      );
    });
  }

  final CheckDataUseCase _checkDataUseCase;
  final StoreDataUseCase _storeDataUseCase;
  final GetDataUseCase _getDataUseCase;
  final DeleteDataUseCase _deleteDataUseCase;
  final ListEncryptedKeysUseCase _listEncryptedKeysUseCase;
  final ListUnencryptedKeysUseCase _listUnencryptedKeysUseCase;
}
