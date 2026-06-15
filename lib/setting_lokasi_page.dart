import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'widgets/shared_widgets.dart';
import 'utils/app_utils.dart';

class SettingLokasiPage extends StatefulWidget {
  const SettingLokasiPage({super.key});

  @override
  State<SettingLokasiPage> createState() => _SettingLokasiPageState();
}

class _SettingLokasiPageState extends State<SettingLokasiPage> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _radiusController = TextEditingController(text: '50');

  String? _companyId;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final hrDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (!hrDoc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      _companyId = hrDoc.data()!['company_id'] as String?;
      if (_companyId == null || _companyId!.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final companyDoc = await FirebaseFirestore.instance.collection('companies').doc(_companyId).get();
      if (companyDoc.exists) {
        final data = companyDoc.data()!;
        _latController.text = (data['latitude'] ?? '').toString();
        _lngController.text = (data['longitude'] ?? '').toString();
        _radiusController.text = (data['radius'] ?? '50').toString();
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _ambilLokasiSaatIni() async {
    setState(() => _isFetchingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Izin lokasi ditolak.', style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
          setState(() => _isFetchingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Izin lokasi diblokir permanen. Buka pengaturan HP.', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        setState(() => _isFetchingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      setState(() {
        _latController.text = position.latitude.toStringAsFixed(8);
        _lngController.text = position.longitude.toStringAsFixed(8);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lokasi berhasil diambil!', style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      showCustomError(context, 'Gagal mengambil lokasi. Pastikan GPS aktif.');
    }
    if (mounted) setState(() => _isFetchingLocation = false);
  }

  Future<void> _simpanLokasi() async {
    if (_companyId == null || _companyId!.isEmpty) return;
    if (_latController.text.isEmpty || _lngController.text.isEmpty || _radiusController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Semua field wajib diisi!', style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: const Color(0xFFEA580C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('companies').doc(_companyId).update({
        'latitude': double.parse(_latController.text.trim()),
        'longitude': double.parse(_lngController.text.trim()),
        'radius': int.parse(_radiusController.text.trim()),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lokasi berhasil diperbarui!', style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      showCustomError(context, 'Gagal menyimpan lokasi. Silakan coba lagi.');
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Pengaturan Lokasi', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 18)),
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
                        Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 22)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Geofencing Kantor', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text('Tentukan titik pusat dan radius area absensi karyawan', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isFetchingLocation ? null : _ambilLokasiSaatIni,
                        icon: _isFetchingLocation
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue))
                            : const Icon(Icons.my_location_rounded, size: 18),
                        label: Text(_isFetchingLocation ? 'Mengambil lokasi...' : 'Ambil Lokasi Saat Ini', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.blue,
                          side: BorderSide(color: AppColors.blue.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    AppLabel(text: 'Latitude (Garis Lintang)'),
                    const SizedBox(height: 8),
                    AppTextField(controller: _latController, hint: 'contoh: -6.91750000', icon: Icons.explore_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true)),
                    const SizedBox(height: 20),
                    AppLabel(text: 'Longitude (Garis Bujur)'),
                    const SizedBox(height: 8),
                    AppTextField(controller: _lngController, hint: 'contoh: 107.61910000', icon: Icons.explore_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true)),
                    const SizedBox(height: 20),
                    AppLabel(text: 'Radius Absensi (meter)'),
                    const SizedBox(height: 8),
                    AppTextField(controller: _radiusController, hint: 'contoh: 50', icon: Icons.radio_button_unchecked, keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.blue.withValues(alpha: 0.1))),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: AppColors.blue.withValues(alpha: 0.6)),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Radius menentukan jarak maksimal karyawan dari titik kantor agar absensi dianggap valid. Default: 50 meter.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.5))),
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
                    onPressed: _isSaving ? null : _simpanLokasi,
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
                            Text('Simpan Lokasi', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                          ]),
                  ),
                ),
              ),
            ]),
    );
  }

}
