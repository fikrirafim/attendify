import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'main.dart';
import 'login_page.dart';
import 'absen_page.dart';
import 'profile_page.dart';
import 'karyawan_list_page.dart';
import 'approval_izin_page.dart';
import 'notification_page.dart';
import 'setting_jam_page.dart';
import 'setting_lokasi_page.dart';
import 'today_attendance_page.dart';
import 'widgets/shared_widgets.dart';

class HRDashboard extends StatefulWidget {
  const HRDashboard({super.key});

  @override
  State<HRDashboard> createState() => _HRDashboardState();
}

class _HRDashboardState extends State<HRDashboard> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const _HRHomeTab(),
      AbsenPage(),
      ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          border: const Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _buildNavItem(0, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Dashboard'),
              _buildNavItem(1, Icons.qr_code_scanner_rounded, Icons.qr_code_scanner_outlined, 'Absensi'),
              _buildNavItem(2, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData icon, String label) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, size: 24, color: isActive ? AppColors.blue : AppColors.textMuted),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w600, color: isActive ? AppColors.blue : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _HRHomeTab extends StatefulWidget {
  const _HRHomeTab();

  @override
  State<_HRHomeTab> createState() => _HRHomeTabState();
}

class _HRHomeTabState extends State<_HRHomeTab> {
  bool _isResettingCuti = false;

