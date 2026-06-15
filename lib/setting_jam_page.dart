import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'utils/app_utils.dart';

class SettingJamPage extends StatefulWidget {
  const SettingJamPage({super.key});

  @override
  State<SettingJamPage> createState() => _SettingJamPageState();
}

class _SettingJamPageState extends State<SettingJamPage> {
  TimeOfDay _jamMasuk = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _jamPulang = const TimeOfDay(hour: 17, minute: 0);
  bool _isLoading = true;
  bool _isSaving = false;
  String _docId = '';

  @override
  void initState() {
    super.initState();
    _loadPengaturan();
  }

  Future<void> _loadPengaturan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: user.email).get();
      if (snapshot.docs.isNotEmpty) {
        _docId = snapshot.docs.first.id;
        final data = snapshot.docs.first.data();
        if (data.containsKey('jam_masuk_default') && data['jam_masuk_default'] != null) {
          final parts = data['jam_masuk_default'].split(':');
          _jamMasuk = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
        if (data.containsKey('jam_pulang_default') && data['jam_pulang_default'] != null) {
          final parts = data['jam_pulang_default'].split(':');
          _jamPulang = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String _formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pilihJam(bool isMasuk) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isMasuk ? _jamMasuk : _jamPulang,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              dayPeriodShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              dayPeriodColor: WidgetStateColor.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.blue : AppColors.bg),
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.white : AppColors.textSecondary),
              dayPeriodTextStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
              hourMinuteColor: WidgetStateColor.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.blue.withValues(alpha: 0.1) : AppColors.bg),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.blue : AppColors.textPrimary),
              dialHandColor: AppColors.blue,
              dialBackgroundColor: AppColors.bg,
              entryModeIconColor: AppColors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            colorScheme: const ColorScheme.light(primary: AppColors.blue, onPrimary: Colors.white, surface: Colors.white, onSurface: AppColors.textPrimary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isMasuk) {
          _jamMasuk = picked;
        } else {
          _jamPulang = picked;
        }
      });
    }
  }

  Future<void> _simpanPengaturan() async {
    if (_docId.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(_docId).update({
        'jam_masuk_default': _formatTime(_jamMasuk),
        'jam_pulang_default': _formatTime(_jamPulang),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Pengaturan jam operasional berhasil disimpan!', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      showCustomError(context, 'Gagal menyimpan pengaturan jam. Silakan coba lagi.');
    }

    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Pengaturan Jam', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
          : Column(children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.blue, AppColors.blueDark], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))]),
                      child: Row(children: [
                        Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 22)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Jam Operasional', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text('Atur batas waktu presensi karyawan', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 28),
                    _buildTimeCard(
                      title: 'Batas Jam Masuk',
                      subtitle: 'Karyawan yang absen setelah jam ini akan dilabeli Terlambat',
                      time: _jamMasuk,
                      icon: Icons.login_rounded,
                      isMasuk: true,
                      accentColor: const Color(0xFF0EA5E9),
                      accentBg: const Color(0xFFF0F9FF),
                    ),
                    const SizedBox(height: 14),
                    _buildTimeCard(
                      title: 'Batas Jam Pulang',
                      subtitle: 'Karyawan yang absen sebelum jam ini akan dilabeli Pulang Cepat',
                      time: _jamPulang,
                      icon: Icons.logout_rounded,
                      isMasuk: false,
                      accentColor: const Color(0xFFF59E0B),
                      accentBg: const Color(0xFFFFFBEB),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.blue.withValues(alpha: 0.1))),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: AppColors.blue.withValues(alpha: 0.6)),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Perubahan jam operasional akan berlaku untuk seluruh karyawan di perusahaan Anda.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.5))),
                      ]),
                    ),
                  ]),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border, width: 0.8))),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _simpanPengaturan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blueDark,
                      disabledBackgroundColor: AppColors.blueDark.withValues(alpha: 0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text('Simpan Pengaturan', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                          ]),
                  ),
                ),
              ),
            ]),
    );
  }

  Widget _buildTimeCard({
    required String title,
    required String subtitle,
    required TimeOfDay time,
    required IconData icon,
    required bool isMasuk,
    required Color accentColor,
    required Color accentBg,
  }) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border, width: 0.8), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _pilihJam(isMasuk),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(width: 52, height: 52, decoration: BoxDecoration(color: accentBg, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: accentColor, size: 24)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted, height: 1.4)),
                const SizedBox(height: 10),
                Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: accentBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: accentColor.withValues(alpha: 0.15))), child: Text('${_formatTime(time)} WIB', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: accentColor, letterSpacing: 1))),
              ])),
              Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted)),
            ]),
          ),
        ),
      ),
    );
  }
}
