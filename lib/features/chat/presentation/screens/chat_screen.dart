import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../chat/data/models/message_model.dart';
import '../../../chat/providers/chat_provider.dart';
import '../widgets/gradual_reveal_view.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final Map<String, dynamic>? extra;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.extra,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _audioRecorder = AudioRecorder();
  bool _isRecordingVoice = false;
  bool _showSuggestion = true;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    ref.read(chatProvider(widget.conversationId).notifier).sendText(text);
    _textController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startVoiceRecord() async {
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) return;

    HapticFeedback.mediumImpact();
    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/voice_msg_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(const RecordConfig(), path: path);
    setState(() => _isRecordingVoice = true);
  }

  Future<void> _stopVoiceRecord() async {
    final path = await _audioRecorder.stop();
    setState(() => _isRecordingVoice = false);
    if (path != null) {
      HapticFeedback.lightImpact();
      ref
          .read(chatProvider(widget.conversationId).notifier)
          .sendVoice(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.conversationId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _ChatAppBar(
        conversationId: widget.conversationId,
        name: widget.extra?['name'] ?? 'Connection',
        trustScore: (widget.extra?['trust_score'] as num?)?.toDouble() ?? 75.0,
        stage: chatState.value?.stage ?? (widget.extra?['stage'] as num?)?.toInt() ?? 1,
        onBack: () => context.pop(),
        onMore: () => _showMoreOptions(context),
      ),
      body: Column(
        children: [
          // Stage indicator
          _StageIndicator(stage: chatState.value?.stage ?? (widget.extra?['stage'] as num?)?.toInt() ?? 1),

          // Feature 4: Gradual Identity Reveal Stepper & Consent
          GradualRevealView(connectionId: widget.conversationId),

          // AI suggestion banner
          if (_showSuggestion && chatState.value?.aiSuggestion != null)
            _AISuggestionBanner(
              suggestion: chatState.value!.aiSuggestion!,
              onDismiss: () => setState(() => _showSuggestion = false),
              onUse: () {
                _textController.text = chatState.value!.aiSuggestion!;
                setState(() => _showSuggestion = false);
              },
            ),

          // Messages
          Expanded(
            child: chatState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error loading messages: $e',
                  style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
                ),
              ),
              data: (state) {
                if (state == null) return const SizedBox();
                return ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: state.messages.length,
                  itemBuilder: (context, i) {
                    final msg = state.messages[i];
                    final showDate = i == 0 ||
                        !_isSameDay(
                          state.messages[i - 1].createdAt,
                          msg.createdAt,
                        );
                    return Column(
                      children: [
                        if (showDate) _DateDivider(date: msg.createdAt),
                        MessageBubble(message: msg),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Voice recording indicator
          if (_isRecordingVoice) _RecordingIndicator(),

          // Input bar
          _ChatInputBar(
            controller: _textController,
            isRecording: _isRecordingVoice,
            onSend: _sendText,
            onVoiceStart: _startVoiceRecord,
            onVoiceStop: _stopVoiceRecord,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? get extra => widget.extra;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ChatMoreOptions(
        onReport: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report submitted for safety review')),
          );
        },
        onBlock: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connection blocked')),
          );
        },
        onSafety: () {
          Navigator.pop(context);
          context.push('/safety');
        },
      ),
    );
  }
}

// ─── App Bar ───────────────────────────────────────────
class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String conversationId;
  final String name;
  final double trustScore;
  final int stage;
  final VoidCallback onBack;
  final VoidCallback onMore;

  const _ChatAppBar({
    required this.conversationId,
    required this.name,
    required this.trustScore,
    required this.stage,
    required this.onBack,
    required this.onMore,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.lora(
              fontSize: 16.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.shield_rounded, size: 11, color: AppColors.trust),
              const SizedBox(width: 3),
              Text(
                '${trustScore.toInt()} Trust · Stage $stage',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Conversation Quest Action
        IconButton(
          tooltip: 'Conversation Quest',
          onPressed: () => context.push('/quest/$conversationId'),
          icon: const Icon(Icons.psychology_outlined, color: AppColors.primary, size: 21),
        ),
        // Connection Garden Action
        IconButton(
          tooltip: 'Connection Garden',
          onPressed: () => context.push('/garden/$conversationId'),
          icon: const Icon(Icons.eco_outlined, color: AppColors.trust, size: 21),
        ),
        // Safety Center
        IconButton(
          tooltip: 'Safety',
          onPressed: () => context.push('/safety'),
          icon: const Icon(Icons.shield_outlined, color: AppColors.textSecondary, size: 20),
        ),
        IconButton(
          onPressed: onMore,
          icon: const Icon(Icons.more_vert_rounded, size: 20),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.border),
      ),
    );
  }
}

// ─── Stage Indicator ───────────────────────────────────
class _StageIndicator extends StatelessWidget {
  final int stage;
  const _StageIndicator({required this.stage});

  String get _label {
    switch (stage) {
      case 1:
        return 'Stage 1 — Breaking the ice 🌱';
      case 2:
        return 'Stage 2 — Getting to know each other 🌿';
      case 3:
        return 'Stage 3 — Building trust 🌸';
      case 4:
        return 'Stage 4 — Deep connection 🌳';
      case 5:
        return 'Stage 5 — Trusted ✨';
      default:
        return 'Stage $stage';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surfaceVariant.withOpacity(0.5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _label,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Stage progress dots
          Row(
            children: List.generate(5, (i) {
              return Container(
                margin: const EdgeInsets.only(left: 4),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < stage
                      ? AppColors.primary
                      : AppColors.border,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── AI Suggestion Banner ──────────────────────────────
class _AISuggestionBanner extends StatelessWidget {
  final String suggestion;
  final VoidCallback onDismiss;
  final VoidCallback onUse;

  const _AISuggestionBanner({
    required this.suggestion,
    required this.onDismiss,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              suggestion,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onUse,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.primary,
            ),
            child: Text(
              'Use',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }
}

// ─── Message Bubble ────────────────────────────────────
class MessageBubble extends StatelessWidget {
  final MessageModel message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: message.type == MessageType.voice
                  ? const EdgeInsets.all(10)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
                border: isMine ? null : Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: message.type == MessageType.voice
                  ? _VoiceMessageContent(
                      message: message,
                      isMine: isMine,
                    )
                  : _TextMessageContent(
                      message: message,
                      isMine: isMine,
                    ),
            ),
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TextMessageContent extends StatelessWidget {
  final MessageModel message;
  final bool isMine;

  const _TextMessageContent({
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          message.content,
          style: GoogleFonts.plusJakartaSans(
            color: isMine ? Colors.white : AppColors.textPrimary,
            fontSize: 14.5,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatTime(message.createdAt),
              style: GoogleFonts.plusJakartaSans(
                color: isMine
                    ? Colors.white.withOpacity(0.7)
                    : AppColors.textMuted,
                fontSize: 10,
              ),
            ),
            if (isMine) ...[
              const SizedBox(width: 4),
              Icon(
                message.isRead
                    ? Icons.done_all_rounded
                    : Icons.done_rounded,
                size: 12,
                color: message.isRead
                    ? AppColors.surfaceVariant
                    : Colors.white.withOpacity(0.7),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _VoiceMessageContent extends StatelessWidget {
  final MessageModel message;
  final bool isMine;

  const _VoiceMessageContent({
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isMine
                ? Colors.white.withOpacity(0.2)
                : AppColors.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            color: isMine ? Colors.white : AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(20, (i) {
                final heights = [
                  4.0, 8.0, 12.0, 6.0, 10.0, 14.0, 8.0,
                  12.0, 6.0, 10.0, 14.0, 8.0, 6.0, 12.0, 8.0, 10.0,
                  6.0, 14.0, 8.0, 4.0,
                ];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  width: 3,
                  height: heights[i],
                  decoration: BoxDecoration(
                    color: isMine
                        ? Colors.white.withOpacity(0.75)
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              '0:${message.voiceDuration?.toString().padLeft(2, '0') ?? '00'}',
              style: GoogleFonts.plusJakartaSans(
                color: isMine
                    ? Colors.white.withOpacity(0.75)
                    : AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Input Bar ─────────────────────────────────────────
class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isRecording;
  final VoidCallback onSend;
  final VoidCallback onVoiceStart;
  final VoidCallback onVoiceStop;
  final ValueChanged<String> onChanged;

  const _ChatInputBar({
    required this.controller,
    required this.isRecording,
    required this.onSend,
    required this.onVoiceStart,
    required this.onVoiceStop,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          // Input field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                maxLines: null,
                style: GoogleFonts.plusJakartaSans(fontSize: 14.5),
                decoration: InputDecoration(
                  hintText: 'Share a genuine reflection...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Send or Voice button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: hasText
                ? GestureDetector(
                    onTap: onSend,
                    key: const ValueKey('send'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  )
                : GestureDetector(
                    onLongPressStart: (_) => onVoiceStart(),
                    onLongPressEnd: (_) => onVoiceStop(),
                    key: const ValueKey('voice'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isRecording
                            ? AppColors.error
                            : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: isRecording
                            ? Colors.white
                            : AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecordingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.error.withOpacity(0.08),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeOut(duration: 600.ms),
          const SizedBox(width: 8),
          Text(
            'Recording voice message... release to send',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.error,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  String get _label {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            _label,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatMoreOptions extends StatelessWidget {
  final VoidCallback onReport;
  final VoidCallback onBlock;
  final VoidCallback onSafety;

  const _ChatMoreOptions({
    required this.onReport,
    required this.onBlock,
    required this.onSafety,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          _Option(
            icon: Icons.shield_rounded,
            label: 'Safety Center',
            color: AppColors.trust,
            onTap: onSafety,
          ),
          _Option(
            icon: Icons.flag_outlined,
            label: 'Report Connection',
            onTap: onReport,
          ),
          _Option(
            icon: Icons.block_rounded,
            label: 'Block Connection',
            color: AppColors.error,
            onTap: onBlock,
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _Option({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? AppColors.textPrimary, size: 22),
      title: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: color ?? AppColors.textPrimary,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
