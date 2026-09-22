import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  List<dynamic> _complaints = [];
  bool _isLoading = true;
  bool _showForm = false;
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isSubmitting = false;
  String _submitMessage = '';
  bool _isSuccessMessage = false;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchComplaints() async {
    setState(() { _isLoading = true; });
    try {
      final response = await ApiService.get('/complaints');
      if (response.statusCode == 200) {
        setState(() {
          _complaints = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching complaints: $e');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _submitComplaint() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    
    if (title.isEmpty || description.isEmpty) {
      setState(() {
        _submitMessage = 'Please fill out all fields.';
        _isSuccessMessage = false;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitMessage = '';
    });

    try {
      final response = await ApiService.post('/complaints', body: {
        'title': title,
        'description': description,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          _isSuccessMessage = true;
          _submitMessage = 'Your complaint/problem has been submitted successfully. It is currently pending admin approval before it appears here.';
          _titleController.clear();
          _descriptionController.clear();
        });
        
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() { _showForm = false; _submitMessage = ''; });
          }
        });
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _isSuccessMessage = false;
          _submitMessage = data['message'] ?? 'Failed to submit the complaint.';
        });
      }
    } catch (e) {
      setState(() {
        _isSuccessMessage = false;
        _submitMessage = 'Failed to submit the complaint.';
      });
    } finally {
      setState(() { _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Complaint / Problem Box'),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 28),
                              const SizedBox(width: 8),
                              const Text('Complaint / Problem Box', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('Raise issues anonymously. Problems require admin approval before they are displayed.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() { _showForm = !_showForm; _submitMessage = ''; });
                      },
                      icon: Icon(_showForm ? Icons.close : Icons.add, color: Colors.red[600]),
                      label: Text(_showForm ? 'Cancel' : 'Raise an Issue', style: TextStyle(color: Colors.red[600], fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red[200]!)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (_showForm)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Submit a New Complaint/Problem', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        
                        if (_submitMessage.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: _isSuccessMessage ? Colors.green[50] : Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _isSuccessMessage ? Colors.green[200]! : Colors.red[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(_isSuccessMessage ? Icons.check_circle : Icons.error, color: _isSuccessMessage ? Colors.green[700] : Colors.red[700]),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_submitMessage, style: TextStyle(color: _isSuccessMessage ? Colors.green[700] : Colors.red[700], fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                          
                        const Text('Title', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: 'Briefly summarize the issue',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red[400]!, width: 2)),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Provide detailed information about your complaint or problem...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red[400]!, width: 2)),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitComplaint,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Submit Anonymously', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Approved Problems & Complaints', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Text('${_complaints.length} Public Issues', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _complaints.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_circle_outline, size: 64, color: Colors.green[200]),
                                          const SizedBox(height: 16),
                                          const Text('No approved complaints to show at the moment.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.all(20),
                                      itemCount: _complaints.length,
                                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                                      itemBuilder: (context, index) {
                                        final complaint = _complaints[index];
                                        return Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey[200]!),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(child: Text(complaint['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: Colors.grey[200]!),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.access_time, size: 12, color: Colors.grey),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          complaint['createdAt'] != null 
                                                              ? DateTime.parse(complaint['createdAt']).toLocal().toString().split(' ')[0]
                                                              : '',
                                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Text(complaint['description'] ?? '', style: TextStyle(color: Colors.grey[700], height: 1.5)),
                                              const SizedBox(height: 16),
                                              const Divider(),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text('ANONYMOUS SUBMITTER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                              )
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
