class AppConstants {
  // Change this to your backend URL
  static const String baseUrl = 'http://172.22.208.88:5000/api'; // Local WiFi — phone & PC on same network

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

class UserRole {
  static const String guard = 'guard';
  static const String host = 'host';
  static const String admin = 'admin';
  static const String superAdmin = 'superAdmin';
}

class VisitorStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String denied = 'denied';
  static const String checkedOut = 'checkedOut';

  static String label(String status) {
    switch (status) {
      case pending: return 'Pending';
      case approved: return 'Approved';
      case denied: return 'Denied';
      case checkedOut: return 'Checked Out';
      default: return status;
    }
  }
}
