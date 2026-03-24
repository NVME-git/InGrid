/// In-memory session flag reset on every page load.
/// Guards the /game route from direct-URL access or page reloads.
class SessionService {
  SessionService._();
  static bool gameSessionActive = false;
}
