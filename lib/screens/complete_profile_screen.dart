import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:io';
import '../services/cloudinary_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class CompleteProfileScreen extends StatefulWidget {
  final User user;
  const CompleteProfileScreen({super.key, required this.user});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.displayName ?? '';
  }

  String _selectedRole = 'user';
  File? _nicFront, _nicBack;
  List<File> _certificates = [];
  bool _isLoading = false;

  final CloudinaryService _cloudinary = CloudinaryService();
  final ImagePicker _picker = ImagePicker();
  final AuthService _authService = AuthService();

  Future<void> _pickImage(String type) async {
    if (type == 'multi_cert') {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _certificates.addAll(images.map((img) => File(img.path)));
        });
      }
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (type == 'front') _nicFront = File(image.path);
        if (type == 'back') _nicBack = File(image.path);
      });
    }
  }

  void _removeCertificate(int index) {
    setState(() => _certificates.removeAt(index));
  }

  Future<void> _handleLogout() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint("Logout error: $e");
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nicFront == null || _nicBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload NIC images')));
      return;
    }
    if (_selectedRole == 'emergency_responder' && _certificates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification documents required for responders')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      String uniqueId = await _authService.generateUniqueId();
      
      String? frontUrl = await _cloudinary.uploadImage(_nicFront!);
      String? backUrl = await _cloudinary.uploadImage(_nicBack!);

      List<String> certUrls = [];
      for (var file in _certificates) {
        String? url = await _cloudinary.uploadImage(file);
        if (url != null) certUrls.add(url);
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
        'uid': widget.user.uid,
        'uniqueId': uniqueId,
        'username': _nameController.text.trim(),
        'email': widget.user.email,
        'phoneNumber': _phoneController.text.trim(),
        'role': _selectedRole,
        'verificationStatus': 'pending',
        'documentsSubmitted': true,
        'authMethod': 'google', // Added for flow separation
        'createdAt': FieldValue.serverTimestamp(),
        'documents': {
          'nicFront': frontUrl,
          'nicBack': backUrl,
          'certificates': certUrls,
        },
        'responderType': _selectedRole == 'emergency_responder' ? 'Medical / First Aid' : null,
      });

      final NotificationService _notif = NotificationService();
      await _notif.updateToken();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration submitted! Verification pending.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE7E7),
      appBar: AppBar(
        title: const Text('Complete Profile', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(LucideIcons.logOut, color: Color(0xFF0F172A)), onPressed: _handleLogout)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // New Header Visual based on screenshot
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 20)],
                ),
                child: const Icon(LucideIcons.fileWarning, size: 64, color: Color(0xFFDC2626)),
              ),
              const SizedBox(height: 32),
              const Text(
                "Final Steps Required",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              const Text(
                "To verify your identity and role, please provide the following details.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 40),
              
              // Role Selector
              Row(
                children: [
                  Expanded(child: _buildRoleCard('Citizen', LucideIcons.user, 'user')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildRoleCard('Responder', LucideIcons.shieldAlert, 'emergency_responder')),
                ],
              ),
              const SizedBox(height: 24),

              // Full Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(LucideIcons.user, color: Color(0xFFDC2626)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(20),
                ),
                validator: (v) => v!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Contact Number',
                  prefixIcon: const Icon(LucideIcons.phone, color: Color(0xFFDC2626)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(20),
                ),
                validator: (v) => v!.isEmpty ? 'Phone number is required' : null,
              ),
              const SizedBox(height: 32),

              const Row(
                children: [
                  Icon(LucideIcons.fingerprint, size: 20, color: Color(0xFF0F172A)),
                  SizedBox(width: 12),
                  Text("Verification Documents", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
                ],
              ),
              const SizedBox(height: 16),
              _buildUploadTile("NIC / ID Front", _nicFront != null, () => _pickImage('front')),
              _buildUploadTile("NIC / ID Back", _nicBack != null, () => _pickImage('back')),
              
              if (_selectedRole == 'emergency_responder') ...[
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Icon(LucideIcons.award, size: 20, color: Color(0xFF0F172A)),
                    SizedBox(width: 12),
                    Text("Professional Proof", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
                  ],
                ),
                const SizedBox(height: 12),
                
                ...List.generate(_certificates.length, (index) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.checkCircle, color: Colors.green, size: 18),
                      const SizedBox(width: 12),
                      Expanded(child: Text("Doc ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold))),
                      IconButton(icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 18), onPressed: () => _removeCertificate(index)),
                    ],
                  ),
                )),

                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _pickImage('multi_cert'),
                  icon: const Icon(LucideIcons.plus, size: 20),
                  label: const Text("UPLOAD CERTIFICATE", style: TextStyle(fontWeight: FontWeight.w900)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                    foregroundColor: const Color(0xFFDC2626),
                  ),
                ),
              ],

              const SizedBox(height: 56),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(LucideIcons.check),
                  label: const Text("SUBMIT VERIFICATION", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 10,
                    shadowColor: const Color(0xFFDC2626).withOpacity(0.4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(LucideIcons.logIn, size: 18),
                label: const Text("Access Different Account", style: TextStyle(fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String title, IconData icon, String role) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDC2626) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: (isSelected ? const Color(0xFFDC2626) : Colors.black).withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFFDC2626), size: 32),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: isSelected ? Colors.white : const Color(0xFF0F172A), fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadTile(String label, bool hasFile, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: (hasFile ? Colors.green : Colors.grey).withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(hasFile ? LucideIcons.check : LucideIcons.upload, color: hasFile ? Colors.green : Colors.grey, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
      ),
    );
  }
}
