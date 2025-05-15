import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pertumbuhan_model.dart';

class PertumbuhanService {
  final String baseUrl = "http://10.10.175.210:8000/api";

  Future<List<PertumbuhanModel>> getDataPertumbuhan(int anakId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/catatan-pertumbuhan/anak/$anakId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    // LOG RESPONSE
    print('Status Code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // Cek apakah ada key 'data'
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        final List<dynamic> data = decoded['data'];

        // Tambah log jumlah data
        print('Jumlah data pertumbuhan: ${data.length}');

        return data.map((e) => PertumbuhanModel.fromJson(e)).toList();
      } else if (decoded is List) {
        // Kalau response langsung List (backup plan)
        print('Response langsung List dengan ${decoded.length} data');
        return decoded.map<PertumbuhanModel>((e) => PertumbuhanModel.fromJson(e)).toList();
      } else {
        throw Exception('Format data tidak dikenali');
      }
    } else {
      throw Exception('Gagal mengambil data pertumbuhan (status ${response.statusCode})');
    }
  }


  Future<bool> tambahDataPertumbuhan({
    required int anakId,
    required double beratBadan,
    required double tinggiBadan,
    required double lingkarKepala,
    required DateTime tanggalPengukuran,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/catatan-pertumbuhan'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'anak_id': anakId,
        'berat_badan': beratBadan,
        'tinggi_badan': tinggiBadan,
        'lingkar_kepala': lingkarKepala,
        'tanggal_pengukuran': tanggalPengukuran.toIso8601String(),
      }),
    );

    return response.statusCode == 201;
  }
  Future<bool> hapusDataPertumbuhan(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('$baseUrl/catatan-pertumbuhan/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true; // Berhasil hapus
    } else {
      throw Exception('Gagal menghapus data pertumbuhan');
    }
  }

  Future<bool> updateDataPertumbuhan({
    required int id,
    required int anakId,
    required double beratBadan,
    required double tinggiBadan,
    required double lingkarKepala,
    required DateTime tanggalPengukuran,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/catatan-pertumbuhan/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'anak_id': anakId,
        'berat_badan': beratBadan,
        'tinggi_badan': tinggiBadan,
        'lingkar_kepala': lingkarKepala,
        'tanggal_pengukuran': tanggalPengukuran.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      return true; // Update sukses
    } else {
      throw Exception('Gagal memperbarui data pertumbuhan');
    }
  }

}
