/// Resolves `listBoxFileNames` to the implementation for the target platform.
///
/// Keeping the `dart:io` usage behind this conditional export is what lets the
/// package run — and be listed as supported — on web.
library;

export 'box_scanner_io.dart'
    if (dart.library.js_interop) 'box_scanner_web.dart';
