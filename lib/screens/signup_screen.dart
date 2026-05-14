import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../data/responder_types.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  String _selectedRole = 'user';
  String? _selectedCategory;
  bool _isLoading = false;
  bool _autoValidate = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  File? _nicFrontImage;
  File? _nicBackImage;
  File? _certImage;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  int _currentStep = 0;

  Future<void> _pickImage(String type, ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        if (type == 'nicFront') _nicFrontImage = File(image.path);
        else if (type == 'nicBack') _nicBackImage = File(image.path);
        else if (type == 'cert') _certImage = File(image.path);
      });
    }
  }

  void _showPicker(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(LucideIcons.image),
                  title: const Text('Photo Library'),
                  onTap: () {
                    _pickImage(type, ImageSource.gallery);
                    Navigator.of(context).pop();
                  }),
              ListTile(
                leading: const Icon(LucideIcons.camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(type, ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _signup() async {
    if (_nicFrontImage == null || _nicBackImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload both sides of your ID')));
      return;
    }

    if (_selectedRole == 'emergency_responder' && _certImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification certificate is required for responders')));
      return;
    }

    setState(() => _isLoading = true);
    Map<String, String> uploadedDocs = {};

    try {
      String? nicFrontUrl = await _cloudinaryService.uploadImage(_nicFrontImage!);
      String? nicBackUrl = await _cloudinaryService.uploadImage(_nicBackImage!);
      
      if (nicFrontUrl == null || nicBackUrl == null) throw 'ID upload failed';
      
      uploadedDocs['nicFront'] = nicFrontUrl;
      uploadedDocs['nicBack'] = nicBackUrl;

      if (_selectedRole == 'emergency_responder') {
        String? certUrl = await _cloudinaryService.uploadImage(_certImage!);
        if (certUrl == null) throw 'Certificate upload failed';
        uploadedDocs['certificate'] = certUrl;
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      return;
    }

    try {
      String? error = await _authService.signUp(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
        responderType: _selectedCategory,
        documents: uploadedDocs,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating account: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
                    ),
                    const Expanded(
                      child: Text(
                        'Create Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                child: Row(
                  children: [
                    _buildProgressDot(0),
                    _buildProgressLine(0),
                    _buildProgressDot(1),
                    _buildProgressLine(1),
                    _buildProgressDot(2),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: _buildCurrentStep(),
              ),

              // Bottom Actions
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => setState(() => _currentStep--),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Back', style: TextStyle(color: Color(0xFF0F172A))),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(_currentStep == 2 ? 'Finish' : 'Continue', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleContinue() {
    if (_currentStep == 0) {
      if (_selectedRole == 'emergency_responder' && _selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your service type')));
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      setState(() => _autoValidate = true);
      if (!_formKey.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please correct the errors in red below')));
        return;
      }
      setState(() => _currentStep = 2);
    } else {
      _signup();
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildRoleSelection();
      case 1: return _buildAccountDetails();
      case 2: return _buildVerification();
      default: return const SizedBox();
    }
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Choose Your Role", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text("Select how you want to use ResQ", style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 32),
        _buildRoleCard(
          'user', 
          'Citizen', 
          'Report emergencies and get immediate help from nearby responders.', 
          LucideIcons.user, 
          Colors.blue
        ),
        const SizedBox(height: 16),
        _buildRoleCard(
          'emergency_responder', 
          'Responder', 
          'Verified emergency service personnel ready to save lives.', 
          LucideIcons.shieldAlert, 
          Colors.red
        ),
        if (_selectedRole == 'emergency_responder') ...[
          const SizedBox(height: 32),
          const Text("Service Category", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                hint: const Text("Select Category"),
                items: responderCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAccountDetails() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Account Details", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text("Setup your official ResQ profile", style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 32),
          _buildInputField(_usernameController, 'Username', LucideIcons.user, validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Username is required';
            if (v.trim().length < 3) return 'Must be at least 3 characters';
            return null;
          }),
          const SizedBox(height: 16),
          _buildInputField(_emailController, 'Email Address', LucideIcons.mail, keyboard: TextInputType.emailAddress, validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            final email = v.trim().toLowerCase();
            final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegExp.hasMatch(email)) return 'Enter a valid email address';
            
            // Smart validation to prevent highly common incomplete domain typos
            if (email.endsWith('@gmail.co') || email.endsWith('@gmail.c')) {
              return 'Did you mean @gmail.com?';
            }
            if (email.endsWith('.co') && (email.contains('@gmail.') || email.contains('@yahoo.') || email.contains('@outlook.') || email.contains('@hotmail.'))) {
              return 'Please enter the complete domain (.com)';
            }
            return null;
          }),
          const SizedBox(height: 16),
          _buildInputField(_phoneController, 'Phone Number', LucideIcons.phone, keyboard: TextInputType.phone, validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Phone number is required';
            final digits = v.replaceAll(' ', '').replaceAll('-', '').replaceAll('+', '');
            if (digits.length < 8) return 'Must contain at least 8 digits';
            return null;
          }),
          const SizedBox(height: 16),
          _buildInputField(_passwordController, 'Password', LucideIcons.lock, isPassword: true, obscure: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword), validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 6) return 'Must be at least 6 characters';
            return null;
          }),
          const SizedBox(height: 16),
          _buildInputField(_confirmPasswordController, 'Confirm Password', LucideIcons.lock, isPassword: true, obscure: _obscureConfirmPassword, onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword), validator: (v) {
            if (v == null || v.isEmpty) return 'Confirm password is required';
            if (v != _passwordController.text) return 'Passwords do not match';
            return null;
          }),
        ],
      ),
    );
  }

  Widget _buildVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Verification", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text("Upload documents to verify your identity", style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 32),
        _buildUploadCard('National ID / License Front', _nicFrontImage, 'nicFront'),
        const SizedBox(height: 16),
        _buildUploadCard('National ID / License Back', _nicBackImage, 'nicBack'),
        if (_selectedRole == 'emergency_responder') ...[
          const SizedBox(height: 16),
          _buildUploadCard('Service Certificate', _certImage, 'cert'),
        ],
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _buildRoleCard(String role, String title, String desc, IconData icon, Color color) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: isSelected ? color : Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade600),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? color : const Color(0xFF0F172A))),
                  Text(desc, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
      TextEditingController controller, String label, IconData icon,
      {bool isPassword = false,
      bool obscure = false,
      VoidCallback? onToggle,
      TextInputType keyboard = TextInputType.text,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      validator: validator,
      autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscure ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: 20),
                onPressed: onToggle)
            : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDC2626))),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2)),
      ),
    );
  }

  Widget _buildUploadCard(String label, File? file, String type) {
    return InkWell(
      onTap: () => _showPicker(context, type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: file != null ? Colors.green.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: file != null ? Colors.green : Colors.grey.shade300, style: file != null ? BorderStyle.solid : BorderStyle.none),
        ),
        child: Row(
          children: [
            Icon(file != null ? LucideIcons.checkCircle2 : LucideIcons.uploadCloud, color: file != null ? Colors.green : Colors.blue),
            const SizedBox(width: 16),
            Expanded(child: Text(file != null ? 'Document Ready' : label, style: TextStyle(fontWeight: file != null ? FontWeight.bold : FontWeight.normal, color: file != null ? Colors.green : const Color(0xFF0F172A)))),
            if (file != null) const Icon(LucideIcons.refreshCw, size: 16, color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDot(int step) {
    bool active = _currentStep >= step;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: active ? const Color(0xFFDC2626) : Colors.grey.shade300, shape: BoxShape.circle),
    );
  }

  Widget _buildProgressLine(int step) {
    bool active = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        color: active ? const Color(0xFFDC2626) : Colors.grey.shade300,
      ),
    );
  }
}
