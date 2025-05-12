class ApiConstants {
  // Base URL untuk API
  static const String baseUrl = 'https://api.kidgoapp.com/api'; // Ganti dengan URL API Anda

  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String getDataAnak = '/anak';

  // Timeout durasi
  static const int connectionTimeout = 30000; // 30 detik
  static const int receiveTimeout = 30000; // 30 detik
}