  Future<DocumentSnapshot?> _loadCompanyForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = userDoc.data();
    final companyId = data == null ? null : data['company_id'] as String?;
    if (companyId == null) return null;
    final companyDoc = await FirebaseFirestore.instance.collection('companies').doc(companyId).get();
    return companyDoc;
  }

  Future<void> _resetCutiTahunan(String companyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset Cuti Tahunan?', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17)),
        content: Text('Tindakan ini akan mereset sisa cuti SELURUH karyawan menjadi 12 hari. Lanjutkan?', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Batal', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Ya, Reset', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isResettingCuti = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'karyawan')
          .where('company_id', isEqualTo: companyId)
          .get();

      if (snapshot.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Tidak ada karyawan ditemukan.', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        setState(() => _isResettingCuti = false);
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'sisa_cuti': 12});
      }
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Sisa cuti seluruh karyawan berhasil direset ke 12 hari.', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal mereset cuti. Silakan coba lagi.', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }

    if (mounted) setState(() => _isResettingCuti = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<DocumentSnapshot?>(
        future: _loadCompanyForCurrentUser(),
        builder: (context, companySnap) {
          if (companySnap.connectionState == ConnectionState.waiting) {
            return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
          }

          final companyDoc = companySnap.data;
          if (companyDoc == null || !companyDoc.exists) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildEmptyCompanyState(context),
                const SizedBox(height: 20),
                AppSectionTitle(title: 'Menu Manajemen'),
                const SizedBox(height: 12),
                _buildMenuList(context),
              ]),
            );
          }

          final companyId = companyDoc.id;
          final companyName = (companyDoc.data() as Map<String, dynamic>)['nama_perusahaan'] ?? 'Perusahaan Anda';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildHeader(context, companyName: companyName),
              const SizedBox(height: 20),
              _buildStatistikHariIni(companyId),
              const SizedBox(height: 16),
              _buildChartStatistik(companyId),
              const SizedBox(height: 20),
              _buildKehadiranHariIni(context, companyId),
              const SizedBox(height: 20),
              _buildTotalKaryawan(companyId),
              const SizedBox(height: 20),
              AppSectionTitle(title: 'Menu Manajemen'),
              const SizedBox(height: 12),
              _buildMenuList(context, companyId: companyId),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {String? companyName}) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Dashboard Admin', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.3)),
        const SizedBox(height: 3),
        Text(companyName ?? 'Universitas Jenderal Achmad Yani', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
      ]),
      Row(children: [
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
        GestureDetector(
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text('Konfirmasi Logout', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17)),
                content: Text('Apakah Anda yakin ingin keluar?', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Batal', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.red))),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
            }
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.blue, Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: const Center(child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22)),
          ),
        ),
      ]),
    ]);
  }

  Widget _buildEmptyCompanyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dashboard Admin', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.3)),
            const SizedBox(height: 3),
            Text('Belum ada data perusahaan', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          ]),
          Container(width: 44, height: 44, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.blue, Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(14)), child: const Center(child: Icon(Icons.business, color: Colors.white))),
        ]),
        const SizedBox(height: 18),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppCardTitle(icon: Icons.info_outline, title: 'Perusahaan Belum Lengkap'),
            const SizedBox(height: 8),
            Text('Data perusahaan tidak ditemukan. Silakan daftar ulang sebagai HR untuk membuat data perusahaan baru.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Logout & Daftar Ulang', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStatistikHariIni(String companyId) {
    final now = DateTime.now();
    final String tanggalHariIni = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('absensi').where('company_id', isEqualTo: companyId).snapshots(),
      builder: (context, snapshot) {
        int hadir = 0, terlambat = 0, izin = 0;
        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? '').toString().toLowerCase();
            final waktuAbsen = (data['waktu_absen'] ?? '').toString();
            if (waktuAbsen.startsWith(tanggalHariIni)) {
              if (status.contains('tepat') || status.contains('selesai')) hadir++;
              else if (status.contains('telat') || status.contains('terlambat')) { hadir++; terlambat++; }
            }
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('pengajuan_izin').where('status_approval', isEqualTo: 'Menunggu').where('company_id', isEqualTo: companyId).snapshots(),
          builder: (context, izinSnap) {
            if (izinSnap.hasData) {
              for (final doc in izinSnap.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final tglMulai = (data['tanggal_mulai'] ?? '').toString();
                if (tglMulai == tanggalHariIni) izin++;
              }
            }

            return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppCardTitle(icon: Icons.bar_chart_rounded, title: 'Statistik Hari Ini'),
              const SizedBox(height: 8),
              Row(children: [
                _buildStatCell(AppColors.green, AppColors.greenLight, '$hadir', 'Hadir'),
                const SizedBox(width: 10),
                _buildStatCell(AppColors.orange, AppColors.orangeLight, '$terlambat', 'Terlambat'),
                const SizedBox(width: 10),
                _buildStatCell(AppColors.blue, AppColors.blueLight, '$izin', 'Izin/Cuti'),
              ])
            ]));
          },
        );
      },
    );
  }

  Widget _buildTotalKaryawan(String companyId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'karyawan').where('company_id', isEqualTo: companyId).snapshots(),
      builder: (context, snapshot) {
        final int total = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return AppCard(child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.blueLight, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.people_alt_rounded, color: AppColors.blue, size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Total Karyawan Terdaftar', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)), const SizedBox(height: 2), Text('$total', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1))])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(8)), child: Text('Active', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.green)))
        ]));
      },
    );
  }

  Widget _buildChartStatistik(String companyId) {
    final now = DateTime.now();
    final String tanggalHariIni = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('absensi').where('company_id', isEqualTo: companyId).snapshots(),
      builder: (context, snapshot) {
        int hadir = 0, terlambat = 0, izin = 0;
        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? '').toString().toLowerCase();
            final waktuAbsen = (data['waktu_absen'] ?? '').toString();
            if (waktuAbsen.startsWith(tanggalHariIni)) {
              if (status.contains('tepat') || status.contains('selesai')) hadir++;
              else if (status.contains('telat') || status.contains('terlambat')) { hadir++; terlambat++; }
            }
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('pengajuan_izin').where('status_approval', isEqualTo: 'Menunggu').where('company_id', isEqualTo: companyId).snapshots(),
          builder: (context, izinSnap) {
            if (izinSnap.hasData) {
              for (final doc in izinSnap.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final tglMulai = (data['tanggal_mulai'] ?? '').toString();
                if (tglMulai == tanggalHariIni) izin++;
              }
            }

            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCardTitle(icon: Icons.bar_chart_rounded, title: 'Grafik Kehadiran Hari Ini'),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (hadir + terlambat + izin + 5).toDouble(),
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return Text('Hadir', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted));
                                  case 1:
                                    return Text('Terlambat', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted));
                                  case 2:
                                    return Text('Izin/Cuti', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted));
                                  default:
                                    return const Text('');
                                }
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}',
                                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
                                );
                              },
                              reservedSize: 32,
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: (hadir + terlambat + izin + 5) / 5,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: AppColors.border,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: hadir.toDouble(),
                                color: AppColors.green,
                                width: 32,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: terlambat.toDouble(),
                                color: AppColors.orange,
                                width: 32,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 2,
                            barRods: [
                              BarChartRodData(
                                toY: izin.toDouble(),
                                color: AppColors.blue,
                                width: 32,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKehadiranHariIni(BuildContext context, String companyId) {
    return AppCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TodayAttendancePage(companyId: companyId)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.people_outline_rounded, color: AppColors.green, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Kehadiran Hari Ini',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lihat daftar karyawan yang sudah melakukan presensi',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuList(BuildContext context, {String? companyId}) {
    return Container(decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]), child: Column(children: [
      _buildMenuItem(context, icon: Icons.people_outline_rounded, iconBg: AppColors.blueLight, iconColor: AppColors.blue, title: 'Manajemen Karyawan', subtitle: 'Input data, rekap absen & edit profil', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const KaryawanListPage()))),
      const AppDivider(),
      _buildMenuItem(context, icon: Icons.description_outlined, iconBg: AppColors.orangeLight, iconColor: AppColors.orange, title: 'Rekapitulasi Kehadiran', subtitle: 'Lihat rekap absensi seluruh karyawan', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const KaryawanListPage()))),
      const AppDivider(),
      _buildMenuItem(context, icon: Icons.checklist_rounded, iconBg: AppColors.greenLight, iconColor: AppColors.green, title: 'Persetujuan Pengajuan', subtitle: 'Review pengajuan', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ApprovalIzinPage()))),
      if (companyId != null) ...[
        const AppDivider(),
        _buildMenuItem(context, icon: Icons.restore_rounded, iconBg: AppColors.redLight, iconColor: AppColors.red, title: 'Reset Cuti Tahunan', subtitle: _isResettingCuti ? 'Mereset...' : 'Reset sisa cuti seluruh karyawan ke 12 hari', onTap: _isResettingCuti ? () {} : () => _resetCutiTahunan(companyId)),
      ],
      const AppDivider(),
      _buildMenuItem(context, icon: Icons.access_time_rounded, iconBg: const Color(0xFFFFF7ED), iconColor: AppColors.orange, title: 'Pengaturan Jam Operasional', subtitle: 'Ubah batas waktu masuk dan pulang', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingJamPage()))),
      const AppDivider(),
      _buildMenuItem(context, icon: Icons.location_on_outlined, iconBg: const Color(0xFFF0FDF4), iconColor: const Color(0xFF16A34A), title: 'Pengaturan Lokasi Absensi', subtitle: 'Atur titik koordinat dan radius kantor', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingLokasiPage()))),
    ]));
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required Color iconBg, required Color iconColor, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16), child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 20)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)), const SizedBox(height: 2), Text(subtitle, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted))])), const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20)])));
  }

  Widget _buildStatCell(Color color, Color bg, String value, String label) {
    return Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.2))), child: Column(children: [Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: color)), const SizedBox(height: 2), Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary))])));
  }
}
