/// User profile / auth — not implemented in MVP.
class ProfileService {
  const ProfileService._();
  static const ProfileService instance = ProfileService._();

  bool get isLoggedIn => false;
  String? get userId => null;
}
