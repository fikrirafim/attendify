import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';
import 'main.dart';
import 'absen_page.dart';
import 'form_izin_page.dart';
import 'history_page.dart';
import 'notification_page.dart';
import 'services/holiday_service.dart';
import 'widgets/shared_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedPengajuan = '';

  static const List<String> _pilihanPengajuan = [
    'Izin',
    'Sakit',
    'Cuti',
    'Izin Pulang Cepat',
    'Izin Masuk Terlambat',
    'Lembur',
  ];

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Silakan login terlebih dahulu.')));
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: currentUser.email)
            .limit(1)
            .get(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return _buildShimmerPage();
          }

          String namaSiswa = 'Karyawan';
          String nrpSiswa = '';
          String namaPerusahaan = 'Attendify User';
          if (userSnap.hasData && userSnap.data!.docs.isNotEmpty) {
            var userData = userSnap.data!.docs.first.data() as Map<String, dynamic>;
            namaSiswa = userData['nama'] ?? userData['nama_hr'] ?? 'Karyawan';
            nrpSiswa = userData['nrp'] ?? '';
            namaPerusahaan = userData['nama_perusahaan'] ?? 'Attendify User';
          }

          String namaPanggilan = namaSiswa.split(' ').first;

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Animate(
                    effects: const [FadeEffect(duration: Duration(milliseconds: 400)), SlideEffect(begin: Offset(0, 0.1), end: Offset.zero)],
                    child: _buildGreeting(namaPanggilan, namaPerusahaan),
                  ),
                  const SizedBox(height: 20),
                  Animate(
                    delay: const Duration(milliseconds: 150),
                    effects: const [FadeEffect(duration: Duration(milliseconds: 400)), SlideEffect(begin: Offset(0, 0.1), end: Offset.zero)],
                    child: _buildCalendarCard(context, nrpSiswa),
                  ),
                  const SizedBox(height: 16),
                  Animate(
                    delay: const Duration(milliseconds: 300),
                    effects: const [FadeEffect(duration: Duration(milliseconds: 400)), SlideEffect(begin: Offset(0, 0.1), end: Offset.zero)],
                    child: _buildActiveCuti(nrpSiswa, namaSiswa),
                  ),
                  const SizedBox(height: 16),
                  Animate(
                    delay: const Duration(milliseconds: 450),
                    effects: const [FadeEffect(duration: Duration(milliseconds: 400)), SlideEffect(begin: Offset(0, 0.1), end: Offset.zero)],
                    child: _buildPengajuanCepat(context),
                  ),
                  const SizedBox(height: 20),
                  Animate(
                    delay: const Duration(milliseconds: 600),
                    effects: const [FadeEffect(duration: Duration(milliseconds: 400)), SlideEffect(begin: Offset(0, 0.1), end: Offset.zero)],
                    child: AppSectionTitle(title: 'Aksi Cepat'),
                  ),
                  const SizedBox(height: 12),
                  Animate(
                    delay: const Duration(milliseconds: 750),
                    effects: const [FadeEffect(duration: Duration(milliseconds: 400)), SlideEffect(begin: Offset(0, 0.1), end: Offset.zero)],
                    child: _buildQuickActions(context),
                  ),
                  const SizedBox(height: 20),
                  Animate(
                    delay: const Duration(milliseconds: 900),
                    effects: const [FadeEffect(duration: Duration(milliseconds: 400)), SlideEffect(begin: Offset(0, 0.1), end: Offset.zero)],
                    child: _buildRecentActivity(nrpSiswa),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGreeting(String nama, String namaPerusahaan) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $nama',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              namaPerusahaan,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            if (currentUser != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('uid', isEqualTo: currentUser.uid)
                    .where('isRead', isEqualTo: false)
                    .snapshots(),
                builder: (context, snap) {
                  final unreadCount = snap.data?.docs.length ?? 0;
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage())),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 22),
                          if (unreadCount > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    unreadCount > 9 ? '9+' : '$unreadCount',
                                    style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(width: 10),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.blue, Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  nama.isNotEmpty ? nama[0].toUpperCase() : 'B',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarCard(BuildContext context, String nrp) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCardTitle(icon: Icons.calendar_today_rounded, title: 'Kalender Kehadiran'),
          _buildCalendarGrid(context, nrp),
          const SizedBox(height: 14),
          _buildStatsRow(),
        ],
      ),
    );
  }

  DateTime? _parseDateIndo(String dateStr) {
    try {
      List<String> parts = dateStr.split('-');
      if (parts.length == 3) {
        if (parts[0].length == 2) {
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    } catch (_) {}
    return null;
  }

  Widget _buildCalendarGrid(BuildContext context, String nrp) {
    final now = DateTime.now();
    final holidayService = HolidayService('');

    return StreamBuilder<List<DateTime>>(
      stream: holidayService.streamCachedHolidays('indonesia', now.year),
      builder: (context, snap) {
        final holidays = snap.data ?? <DateTime>[];
        final holidayDays = holidays
            .where((d) => d.month == now.month && d.year == now.year)
            .map((d) => d.day)
            .toSet();

        return StreamBuilder<QuerySnapshot>(
          stream: nrp.isNotEmpty
              ? FirebaseFirestore.instance
                  .collection('absensi')
                  .where('nrp', isEqualTo: nrp)
                  .snapshots()
              : null,
          builder: (context, absenSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: nrp.isNotEmpty
                  ? FirebaseFirestore.instance
                      .collection('pengajuan_izin')
                      .where('nrp', isEqualTo: nrp)
                      .where('status_approval', isEqualTo: 'Disetujui')
                      .snapshots()
                  : null,
              builder: (context, pengajuanSnap) {
                final Map<String, String> absensiMap = {};

                if (absenSnap.hasData) {
                  for (final doc in absenSnap.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = (data['status'] ?? '').toString();
                    final waktuAbsen = (data['waktu_absen'] ?? '').toString();
                    try {
                      String datePart = waktuAbsen.split(' ')[0];
                      List<String> parts = datePart.split('-');
                      if (parts.length == 3) {
                        String key = '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
                        absensiMap[key] = status;
                      }
                    } catch (_) {}
                  }
                }

                if (pengajuanSnap.hasData) {
                  for (final doc in pengajuanSnap.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final tglMulai = (data['tanggal_mulai'] ?? '').toString();
                    final tglSelesai = (data['tanggal_selesai'] ?? tglMulai).toString();
                    final jenis = (data['jenis_izin'] ?? '').toString();

                    DateTime? start = _parseDateIndo(tglMulai);
                    DateTime? end = _parseDateIndo(tglSelesai);
                    if (start != null && end != null) {
                      DateTime current = start;
                      while (!current.isAfter(end)) {
                        String key = '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
                        absensiMap[key] = jenis;
                        current = current.add(const Duration(days: 1));
                      }
                    }
                  }
                }

            return TableCalendar<dynamic>(
              firstDay: DateTime(now.year, now.month - 3, 1),
              lastDay: DateTime(now.year, now.month + 3, 0),
              focusedDay: now,
              availableGestures: AvailableGestures.horizontalSwipe,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary, size: 22),
                rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 22),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
                weekendStyle: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                todayTextStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                defaultTextStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                weekendTextStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                outsideTextStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                ),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, date, focusedDay) {
                  final isSunday = date.weekday == DateTime.sunday;
                  final isHoliday = date.month == now.month &&
                      date.year == now.year &&
                      holidayDays.contains(date.day);

                  String dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  final absenStatus = absensiMap[dateKey];
                  final isCutiIzin = absenStatus != null &&
                      (absenStatus.toLowerCase().contains('cuti') || absenStatus.toLowerCase().contains('izin'));

                  if (isCutiIzin) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }

                  if (isSunday || isHoliday) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            );
            },
          );
          },
        );
      },
    );
  }

  Future<void> _ajukanPembatalan(BuildContext context, String nrp, String nama, Map<String, dynamic> data) async {
    final tglMulai = data['tanggal_mulai'] ?? '';
    final tglSelesai = data['tanggal_selesai'] ?? tglMulai;
    final tanggalRange = tglMulai == tglSelesai ? tglMulai : '$tglMulai s/d $tglSelesai';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Batalkan Cuti?', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17)),
        content: Text('Ajukan pembatalan cuti untuk tanggal $tanggalRange? HRD akan meninjau permintaan ini.', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Tidak', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Ya, Batalkan', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final docId = data['_docId'] as String;
      await FirebaseFirestore.instance.collection('pengajuan_izin').doc(docId).update({
        'status_approval': 'Menunggu Pembatalan',
      });

      final userCompanyId = data['company_id'] ?? '';
      QuerySnapshot hrSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'hr')
          .where('company_id', isEqualTo: userCompanyId)
          .get();

      for (var hrDoc in hrSnapshot.docs) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'uid': hrDoc.id,
          'title': 'Pengajuan Pembatalan Cuti',
          'message': '$nama mengajukan pembatalan cuti untuk tanggal $tanggalRange.',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Pengajuan pembatalan cuti berhasil dikirim.', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: AppColors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal mengajukan pembatalan.', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Widget _buildActiveCuti(String nrp, String nama) {
    if (nrp.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pengajuan_izin')
          .where('nrp', isEqualTo: nrp)
          .where('status_approval', isEqualTo: 'Disetujui')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        final cutiDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final jenis = (data['jenis_izin'] ?? '').toString().toLowerCase();
          return jenis.contains('cuti');
        }).toList();

        if (cutiDocs.isEmpty) return const SizedBox.shrink();

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCardTitle(icon: Icons.event_busy_rounded, title: 'Cuti Aktif'),
              ...cutiDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final tglMulai = data['tanggal_mulai'] ?? '-';
                final tglSelesai = data['tanggal_selesai'] ?? tglMulai;
                final tanggalRange = tglMulai == tglSelesai ? tglMulai : '$tglMulai → $tglSelesai';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.green.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.calendar_month_rounded, color: AppColors.green, size: 18)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tanggalRange, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('Disetujui', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.green)),
                    ])),
                    GestureDetector(
                      onTap: () {
                        final dataWithId = Map<String, dynamic>.from(data);
                        dataWithId['_docId'] = doc.id;
                        _ajukanPembatalan(context, nrp, nama, dataWithId);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.red.withValues(alpha: 0.2))),
                        child: Text('Batalkan', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.red)),
                      ),
                    ),
                  ]),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: currentUser.email)
          .limit(1)
          .get(),
      builder: (context, userSnap) {
        String nrp = '';
        if (userSnap.hasData && userSnap.data!.docs.isNotEmpty) {
          var userData = userSnap.data!.docs.first.data() as Map<String, dynamic>;
          nrp = userData['nrp'] ?? '';
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('absensi')
              .where('nrp', isEqualTo: nrp)
              .snapshots(),
          builder: (context, snapshot) {
            int hadir = 0;
            int terlambat = 0;

            if (snapshot.hasData) {
              for (final doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final status = (data['status'] ?? '').toString().toLowerCase();
                final waktuAbsen = (data['waktu_absen'] ?? '').toString();

                try {
                  List<String> parts = waktuAbsen.split(' ')[0].split('-');
                  int bln = int.parse(parts[1]);
                  int thn = int.parse(parts[2]);

                  if (bln == DateTime.now().month && thn == DateTime.now().year) {
                    if (status.contains('tepat') || status.contains('selesai')) hadir++;
                    if (status.contains('telat') || status.contains('terlambat')) {
                      hadir++;
                      terlambat++;
                    }
                  }
                } catch (_) {}
              }
            }

            return Row(
              children: [
                _buildStatChip(AppColors.green, hadir, 'Hadir'),
                const SizedBox(width: 10),
                _buildStatChip(AppColors.orange, terlambat, 'Terlambat'),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatChip(Color color, int value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showJenisPengajuanSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pilih Jenis Pengajuan',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(_pilihanPengajuan.length, (i) {
                final item = _pilihanPengajuan[i];
                final isSelected = item == _selectedPengajuan;
                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() => _selectedPengajuan = item);
                        Navigator.pop(ctx);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.blue : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_rounded, color: AppColors.blue, size: 22),
                          ],
                        ),
                      ),
                    ),
                    if (i < _pilihanPengajuan.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(height: 1, color: AppColors.borderLight),
                      ),
                  ],
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPengajuanCepat(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCardTitle(icon: Icons.description_outlined, title: 'Pengajuan Cepat'),
          GestureDetector(
            onTap: _showJenisPengajuanSheet,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedPengajuan.isEmpty
                          ? 'Pilih jenis pengajuan...'
                          : _selectedPengajuan,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: _selectedPengajuan.isEmpty
                            ? FontWeight.w500
                            : FontWeight.w600,
                        color: _selectedPengajuan.isEmpty
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary, size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (_selectedPengajuan.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Pilih jenis pengajuan terlebih dahulu.'),
                    backgroundColor: AppColors.red,
                  ));
                  return;
                }
                Navigator.push(context, MaterialPageRoute(builder: (context) => FormIzinPage(initialJenisIzin: _selectedPengajuan)));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                elevation: 2,
                shadowColor: AppColors.blue.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Ajukan Sekarang',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Absen',
            bg: AppColors.blueLight,
            iconColor: AppColors.blue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AbsenPage())),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.history_rounded,
            label: 'Riwayat',
            bg: AppColors.orangeLight,
            iconColor: AppColors.orange,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryPage())),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color bg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(String nrp) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppCardTitle(icon: Icons.access_time_rounded, title: 'Aktivitas Terbaru'),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryPage())),
                child: Text(
                  'Detail',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ],
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('absensi')
                .where('nrp', isEqualTo: nrp)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerActivityList();
              }

              var docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Belum ada aktivitas.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                  ),
                );
              }

              docs.sort((a, b) {
                try {
                  int timeA = int.parse(a.id.split('_').last);
                  int timeB = int.parse(b.id.split('_').last);
                  return timeB.compareTo(timeA);
                } catch (e) {
                  return 0;
                }
              });

              var latestDocs = docs.take(3).toList();

              return Column(
                children: List.generate(latestDocs.length, (index) {
                  var data = latestDocs[index].data() as Map<String, dynamic>;
                  String status = data['status'] ?? 'Hadir';
                  String jenisAbsen = data['jenis_absen'] ?? 'Masuk';
                  String waktuRaw = data['waktu_absen'] ?? '';

                  String jam = '--:--';
                  if (waktuRaw.contains(' ')) {
                    jam = waktuRaw.split(' ')[1];
                  }

                  Color statusColor = AppColors.green;
                  IconData statusIcon = Icons.check_circle_rounded;

                  if (status.toLowerCase().contains('selesai')) {
                    statusColor = AppColors.blue;
                    statusIcon = Icons.logout_rounded;
                  } else if (status.toLowerCase().contains('terlambat') || status.toLowerCase().contains('telat')) {
                    statusColor = AppColors.orange;
                    statusIcon = Icons.access_time_filled_rounded;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(statusIcon, color: statusColor, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Absen $jenisAbsen ($status)',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          jam,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerPage() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShimmerGreeting(),
            const SizedBox(height: 20),
            _buildShimmerCalendarCard(),
            const SizedBox(height: 16),
            _buildShimmerActionCard(),
            const SizedBox(height: 20),
            _buildShimmerActionCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerGreeting() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 160, height: 22, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 8),
              Container(width: 100, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            ],
          ),
          Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
            const SizedBox(width: 10),
            Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
          ]),
        ],
      ),
    );
  }

  Widget _buildShimmerCalendarCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 140, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 16),
            ...List.generate(5, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: List.generate(7, (_) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 32,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  ),
                )),
              ),
            )),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: Container(height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
              const SizedBox(width: 10),
              Expanded(child: Container(height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerActionCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 120, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 14),
            Container(width: double.infinity, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerActivityList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(3, (_) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 160, height: 13, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
              Container(width: 40, height: 13, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            ],
          ),
        )),
      ),
    );
  }

}
