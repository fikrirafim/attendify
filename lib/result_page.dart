import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:ui'; // Wajib buat efek Glassmorphism

class ResultPage extends StatelessWidget {
  final String nrp;
  final String nama;
  final DateTime waktuAbsen;
  final String lokasi;
  final String koordinat;
  final XFile? capturedImage;

  const ResultPage({
    super.key,
    required this.nrp,
    required this.nama,
    required this.waktuAbsen,
    required this.lokasi,
    required this.koordinat,
    this.capturedImage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Warna background abu-abu kebiruan soft
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Detail Presensi', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Hasil (Modern Success Card)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.green.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
                ],
                border: Border.all(color: Colors.green.withOpacity(0.1), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle_rounded, size: 40, color: Colors.green),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Absen Berhasil!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text('Data kehadiran sukses tercatat di sistem.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Foto Absen dengan Efek Glassmorphism
            Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 420),
                height: 380, // Ditinggiin dikit biar fotonya lebih jelas
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Layer Foto Asli
                      if (capturedImage != null)
                        FutureBuilder<Uint8List>(
                          future: capturedImage!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Container(color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator()));
                            }
                            if (snapshot.hasError || snapshot.data == null) {
                              return Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)));
                            }
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      else
                        Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.person, size: 72, color: Colors.grey))),

                      // 2. Layer Gradient Tipis biar teks tetep kebaca
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                            stops: const [0.4, 1.0],
                          ),
                        ),
                      ),

                      // 3. Layer Glassmorphism (Info Absen Melayang)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15), // Transparan khas kaca
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                                        child: const Text('Check In', style: TextStyle(fontSize: 12, color: Colors.greenAccent, fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildGlassInfoRow(Icons.calendar_today_rounded, '${waktuAbsen.day}/${waktuAbsen.month}/${waktuAbsen.year} • ${waktuAbsen.hour.toString().padLeft(2, '0')}:${waktuAbsen.minute.toString().padLeft(2, '0')} WIB'),
                                  const SizedBox(height: 8),
                                  _buildGlassInfoRow(Icons.location_on_rounded, lokasi),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Tombol Kembali ke Home (Modern Pill Style)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB), // Biru modern
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: const Text('Kembali ke Beranda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget tambahan buat ngerapihin icon & teks di dalam efek kaca
  Widget _buildGlassInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500, height: 1.3),
          ),
        ),
      ],
    );
  }
}