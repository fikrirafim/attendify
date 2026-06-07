import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Tambahan buat baca user login
import 'result_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AbsenPage extends StatefulWidget {
  const AbsenPage({super.key});

  @override
  State<AbsenPage> createState() => _AbsenPageState();
}

class _AbsenPageState extends State<AbsenPage> {
  // --- KONFIGURASI TITIK ABSEN ---
  final double _targetLat = -7.0374897906321445;
  final double _targetLng =  107.69522312602665;
  final double _radiusMax = 50.0;

  // Variabel Lokasi & Kamera
  String _lokasiSaatIni = 'Sedang mencari lokasi...';
  bool _isLoadingLokasi = true;
  bool _dalamRadius = false;
  double _jarakMeter = 0.0;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _dapatkanLokasi();
    _initKamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initKamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false);
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Kamera error: $e");
    }
  }

  Future<void> _dapatkanLokasi() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position position = await Geolocator.getCurrentPosition();
      double distanceInMeters = Geolocator.distanceBetween(_targetLat, _targetLng, position.latitude, position.longitude);
      setState(() {
        _jarakMeter = distanceInMeters;
        _dalamRadius = distanceInMeters <= _radiusMax;
        _lokasiSaatIni = 'Lat: ${position.latitude.toStringAsFixed(4)}\nLong: ${position.longitude.toStringAsFixed(4)}';
        _isLoadingLokasi = false;
      });
    } catch (e) {
      setState(() {
        _lokasiSaatIni = 'Gagal mengakses layanan GPS';
        _isLoadingLokasi = false;
      });
    }
  }

 Future<void> _prosesAbsen() async {
    // 1. Validasi Lokasi & Kamera
    if (!_dalamRadius) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Presensi Gagal: Anda berada di luar jangkauan area kampus.'), backgroundColor: Colors.red));
      return;
    }

    if (!_isCameraInitialized || _cameraController == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sistem kamera belum siap, mohon tunggu sebentar.'), backgroundColor: Colors.red));
      return;
    }

    // 2. Tarik Data User yang sedang Login
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesi tidak valid, silakan login kembali.'), backgroundColor: Colors.red));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot userSnapshot = await firestore.collection('users').where('email', isEqualTo: currentUser.email).limit(1).get();
      
      if (userSnapshot.docs.isEmpty) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data pengguna tidak ditemukan di sistem.'), backgroundColor: Colors.red));
        return;
      }

      var dataUser = userSnapshot.docs.first.data() as Map<String, dynamic>;
      String inputNrp = dataUser['nrp'] ?? '000000';
      String namaSiswa = dataUser['nama'] ?? 'Karyawan';

      // --- LOGIK BARU: CEK JATAH ABSEN HARI INI ---
      DateTime waktuSekarang = DateTime.now();
      String hari = waktuSekarang.day.toString().padLeft(2, '0');
      String bulan = waktuSekarang.month.toString().padLeft(2, '0');
      String tahun = waktuSekarang.year.toString();
      String tanggalHariIni = "$hari-$bulan-$tahun"; // Contoh: 07-06-2026

      // Tarik semua riwayat absen milik NRP ini
      QuerySnapshot riwayatAbsen = await firestore.collection('absensi').where('nrp', isEqualTo: inputNrp).get();

      int hitungAbsenHariIni = 0;
      for (var doc in riwayatAbsen.docs) {
        String waktu = doc['waktu_absen'] ?? '';
        // Kalau format waktunya diawali dengan tanggal hari ini, berarti itu absen hari ini
        if (waktu.startsWith(tanggalHariIni)) {
          hitungAbsenHariIni++;
        }
      }

      // Kalau udah absen 2x hari ini, langsung tolak mentah-mentah!
      if (hitungAbsenHariIni >= 2) {
        if (!mounted) return;
        Navigator.pop(context); // Tutup loading
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Presensi ditolak: Anda sudah melakukan absen Masuk dan Pulang hari ini.'), 
          backgroundColor: Colors.red
        ));
        return;
      }

      // Tentukan ini absen Masuk atau Pulang
      String jenisAbsen = hitungAbsenHariIni == 0 ? "Masuk" : "Pulang";
      String uniqueId = "absen_${inputNrp}_${waktuSekarang.millisecondsSinceEpoch}";
      // ---------------------------------------------

      // 4. Ambil Foto
      XFile? capturedImage;
      try {
        capturedImage = await _cameraController!.takePicture();
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e'), backgroundColor: Colors.red));
        return;
      }

