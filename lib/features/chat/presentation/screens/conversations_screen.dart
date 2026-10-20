// lib/features/chat/presentation/screens/conversations_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/preview/dev_preview.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/mantra_badge.dart';
import '../../../../core/widgets/mantra_card.dart';
import '../../../../core/widgets/mantra_states.dart';

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
    setState(() {
      _isLoading = true;
      _error = null;
    });

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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Editorial Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MINDFUL DIALOGUE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Conversations',
                          style: GoogleFonts.lora(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Unfold connections with patience and depth',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Daily Quest Shortcut Pill
                  Tooltip(
                    message: 'Daily Quest',
                    child: InkWell(
                      onTap: () => context.push('/quest/daily'),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.psychology_outlined, size: 14, color: AppColors.primary),
                            const SizedBox(width: 5),
                            Text(
                              'Daily Quest',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
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

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _error != null
                      ? MantraErrorState(
                          message: _error!,
                          onRetry: _loadConversations,
                        )
                      : _conversations.isEmpty
                          ? MantraEmptyState(
                              icon: Icons.chat_bubble_outline_rounded,
                              title: 'No Active Conversations Yet',
                              message: 'When you connect with mutual sparks or mystery matches, your conversations will bloom here.',
                              actionLabel: 'Discover Today\'s Sparks',
                              onAction: () => context.go('/sparks'),
                            )
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                              itemCount: _conversations.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final c = _conversations[i];
                                final name = c['display_name'] ?? 'Connection';
                                final stage = (c['stage'] as num?)?.toInt() ?? 1;
                                final lastMsg = c['last_message'] ?? 'Stage $stage connection';
                                final convId = c['id'] ?? c['conversation_id'];
                                final trustScore = (c['trust_score'] as num?)?.toDouble() ?? 80.0;
                                final unreadCount = (c['unread_count'] as num?)?.toInt() ?? 0;

                                return _ConversationCard(
                                  name: name,
                                  stage: stage,
                                  lastMessage: lastMsg,
                                  trustScore: trustScore,
                                  unreadCount: unreadCount,
                                  onTap: () => context.push(
                                    '/chat/$convId',
                                    extra: {
                                      'name': name,
                                      'trust_score': trustScore,
                                      'stage': stage,
                                    },
                                  ),
                                ).animate(delay: Duration(milliseconds: i * 70))
                                    .fadeIn(duration: 300.ms)
                                    .slideY(begin: 0.05, end: 0);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final String name;
  final int stage;
  final String lastMessage;
  final double trustScore;
  final int unreadCount;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.name,
    required this.stage,
    required this.lastMessage,
    required this.trustScore,
    required this.unreadCount,
    required this.onTap,
  });

  String _getStageLabel(int stage) {
    switch (stage) {
      case 1:
        return 'Stage 1 • Mind';
      case 2:
        return 'Stage 2 • Voice';
      case 3:
        return 'Stage 3 • Bond';
      case 4:
        return 'Stage 4 • Unlocked';
      default:
        return 'Stage $stage';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MantraCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      hasShadow: unreadCount > 0,
      borderColor: unreadCount > 0 ? AppColors.primaryLight : AppColors.border,
      child: Row(
        children: [
          // Avatar with stage ring
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceVariant,
                  border: Border.all(
                    color: stage >= 3
                        ? AppColors.trust
                        : (stage >= 2 ? AppColors.primary : AppColors.border),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0] : '?',
                    style: GoogleFonts.lora(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
              if (stage >= 2)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: stage >= 3 ? AppColors.trust : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        stage >= 3 ? Icons.lock_open_rounded : Icons.mic_rounded,
                        size: 9,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Message & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: GoogleFonts.lora(
                                fontSize: 16,
                                fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          MantraBadge.trust(
                            score: trustScore,
                            fontSize: 10,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        _getStageLabel(stage),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lastMessage,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                          fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
