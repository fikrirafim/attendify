import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';
import 'result_page.dart';

class AbsenPage extends StatefulWidget {
  const AbsenPage({super.key});

  @override
  State<AbsenPage> createState() => _AbsenPageState();
}

class _AbsenPageState extends State<AbsenPage> {
  final double _targetLat = -7.028953326986354;
  final double _targetLng = 107.69808893907172;
  final double _radiusMax = 50.0;

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
      double distanceInMeters = Geolocator.distanceBetween(
          _targetLat, _targetLng, position.latitude, position.longitude);
      setState(() {
        _jarakMeter = distanceInMeters;
        _dalamRadius = distanceInMeters <= _radiusMax;
        _lokasiSaatIni = 'Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}';
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
    if (!_dalamRadius) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Presensi Gagal: Anda berada di luar jangkauan area kampus.'),
        backgroundColor: AppColors.red,
      ));
      return;
    }

    if (!_isCameraInitialized || _cameraController == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sistem kamera belum siap, mohon tunggu sebentar.'),
        backgroundColor: AppColors.red,
      ));
      return;
    }

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sesi tidak valid, silakan login kembali.'),
        backgroundColor: AppColors.red,
      ));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.blue)),
    );

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot userSnapshot = await firestore
          .collection('users')
          .where('email', isEqualTo: currentUser.email)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Data pengguna tidak ditemukan di sistem.'),
          backgroundColor: AppColors.red,
        ));
        return;
      }

      var dataUser = userSnapshot.docs.first.data() as Map<String, dynamic>;
      String inputNrp = dataUser['nrp'] ?? '000000';
      String namaSiswa = dataUser['nama'] ?? 'Karyawan';

      DateTime waktuSekarang = DateTime.now();
      String hari = waktuSekarang.day.toString().padLeft(2, '0');
      String bulan = waktuSekarang.month.toString().padLeft(2, '0');
      String tahun = waktuSekarang.year.toString();
      String tanggalHariIni = "$hari-$bulan-$tahun";

      QuerySnapshot riwayatAbsen = await firestore
          .collection('absensi')
          .where('nrp', isEqualTo: inputNrp)
          .get();

      int hitungAbsenHariIni = 0;
      for (var doc in riwayatAbsen.docs) {
        String waktu = doc['waktu_absen'] ?? '';
        if (waktu.startsWith(tanggalHariIni)) {
          hitungAbsenHariIni++;
        }
      }

      if (hitungAbsenHariIni >= 2) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Presensi ditolak: Anda sudah melakukan absen Masuk dan Pulang hari ini.'),
          backgroundColor: AppColors.red,
        ));
        return;
      }

      String jenisAbsen = hitungAbsenHariIni == 0 ? "Masuk" : "Pulang";
      String uniqueId = "absen_${inputNrp}_${waktuSekarang.millisecondsSinceEpoch}";

      XFile? capturedImage;
      try {
        capturedImage = await _cameraController!.takePicture();
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal mengambil gambar: $e'),
          backgroundColor: AppColors.red,
        ));
        return;
      }

      String batasJamMasuk = "08:00";
      String batasJamPulang = "17:00";

      try {
        QuerySnapshot hrSnapshot = await firestore
            .collection('users')
            .where('role', isEqualTo: 'hr')
            .get();
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

      if (jenisAbsen == "Masuk") {
        List<String> splitMasuk = batasJamMasuk.split(':');
        int batasHourMasuk = int.parse(splitMasuk[0]);
        int batasMinuteMasuk = int.parse(splitMasuk[1]);

        if (waktuSekarang.hour > batasHourMasuk ||
            (waktuSekarang.hour == batasHourMasuk && waktuSekarang.minute > batasMinuteMasuk)) {
          statusKehadiran = "Terlambat";
        }
      } else {
        List<String> splitPulang = batasJamPulang.split(':');
        int batasHourPulang = int.parse(splitPulang[0]);
        int batasMinutePulang = int.parse(splitPulang[1]);

        if (waktuSekarang.hour < batasHourPulang ||
            (waktuSekarang.hour == batasHourPulang && waktuSekarang.minute < batasMinutePulang)) {
          statusKehadiran = "Pulang Cepat";
        } else {
          statusKehadiran = "Selesai Sif";
        }
      }

      String jam = waktuSekarang.hour.toString().padLeft(2, '0');
      String menit = waktuSekarang.minute.toString().padLeft(2, '0');
      String formatWaktuCantik = "$tanggalHariIni $jam:$menit";

      String downloadUrl = "";
      try {
        final bytes = await capturedImage.readAsBytes();
        String imgbbApiKey = '5d0b36d874199ba68bcffe5dd6f3402a';

        var request = http.MultipartRequest(
            'POST', Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey'));
        request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'absen.jpg'));

        var response = await request.send();
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);

        if (response.statusCode == 200 && json['data'] != null) {
          downloadUrl = json['data']['url'];
        }
      } catch (e) {
        debugPrint("Upload foto gagal: $e");
      }

      await firestore.collection('absensi').doc(uniqueId).set({
        'nrp': inputNrp,
        'nama': namaSiswa,
        'latitude': _targetLat,
        'longitude': _targetLng,
        'waktu_absen': formatWaktuCantik,
        'status': statusKehadiran,
        'jenis_absen': jenisAbsen,
        'photo_url': downloadUrl,
      });

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Presensi $jenisAbsen berhasil: $statusKehadiran'),
        backgroundColor: statusKehadiran == 'Terlambat' || statusKehadiran == 'Pulang Cepat'
            ? AppColors.orange
            : AppColors.green,
      ));

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Terjadi kesalahan sistem: $e'),
        backgroundColor: AppColors.red,
      ));
    }
  }

  String _formatTanggal() {
    final namaHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final namaBulan = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    final now = DateTime.now();
    return '${namaHari[now.weekday - 1]}, ${now.day} ${namaBulan[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Presensi Kehadiran',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _formatTanggal(),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              Center(child: _buildCameraViewfinder()),
              const SizedBox(height: 20),

              _buildLocationCard(),
              const SizedBox(height: 16),

              _buildVerificationCard(),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoadingLokasi ? null : _prosesAbsen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _dalamRadius ? AppColors.blue : AppColors.textMuted,
                    disabledBackgroundColor: AppColors.textMuted,
                    elevation: _dalamRadius ? 3 : 0,
                    shadowColor: _dalamRadius ? AppColors.blue.withValues(alpha: 0.35) : Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'KIRIM PRESENSI',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Pastikan wajah terlihat jelas dan Anda berada di area kampus',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraViewfinder() {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: _isCameraInitialized && _cameraController != null
                  ? CameraPreview(_cameraController!)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1A1D26), Color(0xFF2D3040)],
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                    ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.6,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: _buildCameraCorner(true, true),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: _buildCameraCorner(true, false),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: _buildCameraCorner(false, true),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: _buildCameraCorner(false, false),
            ),
            Center(
              child: Container(
                width: 120,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2.5),
                  borderRadius: BorderRadius.circular(60),
                ),
              ),
            ),
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Front Camera',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraCorner(bool isTop, bool isLeft) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: isTop && isLeft ? const Radius.circular(4) : Radius.zero,
          topRight: isTop && !isLeft ? const Radius.circular(4) : Radius.zero,
          bottomLeft: !isTop && isLeft ? const Radius.circular(4) : Radius.zero,
          bottomRight: !isTop && !isLeft ? const Radius.circular(4) : Radius.zero,
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_rounded, color: AppColors.green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isLoadingLokasi
                    ? Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mencari lokasi...',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green),
                          ),
                        ],
                      )
                    : Text(
                        _dalamRadius
                            ? 'Di dalam radius kampus (${_jarakMeter.toStringAsFixed(0)}m)'
                            : 'Di luar area kampus (${_jarakMeter.toStringAsFixed(0)}m)',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _dalamRadius ? AppColors.green : AppColors.red,
                        ),
                      ),
                const SizedBox(height: 2),
                Text(
                  _isLoadingLokasi ? '' : 'Akurasi: GPS OK • $_lokasiSaatIni',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(
                'Status Verifikasi',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildVerifyChip(
                icon: Icons.location_on_rounded,
                label: 'Lokasi',
                verified: _dalamRadius,
                color: _dalamRadius ? AppColors.green : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              _buildVerifyChip(
                icon: Icons.camera_alt_rounded,
                label: 'Kamera',
                verified: _isCameraInitialized,
                color: _isCameraInitialized ? AppColors.green : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              _buildVerifyChip(
                icon: Icons.hourglass_empty_rounded,
                label: 'Menunggu',
                verified: false,
                color: AppColors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyChip({
    required IconData icon,
    required String label,
    required bool verified,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: verified ? AppColors.greenLight : AppColors.blueLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: verified ? const Color(0xFFBBF7D0) : const Color(0xFFBFDBFE),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              verified ? '$label ✓' : label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
