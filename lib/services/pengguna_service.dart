import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pengguna_model.dart';

class PenggunaService {
  // Ganti dengan URL API Anda
  final String baseUrl = "http://192.168.1.12:8000/api";

  // Mendapatkan token dari SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Mendapatkan data profil pengguna
  Future<PenggunaModel> getProfile() async {
    final token = await _getToken();

    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login kembali.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PenggunaModel.fromJson(data);
    } else {
      // Coba decode pesan error
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal mengambil data profil');
      } catch (_) {
        throw Exception('Gagal mengambil data profil: ${response.statusCode}');
      }
    }
  }

  // Memperbarui profil pengguna
  Future<bool> updateProfile(PenggunaModel pengguna) async {
    final token = await _getToken();

    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login kembali.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/update-profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(pengguna.toJson()),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal memperbarui profil');
      } catch (_) {
        throw Exception('Gagal memperbarui profil: ${response.statusCode}');
      }
    }
  }
}