// 5. Cek Batas Jam HR (Masuk & Pulang)
      String batasJamMasuk = "08:00"; 
      String batasJamPulang = "17:00"; 
      
      try {
        QuerySnapshot hrSnapshot = await firestore.collection('users').where('role', isEqualTo: 'hr').get();
        for (var doc in hrSnapshot.docs) {
          Map<String, dynamic> dataHR = doc.data() as Map<String, dynamic>;
          if (dataHR.containsKey('jam_masuk_default') && dataHR['jam_masuk_default'] != null) {
            batasJamMasuk = dataHR['jam_masuk_default'];
          }
          if (dataHR.containsKey('jam_pulang_default') && dataHR['jam_pulang_default'] != null) {
            batasJamPulang = dataHR['jam_pulang_default'];
          }
        }
      } catch (e) {
        debugPrint("Gagal memuat konfigurasi jam HR");
      }

      String statusKehadiran = "Tepat Waktu"; 
      
      // LOGIKA KETAT: Masuk vs Pulang
      if (jenisAbsen == "Masuk") {
        List<String> splitMasuk = batasJamMasuk.split(':');
        int batasHourMasuk = int.parse(splitMasuk[0]);
        int batasMinuteMasuk = int.parse(splitMasuk[1]);
        
        // Kalau jam sekarang LEBIH DARI jam masuk = Terlambat
        if (waktuSekarang.hour > batasHourMasuk || (waktuSekarang.hour == batasHourMasuk && waktuSekarang.minute > batasMinuteMasuk)) {
          statusKehadiran = "Terlambat";
        }
      } else {
        // Kalau ini absen Pulang
        List<String> splitPulang = batasJamPulang.split(':');
        int batasHourPulang = int.parse(splitPulang[0]);
        int batasMinutePulang = int.parse(splitPulang[1]);
        
        // Kalau jam sekarang KURANG DARI jam pulang = Pulang Cepat
        if (waktuSekarang.hour < batasHourPulang || (waktuSekarang.hour == batasHourPulang && waktuSekarang.minute < batasMinutePulang)) {
          statusKehadiran = "Pulang Cepat";
        } else {
          statusKehadiran = "Selesai Sif"; // Pulang di jam yang aman
        }
      }

      String jam = waktuSekarang.hour.toString().padLeft(2, '0');
      String menit = waktuSekarang.minute.toString().padLeft(2, '0');
      String formatWaktuCantik = "$tanggalHariIni $jam:$menit";

      // 6. Upload ImgBB
      final bytes = await capturedImage.readAsBytes(); 
      String imgbbApiKey = '5d0b36d874199ba68bcffe5dd6f3402a'; 
      
      var request = http.MultipartRequest('POST', Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey'));
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'absen.jpg'));
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var json = jsonDecode(responseData);
      String downloadUrl = json['data']['url']; 

      // 7. Simpan Database
      await firestore.collection('absensi').doc(uniqueId).set({
        'nrp': inputNrp,
        'nama': namaSiswa,
        'latitude': _targetLat,
        'longitude': _targetLng,
        'waktu_absen': formatWaktuCantik, 
        'status': statusKehadiran, 
        'jenis_absen': jenisAbsen, // Menyimpan keterangan Masuk/Pulang
        'photo_url': downloadUrl, 
      });

      if (!mounted) return;
      Navigator.pop(context); 

      // Notifikasi Formal
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Presensi $jenisAbsen berhasil: $statusKehadiran'), 
        backgroundColor: statusKehadiran == 'Terlambat' ? Colors.red : Colors.green,
      ));

      // 8. Pindah Result
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(
            nrp: inputNrp,
            nama: namaSiswa,
            waktuAbsen: waktuSekarang,
            lokasi: 'Terverifikasi di Area Kampus',
            koordinat: '$_targetLat, $_targetLng',
            capturedImage: capturedImage,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      debugPrint("ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan sistem: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Presensi', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Lokasi & Jarak
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                border: Border.all(
                  color: _isLoadingLokasi ? Colors.transparent : (_dalamRadius ? Colors.green.shade200 : Colors.red.shade200),
                  width: 2,
                )
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isLoadingLokasi ? Colors.blue[50] : (_dalamRadius ? Colors.green[50] : Colors.red[50]), 
                      shape: BoxShape.circle
                    ),
                    child: _isLoadingLokasi 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(_dalamRadius ? Icons.check_circle : Icons.cancel, color: _dalamRadius ? Colors.green : Colors.red),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status Jangkauan', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        if (!_isLoadingLokasi) ...[
                          Text(_dalamRadius ? 'Di Area Kampus (${_jarakMeter.toStringAsFixed(0)}m)' : 'Di Luar Area (${_jarakMeter.toStringAsFixed(0)}m)', 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _dalamRadius ? Colors.green[700] : Colors.red[700])
                          ),
                          const SizedBox(height: 4),
                          Text(_lokasiSaatIni, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Kamera Preview
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _isCameraInitialized
                    ? CameraPreview(_cameraController!)
                    : const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 30),

            // Tombol Action - SEKARANG LANGSUNG DI BAWAH KAMERA
            ElevatedButton(
              onPressed: _isLoadingLokasi ? null : _prosesAbsen,
              style: ElevatedButton.styleFrom(
                backgroundColor: _dalamRadius ? Colors.blueAccent : Colors.grey[400],
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: _dalamRadius ? 5 : 0,
              ),
              child: const Text('KIRIM PRESENSI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}