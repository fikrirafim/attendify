import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

class EmployeeDetailHistoryPage extends StatelessWidget {
  final String employeeUid;
  final String employeeName;
  final int selectedMonth;
  final int selectedYear;

  const EmployeeDetailHistoryPage({
    super.key,
    required this.employeeUid,
    required this.employeeName,
    required this.selectedMonth,
    required this.selectedYear,
  });

  static const _namaBulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static const _namaHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  String _formatTanggal(String raw) {
    try {
      final parts = raw.split(' ')[0].split('-');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final dt = DateTime(year, month, day);
        final hari = _namaHari[dt.weekday - 1];
        return '$hari, $day ${_namaBulan[month - 1]} $year';
      }
    } catch (_) {}
    return raw;
  }

  String _extractJam(String raw) {
    final parts = raw.split(' ');
    return parts.length > 1 ? parts[1] : '-';
  }

  Color _statusColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('tepat') || lower.contains('selesai')) return AppColors.green;
    if (lower.contains('telat') || lower.contains('terlambat')) return AppColors.orange;
    if (lower.contains('izin') || lower.contains('cuti')) return AppColors.blue;
    if (lower.contains('tidak') || lower.contains('alpha')) return AppColors.red;
    return AppColors.textMuted;
  }

  Color _statusBg(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('tepat') || lower.contains('selesai')) return AppColors.greenLight;
    if (lower.contains('telat') || lower.contains('terlambat')) return AppColors.orangeLight;
    if (lower.contains('izin') || lower.contains('cuti')) return AppColors.blueLight;
    if (lower.contains('tidak') || lower.contains('alpha')) return AppColors.redLight;
    return AppColors.borderLight;
  }

  IconData _statusIcon(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('tepat') || lower.contains('selesai')) return Icons.check_circle_rounded;
    if (lower.contains('telat') || lower.contains('terlambat')) return Icons.access_time_rounded;
    if (lower.contains('izin') || lower.contains('cuti')) return Icons.description_outlined;
    if (lower.contains('tidak') || lower.contains('alpha')) return Icons.cancel_rounded;
    return Icons.help_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Detail Absensi',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: SizedBox(height: 1, child: ColoredBox(color: AppColors.border)),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employeeName,
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_namaBulan[selectedMonth - 1]} $selectedYear',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('absensi')
                  .where('uid', isEqualTo: employeeUid)
                  .orderBy('waktu_absen', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.blue));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.red),
                        const SizedBox(height: 12),
                        Text('Gagal memuat data', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text(
                          'Pastikan index Firestore sudah dibuat.',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];
                final docs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final waktu = (data['waktu_absen'] ?? '').toString();
                  try {
                    final parts = waktu.split(' ')[0].split('-');
                    if (parts.length == 3) {
                      final bulan = int.parse(parts[1]);
                      final tahun = int.parse(parts[2]);
                      return bulan == selectedMonth && tahun == selectedYear;
                    }
                  } catch (_) {}
                  return false;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada data absensi',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'di ${_namaBulan[selectedMonth - 1]} $selectedYear',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final waktuAbsen = (data['waktu_absen'] ?? '').toString();
                    final status = (data['status'] ?? '-').toString();
                    final lokasi = (data['lokasi'] ?? data['koordinat'] ?? '').toString();
                    final jenisAbsen = (data['jenis_absen'] ?? '').toString();
                    final latitude = data['latitude'];
                    final longitude = data['longitude'];

                    final tanggal = _formatTanggal(waktuAbsen);
                    final jam = _extractJam(waktuAbsen);
                    final koordinat = (latitude != null && longitude != null)
                        ? '$latitude, $longitude'
                        : lokasi;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _statusBg(status),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(_statusIcon(status), color: _statusColor(status), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tanggal,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      if (jenisAbsen.isNotEmpty)
                                        Text(
                                          jenisAbsen,
                                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _statusBg(status),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _statusColor(status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  _detailRow(Icons.access_time_rounded, 'Jam Absen', jam),
                                  if (koordinat.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    _detailRow(Icons.location_on_outlined, 'Koordinat', koordinat),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
