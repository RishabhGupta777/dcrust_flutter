import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _tabs = [
    const _AdminEventsTab(),
    const _AdminUsersTab(),
    const _AdminComplaintsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null || (user.role != 'admin' && user.role != 'superadmin')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.indigo[600],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.report_problem), label: 'Complaints'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// EVENTS TAB
// -----------------------------------------------------------------------------
class _AdminEventsTab extends StatefulWidget {
  const _AdminEventsTab();

  @override
  State<_AdminEventsTab> createState() => _AdminEventsTabState();
}

class _AdminEventsTabState extends State<_AdminEventsTab> {
  List<dynamic> _events = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _dateController = TextEditingController();
  final _locationController = TextEditingController();
  final _linkController = TextEditingController();
  String _imageUrl = ''; // In a real app, use image picker and upload. For now, we'll accept a URL string.

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/events');
      if (res.statusCode == 200) {
        setState(() => _events = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('Error fetching events: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDeleteEvent(String id) async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.delete('/events/$id');
      _fetchEvents();
    } catch (e) {
      debugPrint('Error deleting event: $e');
    }
  }

  Future<void> _handleSubmit() async {
    if (_titleController.text.isEmpty || _imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and Image URL are required')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ApiService.post('/events', body: {
        'title': _titleController.text,
        'description': _descController.text,
        'imageUrl': _imageUrl,
        'date': _dateController.text,
        'location': _locationController.text,
        'registrationLink': _linkController.text,
      });
      _titleController.clear();
      _descController.clear();
      _dateController.clear();
      _locationController.clear();
      _linkController.clear();
      setState(() => _imageUrl = '');
      _fetchEvents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Create New Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title *')),
                  const SizedBox(height: 8),
                  TextField(controller: _dateController, decoration: const InputDecoration(labelText: 'Date (e.g. 2024-12-01)')),
                  const SizedBox(height: 8),
                  TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location')),
                  const SizedBox(height: 8),
                  TextField(controller: _linkController, decoration: const InputDecoration(labelText: 'Registration Link')),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (v) => setState(() => _imageUrl = v),
                    decoration: const InputDecoration(labelText: 'Image URL *', hintText: 'https://...'),
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: _descController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                      child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Publish Event', style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Current Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_isLoading) const Center(child: CircularProgressIndicator())
          else if (_events.isEmpty) const Text('No events found.')
          else ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _events.length,
            itemBuilder: (context, index) {
              final ev = _events[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: ev['imageUrl'] != null ? Image.network(ev['imageUrl'], width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image)) : const Icon(Icons.event),
                  title: Text(ev['title'] ?? ''),
                  subtitle: Text(ev['date'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _handleDeleteEvent(ev['_id']),
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// USERS TAB
// -----------------------------------------------------------------------------
class _AdminUsersTab extends StatefulWidget {
  const _AdminUsersTab();

  @override
  State<_AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<_AdminUsersTab> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/auth/users');
      if (res.statusCode == 200) {
        setState(() => _users = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveUser(String id) async {
    try {
      await ApiService.put('/auth/admin/users/$id/approve', body: {});
      _fetchUsers();
    } catch (e) {
      debugPrint('Error approving user: $e');
    }
  }

  Future<void> _deleteUser(String id) async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete User?'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.delete('/auth/users/$id');
      _fetchUsers();
    } catch (e) {
      debugPrint('Error deleting user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final u = _users[index];
        final isApproved = u['role'] == 'admin' || u['role'] == 'superadmin' || u['isApprovedByAdmin'] == true;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(u['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${u['email']}\nRole: ${u['role']}', style: const TextStyle(fontSize: 12)),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isApproved)
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _approveUser(u['_id']),
                    tooltip: 'Approve User',
                  ),
                if (u['role'] != 'superadmin')
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteUser(u['_id']),
                    tooltip: 'Delete User',
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// COMPLAINTS TAB
// -----------------------------------------------------------------------------
class _AdminComplaintsTab extends StatefulWidget {
  const _AdminComplaintsTab();

  @override
  State<_AdminComplaintsTab> createState() => _AdminComplaintsTabState();
}

class _AdminComplaintsTabState extends State<_AdminComplaintsTab> {
  List<dynamic> _complaints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/complaints/admin');
      if (res.statusCode == 200) {
        setState(() => _complaints = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('Error fetching admin complaints: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveComplaint(String id) async {
    try {
      await ApiService.put('/complaints/admin/$id/approve', body: {});
      _fetchComplaints();
    } catch (e) {
      debugPrint('Error approving complaint: $e');
    }
  }

  Future<void> _deleteComplaint(String id) async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Complaint?'),
        content: const Text('Are you sure you want to delete this complaint?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.delete('/complaints/admin/$id');
      _fetchComplaints();
    } catch (e) {
      debugPrint('Error deleting complaint: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_complaints.isEmpty) return const Center(child: Text('No complaints found.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _complaints.length,
      itemBuilder: (context, index) {
        final c = _complaints[index];
        final isApproved = c['status'] == 'approved';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(c['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isApproved ? Colors.green[100] : Colors.yellow[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isApproved ? 'Approved' : 'Pending',
                        style: TextStyle(color: isApproved ? Colors.green[800] : Colors.yellow[800], fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(c['description'] ?? '', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isApproved)
                      TextButton.icon(
                        icon: const Icon(Icons.check, color: Colors.green),
                        label: const Text('Approve', style: TextStyle(color: Colors.green)),
                        onPressed: () => _approveComplaint(c['_id']),
                      ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                      onPressed: () => _deleteComplaint(c['_id']),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
