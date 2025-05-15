import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kidgoapp/models/imunisasi_model.dart';
import 'package:kidgoapp/services/imunisasi_service.dart';
import 'package:kidgoapp/screens/ImagePreview.dart';

class JadwalImunisasiDetailScreen extends StatefulWidget {
  final ImunisasiModel imunisasi;

  const JadwalImunisasiDetailScreen({super.key, required this.imunisasi});

  @override
  State<JadwalImunisasiDetailScreen> createState() => _JadwalImunisasiDetailScreenState();
}

class _JadwalImunisasiDetailScreenState extends State<JadwalImunisasiDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  late TextEditingController _namaController;
  late TextEditingController _tanggalController;
  late DateTime _selectedDateTime;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  File? _buktiFile;
  bool _isDone = false;
  final picker = ImagePicker();
  late ImunisasiModel imunisasi;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeTimeZone();
    imunisasi = widget.imunisasi;
    _selectedDateTime = widget.imunisasi.tanggal;

    _namaController = TextEditingController(text: widget.imunisasi.nama);
    _tanggalController = TextEditingController(
      text: DateFormat('dd-MM-yyyy HH:mm').format(widget.imunisasi.tanggal),
    );

    _isDone = widget.imunisasi.isDone;
    _setupNotifications();
  }

  Future<void> _initializeTimeZone() async {
    tz_data.initializeTimeZones();
    final String currentTimeZone = tz.local.name;
    debugPrint('Current timezone: $currentTimeZone');
  }

  @override
  void dispose() {
    _namaController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }

  Future<void> _setupNotifications() async {
    // Inisialisasi pengaturan untuk Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Gabungkan semua pengaturan platform
    const initSettings = InitializationSettings(android: androidSettings);

    // Inisialisasi plugin notifikasi
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handler ketika notifikasi diklik
        debugPrint('Notification clicked: ${details.payload}');
        // Tambahkan navigasi jika diperlukan
      },
    );
  }

  Future<void> _updateNotifications() async {
    // Batalkan notifikasi sebelumnya untuk jadwal ini
    await _notificationsPlugin.cancel(imunisasi.id);
    await _notificationsPlugin.cancel(imunisasi.id * 10); // Hapus notifikasi pengingat juga

    // Jika sudah selesai atau tanggal sudah lewat, tidak perlu buat notifikasi baru
    final now = DateTime.now();
    if (_isDone || _selectedDateTime.isBefore(now)) {
      return;
    }

    // Jadwalkan notifikasi baru
    // Notifikasi 1 jam sebelum jadwal
    final reminderTime = _selectedDateTime.subtract(const Duration(hours: 1));
    if (reminderTime.isAfter(now)) {
      await _scheduleSpecificNotification(
        id: imunisasi.id * 10, // Unique ID untuk reminder
        title: 'Pengingat Imunisasi',
        body: 'Imunisasi ${_namaController.text} akan berlangsung 1 jam lagi',
        scheduledTime: reminderTime,
        payload: imunisasi.id.toString(),
      );
    }

    // Notifikasi pada waktu jadwal
    await _scheduleSpecificNotification(
      id: imunisasi.id,
      title: 'Jadwal Imunisasi Sekarang',
      body: 'Waktunya imunisasi ${_namaController.text}',
      scheduledTime: _selectedDateTime,
      payload: imunisasi.id.toString(),
    );
  }

  Future<void> _scheduleSpecificNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    // Ensure timezone data is initialized
    tz_data.initializeTimeZones();

    // Convert DateTime to TZDateTime with proper timezone handling
    final location = tz.local;
    final tzDateTime = tz.TZDateTime(
      location,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    debugPrint('Scheduling notification at exact time: ${tzDateTime.toString()} for ID: $id');

    const androidDetails = AndroidNotificationDetails(
      'jadwal_channel',
      'Jadwal Imunisasi',
      channelDescription: 'Notifikasi untuk jadwal imunisasi',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('imunisasi_reminder'),
      enableVibration: true,
      visibility: NotificationVisibility.public,
      // Set full-screen intent for higher priority
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      autoCancel: true,
    );

    const notifDetails = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
      debugPrint('Notification successfully scheduled for ${scheduledTime.toString()} with ID: $id');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> _pickFile() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _buktiFile = File(picked.path);
      });
    }
  }

  Future<void> _selectDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.pinkAccent,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.pinkAccent,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _selectedDateTime = selectedDateTime;
          _tanggalController.text =
              DateFormat('dd-MM-yyyy HH:mm').format(selectedDateTime);
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update jadwal
      final updated = await ImunisasiService().updateJadwal(
        id: widget.imunisasi.id,
        namaImunisasi: _namaController.text,
        tanggalImunisasi: _selectedDateTime,
        isDone: _isDone,
        buktiFile: _buktiFile,
      );

      if (updated != null) {
        setState(() {
          imunisasi = updated;
          _isEditing = false;
        });

        // Update notifikasi setelah perubahan jadwal
        await _updateNotifications();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berhasil memperbarui data jadwal imunisasi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showErrorDialog("Gagal", "Gagal memperbarui data jadwal.");
      }
    } catch (e) {
      debugPrint('Error saving changes: $e');
      _showErrorDialog("Error", "Terjadi kesalahan: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.pink[50],
        title: Text(title, style: const TextStyle(color: Colors.pink)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.pink)),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.pink[50],
        title: const Text('Konfirmasi Hapus', style: TextStyle(color: Colors.pink)),
        content: const Text('Apakah Anda yakin ingin menghapus jadwal imunisasi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('BATAL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('HAPUS', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteJadwalImunisasi();
    }
  }

  Future<void> _deleteJadwalImunisasi() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Batalkan notifikasi untuk jadwal yang dihapus
      await _notificationsPlugin.cancel(imunisasi.id);
      await _notificationsPlugin.cancel(imunisasi.id * 10);

      final success = await ImunisasiService().hapusJadwal(imunisasi.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil menghapus jadwal imunisasi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        _showErrorDialog('Gagal', 'Gagal menghapus jadwal imunisasi');
      }
    } catch (e) {
      debugPrint('Error deleting jadwal: $e');
      _showErrorDialog('Error', 'Terjadi kesalahan saat menghapus: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildBuktiImunisasi() {
    final buktiFileName = imunisasi.buktiImunisasi ?? '';
    final hasExistingImage = buktiFileName.isNotEmpty;
    final imageUrl = 'http://10.10.175.210:8000/storage/$buktiFileName';

    return InkWell(
      onTap: () {
        if (_buktiFile != null) return;
        if (hasExistingImage) {
          final isPdf = buktiFileName.toLowerCase().endsWith('.pdf');
          if (!isPdf) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImagePreviewPage(imageUrl: imageUrl),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File ini adalah PDF, tidak dapat dipreview langsung.'),
              ),
            );
          }
        }
      },
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: _buktiFile != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            _buktiFile!,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        )
            : hasExistingImage
            ? (buktiFileName.endsWith('.pdf')
            ? Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.picture_as_pdf,
                size: 48, color: Colors.redAccent),
          ),
        )
            : ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                      : null,
                  color: Colors.pinkAccent,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.broken_image,
                      size: 48, color: Colors.redAccent),
                ),
              );
            },
          ),
        ))
            : Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: _isEditing ? _pickFile : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.upload_file,
                  color: Colors.grey[600],
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  _isEditing ? 'Tap untuk upload bukti' : 'Belum ada bukti imunisasi',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pinkAccent,
      appBar: AppBar(
        title: const Text("Detail Imunisasi"),
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: _isLoading
                ? null
                : () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama Imunisasi
                      const Text(
                        "Nama Imunisasi",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _namaController,
                        enabled: _isEditing,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.medical_services, color: Colors.pinkAccent),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.pinkAccent),
                          ),
                          hintText: "Masukkan nama imunisasi",
                        ),
                        validator: (value) =>
                        value!.isEmpty ? 'Nama imunisasi tidak boleh kosong' : null,
                      ),

                      const SizedBox(height: 16),

                      // Tanggal Imunisasi
                      const Text(
                        "Tanggal & Waktu",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _tanggalController,
                        readOnly: true,
                        enabled: _isEditing,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.calendar_today, color: Colors.pinkAccent),
                          suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.pinkAccent),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.pinkAccent),
                          ),
                          hintText: "Pilih tanggal dan waktu",
                        ),
                        onTap: _isEditing ? _selectDateTime : null,
                        validator: (value) =>
                        value!.isEmpty ? 'Tanggal dan waktu wajib diisi' : null,
                      ),

                      const SizedBox(height: 16),

                      // Status Imunisasi
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              _isDone ? Icons.check_circle : Icons.pending_actions,
                              color: _isDone ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Status Imunisasi",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: _isDone,
                              onChanged: _isEditing
                                  ? (val) {
                                setState(() {
                                  _isDone = val;
                                });
                              }
                                  : null,
                              activeColor: Colors.pinkAccent,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Bukti Imunisasi
                      const Text(
                        "Bukti Imunisasi",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isEditing)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ElevatedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.upload_file),
                            label: const Text("Upload Bukti Imunisasi"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pinkAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      _buildBuktiImunisasi(),

                      const SizedBox(height: 32),

                      // Tombol Simpan
                      if (_isEditing)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pinkAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'SIMPAN PERUBAHAN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Tombol Hapus
                      if (_isEditing)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: TextButton(
                            onPressed: _showConfirmDelete,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                            child: const Text(
                              'HAPUS JADWAL IMUNISASI',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}