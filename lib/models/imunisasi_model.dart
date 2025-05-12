class ImunisasiModel {
  final int id;
  final int anakId;
  final String nama;
  final DateTime tanggal;
  final bool isDone;
  final String? buktiImunisasi;

  ImunisasiModel({
    required this.id,
    required this.anakId,
    required this.nama,
    required this.tanggal,
    required this.isDone,
    this.buktiImunisasi,
  });

  factory ImunisasiModel.fromJson(Map<String, dynamic> json) {
    return ImunisasiModel(
      id: json['id'],
      anakId: json['anak_id'],
      nama: json['nama_imunisasi'],
      tanggal: DateTime.parse(json['tanggal_imunisasi']),
      isDone: json['is_done'] == true || json['is_done'] == 1,
      buktiImunisasi: json['bukti_file'], // akan null jika tidak ada
    );
  }
}
