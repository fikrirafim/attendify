import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  String _formatDateTime(String raw) {
    final dateTime = DateTime.tryParse(raw);
    if (dateTime == null) return raw;
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year • $hour:$minute';
  }

  Color _statusColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('hadir')) return Colors.green;
    if (lower.contains('terlambat') || lower.contains('telat') || lower.contains('late')) return Colors.orange;
    if (lower.contains('check out') || lower.contains('checkout')) return Colors.blueAccent;
    if (lower.contains('tidak') || lower.contains('absen')) return Colors.red;
    return Colors.grey;
  }

  IconData _statusIcon(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('hadir')) return Icons.check_circle_outline;
    if (lower.contains('terlambat') || lower.contains('telat') || lower.contains('late')) return Icons.access_time;
    if (lower.contains('check out') || lower.contains('checkout')) return Icons.logout;
    if (lower.contains('tidak') || lower.contains('absen')) return Icons.cancel_outlined;
    return Icons.history;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('absensi')
            .orderBy('waktu_absen', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.history, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Belum ada riwayat absensi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          int hadir = 0;
          int terlambat = 0;
          int tidakHadir = 0;
          for (final doc in docs) {
            final status = (doc.data()['status'] ?? '').toString().toLowerCase();
            if (status.contains('hadir')) {
              hadir++;
            } else if (status.contains('terlambat') || status.contains('telat') || status.contains('late')) {
              terlambat++;
            } else if (status.contains('tidak') || status.contains('absen')) {
              tidakHadir++;
            }
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Semua riwayat absen dari database',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '${docs.length} entri',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildSummaryCard('Hadir', hadir.toString(), Colors.green),
                    const SizedBox(width: 12),
                    _buildSummaryCard('Terlambat', terlambat.toString(), Colors.orange),
                    const SizedBox(width: 12),
                    _buildSummaryCard('Tidak Hadir', tidakHadir.toString(), Colors.red),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final status = (data['status'] ?? 'Tidak diketahui').toString();
                      final name = (data['nama'] ?? '-').toString();
                      final nrp = (data['nrp'] ?? '-').toString();
                      final waktu = (data['waktu_absen'] ?? '').toString();
                      final lokasi = (data['lokasi'] ?? data['koordinat'] ?? 'Lokasi tidak tersedia').toString();

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.16),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(_statusIcon(status), color: _statusColor(status), size: 26),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        status,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: _statusColor(status),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '#$nrp',
                                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    name,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatDateTime(waktu),
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    lokasi,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}
