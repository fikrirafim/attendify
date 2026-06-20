import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'main.dart';

class TodayAttendancePage extends StatefulWidget {
  final String companyId;

  const TodayAttendancePage({super.key, required this.companyId});

  @override
  State<TodayAttendancePage> createState() => _TodayAttendancePageState();
}

class _TodayAttendancePageState extends State<TodayAttendancePage> {
  late Future<List<Map<String, dynamic>>> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = _fetchHelicopterView();
  }

  Future<List<Map<String, dynamic>>> _fetchHelicopterView() async {
    final now = DateTime.now();
    final String todayDisplay =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

    final results = await Future.wait([
      FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'karyawan')
          .where('company_id', isEqualTo: widget.companyId)
          .get(),
      FirebaseFirestore.instance
          .collection('absensi')
          .where('company_id', isEqualTo: widget.companyId)
          .get(),
      FirebaseFirestore.instance
          .collection('pengajuan_izin')
          .where('company_id', isEqualTo: widget.companyId)
          .where('status_approval', isEqualTo: 'Disetujui')
          .get(),
    ]);

    final userDocs = results[0].docs;
    final absensiDocs = results[1].docs;
    final izinDocs = results[2].docs;

    final Map<String, Map<String, dynamic>> absensiMap = {};
    for (final doc in absensiDocs) {
      final data = doc.data();
      final waktuAbsen = (data['waktu_absen'] ?? '').toString();
      if (waktuAbsen.startsWith(todayDisplay)) {
        final nrp = (data['nrp'] ?? '').toString();
        if (nrp.isNotEmpty) {
          absensiMap[nrp] = data;
        }
      }
    }

    final List<Map<String, dynamic>> izinToday = [];
    for (final doc in izinDocs) {
      final data = doc.data();
      final tglMulai = (data['tanggal_mulai'] ?? '').toString();
      final tglSelesai = (data['tanggal_selesai'] ?? tglMulai).toString();

      final start = _parseDateIndo(tglMulai);
      final end = _parseDateIndo(tglSelesai);
      if (start != null && end != null) {
        final today = DateTime(now.year, now.month, now.day);
        if (!today.isBefore(start) && !today.isAfter(end)) {
          izinToday.add(data);
        }
      }
    }

    final Map<String, Map<String, dynamic>> izinMap = {};
    for (final data in izinToday) {
      final nrp = (data['nrp'] ?? '').toString();
      if (nrp.isNotEmpty) {
        izinMap[nrp] = data;
      }
    }

    final List<Map<String, dynamic>> result = [];
    for (final doc in userDocs) {
      final data = doc.data();
      final nama = (data['nama'] ?? data['nama_hr'] ?? '-').toString();
      final nrp = (data['nrp'] ?? '').toString();
      final uid = doc.id;
      final photoUrl = (data['photo_url'] ?? '').toString();

      String status = 'Belum Absen';
      String jamAbsen = '';
      String? jenisIzin;

      if (nrp.isNotEmpty && absensiMap.containsKey(nrp)) {
        final absenData = absensiMap[nrp]!;
        final rawStatus = (absenData['status'] ?? '').toString().toLowerCase();
        final waktuAbsen = (absenData['waktu_absen'] ?? '').toString();
        final parts = waktuAbsen.split(' ');
        jamAbsen = parts.length > 1 ? parts[1] : waktuAbsen;

        if (rawStatus.contains('tepat') || rawStatus.contains('selesai')) {
          status = 'Hadir';
        } else if (rawStatus.contains('telat') || rawStatus.contains('terlambat')) {
          status = 'Terlambat';
        } else {
          status = 'Hadir';
        }
      } else if (nrp.isNotEmpty && izinMap.containsKey(nrp)) {
        final izinData = izinMap[nrp]!;
        jenisIzin = (izinData['jenis_izin'] ?? '').toString();
        status = jenisIzin;
      }

      result.add({
        'nama': nama,
        'nrp': nrp,
        'uid': uid,
        'photoUrl': photoUrl,
        'status': status,
        'jamAbsen': jamAbsen,
        'jenisIzin': jenisIzin,
      });
    }

    result.sort((a, b) {
      final order = {'Hadir': 0, 'Terlambat': 1};
      final aOrder = order[a['status']] ?? (a['status'] == 'Belum Absen' ? 3 : 2);
      final bOrder = order[b['status']] ?? (b['status'] == 'Belum Absen' ? 3 : 2);
      if (aOrder != bOrder) return aOrder.compareTo(bOrder);
      return (a['nama'] as String).compareTo(b['nama'] as String);
    });

    return result;
  }

  DateTime? _parseDateIndo(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        if (parts[0].length == 2) {
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    } catch (_) {}
    return null;
  }

  Future<void> _onRefresh() async {
    setState(() {
      _futureData = _fetchHelicopterView();
    });
    await _futureData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Kehadiran Hari Ini',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerList();
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: AppColors.red.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text('Gagal memuat data', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _onRefresh, child: Text('Coba Lagi', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.blue))),
                ],
              ),
            );
          }

          final employees = snapshot.data ?? [];

          if (employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('Belum ada karyawan terdaftar', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          final int hadir = employees.where((e) => e['status'] == 'Hadir').length;
          final int terlambat = employees.where((e) => e['status'] == 'Terlambat').length;
          final int izinCuti = employees.where((e) => e['status'] != 'Hadir' && e['status'] != 'Terlambat' && e['status'] != 'Belum Absen').length;
          final int belumAbsen = employees.where((e) => e['status'] == 'Belum Absen').length;

          return RefreshIndicator(
            color: AppColors.blue,
            onRefresh: _onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _buildSummaryBar(hadir, terlambat, izinCuti, belumAbsen, employees.length),
                const SizedBox(height: 16),
                ...employees.map((emp) => _buildEmployeeCard(emp)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryBar(int hadir, int terlambat, int izinCuti, int belumAbsen, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          _buildSummaryItem(AppColors.green, '$hadir', 'Hadir'),
          Container(width: 1, height: 28, color: AppColors.borderLight),
          _buildSummaryItem(AppColors.orange, '$terlambat', 'Terlambat'),
          Container(width: 1, height: 28, color: AppColors.borderLight),
          _buildSummaryItem(AppColors.blue, '$izinCuti', 'Izin'),
          Container(width: 1, height: 28, color: AppColors.borderLight),
          _buildSummaryItem(AppColors.textMuted, '$belumAbsen', 'Absen'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(Color color, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: color, height: 1)),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> emp) {
    final nama = emp['nama'] as String;
    final nrp = emp['nrp'] as String;
    final uid = emp['uid'] as String;
    final photoUrl = emp['photoUrl'] as String;
    final status = emp['status'] as String;
    final jamAbsen = emp['jamAbsen'] as String;

    final initials = nama.isNotEmpty
        ? nama.trim().split(RegExp(r'\s+')).map((e) => e[0]).take(2).join().toUpperCase()
        : '?';

    final String subtitle;
    if (jamAbsen.isNotEmpty) {
      subtitle = 'Jam $jamAbsen';
    } else if (nrp.isNotEmpty) {
      subtitle = nrp;
    } else {
      subtitle = '-';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _buildAvatar(uid, initials, photoUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nama, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
                ],
              ),
            ),
            _buildStatusChip(status),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String uid, String initials, String photoUrl) {
    if (photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.blueLight,
        backgroundImage: NetworkImage(photoUrl),
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: statusColor(initials).withValues(alpha: 0.12),
      child: Text(
        initials,
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: statusColor(initials)),
      ),
    );
  }

  Color statusColor(String s) => AppColors.blue;

  Widget _buildStatusChip(String status) {
    final lower = status.toLowerCase();
    Color bg;
    Color fg;
    String label;

    if (lower.contains('tepat') || lower.contains('selesai') || status == 'Hadir') {
      bg = const Color(0xFFF0FDF4);
      fg = const Color(0xFF16A34A);
      label = 'Hadir';
    } else if (lower.contains('telat') || lower.contains('terlambat') || status == 'Terlambat') {
      bg = const Color(0xFFFFF7ED);
      fg = const Color(0xFFEA580C);
      label = 'Terlambat';
    } else if (lower.contains('sakit')) {
      bg = const Color(0xFFFEF2F2);
      fg = const Color(0xFFDC2626);
      label = 'Sakit';
    } else if (lower.contains('cuti')) {
      bg = AppColors.blueLight;
      fg = AppColors.blue;
      label = 'Cuti';
    } else if (lower.contains('izin')) {
      bg = const Color(0xFFFFF7ED);
      fg = const Color(0xFFEA580C);
      label = 'Izin';
    } else if (lower.contains('lembur')) {
      bg = const Color(0xFFF5F3FF);
      fg = const Color(0xFF7C3AED);
      label = 'Lembur';
    } else {
      bg = AppColors.borderLight;
      fg = AppColors.textMuted;
      label = 'Belum Absen';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Container(
            height: 64,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          ),
          const SizedBox(height: 16),
          ...List.generate(6, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 72,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            ),
          )),
        ],
      ),
    );
  }
}
