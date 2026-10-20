import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/preview/dev_preview.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() { _isLoading = true; _error = null; });
    final isPreview = !kReleaseMode && ref.read(devPreviewProvider);
    if (isPreview) {
      setState(() {
        _conversations = DevMockData.mockConversations;
        _isLoading = false;
      });
      return;
    }

    try {
      final res = await ApiClient.instance.get('/chat/conversations');
      if (res.statusCode == 200 && res.data['success'] == true) {
        setState(() {
          _conversations = res.data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = res.data['error'] ?? 'Failed to load conversations';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Conversations'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadConversations, child: const Text('Retry')),
                    ],
                  ),
                )
              : _conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          const Text('No active conversations yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Text('Mutual sparks will appear here.', style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _conversations.length,
                      itemBuilder: (_, i) {
                        final c = _conversations[i];
                        final name = c['display_name'] ?? 'Connection';
                        final stage = c['stage'] ?? 1;
                        final lastMsg = c['last_message'] ?? 'Stage $stage connection';
                        final convId = c['id'] ?? c['conversation_id'];
                        final trustScore = (c['trust_score'] as num?)?.toDouble() ?? 80.0;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                            child: Text(name.isNotEmpty ? name[0] : '?'),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(lastMsg, style: TextStyle(fontSize: 12, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
                            child: Text('Stage $stage', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                          ),
                          onTap: () => context.push('/chat/$convId', extra: {'name': name, 'trust_score': trustScore}),
                        );
                      },
                    ),
    );
  }
}
