import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'hr_dashboard.dart';

class CompanyIdentityPage extends StatefulWidget {
  final String? uid;
  const CompanyIdentityPage({super.key, this.uid});

  @override
  State<CompanyIdentityPage> createState() => _CompanyIdentityPageState();
}

class _CompanyIdentityPageState extends State<CompanyIdentityPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveCompany() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final companyRef = await FirebaseFirestore.instance.collection('companies').add({
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'phone': _phoneController.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });

      final uid = widget.uid ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'company_id': companyRef.id,
          'nama_perusahaan': _nameController.text.trim(),
        });
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HRDashboard()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan data perusahaan: $e')));
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identitas Perusahaan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Perusahaan'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama perusahaan wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Lokasi / Alamat'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Lokasi wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'No. Telepon (opsional)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCompany,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan dan Lanjutkan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
