/// Conditional export: uses dart:html on web, stub elsewhere.
export 'pwa_helper_stub.dart'
    if (dart.library.html) 'pwa_helper_web.dart';
