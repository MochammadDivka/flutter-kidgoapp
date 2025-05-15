import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pengguna_model.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AuthService {
  String? errorMessage;
  final String baseUrl = "http://10.10.175.210:8000/api";

  Future<bool> register(PenggunaModel pengguna) async {
    try {
      print("🔄 Mengirim data ke API...");

      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: jsonEncode(pengguna.toJson()),
      );

      print("✅ Response status: ${response.statusCode}");
      print("📩 Response body: ${response.body}");

      if (response.statusCode == 201) {
        return true;
      } else {
        // Coba decode response body untuk mengambil pesan error
        final responseBody = jsonDecode(response.body);

        // Kasus validasi 422 (misal: email sudah dipakai)
        if (response.statusCode == 422 && responseBody['errors'] != null) {
          if (responseBody['errors']['email'] != null) {
            String rawMessage = responseBody['errors']['email'][0];
            if (rawMessage.contains("already been taken")) {
              errorMessage = "Email ini sudah terdaftar. Silakan gunakan email lain.";
            } else {
              errorMessage = rawMessage;
            }
          } else {
            errorMessage = responseBody['message'];
          }
        } else {
          // Jika error umum
          errorMessage = responseBody['message'] ?? "Registrasi gagal. Silakan coba lagi.";
        }

        return false;
      }
    } catch (e) {
      print("❌ Error saat mengirim request: $e");
      errorMessage = "Terjadi kesalahan saat menghubungi server.";
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print("🔐 Mengirim data login ke API...");

      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: jsonEncode({
          "email": email,
          "kata_sandi": password,
        }),
      );

      print("✅ Response status: ${response.statusCode}");
      print("📩 Response body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Simpan token ke SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);

        return {
          'success': true,
          'token': data['token'],
          'punya_data_anak': data['punya_data_anak'] ?? false,
          'message': "Login berhasil"
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? "Email atau password salah."
        };
      }
    } catch (e) {
      print("❌ Error saat login: $e");
      return {
        'success': false,
        'message': "Tidak dapat terhubung ke server."
      };
    }
  }

  // Forgot Password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      print("📧 Mengirim permintaan reset password ke API...");

      final response = await http.post(
        Uri.parse("$baseUrl/forgot-password"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: jsonEncode({
          "email": email,
        }),
      );

      print("✅ Response status: ${response.statusCode}");
      print("📩 Response body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? "Email reset password telah dikirim"
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? "Gagal mengirim email reset password"
        };
      }
    } catch (e) {
      print("❌ Error saat mengirim permintaan reset password: $e");
      return {
        'success': false,
        'message': "Terjadi kesalahan koneksi."
      };
    }
  }

  // Reset Password - Perbarui implementasi untuk lebih robustness
  Future<Map<String, dynamic>> resetPassword(String email, String token, String password, String passwordConfirmation) async {
    try {
      print("🔄 Mengirim data reset password ke API...");

      final response = await http.post(
        Uri.parse("$baseUrl/reset-password"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: jsonEncode({
          "email": email,  // Tambahkan email yang sebelumnya tidak ada
          "token": token,
          "password": password,
          "password_confirmation": passwordConfirmation,
        }),
      );

      print("✅ Response status: ${response.statusCode}");
      print("📩 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? "Password berhasil direset"
        };
      } else {
        // Coba parse pesan error
        try {
          final data = jsonDecode(response.body);
          return {
            'success': false,
            'message': data['message'] ?? "Gagal mereset password"
          };
        } catch (e) {
          return {
            'success': false,
            'message': "Gagal mereset password. Status code: ${response.statusCode}"
          };
        }
      }
    } catch (e) {
      print("❌ Error saat reset password: $e");
      return {
        'success': false,
        'message': "Terjadi kesalahan koneksi: $e"
      };
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null;
  }
}