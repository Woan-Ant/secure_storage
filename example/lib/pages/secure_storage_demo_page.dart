import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:secure_storage/secure_storage.dart';
import 'package:secure_storage_example/bloc/demo_storage_bloc.dart';

/// Exercises every storage operation against a box and key you type in.
class SecureStorageDemoPage extends StatefulWidget {
  /// Creates a [SecureStorageDemoPage].
  const SecureStorageDemoPage({super.key});

  /// Route path for this page.
  static const String path = '/secure_storage_demo_page';

  @override
  State<SecureStorageDemoPage> createState() => _SecureStorageDemoPageState();
}

class _SecureStorageDemoPageState extends State<SecureStorageDemoPage> {
  final TextEditingController _boxController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  final FocusNode _boxFocusNode = FocusNode();
  final FocusNode _keyFocusNode = FocusNode();
  bool _isEncrypted = true;

  @override
  void dispose() {
    _boxController.dispose();
    _keyController.dispose();
    _dataController.dispose();
    _boxFocusNode.dispose();
    _keyFocusNode.dispose();
    super.dispose();
  }

  void _show(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  /// Guards against the assertions in [StorageParam], which reject empty or
  /// non-alphanumeric segments in debug builds.
  bool _hasValidInput() {
    final isValid = RegExp(r'^[a-zA-Z0-9_ ]+$');
    if (!isValid.hasMatch(_boxController.text) ||
        !isValid.hasMatch(_keyController.text)) {
      _show('Box and key must be non-empty letters, digits, spaces or _');
      return false;
    }
    return true;
  }

  void _add(DemoStorageEvent event) =>
      context.read<DemoStorageBloc>().add(event);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secure Storage Demo')),
      body: BlocListener<DemoStorageBloc, DemoStorageState>(
        listener: (context, state) {
          switch (state) {
            case DemoStorageInitial() || DemoStorageLoading():
              break;
            case DemoCheckDataSuccess():
              _show(
                'exists: ${state.checker.exist}, '
                'encrypted: ${state.checker.encrypted}',
              );
            case DemoStoreDataSuccess():
              _show(state.message);
            case DemoGetDataSuccess():
              _show(state.data.toString());
            case DemoDeleteDataSuccess():
              _show(state.message);
            case DemoListEncryptedKeysSuccess():
              // Show the box names only — the values are live encryption keys.
              _show('encrypted boxes: ${state.keys.keys.toList()}');
            case DemoListUnencryptedKeysSuccess():
              _show('unencrypted boxes: ${state.keys}');
            case DemoStorageError():
              _show('Error: ${state.failure}');
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: _boxController,
                decoration: const InputDecoration(labelText: 'Box Name'),
                focusNode: _boxFocusNode,
                autofocus: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _keyController,
                decoration: const InputDecoration(labelText: 'Key Name'),
                focusNode: _keyFocusNode,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dataController,
                decoration: const InputDecoration(labelText: 'Data'),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 8),
              RadioGroup<bool>(
                groupValue: _isEncrypted,
                onChanged: (value) =>
                    setState(() => _isEncrypted = value ?? _isEncrypted),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Radio<bool>(value: true),
                    Text('Encrypted'),
                    Radio<bool>(value: false),
                    Text('Not Encrypted'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isDataExist,
                child: const Text('isDataExist'),
              ),
              ElevatedButton(onPressed: _storeData, child: const Text('store')),
              ElevatedButton(onPressed: _getData, child: const Text('get')),
              ElevatedButton(
                onPressed: _deleteData,
                child: const Text('delete'),
              ),
              ElevatedButton(
                onPressed: () =>
                    _add(const DemoListEncryptedKeysEvent()),
                child: const Text('listEncryptedKeys'),
              ),
              ElevatedButton(
                onPressed: () =>
                    _add(const DemoListUnencryptedKeysEvent()),
                child: const Text('listUnencryptedKeys'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _isDataExist() {
    if (!_hasValidInput()) return;
    _add(
      DemoCheckDataEvent(
        param: ParamCheckData(
          boxName: _boxController.text,
          dataKey: _keyController.text,
        ),
      ),
    );
  }

  void _storeData() {
    if (!_hasValidInput()) return;
    _add(
      DemoStoreDataEvent(
        param: ParamStoreData(
          boxName: _boxController.text,
          dataKey: _keyController.text,
          encrypted: _isEncrypted,
        ),
        data: _dataController.text,
      ),
    );
  }

  void _getData() {
    if (!_hasValidInput()) return;
    _add(
      DemoGetDataEvent(
        param: ParamGetData(
          boxName: _boxController.text,
          dataKey: _keyController.text,
        ),
      ),
    );
  }

  void _deleteData() {
    if (!_hasValidInput()) return;
    _add(
      DemoDeleteDataEvent(
        param: ParamDeleteData(
          boxName: _boxController.text,
          dataKey: _keyController.text,
        ),
      ),
    );
  }
}
