import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import '../models/imunisasi_model.dart';

class ImunisasiService {
  final String baseUrl = 'http://10.10.175.210:8000/api';

  /// Ambil jadwal imunisasi berdasarkan anak ID
  Future<List<ImunisasiModel>> getJadwal(int anakId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/jadwal-imunisasi?anak_id=$anakId'),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json"
      },
    );

    print("GET STATUS: ${response.statusCode}");
    print("GET BODY: ${response.body}");
    print("Response JSON: ${response.body}");

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body is List) {
        return body.map((e) => ImunisasiModel.fromJson(e)).toList();
      }
      final List list = body['data'] ?? [];
      return list.map((e) => ImunisasiModel.fromJson(e)).toList();
    } else {
      throw Exception("Gagal mengambil data jadwal");
    }
  }

  /// Tambah data jadwal imunisasi baru
  Future<bool> tambahJadwal({
    required int anakId,
    required String namaImunisasi,
    required DateTime tanggalImunisasi,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/jadwal-imunisasi'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'anak_id': anakId,
        'nama_imunisasi': namaImunisasi,
        'tanggal_imunisasi': tanggalImunisasi.toIso8601String(),
      }),
    );

    return response.statusCode == 201;
  }

  /// Update data jadwal imunisasi termasuk file bukti
  Future<ImunisasiModel?> updateJadwal({
    required int id,
    required String namaImunisasi,
    required DateTime tanggalImunisasi,
    bool? isDone,
    File? buktiFile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/jadwal-imunisasi/$id?_method=PUT');
    final request = http.MultipartRequest('POST', uri); // Gunakan POST + _method=PUT
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['nama_imunisasi'] = namaImunisasi;
    request.fields['tanggal_imunisasi'] = tanggalImunisasi.toIso8601String();
    if (isDone != null) {
      request.fields['is_done'] = isDone ? '1' : '0';
    }

    if (buktiFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'bukti_file',
        buktiFile.path,
        filename: basename(buktiFile.path),
      ));
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseBody);

      print("UPDATE RESPONSE: $jsonResponse");

      // Cek apakah ada key 'data'
      final data = jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('data')
          ? jsonResponse['data']
          : jsonResponse;

      if (data == null || data is! Map<String, dynamic>) {
        throw Exception("Response data tidak valid");
      }

      return ImunisasiModel.fromJson(data);
    }

  }

  /// Menandai status selesai via endpoint toggle
  Future<bool> tandaiSelesai(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/imunisasi/$id/selesai'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    return response.statusCode == 200;
  }
  /// Hapus jadwal imunisasi berdasarkan ID
  Future<bool> hapusJadwal(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('$baseUrl/jadwal-imunisasi/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print("DELETE STATUS: ${response.statusCode}");
    print("DELETE BODY: ${response.body}");

    return response.statusCode == 200;
  }

}
