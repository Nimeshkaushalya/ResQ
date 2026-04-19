import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';

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
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isPasswordVisible = false; // Added back the missing variable

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final error = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Fixed BuildContext across async gaps
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  void _loginWithGoogle() async {
    setState(() => _isLoading = true);
    final result = await _authService.signInWithGoogle();
    
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    final String? error = result['error'];
    if (error != null) {
      if (error != 'Google sign in cancelled.') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }

    // Successfully logged in via Google. 
    // We don't need to do anything else because AuthWrapper listens to authStateChanges.
    // However, to be extra safe and ensure the UI updates immediately without hot restart:
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _showForgotPasswordDialog() {
    final resetController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Reset Password", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter your email address to receive a recovery link."),
            const SizedBox(height: 20),
            TextField(
              controller: resetController,
              decoration: InputDecoration(
                labelText: "Email address",
                prefixIcon: const Icon(LucideIcons.mail, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              String email = resetController.text.trim();
              if (email.isEmpty) return;
              
              final error = await _authService.sendPasswordResetEmail(email);
              if (context.mounted) Navigator.pop(context);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? "Password reset email sent! Check your inbox."),
                    backgroundColor: error == null ? Colors.green : Colors.red,
                  )
                );
              }
            },
            child: const Text("Send Link", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE7E7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: const BoxDecoration(color: Color(0xFFF9DADA), shape: BoxShape.circle),
                          child: const Icon(LucideIcons.siren, size: 54, color: Color(0xFFDC2626)),
                        ),
                        const SizedBox(height: 32),
                        const Text("Welcome to ResQ", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                        const SizedBox(height: 10),
                        const Text("Safety through community and speed", style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 48),

                        _buildInputField(_emailController, 'Email Address', LucideIcons.mail),
                        const SizedBox(height: 16),
                        _buildInputField(_passwordController, 'Password', LucideIcons.lock, isPassword: true),
                        
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe, 
                                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                  activeColor: const Color(0xFFDC2626),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                const Text("Remember Me", style: TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                            TextButton(onPressed: _showForgotPasswordDialog, child: const Text("Forgot?", style: TextStyle(color: Color(0xFFDC2626)))),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        Row(children: [const Expanded(child: Divider()), const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('OR')), const Expanded(child: Divider())]),
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: OutlinedButton.icon(
                            icon: const Icon(LucideIcons.chrome, color: Color(0xFF4285F4)),
                            label: const Text('Continue with Google', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            onPressed: _isLoading ? null : _loginWithGoogle,
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("No account?"),
                            TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())), child: const Text('Sign Up', style: TextStyle(color: Color(0xFFDC2626)))),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFFDC2626)),
        suffixIcon: isPassword 
          ? IconButton(
              icon: Icon(_isPasswordVisible ? LucideIcons.eye : LucideIcons.eyeOff, size: 18, color: Colors.grey),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            )
          : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      ),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }
}
