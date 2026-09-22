import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../utils/programs_list.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _yearFromController = TextEditingController();
  final _yearToController = TextEditingController();
  final _sectionController = TextEditingController();
  final _rollNoController = TextEditingController();
  final _skillsController = TextEditingController();
  
  String _selectedDegree = '';
  String _selectedBranch = '';

  bool _showPassword = false;
  bool _isLoading = false;
  String _error = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _linkedInController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _yearFromController.dispose();
    _yearToController.dispose();
    _sectionController.dispose();
    _rollNoController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDegree.isEmpty || _selectedBranch.isEmpty) {
      setState(() { _error = 'Please select degree and branch'; });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() { _error = 'Passwords do not match'; });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final skills = _skillsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
        'linkedInProfile': _linkedInController.text.trim(),
        'educationDetails': {
          'yearFrom': _yearFromController.text.trim(),
          'yearTo': _yearToController.text.trim(),
          'degree': _selectedDegree,
          'branch': _selectedBranch,
          'section': _sectionController.text.trim(),
          'rollNo': _rollNoController.text.trim(),
        },
        'skills': skills,
      };

      await AuthService.register(userData);
      
      if (mounted) {
        // Registration successful, navigate to email verification
        context.push('/verify-email', extra: {'email': _emailController.text.trim()});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isPassword = false, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_showPassword,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ) : null,
        ),
        validator: required ? (value) {
          if (value == null || value.isEmpty) return 'This field is required';
          return null;
        } : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personal Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_nameController, 'Full Name')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(_phoneController, 'Mobile Number')),
                    ],
                  ),
                  _buildTextField(_emailController, 'Email Address'),
                  _buildTextField(_linkedInController, 'LinkedIn Profile Link'),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_passwordController, 'Password', isPassword: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(_confirmPasswordController, 'Confirm Password', isPassword: true)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  const Text('Education Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_yearFromController, 'Year (From)')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(_yearToController, 'Year (To)')),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedDegree.isNotEmpty ? _selectedDegree : null,
                              hint: const Text('Select Degree *'),
                              items: programsData.keys.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedDegree = newValue!;
                                  _selectedBranch = '';
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: _selectedDegree.isEmpty ? Colors.grey[200] : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedBranch.isNotEmpty ? _selectedBranch : null,
                              hint: const Text('Select Branch *'),
                              items: _selectedDegree.isNotEmpty ? programsData[_selectedDegree]!.map((Program prog) {
                                return DropdownMenuItem<String>(
                                  value: prog.name,
                                  child: Text('${prog.code} - ${prog.name}', overflow: TextOverflow.ellipsis),
                                );
                              }).toList() : [],
                              onChanged: _selectedDegree.isEmpty ? null : (newValue) {
                                setState(() {
                                  _selectedBranch = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_sectionController, 'Section')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(_rollNoController, 'Roll Number')),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  const Text('Skills (Optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildTextField(_skillsController, 'Skills (comma separated)', required: false),
                  
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(_error, style: const TextStyle(color: Colors.red)),
                  ],
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => context.push('/login'),
                      child: const Text('Already have an account? Sign In'),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
