import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'result_page.dart';

class AbsenPage extends StatefulWidget {
  const AbsenPage({super.key});

  @override
  State<AbsenPage> createState() => _AbsenPageState();
}

class _AbsenPageState extends State<AbsenPage> {
  // --- KONFIGURASI TITIK ABSEN ---
  final double _targetLat = -6.938396;
  final double _targetLng = 107.658411;
  final double _radiusMax = 50.0;

  // Variabel Lokasi & Kamera
  String _lokasiSaatIni = 'Mencari lokasi...';
  bool _isLoadingLokasi = true;
  bool _dalamRadius = false;
  double _jarakMeter = 0.0;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  // --- TAMBAHAN: CONTROLLER NRP & DATABASE LOKAL ---
  final TextEditingController _nrpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dapatkanLokasi();
    _initKamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _nrpController.dispose(); // Jangan lupa dibuang biar gak bocor memori
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
        _lokasiSaatIni = 'Gagal akses GPS';
        _isLoadingLokasi = false;
      });
    }
  }

  Future<void> _prosesAbsen() async {
    // 1. Validasi Input Kosong
    String inputNrp = _nrpController.text.trim();
    if (inputNrp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NRP wajib diisi bro!'), backgroundColor: Colors.orange));
      return;
    }

    // 2. Validasi Jarak
    if (!_dalamRadius) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: Lu masih di luar radius kampus!'), backgroundColor: Colors.red));
      return;
    }

    // 3. Validasi Kamera
    if (!_isCameraInitialized || _cameraController == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kamera belum siap!'), backgroundColor: Colors.red));
      return;
    }

    // Munculin Loading...
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 4. AMBIL FOTO DARI KAMERA
      XFile? capturedImage;
      try {
        capturedImage = await _cameraController!.takePicture();
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Tutup loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal ambil foto: $e'), backgroundColor: Colors.red));
        return;
      }

      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // 5. CEK NRP KE BUKU INDUK FIREBASE (Cek ke collection 'nrp')
      DocumentSnapshot docUser = await firestore.collection('nrp').doc(inputNrp).get();

      // Kalau NRP gak ketemu di database Firebase...
      if (!docUser.exists) {
        if (!mounted) return;
        Navigator.pop(context); // Tutup loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('NRP $inputNrp tidak ada di Database Firebase!'), backgroundColor: Colors.red));
        return;
      }

      // Kalau NRP ketemu, tarik nama aslinya dari database
      String namaSiswa = docUser.get('nama');

      // 6. SIMPAN DATA ABSENSI KE COLLECTION 'absensi'
      String uniqueId = "absen_${inputNrp}_${DateTime.now().millisecondsSinceEpoch}";

      await firestore.collection('absensi').doc(uniqueId).set({
        'nrp': inputNrp,
        'nama': namaSiswa,
        'latitude': _targetLat,
        'longitude': _targetLng,
        'waktu_absen': DateTime.now().toIso8601String(),
        'status': 'Hadir',
        'photo_path': capturedImage.path, // Simpan path foto
      });

      if (!mounted) return;
      Navigator.pop(context); // Tutup loading
      _nrpController.clear(); // Bersihin inputan biar kosong lagi

      // 7. NAVIGASI KE RESULT PAGE DENGAN DATA LENGKAP
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(
            nrp: inputNrp,
            nama: namaSiswa,
            waktuAbsen: DateTime.now(),
            lokasi: 'Dalam Radius Kantor',
            koordinat: '$_targetLat, $_targetLng',
            capturedImage: capturedImage,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      debugPrint("ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error jaringan: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Presensi LPKIA', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
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

            // INPUT NRP
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: TextField(
                controller: _nrpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Masukkan NRP',
                  hintText: 'Contoh: 2304140028',
                  prefixIcon: const Icon(Icons.badge_outlined, color: Colors.blueAccent),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Action
            ElevatedButton(
              onPressed: _isLoadingLokasi ? null : _prosesAbsen,
              style: ElevatedButton.styleFrom(
                backgroundColor: _dalamRadius ? Colors.blueAccent : Colors.grey[400],
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: _dalamRadius ? 5 : 0,
              ),
              child: const Text('KIRIM ABSENSI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}