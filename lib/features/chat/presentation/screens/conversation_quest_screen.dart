// lib/features/chat/presentation/screens/conversation_quest_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../models/conversation_quest_model.dart';
import '../providers/quest_provider.dart';

class ConversationQuestScreen extends ConsumerStatefulWidget {
  final String connectionId;

  const ConversationQuestScreen({super.key, required this.connectionId});

  @override
  ConsumerState<ConversationQuestScreen> createState() => _ConversationQuestScreenState();
}

class _ConversationQuestScreenState extends ConsumerState<ConversationQuestScreen> {
  final _answerController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer(String questId) async {
    final text = _answerController.text.trim();
    if (text.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a thoughtful answer before submitting.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      HapticFeedback.mediumImpact();
      final res = await ref
          .read(connectionQuestFamily(widget.connectionId).notifier)
          .submitAnswer(questId, text);
      _answerController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Response submitted!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'values':
        return const Color(0xFFC4654A);
      case 'memories':
        return const Color(0xFF7A9E7E);
      case 'relationships':
        return const Color(0xFF5B8DB8);
      case 'aspirations':
        return const Color(0xFFD4884A);
      case 'humour':
        return const Color(0xFFE8A030);
      case 'everyday_life':
        return const Color(0xFF8B6BB1);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final questAsync = ref.watch(connectionQuestFamily(widget.connectionId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Conversation Quest', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: questAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text('Could not load today\'s quest'),
                  const SizedBox(height: 8),
                  Text(e.toString(), style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(connectionQuestFamily(widget.connectionId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (quest) {
            final catColor = _getCategoryColor(quest.category);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // Daily Quest Prompt Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          quest.category.toUpperCase().replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: catColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Main Prompt
                      Text(
                        quest.promptText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Mutual Participation State Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: quest.isUnlocked
                              ? AppColors.trust.withOpacity(0.1)
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              quest.isUnlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                              size: 14,
                              color: quest.isUnlocked ? AppColors.trust : AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              quest.isUnlocked
                                  ? 'Unlocked! Both answered ✨'
                                  : quest.hasUserAnswered
                                      ? 'Your answer recorded. Waiting for partner.'
                                      : 'Answer to unlock each other\'s responses',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: quest.isUnlocked ? AppColors.trust : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.04, end: 0),

                const SizedBox(height: 16),

                // My Answer Section
                if (quest.hasUserAnswered && quest.myAnswer != null) ...[
                  _AnswerCard(
                    title: 'Your Reflection',
                    answer: quest.myAnswer!,
                    isMe: true,
                  ),
                ] else ...[
                  // Input Box to Answer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Share your answer',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _answerController,
                          maxLines: 4,
                          maxLength: 1000,
                          decoration: InputDecoration(
                            hintText: 'Take your time. Reflect thoughtfully...',
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceVariant.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isSubmitting ? null : () => _submitAnswer(quest.id),
                          child: _isSubmitting
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Submit Reflection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Partner's Answer Section (Unlocked vs Locked)
                if (quest.isUnlocked && quest.partnerAnswer != null) ...[
                  _AnswerCard(
                    title: 'Their Reflection',
                    answer: quest.partnerAnswer!,
                    isMe: false,
                    onReact: (emoji) => ref
                        .read(connectionQuestFamily(widget.connectionId).notifier)
                        .react(quest.partnerAnswer!.id, emoji),
                  ),
                  const SizedBox(height: 16),

                  // Follow-Up Question Card
                  if (quest.followUpPrompt != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.trust.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.trust.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.explore_outlined, size: 16, color: AppColors.trust),
                              SizedBox(width: 6),
                              Text(
                                'Deeper Follow-Up',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.trust),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            quest.followUpPrompt!,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.35),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Feel free to explore this question in your private conversation.',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else if (quest.hasUserAnswered && !quest.isUnlocked) ...[
                  // Locked Partner Placeholder
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.lock_rounded, size: 32, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        const Text(
                          'Partner\'s Answer is Gated',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'To encourage mutual vulnerability, their response will be revealed once they also share theirs.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Non-compulsive slow dating notice
                Center(
                  child: Text(
                    'Participation in Conversation Quests is always optional.\nNo streaks. No rush. Just meaningful connection.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final String title;
  final QuestAnswerItem answer;
  final bool isMe;
  final ValueChanged<String>? onReact;

  const _AnswerCard({
    required this.title,
    required this.answer,
    required this.isMe,
    this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    final emojis = ['❤️', '💭', '✨', '🌱', '🙏'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              Text(
                answer.createdAt.isNotEmpty ? answer.createdAt.substring(0, 10) : '',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            answer.answerText,
            style: const TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w500),
          ),
          if (answer.reactions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: answer.reactions
                  .map((e) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 12)),
                      ))
                  .toList(),
            ),
          ],
          if (onReact != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Text('React: ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ...emojis.map((e) => GestureDetector(
                      onTap: () => onReact!(e),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(e, style: const TextStyle(fontSize: 18)),
                      ),
                    )),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
