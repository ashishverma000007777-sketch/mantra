// lib/features/chat/presentation/screens/conversation_quest_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_card.dart';
import '../../../../core/widgets/mantra_states.dart';
import '../../data/models/conversation_quest_model.dart';
import '../../providers/quest_provider.dart';

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
        const SnackBar(content: Text('Please write a thoughtful reflection before submitting.')),
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
        SnackBar(content: Text(res['message'] ?? 'Reflection shared ✨')),
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
    switch (category.toLowerCase()) {
      case 'values':
      case 'values & reflections':
        return AppColors.accent;
      case 'memories':
      case 'shared memories':
        return AppColors.trust;
      case 'relationships':
        return const Color(0xFF86A5C4);
      case 'aspirations':
        return const Color(0xFFD4B07A);
      default:
        return AppColors.accent;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conversation Quest',
              style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'A mindful prompt for mutual vulnerability',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: questAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
          error: (e, _) => MantraErrorState(
            message: 'Could not load today\'s quest.\n${e.toString()}',
            onRetry: () => ref.refresh(connectionQuestFamily(widget.connectionId)),
          ),
          data: (quest) {
            final catColor = _getCategoryColor(quest.category);

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                // Daily Quest Prompt Card
                MantraCard(
                  padding: const EdgeInsets.all(20),
                  hasShadow: true,
                  borderColor: AppColors.accent.withOpacity(0.35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          border: Border.all(color: catColor.withOpacity(0.4), width: 0.8),
                        ),
                        child: Text(
                          quest.category.toUpperCase().replaceAll('_', ' '),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: catColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Main Prompt
                      Text(
                        quest.promptText,
                        style: GoogleFonts.lora(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Mutual Participation State Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: quest.isUnlocked
                              ? AppColors.trust.withOpacity(0.15)
                              : AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                          border: Border.all(
                            color: quest.isUnlocked ? AppColors.trust : AppColors.border,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              quest.isUnlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                              size: 14,
                              color: quest.isUnlocked ? AppColors.trust : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                quest.isUnlocked
                                    ? 'Unlocked! Both answers revealed ✨'
                                    : quest.hasUserAnswered
                                        ? 'Your reflection recorded. Waiting for partner.'
                                        : 'Answer to mutually reveal reflections',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: quest.isUnlocked ? AppColors.trust : AppColors.textSecondary,
                                ),
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
                  MantraCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Share your reflection',
                          style: GoogleFonts.lora(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _answerController,
                          maxLines: 4,
                          maxLength: 1000,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Take your time. Speak from the heart...',
                            hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 13.5),
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
                              borderSide: const BorderSide(color: AppColors.accent),
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE5C896), Color(0xFFC79E5E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
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
                            onPressed: _isSubmitting ? null : () => _submitAnswer(quest.id),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF080B0D)),
                                  )
                                : Text(
                                    'Submit Reflection',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF080B0D),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                    ),
                                  ),
                          ),
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
                    MantraCard(
                      padding: const EdgeInsets.all(16),
                      color: AppColors.surfaceSecondary,
                      borderColor: AppColors.trust.withOpacity(0.3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.spa_outlined, size: 16, color: AppColors.trust),
                              const SizedBox(width: 6),
                              Text(
                                'DEEPER REFLECTION',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  letterSpacing: 0.8,
                                  color: AppColors.trust,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            quest.followUpPrompt!,
                            style: GoogleFonts.lora(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Feel free to explore this question together in your private chat.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else if (quest.hasUserAnswered && !quest.isUnlocked) ...[
                  // Locked Partner Placeholder
                  MantraCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.lock_rounded, size: 24, color: AppColors.accent),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Partner\'s Answer is Gated',
                          style: GoogleFonts.lora(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'To encourage mutual vulnerability, their reflection will be revealed once they also share theirs.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Non-compulsive slow dating notice
                Center(
                  child: Text(
                    'Participation in Conversation Quests is always optional.\nNo streaks. No rush. Just genuine connection.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                      height: 1.45,
                    ),
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
    final emojis = ['🌿', '🤍', '✨', '💭', '🙏'];

    return MantraCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.lora(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                answer.createdAt.isNotEmpty ? answer.createdAt.substring(0, 10) : '',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${answer.answerText}"',
            style: GoogleFonts.lora(
              fontSize: 14.5,
              height: 1.5,
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary,
            ),
          ),
          if (answer.reactions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: answer.reactions
                  .map((e) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 12)),
                      ))
                  .toList(),
            ),
          ],
          if (onReact != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'React: ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ...emojis.map((e) => GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onReact!(e);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
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
