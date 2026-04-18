import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('email') ?? '';
      _passwordController.text = prefs.getString('password') ?? '';
      _rememberMe = prefs.getBool('rememberMe') ?? false;
    });
  }

  void _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('email', _emailController.text.trim());
      await prefs.setString('password', _passwordController.text.trim());
      await prefs.setBool('rememberMe', true);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('rememberMe', false);
    }
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      _saveCredentials();

      String? error = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      }
    }
  }

  void _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _authService.signInWithGoogle();
    final String? error = result['error'];
    final bool isNewUser = result['isNewUser'];
    final user = result['user'];

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (error != null && error != 'Google sign in cancelled.') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } else if (isNewUser && user != null) {
      if (mounted) {
        _showRoleSelectionDialog(user);
      }
    }
  }

  void _showRoleSelectionDialog(user) {
    File? nicFront;
    File? nicBack;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Complete Your Profile 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('To ensure community safety, please upload your National ID for verification.'),
                const SizedBox(height: 20),
                _buildDialogUploadCard('NIC Front Side', nicFront, () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) setDialogState(() => nicFront = File(image.path));
                }),
                const SizedBox(height: 10),
                _buildDialogUploadCard('NIC Back Side', nicBack, () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) setDialogState(() => nicBack = File(image.path));
                }),
                const SizedBox(height: 20),
                const Text('Join as:', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: (nicFront == null || nicBack == null) ? null : () => _finalizeGoogleSignup(user, 'user', nicFront!, nicBack!),
                    child: const Text('Citizen (I need help)'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: (nicFront == null || nicBack == null) ? null : () => _finalizeGoogleSignup(user, 'emergency_responder', nicFront!, nicBack!),
                    child: const Text('Responder (I want to help)'),
                  ),
                ),
                if (nicFront == null || nicBack == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text('Please upload ID images to continue', style: TextStyle(color: Colors.red, fontSize: 10)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogUploadCard(String label, File? file, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: file != null ? Colors.green.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: file != null ? Colors.green : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(file != null ? LucideIcons.checkCircle : LucideIcons.upload, size: 20, color: file != null ? Colors.green : Colors.grey),
            const SizedBox(width: 10),
            Expanded(child: Text(file != null ? 'Image Selected' : label, style: TextStyle(fontSize: 12, color: file != null ? Colors.green : Colors.black))),
          ],
        ),
      ),
    );
  }

  void _finalizeGoogleSignup(user, String role, File nicFront, File nicBack) async {
    Navigator.pop(context); // Close dialog
    setState(() => _isLoading = true);
    
    try {
      // Upload images to Cloudinary
      String? frontUrl = await _cloudinaryService.uploadImage(nicFront);
      String? backUrl = await _cloudinaryService.uploadImage(nicBack);

      if (frontUrl == null || backUrl == null) throw 'Image upload failed';

      // Update AuthService to accept images for Google users
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'role': role,
        'username': user.displayName ?? 'User',
        'phoneNumber': user.phoneNumber ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'verificationStatus': 'pending',
        'documents': {
          'nicFront': frontUrl,
          'nicBack': backUrl,
        }
      });
      
      // Update FCM Token
      await _authService.updateUserProfile(data: {'fcmToken': 'updated'}); // Simple trigger
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFDC2626).withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Branding
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.siren, size: 48, color: Color(0xFFDC2626)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Welcome to ResQ",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Safety through community and speed",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 48),

                  // Input Fields
                  _buildInputField(_emailController, 'Email Address', LucideIcons.mail, keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildInputField(
                    _passwordController, 
                    'Password', 
                    LucideIcons.lock, 
                    isPassword: true, 
                    obscure: _obscurePassword, 
                    onToggle: () => setState(() => _obscurePassword = !_obscurePassword)
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Remember Me
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (value) => setState(() => _rememberMe = value ?? false),
                              activeColor: const Color(0xFFDC2626),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Remember Me', style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade200)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade200)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Google Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(LucideIcons.chrome, color: Colors.blue, size: 20),
                      label: const Text('Continue with Google', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                      onPressed: _isLoading ? null : _loginWithGoogle,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: TextStyle(color: Colors.grey.shade600)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                        child: const Text("Sign Up", style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, bool obscure = false, VoidCallback? onToggle, TextInputType keyboard = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        validator: (value) => value!.isEmpty ? 'Please enter your $label' : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade400),
          suffixIcon: isPassword ? IconButton(icon: Icon(obscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 20, color: Colors.grey.shade400), onPressed: onToggle) : null,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade100)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1)),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
