import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';

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
                          Text(p['author_name'] ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(p['content'] ?? ''),
                        ],
                      ),
                    ),
                  )),
              ],
            ),
    );
  }
}
