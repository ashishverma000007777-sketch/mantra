import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/preview/dev_preview.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/mantra_card.dart';
import '../../../../core/widgets/mantra_states.dart';
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
  bool _isMember = true;
  final _postController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRoom();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
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
          'color': '#C66F55',
        };
        _posts = [
          {
            'id': 'dev-post-1',
            'content': 'Welcome to ${mock.name}! A quiet space to share reflections without algorithmic rush.',
            'author_name': 'Mantra Guide',
            'created_at': '2 hours ago',
            'likes_count': 12,
            'comments_count': 4,
          },
          {
            'id': 'dev-post-2',
            'content': 'What brought you to this room today? Feel free to share a brief thought or memory.',
            'author_name': 'Aanya',
            'created_at': '1 hour ago',
            'likes_count': 8,
            'comments_count': 2,
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
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddPostDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Share a Reflection',
                  style: GoogleFonts.lora(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _postController,
              maxLines: 4,
              maxLength: 500,
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Write a calm, thoughtful perspective...',
                hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
                onPressed: () {
                  final content = _postController.text.trim();
                  if (content.isEmpty) return;
                  HapticFeedback.lightImpact();
                  setState(() {
                    _posts.insert(0, {
                      'id': 'post-${DateTime.now().millisecondsSinceEpoch}',
                      'content': content,
                      'author_name': 'You',
                      'created_at': 'Just now',
                      'likes_count': 1,
                      'comments_count': 0,
                    });
                  });
                  _postController.clear();
                  Navigator.pop(ctx);
                },
                child: Text(
                  'Publish Reflection',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emoji = _room?['emoji'] ?? '🌿';
    final name = _room?['name'] ?? 'Community Room';
    final desc = _room?['description'] ?? 'A quiet space for mindful discussions.';
    final memberCount = _room?['member_count'] ?? 120;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _isMember = !_isMember);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_isMember ? 'Joined $name' : 'Left $name')),
                );
              },
              icon: Icon(
                _isMember ? Icons.check_circle_outline_rounded : Icons.add_circle_outline_rounded,
                size: 16,
              ),
              label: Text(_isMember ? 'Joined' : 'Join Room'),
              style: TextButton.styleFrom(
                foregroundColor: _isMember ? AppColors.trust : AppColors.primary,
                textStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPostDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: Text(
          'Reflect',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
              children: [
                // Room Header Card
                MantraCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.lora(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$memberCount members · Slow pace',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 12),

                // Description card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    desc,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Posts Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reflections & Discussions',
                      style: GoogleFonts.lora(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${_posts.length} shared',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_posts.isEmpty)
                  MantraEmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No reflections yet',
                    message: 'Be the first to share a thoughtful reflection in this community.',
                    actionLabel: 'Share Reflection',
                    onAction: _showAddPostDialog,
                  )
                else
                  ..._posts.map((p) => _PostCard(
                        post: p,
                        roomId: widget.roomId,
                        onLike: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            p['likes_count'] = (p['likes_count'] ?? 0) + 1;
                          });
                        },
                      )),
              ],
            ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final String roomId;
  final VoidCallback onLike;

  const _PostCard({
    required this.post,
    required this.roomId,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final postId = post['id'] ?? 'post-1';
    final author = post['author_name'] ?? 'Mantra Member';
    final content = post['content'] ?? '';
    final createdAt = post['created_at'] ?? '';
    final likesCount = post['likes_count'] ?? 0;
    final commentsCount = post['comments_count'] ?? 0;

    return MantraCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: () => context.push('/rooms/$roomId/post/$postId', extra: post),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Text(
                        author.isNotEmpty ? author[0] : '?',
                        style: GoogleFonts.lora(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    author,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                createdAt,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.lora(
              fontSize: 14.5,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: onLike,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_rounded, size: 15, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '$likesCount',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '$commentsCount reflections',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
