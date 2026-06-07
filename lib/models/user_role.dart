enum UserRole {
  admin,
  moderator,
  user;

  static UserRole fromString(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'moderator':
        return UserRole.moderator;
      default:
        return UserRole.user;
    }
  }

  String get firestoreValue {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.moderator:
        return 'moderator';
      case UserRole.user:
        return 'user';
    }
  }
}
