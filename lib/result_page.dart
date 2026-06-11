import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class ResultPage extends StatelessWidget {
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

  static const Color _accentBlue = Color(0xFF2563EB);
  static const Color _textPrimary = Color(0xFF1A1D26);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _textMuted = Color(0xFF9CA3AF);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _bgOffWhite = Color(0xFFF4F6F9);

  String _formatHari() {
    const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const bulan = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${hari[waktuAbsen.weekday - 1]}, ${waktuAbsen.day} ${bulan[waktuAbsen.month - 1]} ${waktuAbsen.year}';
  }

  String _formatJam() {
    return '${waktuAbsen.hour.toString().padLeft(2, '0')}:${waktuAbsen.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgOffWhite,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Detail Presensi',
          style: GoogleFonts.inter(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderColor),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          children: [
            _buildSuccessHeader(),
            const SizedBox(height: 24),
            _buildDetailCard(),
            const SizedBox(height: 32),
            _buildConfirmButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFBBF7D0), width: 2),
          ),
          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 40),
        ),
        const SizedBox(height: 16),
        Text(
          'Presensi Berhasil',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Data Anda telah tercatat',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(),
          const SizedBox(height: 20),
          _buildTimeRow(),
          const SizedBox(height: 24),
          Container(height: 1, color: _borderColor),
          const SizedBox(height: 20),
          _buildInfoList(),
        ],
      ),
    );
  }

  Widget _buildCardHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Detail Presensi',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _accentBlue,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF16A34A)),
              const SizedBox(width: 4),
              Text(
                'Terverifikasi',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildThumbnail(),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_formatJam()} WIB',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E40AF),
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatHari(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnail() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        color: const Color(0xFFF9FAFB),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: capturedImage != null
            ? FutureBuilder<Uint8List>(
                future: capturedImage!.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _accentBlue),
                      ),
                    );
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    return const Icon(Icons.person_rounded, size: 32, color: _textMuted);
                  }
                  return Image.memory(snapshot.data!, fit: BoxFit.cover);
                },
              )
            : const Icon(Icons.person_rounded, size: 32, color: _textMuted),
      ),
    );
  }

  Widget _buildInfoList() {
    return Column(
      children: [
        _buildInfoRow(Icons.person_outline_rounded, 'Nama', nama),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.badge_outlined, 'NRP', nrp),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.location_on_outlined, 'Status Lokasi', lokasi),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.map_outlined, 'Koordinat', koordinat),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _borderColor),
          ),
          child: Icon(icon, size: 18, color: _accentBlue),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _textMuted,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentBlue,
          elevation: 1,
          shadowColor: _accentBlue.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          'Konfirmasi & Kembali',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
