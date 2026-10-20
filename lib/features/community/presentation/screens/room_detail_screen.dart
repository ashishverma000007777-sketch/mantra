import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/preview/dev_preview.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/room_model.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  Map<String, dynamic>? _room;
  List<dynamic> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRoom();
  }

  Future<void> _fetchRoom() async {
    final isPreview = !kReleaseMode && ref.read(devPreviewProvider);
    if (isPreview) {
      final mock = RoomModel.mockRooms().firstWhere(
        (r) => r.id == widget.roomId,
        orElse: () => RoomModel.mockRooms().first,
      );
      setState(() {
        _room = {
          'id': mock.id,
          'name': mock.name,
          'description': mock.description,
          'emoji': mock.emoji,
          'member_count': mock.memberCount,
          'color': '#8B5E3C',
        };
        _posts = [
          {
            'id': 'dev-post-1',
            'content': 'Welcome to ${mock.name}! A quiet space to share reflections without algorithmic rush.',
            'author_name': 'Mantra Guide',
            'created_at': '2 hours ago',
            'likes_count': 12,
          },
          {
            'id': 'dev-post-2',
            'content': 'What brought you to this room today? Feel free to introduce your cadence.',
            'author_name': 'Aanya',
            'created_at': '1 hour ago',
            'likes_count': 8,
          },
        ];
        _isLoading = false;
      });
      return;
    }

    try {
      final res = await ApiClient.instance.get('/rooms/${widget.roomId}');
      if (res.statusCode == 200 && res.data['success'] == true) {
        setState(() {
          _room = res.data['data']?['room'];
          _posts = res.data['data']?['posts'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_room?['name'] ?? 'Room Details'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_room != null) ...[
                  Text(_room!['description'] ?? '', style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 16),
                  Text('Posts (${_posts.length})', style: Theme.of(context).textTheme.titleMedium),
                  const Divider(),
                ],
                if (_posts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('No posts in this room yet.')),
                  )
                else
                  ..._posts.map((p) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(p['author_name'] ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(p['created_at'] ?? '', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(p['content'] ?? ''),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.favorite_border_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text('${p['likes_count'] ?? 0}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
              ],
            ),
    );
  }
}
