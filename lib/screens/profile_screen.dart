import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:resq_flutter/services/theme_provider.dart';
import '../services/auth_service.dart';
import 'package:resq_flutter/screens/my_reports_screen.dart' as resq_my_reports;
import 'package:resq_flutter/screens/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  void _showEditMedicalProfile(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EditMedicalProfileSheet(data: data),
    );
  }

  void _showAddContactDialog(Map<String, dynamic> data) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Emergency Contact"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone Number"),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || phoneController.text.isEmpty) return;
              
              List<dynamic> contacts = List.from(data['emergencyContacts'] ?? []);
              contacts.add({
                'name': nameController.text,
                'phone': phoneController.text,
              });

              await _authService.updateUserProfile(data: {'emergencyContacts': contacts});
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _removeContact(Map<String, dynamic> data, int index) async {
    List<dynamic> contacts = List.from(data['emergencyContacts'] ?? []);
    contacts.removeAt(index);
    await _authService.updateUserProfile(data: {'emergencyContacts': contacts});
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(themeProvider.t('profile'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit3, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _authService.getUserStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text(themeProvider.t('not_set')));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          String username = data['username'] ?? 'User';
          String email = data['email'] ?? 'No email';
          String phone = data['phoneNumber'] ?? 'No phone number';
          String bloodGroup = data['bloodGroup'] ?? 'Not set';
          String uniqueId = data['uniqueId'] ?? 'N/A';
          List<dynamic> conditions = data['medicalConditions'] ?? [];
          List<dynamic> contacts = data['emergencyContacts'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Profile Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFFDC2626).withOpacity(0.1),
                        child: const Icon(LucideIcons.user, size: 40, color: Color(0xFFDC2626)),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(username,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A))),
                            const SizedBox(height: 4),
                            Text(email, style: const TextStyle(color: Color(0xFF64748B))),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(uniqueId,
                                  style: const TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Medical Profile Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Medical Profile",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    TextButton.icon(
                      onPressed: () => _showEditMedicalProfile(data),
                      icon: const Icon(LucideIcons.edit3, size: 16),
                      label: const Text("Edit"),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildMedicalInfoCard(
                  icon: LucideIcons.droplets,
                  label: "Blood Group",
                  value: bloodGroup,
                  color: Colors.red.shade500,
                ),
                const SizedBox(height: 12),
                _buildMedicalInfoCard(
                  icon: LucideIcons.activity,
                  label: "Chronic Conditions",
                  value: conditions.isEmpty ? "None reported" : conditions.join(", "),
                  color: Colors.orange.shade500,
                ),
                const SizedBox(height: 12),
                _buildMedicalInfoCard(
                  icon: LucideIcons.phone,
                  label: "Primary Phone",
                  value: phone,
                  color: Colors.blue.shade500,
                ),

                const SizedBox(height: 32),

                // Emergency Contacts
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Emergency Contacts",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    IconButton(
                      icon: const Icon(LucideIcons.plusCircle, color: Color(0xFFDC2626), size: 20),
                      onPressed: () => _showAddContactDialog(data),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (contacts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text("No emergency contacts added yet.",
                        style: TextStyle(color: Color(0xFF64748B))),
                  ),
                ...contacts.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.contact, color: Color(0xFF64748B)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c['name'] ?? 'No Name',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(c['phone'] ?? 'No Phone',
                                      style: const TextStyle(color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, color: Colors.grey, size: 18),
                              onPressed: () => _removeContact(data, contacts.indexOf(c)),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.phone, color: Colors.green, size: 20),
                              onPressed: () {}, // Link to call
                            ),
                          ],
                        ),
                      ),
                    )),

                const SizedBox(height: 40),

                // Other Actions
                _buildActionItem(LucideIcons.history, "My Emergency Reports", () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const resq_my_reports.MyReportsScreen()));
                }),
                _buildActionItem(LucideIcons.settings, themeProvider.t('settings'), () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                }),
                _buildActionItem(LucideIcons.logOut, themeProvider.t('logout'), () async {
                  await _authService.signOut();
                }, isDestructive: true),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMedicalInfoCard(
      {required IconData icon,
      required String label,
      required String value,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : const Color(0xFF334155)),
      title: Text(label,
          style: TextStyle(
              color: isDestructive ? Colors.red : const Color(0xFF334155),
              fontWeight: FontWeight.w500)),
      trailing: const Icon(LucideIcons.chevronRight, size: 16),
      onTap: onTap,
    );
  }
}

class EditMedicalProfileSheet extends StatefulWidget {
  final Map<String, dynamic> data;
  const EditMedicalProfileSheet({super.key, required this.data});

  @override
  State<EditMedicalProfileSheet> createState() => _EditMedicalProfileSheetState();
}

class _EditMedicalProfileSheetState extends State<EditMedicalProfileSheet> {
  final _phoneController = TextEditingController();
  final _conditionsController = TextEditingController();
  String? _selectedBloodGroup;
  bool _isLoading = false;

  final List<String> _bloodGroups = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.data['phoneNumber'] ?? '';
    _selectedBloodGroup = widget.data['bloodGroup'];
    List<dynamic> conditions = widget.data['medicalConditions'] ?? [];
    _conditionsController.text = conditions.join(", ");
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Edit Medical Profile",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text("Contact Number", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              hintText: "Enter real phone number",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(LucideIcons.phone, size: 18),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          const Text("Blood Group", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedBloodGroup,
            items: _bloodGroups
                .map((group) => DropdownMenuItem(value: group, child: Text(group)))
                .toList(),
            onChanged: (val) => setState(() => _selectedBloodGroup = val),
            decoration:
                InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 20),
          const Text("Chronic Conditions (Comma separated)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _conditionsController,
            decoration: InputDecoration(
              hintText: "e.g. Diabetes, Asthma",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    final List<String> conditionsList = _conditionsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final error = await AuthService().updateUserProfile(data: {
      'phoneNumber': _phoneController.text,
      'bloodGroup': _selectedBloodGroup,
      'medicalConditions': conditionsList,
    });

    if (mounted) {
      setState(() => _isLoading = false);
      if (error == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Profile updated successfully!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $error")));
      }
    }
  }
}
