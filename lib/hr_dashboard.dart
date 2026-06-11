import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';
import 'absen_page.dart';
import 'profile_page.dart';
import 'karyawan_list_page.dart';
import 'approval_izin_page.dart';
import 'setting_jam_page.dart';

class AppColors {
  static const Color bg = Color(0xFFF4F6F9);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color blue = Color(0xFF2563EB);
  static const Color blueLight = Color(0xFFEFF6FF);
  static const Color green = Color(0xFF16A34A);
  static const Color greenLight = Color(0xFFF0FDF4);
  static const Color orange = Color(0xFFEA580C);
  static const Color orangeLight = Color(0xFFFFF7ED);
  static const Color red = Color(0xFFDC2626);
  static const Color redLight = Color(0xFFFEF2F2);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
}

class HRDashboard extends StatefulWidget {
  const HRDashboard({super.key});

  @override
  State<HRDashboard> createState() => _HRDashboardState();
}

class _HRDashboardState extends State<HRDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    _HRHomeTab(),
    AbsenPage(),
    ProfilePage(),
  ];

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
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          border: const Border(
            top: BorderSide(color: AppColors.borderLight, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Dashboard'),
                _buildNavItem(1, Icons.qr_code_scanner_rounded, Icons.qr_code_scanner_outlined, 'Absensi'),
                _buildNavItem(2, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
              ],
            ),
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
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive ? AppColors.blue : AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? AppColors.blue : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HRHomeTab extends StatelessWidget {
  const _HRHomeTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildStatistikHariIni(),
            const SizedBox(height: 16),
            _buildTotalKaryawan(),
            const SizedBox(height: 20),
            _buildSectionTitle('Menu Manajemen'),
            const SizedBox(height: 12),
            _buildMenuList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Admin',
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
        GestureDetector(
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Text('Konfirmasi Logout',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 17)),
                content: Text('Apakah Anda yakin ingin keluar?',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.textSecondary)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('Batal',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('Logout',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: AppColors.red)),
                  ),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const LoginPage()));
            }
          },
          child: Container(
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
            child: const Center(
              child: Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatistikHariIni() {
    final now = DateTime.now();
    final String tanggalHariIni =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('absensi').snapshots(),
      builder: (context, snapshot) {
        int hadir = 0;
        int terlambat = 0;
        int izin = 0;

        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? '').toString().toLowerCase();
            final waktuAbsen = (data['waktu_absen'] ?? '').toString();

            if (waktuAbsen.startsWith(tanggalHariIni)) {
              if (status.contains('tepat') || status.contains('selesai')) {
                hadir++;
              } else if (status.contains('telat') || status.contains('terlambat')) {
                hadir++;
                terlambat++;
              }
          }
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('pengajuan_izin')
              .where('status_approval', isEqualTo: 'Menunggu')
              .snapshots(),
          builder: (context, izinSnap) {
            if (izinSnap.hasData) {
              for (final doc in izinSnap.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final tglMulai = (data['tanggal_mulai'] ?? '').toString();
                if (tglMulai == tanggalHariIni) {
                  izin++;
                }
              }
            }

            return _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardTitle(Icons.bar_chart_rounded, 'Statistik Hari Ini'),
                  Row(
                    children: [
                      _buildStatCell(AppColors.green, AppColors.greenLight,
                          '$hadir', 'Hadir'),
                      const SizedBox(width: 10),
                      _buildStatCell(AppColors.orange, AppColors.orangeLight,
                          '$terlambat', 'Terlambat'),
                      const SizedBox(width: 10),
                      _buildStatCell(AppColors.blue, AppColors.blueLight,
                          '$izin', 'Izin/Cuti'),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTotalKaryawan() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'karyawan')
          .snapshots(),
      builder: (context, snapshot) {
        final int total = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return _buildCard(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.people_alt_rounded,
                    color: AppColors.blue, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Karyawan Terdaftar',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$total',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Active',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuList(BuildContext context) {
    return Container(
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
        children: [
          _buildMenuItem(
            context,
            icon: Icons.people_outline_rounded,
            iconBg: AppColors.blueLight,
            iconColor: AppColors.blue,
            title: 'Manajemen Karyawan',
            subtitle: 'Input data, rekap absen & edit profil',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const KaryawanListPage())),
          ),
          _buildDivider(),
          _buildMenuItem(
            context,
            icon: Icons.description_outlined,
            iconBg: AppColors.orangeLight,
            iconColor: AppColors.orange,
            title: 'Rekapitulasi Kehadiran',
            subtitle: 'Lihat rekap absensi seluruh karyawan',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const KaryawanListPage())),
          ),
          _buildDivider(),
          _buildMenuItem(
            context,
            icon: Icons.checklist_rounded,
            iconBg: AppColors.greenLight,
            iconColor: AppColors.green,
            title: 'Persetujuan Izin & Cuti',
            subtitle: 'Review pengajuan cuti, sakit & izin',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ApprovalIzinPage())),
          ),
          _buildDivider(),
          _buildMenuItem(
            context,
            icon: Icons.access_time_rounded,
            iconBg: const Color(0xFFFFF7ED),
            iconColor: AppColors.orange,
            title: 'Pengaturan Jam Operasional',
            subtitle: 'Ubah batas waktu masuk dan pulang',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const SettingJamPage())),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCell(Color color, Color bg, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
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

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(height: 1, color: AppColors.borderLight),
    );
  }
}
