class AdminAuthService {
  static const String adminEmail = 'admin@gmail.com';
  static const String adminPassword = 'admin123';

  static bool _isAdminSignedIn = false;

  static bool get isAdminSignedIn => _isAdminSignedIn;

  static bool isAdminEmail(String email) {
    return email.trim().toLowerCase() == adminEmail;
  }

  static bool signIn({required String email, required String password}) {
    _isAdminSignedIn = isAdminEmail(email) && password.trim() == adminPassword;
    return _isAdminSignedIn;
  }

  static void signOut() {
    _isAdminSignedIn = false;
  }
}
