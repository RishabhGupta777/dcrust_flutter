import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class PapersScreen extends StatefulWidget {
  const PapersScreen({super.key});

  @override
  State<PapersScreen> createState() => _PapersScreenState();
}

class _PapersScreenState extends State<PapersScreen> {
  String? _selectedYear;
  final TextEditingController _subjectCodeController = TextEditingController();
  
  bool _isLoading = false;
  String? _error;
  String? _pdfUrl;

  final List<String> _years = [
    "may2018", "dec2018", "may2019", "dec2019",
    "june2022", "jan2023", "june2023", "dec2023",
    "june2024", "dec2024"
  ];

  final List<Map<String, String>> _faqs = [
    {
      'question': 'Which exam sessions are available on DCRUST Portal?',
      'answer': 'Previous year question papers are available for May 2018, December 2018, May 2019, December 2019, June 2022, January 2023, June 2023, December 2023, June 2024, and December 2024 sessions.',
    },
    {
      'question': 'How do I find my DCRUST subject code?',
      'answer': 'Start typing your subject name or code (e.g. "CE484C") in the search box.',
    },
    {
      'question': 'What if my paper is not found?',
      'answer': 'Not every subject and session has been uploaded yet. If a paper is missing, try a different session or check back later as the archive is updated regularly.',
    },
  ];

  Future<void> _handleSearch() async {
    final subjectCode = _subjectCodeController.text.trim();
    if (_selectedYear == null) {
      setState(() => _error = 'Please select Session & Year');
      return;
    }
    if (subjectCode.isEmpty) {
      setState(() => _error = 'Enter subject code');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _pdfUrl = null;
    });

    try {
      final response = await ApiService.get('/papers/check?year=$_selectedYear&subject=$subjectCode');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['found'] == true && data['url'] != null) {
          setState(() {
            _pdfUrl = data['url'];
          });
        }
      } else {
        final data = jsonDecode(response.body);
        setState(() => _error = data['message'] ?? 'Not found');
      }
    } catch (e) {
      setState(() => _error = 'Network Error: Check your connection');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _subjectCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAuthenticated = authProvider.isAuthenticated;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('DCRUST Papers', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    const Text('📚', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    const Text('Login to Search Exam Papers', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    const Text('Please login to your DCRUST Portal account to search and download previous year question papers.', style: TextStyle(color: Colors.grey, fontSize: 16), textAlign: TextAlign.center),
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
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade100),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700),
                                const SizedBox(width: 12),
                                Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500))),
                              ],
                            ),
                          ),
                        const Text('Select Session & Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedYear,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                          ),
                          hint: const Text('Select Session & Year'),
                          items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                          onChanged: (val) => setState(() => _selectedYear = val),
                        ),
                        const SizedBox(height: 20),
                        const Text('Subject Code or Name (like CE484C)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _subjectCodeController,
                          decoration: InputDecoration(
                            hintText: 'Subject Code or Name...',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _handleSearch,
                            icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search),
                            label: Text(_isLoading ? 'Searching...' : 'Search'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_pdfUrl != null)
                    InkWell(
                      onTap: () => launchUrl(Uri.parse(_pdfUrl!)),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.indigo.shade100),
                          boxShadow: [
                            BoxShadow(color: Colors.indigo.shade50, blurRadius: 10, offset: const Offset(0, 4))
                          ]
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16)),
                              child: Icon(Icons.picture_as_pdf, color: Colors.red.shade500, size: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_subjectCodeController.text.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                                    child: Text(_selectedYear ?? '', style: TextStyle(color: Colors.indigo.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                            ),
                            Icon(Icons.open_in_new, color: Colors.indigo.shade300)
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 48),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Frequently Asked Questions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  ..._faqs.map((faq) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(faq['question']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(faq['answer']!, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
