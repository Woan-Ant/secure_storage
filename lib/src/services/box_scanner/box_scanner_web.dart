import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Returns the name of every Hive box held in IndexedDB.
///
/// There are no files on web, so [directoryPath] is ignored. Hive CE opens one
/// IndexedDB database per box, named after the box, so enumerating the
/// databases for this origin enumerates the boxes.
///
/// Two caveats follow from the browser API:
///
/// * `indexedDB.databases()` is unimplemented in Firefox, which has no other
///   way to enumerate. This returns an empty list there rather than throwing.
/// * The listing covers every IndexedDB database on the origin. If your app
///   stores IndexedDB data outside Hive, those database names appear here too.
Future<List<String>> listBoxNames(String? directoryPath) async {
  final factory = web.window.indexedDB;
  if (!factory.has('databases')) return const [];

  final databases = await factory.databases().toDart;
  return <String>[for (final info in databases.toDart) info.name];
}
