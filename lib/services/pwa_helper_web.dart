/// Web implementation using dart:html for PWA detection.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Returns true when the app is running as an installed PWA (standalone mode).
bool isStandalonePwa() {
  try {
    return html.window.matchMedia('(display-mode: standalone)').matches ||
        // Safari on iOS sets this property on the navigator object.
        (html.window.navigator as dynamic).standalone == true;
  } catch (_) {
    return false;
  }
}

/// Returns true when the user is on iOS (iPhone / iPad / iPod).
bool isIosBrowser() {
  try {
    final ua = html.window.navigator.userAgent.toLowerCase();
    return ua.contains('iphone') ||
        ua.contains('ipad') ||
        ua.contains('ipod');
  } catch (_) {
    return false;
  }
}
