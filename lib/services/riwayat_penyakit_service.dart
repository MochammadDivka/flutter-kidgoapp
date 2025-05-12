import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/riwayat_penyakit_model.dart';

class RiwayatPenyakitService {
  final String baseUrl = 'http://192.168.1.12:8000/api';

  /// Mengambil data riwayat penyakit berdasarkan ID anak
  Future<List<RiwayatPenyakitModel>> getRiwayatPenyakit(int anakId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/riwayat-penyakit?anak_id=$anakId'),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json"
      },
    );

    print("GET STATUS: ${response.statusCode}");
    print("GET BODY: ${response.body}");

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body is List) {
        return body.map((e) => RiwayatPenyakitModel.fromJson(e)).toList();
      }
      final List list = body['data'] ?? [];
      return list.map((e) => RiwayatPenyakitModel.fromJson(e)).toList();
    } else {
      throw Exception("Gagal mengambil data riwayat penyakit");
    }
  }

  /// Tambah data riwayat penyakit baru
  Future<bool> tambahRiwayatPenyakit({
    required int anakId,
    required String namaPenyakit,
    required DateTime tanggalSakit,
    String? deskripsi,
    String? obat,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/riwayat-penyakit'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'anak_id': anakId,
        'nama_penyakit': namaPenyakit,
        'tanggal_sakit': tanggalSakit.toIso8601String(),
        'deskripsi': deskripsi,
        'obat': obat,
      }),
    );

    print("POST STATUS: ${response.statusCode}");
    print("POST BODY: ${response.body}");

    return response.statusCode == 201;
  }

  /// Update data riwayat penyakit
  Future<RiwayatPenyakitModel?> updateRiwayatPenyakit({
    required int id,
    required String namaPenyakit,
    required DateTime tanggalSakit,
    String? deskripsi,
    String? obat,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/riwayat-penyakit/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nama_penyakit': namaPenyakit,
        'tanggal_sakit': tanggalSakit.toIso8601String(),
        'deskripsi': deskripsi,
        'obat': obat,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      // Cek apakah ada key 'data'
      final data = jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('data')
          ? jsonResponse['data']
          : jsonResponse;

      if (data == null || data is! Map<String, dynamic>) {
        throw Exception("Response data tidak valid");
      }

      return RiwayatPenyakitModel.fromJson(data);
    } else {
      throw Exception("Gagal update data riwayat penyakit");
    }
  }

  /// Hapus data riwayat penyakit
  Future<bool> hapusRiwayatPenyakit(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('$baseUrl/riwayat-penyakit/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    return response.statusCode == 200;
  }
}