import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../data/responder_types.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(); // NEW
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // NEW
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // NEW
  final AuthService _authService = AuthService();

  String _selectedRole = 'user'; // Default role
  String? _selectedCategory; // NEW
  bool _isLoading = false;
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
        if (type == 'nicFront')
          _nicFrontImage = File(image.path);
        else if (type == 'nicBack')
          _nicBackImage = File(image.path);
        else if (type == 'cert') _certImage = File(image.path);
      });
    }
  }

  void _showPicker(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Photo Library'),
                  onTap: () {
                    _pickImage(type, ImageSource.gallery);
                    Navigator.of(context).pop();
                  }),
              ListTile(
                leading: const Icon(Icons.photo_camera),
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

  void _skipVerification() async {
    // DEV ONLY: Bypass Cloudinary and image requirements entirely
    setState(() {
      _isLoading = true;
    });

    print('DEV SKIP: Signup attempt started for ${_emailController.text}');
    String? error = await _authService.signUp(
      email: _emailController.text.trim(),
      username: _usernameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      role: _selectedRole,
      responderType: _selectedCategory,
      documents: {'devSkip': 'true'}, // Dummy data
    );
    print('DEV SKIP: Signup attempt finished with error: $error');

    setState(() {
      _isLoading = false;
    });

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } else {
      if (mounted) {
        Navigator.pop(context); // Go back to login/main flow
      }
    }
  }

  void _signup() async {
    // TEMPORARY: Disabled document validation for easy testing
    /*
    if (_selectedRole == 'emergency_responder') {
      if (_nicFrontImage == null || _certImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Work ID Details and Professional Certificate are required')),
        );
        return;
      }
    } else {
      // user
      if (_nicFrontImage == null || _nicBackImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'NIC/Driving License/Passport (Front & Back) are required')),
        );
        return;
      }
    }
    */

    setState(() {
      _isLoading = true;
    });

    Map<String, String>? uploadedDocs;

    try {
      String nicFrontUrl = _nicFrontImage != null
          ? await _cloudinaryService.uploadImage(_nicFrontImage!) ?? 'dummy_url'
          : 'dummy_url';

      String? certUrl;
      if (_selectedRole == 'emergency_responder') {
        certUrl = _certImage != null
            ? await _cloudinaryService.uploadImage(_certImage!) ?? 'dummy_url'
            : 'dummy_url';
      }

      String? nicBackUrl;
      if (_nicBackImage != null) {
        nicBackUrl = await _cloudinaryService.uploadImage(_nicBackImage!);
      } else {
        nicBackUrl = 'dummy_url';
      }

      uploadedDocs = {
        'nicFront': nicFrontUrl,
      };

      if (certUrl != null) {
        uploadedDocs['certificate'] = certUrl;
      }
      if (nicBackUrl != null) {
        uploadedDocs['nicBack'] = nicBackUrl;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document upload failed: $e')),
        );
      }
      return;
    }

    print('Signup attempt started for ${_emailController.text}');
    String? error = await _authService.signUp(
      email: _emailController.text.trim(),
      username: _usernameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      role: _selectedRole,
      responderType: _selectedCategory,
      documents: uploadedDocs,
    );
    print('Signup attempt finished with error: $error');

    setState(() {
      _isLoading = false;
    });

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } else {
      print('Signup successful. Popping screen.');
      if (mounted) {
        Navigator.pop(context); // Go back to login/main flow
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ResQ Sign Up')),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep == 0) {
              // TEMPORARY: form validation disabled for easy testing
              // if (_formKey.currentState!.validate()) {
              if (_passwordController.text != _confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              /*
                if (_selectedRole == 'emergency_responder' &&
                    _selectedCategory == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select a responder category')),
                  );
                  return;
                }
                */
              setState(() {
                _currentStep += 1;
              });
              // }
            } else if (_currentStep == 1) {
              _signup();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep -= 1;
              });
            } else {
              Navigator.pop(context);
            }
          },
          controlsBuilder: (BuildContext context, ControlsDetails details) {
            return Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: details.onStepContinue,
                            child: Text(_currentStep == 1
                                ? 'Complete Sign Up'
                                : 'Continue'),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Account Details'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a username' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter your email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration:
                        const InputDecoration(labelText: 'Phone Number'),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value!.isEmpty
                        ? 'Please enter your phone number'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter your password';
                      if (value.length < 6)
                        return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureConfirmPassword,
                    validator: (value) =>
                        value!.isEmpty ? 'Please confirm your password' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('User')),
                      DropdownMenuItem(
                          value: 'emergency_responder',
                          child: Text('Emergency Service')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                        if (_selectedRole != 'emergency_responder') {
                          _selectedCategory = null;
                        }
                      });
                    },
                  ),
                  if (_selectedRole == 'emergency_responder') ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                          labelText: 'Responder Category'),
                      items: responderCategories.map((String category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
            Step(
              title: const Text('Identity Verification'),
              isActive: _currentStep >= 1,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedRole == 'user'
                        ? 'Please upload your National ID, Driving License, or Passport to verify your account.'
                        : 'Please upload your Service ID and Professional Certificate to verify your responder status.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  if (_selectedRole == 'user') ...[
                    _buildImagePickerButton(
                        'ID/License/Passport Front (Required)',
                        _nicFrontImage,
                        () => _showPicker(context, 'nicFront')),
                    const SizedBox(height: 12),
                    _buildImagePickerButton(
                        'ID/License/Passport Back (Required)',
                        _nicBackImage,
                        () => _showPicker(context, 'nicBack')),
                  ] else ...[
                    _buildImagePickerButton('Work ID / Details (Required)',
                        _nicFrontImage, () => _showPicker(context, 'nicFront')),
                    const SizedBox(height: 12),
                    _buildImagePickerButton(
                        'Professional Certificate (Required)',
                        _certImage,
                        () => _showPicker(context, 'cert')),
                    const SizedBox(height: 12),
                    _buildImagePickerButton('Additional Docs (Optional)',
                        _nicBackImage, () => _showPicker(context, 'nicBack')),
                  ],
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton.icon(
                      onPressed: _skipVerification,
                      icon: const Icon(Icons.bug_report, color: Colors.orange),
                      label: const Text('Skip Verification (Dev Only)',
                          style: TextStyle(color: Colors.orange)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerButton(
      String label, File? image, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: image != null ? Colors.green.withOpacity(0.1) : Colors.white,
          border: Border.all(
              color: image != null ? Colors.green : Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(image != null ? Icons.check_circle : Icons.cloud_upload,
                color: image != null ? Colors.green : Colors.blue.shade700,
                size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                image != null ? 'Document Uploaded' : label,
                style: TextStyle(
                    color:
                        image != null ? Colors.green.shade700 : Colors.black87,
                    fontWeight:
                        image != null ? FontWeight.bold : FontWeight.w500,
                    fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
