import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'main.dart';
import 'absen_page.dart';
import 'form_izin_page.dart';
import 'history_page.dart';
import 'services/holiday_service.dart';

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
            return const Center(child: CircularProgressIndicator(color: AppColors.blue));
          }

          String namaSiswa = 'Karyawan';
          String nrpSiswa = '';
          if (userSnap.hasData && userSnap.data!.docs.isNotEmpty) {
            var userData = userSnap.data!.docs.first.data() as Map<String, dynamic>;
            namaSiswa = userData['nama'] ?? 'Karyawan';
            nrpSiswa = userData['nrp'] ?? '';
          }

          String namaPanggilan = namaSiswa.split(' ').first;

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(namaPanggilan),
                  const SizedBox(height: 20),
                  _buildCalendarCard(context),
                  const SizedBox(height: 16),
                  _buildPengajuanCepat(context),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Aksi Cepat'),
                  const SizedBox(height: 12),
                  _buildQuickActions(context),
                  const SizedBox(height: 20),
                  _buildRecentActivity(nrpSiswa),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGreeting(String nama) {
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
              'Universitas Jenderal Achmad Yani',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
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
    );
  }

  Widget _buildCalendarCard(BuildContext context) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle(Icons.calendar_today_rounded, 'Kalender Kehadiran'),
          _buildCalendarGrid(context),
          const SizedBox(height: 14),
          _buildStatsRow(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
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
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle(Icons.description_outlined, 'Pengajuan Cepat'),
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
                Navigator.push(context, MaterialPageRoute(builder: (context) => const FormIzinPage()));
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
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCardTitle(Icons.access_time_rounded, 'Aktivitas Terbaru'),
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
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator(color: AppColors.blue, strokeWidth: 2)),
                );
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

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: child,
    );
  }

  Widget _buildCardTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.blue),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}
