import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resq_flutter/services/auth_service.dart';
import 'package:resq_flutter/services/cloudinary_service.dart';
import 'package:resq_flutter/screens/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final error = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) setState(() => _isLoading = false);
      if (error != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  void _loginWithGoogle() async {
    setState(() => _isLoading = true);
    final result = await _authService.signInWithGoogle();
    final String? error = result['error'];
    final bool isNewUser = result['isNewUser'];
    final user = result['user'];

    if (mounted) setState(() => _isLoading = false);

    if (error != null && error != 'Google sign in cancelled.') {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
    } else if (isNewUser && user != null) {
      if (mounted) _showRoleSelectionDialog(user);
    }
  }

  void _showRoleSelectionDialog(User user) {
    File? nicFront;
    File? nicBack;
    File? certificate;
    String selectedRole = 'user';
    final phoneController = TextEditingController(text: user.phoneNumber ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Stack(
            clipBehavior: Clip.none,
            children: [
              const Column(
                children: [
                  Icon(LucideIcons.shieldCheck,
                      color: Color(0xFFDC2626), size: 40),
                  SizedBox(height: 12),
                  Text('Complete Profile',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
              Positioned(
                right: -10,
                top: -10,
                child: IconButton(
                  icon: const Icon(LucideIcons.x, size: 20, color: Colors.grey),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Provide details for verification.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Expanded(
                          child: _buildRoleTab(
                              'Citizen',
                              selectedRole == 'user',
                              () =>
                                  setDialogState(() => selectedRole = 'user'))),
                      Expanded(
                          child: _buildRoleTab(
                              'Responder',
                              selectedRole == 'emergency_responder',
                              () => setDialogState(
                                  () => selectedRole = 'emergency_responder'))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildDialogField(phoneController, 'Phone Number',
                    LucideIcons.phone, TextInputType.phone),
                const SizedBox(height: 12),
                _buildDialogUploadCard('NIC Front Side', nicFront, () async {
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null)
                    setDialogState(() => nicFront = File(image.path));
                }),
                const SizedBox(height: 8),
                _buildDialogUploadCard('NIC Back Side', nicBack, () async {
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null)
                    setDialogState(() => nicBack = File(image.path));
                }),
                if (selectedRole == 'emergency_responder') ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text('Professional Verification',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  _buildDialogUploadCard('Professional Proof', certificate,
                      () async {
                    final XFile? image =
                        await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null)
                      setDialogState(() => certificate = File(image.path));
                  }, isSecondary: true),
                ],
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (nicFront != null &&
                      nicBack != null &&
                      phoneController.text.isNotEmpty &&
                      (selectedRole == 'user' || certificate != null)) {
                    _finalizeGoogleSignup(user, selectedRole, nicFront!,
                        nicBack!, phoneController.text, certificate);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Incomplete Fields')));
                  }
                },
                child: const Text('SUBMIT',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTab(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 4)
                ]
              : [],
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFFDC2626) : Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildDialogField(TextEditingController ctrl, String hint,
      IconData icon, TextInputType type) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18),
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDialogUploadCard(String label, File? file, VoidCallback onTap,
      {bool isSecondary = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: file != null
              ? (isSecondary ? Colors.blue : Colors.green).withOpacity(0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: file != null
                  ? (isSecondary ? Colors.blue : Colors.green)
                  : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(file != null ? LucideIcons.checkCircle : LucideIcons.upload,
                size: 18,
                color: file != null
                    ? (isSecondary ? Colors.blue : Colors.green)
                    : Colors.grey),
            const SizedBox(width: 10),
            Expanded(
                child: Text(file != null ? 'Image Selected' : label,
                    style: const TextStyle(fontSize: 12))),
          ],
        ),
      ),
    );
  }

  void _finalizeGoogleSignup(User user, String role, File nicFront,
      File nicBack, String phone, File? cert) async {
    setState(() => _isLoading = true);
    try {
      String? frontUrl = await _cloudinaryService.uploadImage(nicFront);
      String? backUrl = await _cloudinaryService.uploadImage(nicBack);
      String? certUrl;
      if (role == 'emergency_responder' && cert != null)
        certUrl = await _cloudinaryService.uploadImage(cert);

      if (frontUrl == null || backUrl == null) throw 'Upload Failed';

      String uniqueId =
          "RQ${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'uniqueId': uniqueId,
        'email': user.email,
        'role': role,
        'username': user.displayName ?? 'User',
        'phoneNumber': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'verificationStatus': 'pending',
        'documents': {
          'nicFront': frontUrl,
          'nicBack': backUrl,
          if (certUrl != null) 'certificate': certUrl,
        }
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Submitted'),
            content: const Text('Pending verification.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
          0xFFFDE7E7), // Soft pink/light red background from screenshot
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Top Circular Icon (Matches Screenshot)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9DADA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.siren,
                      size: 52, color: Color(0xFFDC2626)),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Welcome to ResQ",
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Text(
                  "Safety through community and speed",
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 56),

                // Email Input
                _buildInputField(
                    _emailController, 'Email Address', LucideIcons.mail),
                const SizedBox(height: 16),
                // Password Input
                _buildInputField(
                    _passwordController, 'Password', LucideIcons.lock,
                    isPassword: true),

                const SizedBox(height: 16),
                // Remember Me & Forgot Password Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? false),
                          activeColor: const Color(0xFFDC2626),
                        ),
                        const Text("Remember Me",
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                    TextButton(
                        onPressed: () {},
                        child: const Text("Forgot Password?",
                            style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                                fontSize: 13))),
                  ],
                ),

                const SizedBox(height: 24),
                // Log In Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Log In',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 20),
                // OR Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),

                const SizedBox(height: 20),
                // Continue with Google Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    icon: const Icon(LucideIcons.chrome,
                        size: 22,
                        color: Color(0xFF4285F4)), // Google Blue color
                    label: const Text('Continue with Google',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: Colors.white.withOpacity(0.5)),
                    ),
                    onPressed: _isLoading ? null : _loginWithGoogle,
                  ),
                ),

                const SizedBox(height: 48),
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?",
                        style: TextStyle(color: Colors.grey.shade600)),
                    TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignupScreen())),
                      child: const Text('Sign Up',
                          style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
      TextEditingController controller, String label, IconData icon,
      {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      validator: (v) => v!.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    _isPasswordVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 20,
                    color: Colors.grey),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible))
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
      ),
    );
  }
}
