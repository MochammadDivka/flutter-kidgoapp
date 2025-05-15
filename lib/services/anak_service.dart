import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/anak_model.dart';

class AnakService {
  final String baseUrl = "http://10.10.175.210:8000/api";

  Future<List<AnakModel>> getDataAnak() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/anak'),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json"
      },
    );

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(response.body);
      return body.map((e) => AnakModel.fromJson(e)).toList();
    } else {
      throw Exception('Gagal mengambil data anak: ${response.body}');
    }
  }


  Future<bool> tambahDataAnak({
    required String nama,
    required DateTime tanggalLahir,
    required String jenisKelamin,
    File? foto,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/anak'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['nama'] = nama;
    request.fields['tanggal_lahir'] = tanggalLahir.toIso8601String();
    request.fields['jenis_kelamin'] = jenisKelamin;

    if (foto != null) {
      request.files.add(await http.MultipartFile.fromPath('foto', foto.path));
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    print("STATUS CODE: ${response.statusCode}");
    print("RESPONSE BODY: $responseBody");

    return response.statusCode == 201;
  }
  Future<bool> updateDataAnak({
    required int id,
    required String nama,
    required DateTime tanggalLahir,
    required String jenisKelamin,
    File? foto,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/anak/$id?_method=PUT'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['nama'] = nama;
    request.fields['tanggal_lahir'] = tanggalLahir.toIso8601String();
    request.fields['jenis_kelamin'] = jenisKelamin;

    if (foto != null) {
      request.files.add(await http.MultipartFile.fromPath('foto', foto.path));
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    print("STATUS CODE: ${response.statusCode}");
    print("RESPONSE BODY: $responseBody");

        return response.statusCode == 200;
    }

  Future<void> hapusDataAnak(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('$baseUrl/anak/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus data anak');
    }
  }
  Future<AnakModel> getAnakById(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/anak/$id'),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json"
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return AnakModel.fromJson(data);
    } else {
      throw Exception('Gagal mengambil data anak: ${response.body}');
    }
  }


}
