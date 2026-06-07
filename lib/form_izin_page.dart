import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FormIzinPage extends StatefulWidget {
  const FormIzinPage({super.key});

  @override
  State<FormIzinPage> createState() => _FormIzinPageState();
}

class _FormIzinPageState extends State<FormIzinPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Variabel State
  String _jenisIzin = 'Sakit';
  DateTime _tanggalMulai = DateTime.now();
  DateTime _tanggalSelesai = DateTime.now();
  TimeOfDay _jamIzin = TimeOfDay.now();
  final TextEditingController _keteranganController = TextEditingController();
  XFile? _fotoBukti;
  bool _isLoading = false;

  final List<String> _pilihanIzin = [
    'Sakit', 
    'Cuti Tahunan', 
    'Izin Pribadi', 
    'Izin Masuk Terlambat', 
    'Izin Pulang Cepat'
  ];

  // --- FUNGSI AMBIL FOTO ---
  Future<void> _ambilFoto(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 70);
    if (image != null) {
      setState(() => _fotoBukti = image);
    }
  }

  // --- FUNGSI PILIH TANGGAL & JAM ---
  Future<void> _pilihTanggal(BuildContext context, bool isMulai) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isMulai ? _tanggalMulai : _tanggalSelesai,
      firstDate: DateTime.now().subtract(const Duration(days: 7)), // Boleh ngajuin mundur maks 7 hari
      lastDate: DateTime.now().add(const Duration(days: 90)), // Boleh ngajuin maju maks 3 bulan
    );
    if (picked != null) {
      setState(() {
        if (isMulai) {
          _tanggalMulai = picked;
          // Biar tanggal selesai otomatis minimal sama kayak tanggal mulai
          if (_tanggalSelesai.isBefore(_tanggalMulai)) {
            _tanggalSelesai = picked;
          }
        } else {
          _tanggalSelesai = picked;
        }
      });
    }
  }

  Future<void> _pilihJam(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _jamIzin,
    );
    if (picked != null) {
      setState(() => _jamIzin = picked);
    }
  }

  // --- FUNGSI SUBMIT KE FIRESTORE ---
  Future<void> _submitPengajuan() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi khusus "Sakit" wajib ada foto
    if (_jenisIzin == 'Sakit' && _fotoBukti == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Surat Dokter wajib dilampirkan untuk pengajuan Sakit!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Tarik Data User (NRP & Nama)
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("Sesi login tidak ditemukan");

      QuerySnapshot userSnap = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: currentUser.email).limit(1).get();
      if (userSnap.docs.isEmpty) throw Exception("Biodata user tidak ditemukan di database");
      
      var userData = userSnap.docs.first.data() as Map<String, dynamic>;
      String nrpSiswa = userData['nrp'] ?? '000000';
      String namaSiswa = userData['nama'] ?? 'Karyawan';

      // 2. Upload Foto ke ImgBB (Kalau Ada)
      String? downloadUrl;
      if (_fotoBukti != null) {
        final bytes = await _fotoBukti!.readAsBytes(); 
        String imgbbApiKey = '5d0b36d874199ba68bcffe5dd6f3402a'; // API Key lu yang kemaren
        
        var request = http.MultipartRequest('POST', Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey'));
        request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'bukti_izin.jpg'));
        
        var response = await request.send();
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        downloadUrl = json['data']['url']; 
      }

      // 3. Format Waktu
      String formatTgl(DateTime dt) => "${dt.day.toString().padLeft(2,'0')}-${dt.month.toString().padLeft(2,'0')}-${dt.year}";
      String formatJm(TimeOfDay jam) => "${jam.hour.toString().padLeft(2,'0')}:${jam.minute.toString().padLeft(2,'0')}";
      
      bool isWaktuSingkat = _jenisIzin.contains('Terlambat') || _jenisIzin.contains('Pulang');

      // 4. Simpan ke Collection 'pengajuan_izin'
      await FirebaseFirestore.instance.collection('pengajuan_izin').add({
        'nrp': nrpSiswa,
        'nama': namaSiswa,
        'jenis_izin': _jenisIzin,
        'keterangan': _keteranganController.text,
        'tanggal_mulai': formatTgl(_tanggalMulai),
        'tanggal_selesai': isWaktuSingkat ? formatTgl(_tanggalMulai) : formatTgl(_tanggalSelesai),
        'jam_izin': isWaktuSingkat ? formatJm(_jamIzin) : null,
        'bukti_url': downloadUrl,
        'status_approval': 'Menunggu', // Default nunggu di-acc HR
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pop(context); // Balik ke halaman sebelumnya
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan berhasil dikirim! Menunggu persetujuan HRD.'), backgroundColor: Colors.green));

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengirim pengajuan: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isWaktuSingkat = _jenisIzin.contains('Terlambat') || _jenisIzin.contains('Pulang');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pengajuan Izin', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PILIH JENIS IZIN ---
                  const Text('Jenis Pengajuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _jenisIzin,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _pilihanIzin.map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _jenisIzin = val);
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- PILIH TANGGAL (DINAMIS) ---
                  if (!isWaktuSingkat) ...[
                    Row(
                      children: [
                        Expanded(child: _buildDatePickerCard('Dari Tanggal', _tanggalMulai, () => _pilihTanggal(context, true))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDatePickerCard('Sampai Tanggal', _tanggalSelesai, () => _pilihTanggal(context, false))),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(child: _buildDatePickerCard('Tanggal', _tanggalMulai, () => _pilihTanggal(context, true))),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pilihJam(context),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Estimasi Jam', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  const SizedBox(height: 4),
                                  Text('${_jamIzin.hour.toString().padLeft(2,'0')}:${_jamIzin.minute.toString().padLeft(2,'0')} WIB', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),

                  // --- KETERANGAN / ALASAN ---
                  const Text('Keterangan / Alasan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _keteranganController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tuliskan alasan lengkap Anda di sini...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                    validator: (value) => value!.isEmpty ? 'Keterangan tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 20),

                  // --- UPLOAD BUKTI ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Lampiran Bukti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (_jenisIzin == 'Sakit')
                         const Text('*Wajib', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold))
                      else
                         const Text('*Opsional', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Ambil dari Kamera'), onTap: () { Navigator.pop(context); _ambilFoto(ImageSource.camera); }),
                            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Pilih dari Galeri'), onTap: () { Navigator.pop(context); _ambilFoto(ImageSource.gallery); }),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100, style: BorderStyle.solid)),
                      child: Column(
                        children: [
                          Icon(_fotoBukti != null ? Icons.check_circle : Icons.upload_file, color: _fotoBukti != null ? Colors.green : Colors.blueAccent, size: 40),
                          const SizedBox(height: 8),
                          Text(_fotoBukti != null ? 'Bukti Foto Berhasil Dipilih' : 'Ketuk untuk mengunggah foto', style: TextStyle(color: _fotoBukti != null ? Colors.green : Colors.blueAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- TOMBOL SUBMIT ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitPengajuan,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Kirim Pengajuan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDatePickerCard(String title, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text('${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}