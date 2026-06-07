class AdminConfig {
  AdminConfig._();

  static const Set<String> _adminUids = {'WLZuhj6DaIT2x05uY6fiS88X6852'};

  static bool isAdmin(String? uid) =>
      uid != null && _adminUids.contains(uid);
}
