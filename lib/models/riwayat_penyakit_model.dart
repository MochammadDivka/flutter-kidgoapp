class RiwayatPenyakitModel {
  final int id;
  final int anakId;
  final String namaPenyakit;
  final String? deskripsi;
  final String? obat;
  final DateTime tanggalSakit;

  RiwayatPenyakitModel({
    required this.id,
    required this.anakId,
    required this.namaPenyakit,
    this.deskripsi,
    this.obat,
    required this.tanggalSakit,
  });

  factory RiwayatPenyakitModel.fromJson(Map<String, dynamic> json) {
    return RiwayatPenyakitModel(
      id: json['id'],
      anakId: json['anak_id'],
      namaPenyakit: json['nama_penyakit'],
      deskripsi: json['deskripsi'],
      obat: json['obat'],
      tanggalSakit: DateTime.parse(json['tanggal_sakit']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'anak_id': anakId,
      'nama_penyakit': namaPenyakit,
      'deskripsi': deskripsi,
      'obat': obat,
      'tanggal_sakit': tanggalSakit.toIso8601String(),
    };
  }
}