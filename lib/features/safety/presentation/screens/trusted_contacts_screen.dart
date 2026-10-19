import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/mantra_button.dart';
import '../../../../core/network/api_client.dart';

class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({super.key});

  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  List<dynamic> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final res = await ApiClient.instance.get('/safety/trusted-contacts');
      if (res.statusCode == 200 && res.data['success'] == true) {
        setState(() {
          _contacts = res.data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addContact() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) return;

    try {
      final res = await ApiClient.instance.post('/safety/trusted-contacts', data: {
        'name': name,
        'phone': phone,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        _nameController.clear();
        _phoneController.clear();
        _loadContacts();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add contact: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Trusted Contacts'), backgroundColor: Colors.transparent),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add up to 3 contacts who will receive emergency alerts when you trigger SOS.', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Phone'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 32),
                        onPressed: _contacts.length < 3 ? _addContact : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Saved Contacts (${_contacts.length}/3)', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _contacts.isEmpty
                        ? const Center(child: Text('No trusted contacts added yet.'))
                        : ListView.builder(
                            itemCount: _contacts.length,
                            itemBuilder: (_, i) {
                              final c = _contacts[i];
                              return ListTile(
                                leading: const Icon(Icons.person, color: AppColors.trust),
                                title: Text(c['name'] ?? ''),
                                subtitle: Text(c['phone'] ?? ''),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
