import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

class ResultPage extends StatefulWidget {
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
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Hasil Absen', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Hasil (Success Card)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle, size: 60, color: Colors.green),
                  ),
                  const SizedBox(height: 16),
                  const Text('Absen Berhasil!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text('Presensi ${widget.nama} telah tercatat dengan sukses.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Foto Absen
            Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 420),
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: widget.capturedImage != null
                      ? Image.file(
                          File(widget.capturedImage!.path),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.person, size: 72, color: Colors.grey),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            // Detail Keterangan Absen
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Keterangan Absen',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  // Status Absen
                  _buildDetailRow('Status', 'Check In', Icons.check_circle, Colors.green),

                  // Waktu Absen
                  _buildDetailRow('Waktu Absen', '${_formatDate(widget.waktuAbsen)} - ${_formatTime(widget.waktuAbsen)}', Icons.access_time, Colors.blue),

                  // Lokasi
                  _buildDetailRow('Lokasi', widget.lokasi, Icons.location_on, Colors.orange),

                  // Koordinat GPS
                  _buildDetailRow('Koordinat', widget.koordinat, Icons.gps_fixed, Colors.purple),

                  // NRP/ID Karyawan
                  _buildDetailRow('NRP', widget.nrp, Icons.badge, Colors.teal),

                  // Nama
                  _buildDetailRow('Nama', widget.nama, Icons.person, Colors.indigo),

                  // Validasi Wajah
                  _buildDetailRow('Validasi Wajah', 'Berhasil', Icons.face, Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Kembali ke Home
            ElevatedButton(
              onPressed: () {
                // Kembali ke halaman utama (Home)
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
                shadowColor: Colors.blueAccent.withOpacity(0.5),
              ),
              child: const Text('Kembali ke Beranda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    const List<String> hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const List<String> bulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    return '${hari[dateTime.weekday - 1]}, ${dateTime.day} ${bulan[dateTime.month - 1]} ${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
  }
}