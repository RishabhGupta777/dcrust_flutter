import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../utils/programs_list.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _message;
  bool _isSuccess = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _linkedInController;
  
  late TextEditingController _yearFromController;
  late TextEditingController _yearToController;
  late TextEditingController _sectionController;
  late TextEditingController _rollNoController;
  
  String _selectedDegree = '';
  String _selectedBranch = '';
  
  List<String> _skills = [];
  final TextEditingController _skillController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _linkedInController = TextEditingController();
    _yearFromController = TextEditingController();
    _yearToController = TextEditingController();
    _sectionController = TextEditingController();
    _rollNoController = TextEditingController();
    
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _linkedInController.dispose();
    _yearFromController.dispose();
    _yearToController.dispose();
    _sectionController.dispose();
    _rollNoController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/auth/profile');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _linkedInController.text = data['linkedInProfile'] ?? '';
          
          final ed = data['educationDetails'] ?? {};
          _yearFromController.text = ed['yearFrom'] ?? '';
          _yearToController.text = ed['yearTo'] ?? '';
          _selectedDegree = ed['degree'] ?? '';
          _selectedBranch = ed['branch'] ?? '';
          _sectionController.text = ed['section'] ?? '';
          _rollNoController.text = ed['rollNo'] ?? '';
          
          _skills = List<String>.from(data['skills'] ?? []);
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Failed to load profile';
        _isSuccess = false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
      _message = null;
    });
    
    try {
      final payload = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'linkedInProfile': _linkedInController.text,
        'educationDetails': {
          'yearFrom': _yearFromController.text,
          'yearTo': _yearToController.text,
          'degree': _selectedDegree,
          'branch': _selectedBranch,
          'section': _sectionController.text,
          'rollNo': _rollNoController.text,
        },
        'skills': _skills,
      };

      final response = await ApiService.put('/auth/profile', body: payload);
      
      if (response.statusCode == 200) {
        setState(() {
          _message = 'Profile updated successfully!';
          _isSuccess = true;
        });
        // Update user in provider
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.checkAuthStatus();
        }
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _message = data['message'] ?? 'Failed to update profile';
          _isSuccess = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error updating profile';
        _isSuccess = false;
      });
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
      _saveProfile();
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
    _saveProfile();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        drawer: const AppDrawer(),
        body: const Center(child: Text('Please log in')),
      );
    }

    final isStudent = user.role == 'user';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account Settings')),
        drawer: const AppDrawer(),
        body: const Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Account Settings'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          children: [
            const Text('View your personal information and educational details all in one place.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            
            if (isStudent)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.blue.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your details are locked. Please contact the administrator for any changes.',
                        style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            if (_message != null)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isSuccess ? Colors.green.shade200 : Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: _isSuccess ? Colors.green.shade800 : Colors.red.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _message!,
                        style: TextStyle(color: _isSuccess ? Colors.green.shade800 : Colors.red.shade800, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Personal Info
                        Row(
                          children: [
                            CircleAvatar(backgroundColor: Colors.green.shade100, child: Icon(Icons.person, color: Colors.green.shade700)),
                            const SizedBox(width: 12),
                            const Text('Personal Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildTextField('Full Name', _nameController, Icons.person, disabled: isStudent),
                        const SizedBox(height: 16),
                        _buildTextField('Email Address', _emailController, Icons.email, disabled: isStudent),
                        const SizedBox(height: 16),
                        _buildTextField('Phone Number', _phoneController, Icons.phone, disabled: isStudent),
                        const SizedBox(height: 16),
                        _buildTextField('LinkedIn Profile', _linkedInController, Icons.link, disabled: isStudent),
                        
                        const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),
                        
                        // Education Details
                        Row(
                          children: [
                            CircleAvatar(backgroundColor: Colors.orange.shade100, child: Icon(Icons.school, color: Colors.orange.shade700)),
                            const SizedBox(width: 12),
                            const Text('Education Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Academic Year (From)', _yearFromController, Icons.menu_book, disabled: isStudent)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField('Academic Year (To)', _yearToController, Icons.menu_book, disabled: isStudent)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Degree Dropdown
                        const Text('Degree / Program Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isStudent ? Colors.grey.shade100 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedDegree.isNotEmpty && programsData.containsKey(_selectedDegree) ? _selectedDegree : null,
                              hint: const Text('Select Category'),
                              items: programsData.keys.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: isStudent ? null : (newValue) {
                                setState(() {
                                  _selectedDegree = newValue!;
                                  _selectedBranch = '';
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Branch Dropdown
                        const Text('Branch / Course', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isStudent || _selectedDegree.isEmpty ? Colors.grey.shade100 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedBranch.isNotEmpty ? _selectedBranch : null,
                              hint: const Text('Select Branch'),
                              items: _selectedDegree.isNotEmpty ? programsData[_selectedDegree]!.map((Program prog) {
                                return DropdownMenuItem<String>(
                                  value: prog.name,
                                  child: Text('${prog.code} - ${prog.name}', overflow: TextOverflow.ellipsis),
                                );
                              }).toList() : [],
                              onChanged: (isStudent || _selectedDegree.isEmpty) ? null : (newValue) {
                                setState(() {
                                  _selectedBranch = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Section', _sectionController, null, disabled: isStudent)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField('Roll Number', _rollNoController, Icons.numbers, disabled: isStudent)),
                          ],
                        ),
                        
                        const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),

                        // Skills
                        Row(
                          children: [
                            CircleAvatar(backgroundColor: Colors.indigo.shade100, child: Icon(Icons.star, color: Colors.indigo.shade700)),
                            const SizedBox(width: 12),
                            const Text('Skills', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _skillController,
                                decoration: InputDecoration(
                                  hintText: 'Add a skill (e.g. React)',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                ),
                                onSubmitted: (_) => _addSkill(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _addSkill,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade100,
                                foregroundColor: Colors.indigo.shade700,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _skills.isEmpty 
                          ? const Text('No skills added yet.', style: TextStyle(color: Colors.grey))
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _skills.map((skill) => Chip(
                                label: Text(skill, style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold)),
                                backgroundColor: Colors.indigo.shade50,
                                side: BorderSide(color: Colors.indigo.shade100),
                                deleteIcon: Icon(Icons.close, color: Colors.indigo.shade900, size: 16),
                                onDeleted: () => _removeSkill(skill),
                              )).toList(),
                            )
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveProfile,
                        icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Saving...' : 'Save Changes', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData? icon, {bool disabled = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: !disabled,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
            filled: true,
            fillColor: disabled ? Colors.grey.shade100 : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
        )
      ],
    );
  }
}
