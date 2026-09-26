import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/programs_list.dart';
import '../utils/academic_year.dart';

class AlumniDirectoryScreen extends StatefulWidget {
  const AlumniDirectoryScreen({super.key});

  @override
  State<AlumniDirectoryScreen> createState() => _AlumniDirectoryScreenState();
}

class _AlumniDirectoryScreenState extends State<AlumniDirectoryScreen> {
  List<UserModel> _directoryUsers = [];
  bool _isLoading = false;

  String _filterDegree = '';
  String _filterBranch = '';
  String _filterYear = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        _fetchDirectory();
      }
    });
  }

  Future<void> _fetchDirectory() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/auth/directory');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _directoryUsers = data.map((json) => UserModel.fromJson(json)).toList();
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch directory: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        final edu = user.educationDetails ?? {};
        final yearLabel = getAcademicYearLabel(edu['yearFrom'], edu['yearTo']);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade600, Colors.purple.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            if (yearLabel != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  yearLabel,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              )
                            ]
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    shrinkWrap: true,
                    children: [
                      const Text('EDUCATION', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Text('${edu['degree'] ?? 'N/A'} - ${edu['branch'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Batch: ${edu['yearFrom'] ?? 'N/A'} - ${edu['yearTo'] ?? 'N/A'}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 24),
                      const Text('SKILLS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      if (user.skills.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: user.skills.map((s) => Chip(
                            label: Text(s, style: TextStyle(color: Colors.indigo.shade700, fontSize: 12)),
                            backgroundColor: Colors.indigo.shade50,
                            side: BorderSide(color: Colors.indigo.shade100),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          )).toList(),
                        )
                      else
                        const Text('No skills added yet.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.email, color: Colors.grey),
                        title: Text(user.email),
                        onTap: () => launchUrl(Uri.parse('mailto:${user.email}')),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        tileColor: Colors.grey.shade50,
                      ),
                      if (user.linkedInProfile.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.link, color: Colors.blue),
                          title: const Text('LinkedIn Profile', style: TextStyle(color: Colors.blue)),
                          onTap: () => launchUrl(Uri.parse(user.linkedInProfile)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          tileColor: Colors.blue.shade50,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          if (auth.user != null && auth.user!.id != user.id) {
                            return ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                context.push('/chat', extra: {'startChatWith': user.id});
                              },
                              icon: const Icon(Icons.message),
                              label: Text('Message ${user.name.split(' ')[0]}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAuthenticated = authProvider.isAuthenticated;

    List<UserModel> filteredUsers = _directoryUsers.where((u) {
      final edu = u.educationDetails ?? {};
      if (_filterDegree.isNotEmpty && edu['degree'] != _filterDegree) return false;
      if (_filterBranch.isNotEmpty && edu['branch'] != _filterBranch) return false;
      if (_filterYear.isNotEmpty) {
        final String yearTo = edu['yearTo']?.toString() ?? '';
        if (!yearTo.contains(_filterYear)) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Alumni Directory', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: !isAuthenticated 
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎓', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    const Text('Login to Search the Alumni Directory', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    const Text('The DCRUST alumni directory lets students find and connect with graduates by degree, branch, and passing year. Please login to your DCRUST Portal account to search.', style: TextStyle(color: Colors.grey, fontSize: 16), textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => context.push('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Login to Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SEARCH FILTERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _filterDegree.isEmpty ? null : _filterDegree,
                          decoration: InputDecoration(
                            hintText: 'All Degrees / Categories',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          ),
                          items: [
                            const DropdownMenuItem(value: '', child: Text('All Degrees / Categories')),
                            ...programsData.keys.map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          ],
                          onChanged: (val) {
                            setState(() {
                              _filterDegree = val ?? '';
                              _filterBranch = '';
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _filterBranch.isEmpty ? null : _filterBranch,
                          decoration: InputDecoration(
                            hintText: 'All Branches',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          ),
                          items: [
                            const DropdownMenuItem(value: '', child: Text('All Branches')),
                            if (_filterDegree.isNotEmpty && programsData.containsKey(_filterDegree))
                              ...programsData[_filterDegree]!.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name)))
                          ],
                          onChanged: _filterDegree.isEmpty ? null : (val) {
                            setState(() {
                              _filterBranch = val ?? '';
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Passing Year (Required, e.g. 2024)',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          ),
                          onChanged: (val) => setState(() => _filterYear = val),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_filterYear.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(48),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Column(
                        children: [
                          Text('🎓', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 16),
                          Text('Find Your Seniors', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Please enter a passing year (and optional program details) to search for alumni.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  else if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (filteredUsers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No alumni found for the selected passing year.', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final u = filteredUsers[index];
                        final edu = u.educationDetails ?? {};
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.indigo.shade50,
                                      child: Text(
                                        u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                                        style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold, fontSize: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          Text(u.email, style: TextStyle(color: Colors.indigo.shade600, fontSize: 14)),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text('Course: ${edu['degree'] ?? 'N/A'} - ${edu['branch'] ?? 'N/A'}', style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('Batch: ${edu['yearFrom'] ?? 'N/A'} - ${edu['yearTo'] ?? 'N/A'}', style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    if (u.linkedInProfile.isNotEmpty)
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => launchUrl(Uri.parse(u.linkedInProfile)),
                                          icon: const Icon(Icons.link, size: 18),
                                          label: const Text('LinkedIn'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.blue,
                                            side: BorderSide(color: Colors.blue.shade100),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                      ),
                                    if (u.linkedInProfile.isNotEmpty) const SizedBox(width: 8),
                                    if (authProvider.user != null && authProvider.user!.id != u.id)
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => context.push('/chat', extra: {'startChatWith': u.id}),
                                          icon: const Icon(Icons.message, size: 18),
                                          label: const Text('Message'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.indigo,
                                            side: BorderSide(color: Colors.indigo.shade100),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => _showUserDetails(u),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black87,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      }
                    )
                ],
              ),
            ),
    );
  }
}
