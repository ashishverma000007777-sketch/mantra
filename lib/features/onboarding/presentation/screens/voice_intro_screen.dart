import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import 'package:path_provider/path_provider.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_scaffold.dart';
import '../../../../core/widgets/mantra_button.dart';
import '../../../../core/widgets/mantra_card.dart';
import '../widgets/step_bar.dart';

enum VoiceRecordState { idle, recording, recorded, playing }

class VoiceIntroScreen extends ConsumerStatefulWidget {
  const VoiceIntroScreen({super.key});

  @override
  ConsumerState<VoiceIntroScreen> createState() => _VoiceIntroScreenState();
}

class _VoiceIntroScreenState extends ConsumerState<VoiceIntroScreen>
    with SingleTickerProviderStateMixin {
  final _audioRecorder = AudioRecorder();
  final _player = AudioPlayer();
  late RecorderController _recorderController;
  late PlayerController _playerController;

  VoiceRecordState _state = VoiceRecordState.idle;
  String? _recordedPath;
  int _recordingSeconds = 0;
  final int _maxSeconds = 45;
  final int _minSeconds = 10;

  @override
  void initState() {
    super.initState();
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
    _playerController = PlayerController();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _player.dispose();
    _recorderController.dispose();
    _playerController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final micPerm = await Permission.microphone.request();
    if (!micPerm.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is needed to record a voice intro')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final dir = await getApplicationDocumentsDirectory();
    _recordedPath = '${dir.path}/voice_intro_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorderController.record(path: _recordedPath!);
    setState(() {
      _state = VoiceRecordState.recording;
      _recordingSeconds = 0;
    });

    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_state != VoiceRecordState.recording) return false;
      setState(() => _recordingSeconds++);
      if (_recordingSeconds >= _maxSeconds) {
        _stopRecording();
        return false;
      }
      return true;
    });
  }

  Future<void> _stopRecording() async {
    if (_recordingSeconds < _minSeconds) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please record at least $_minSeconds seconds for your matches to hear you.'),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    await _recorderController.stop();
    await _playerController.preparePlayer(
      path: _recordedPath!,
      shouldExtractWaveform: true,
    );
    setState(() => _state = VoiceRecordState.recorded);
  }

  Future<void> _playPreview() async {
    if (_playerController.playerState == PlayerState.playing) {
      await _playerController.pausePlayer();
      setState(() => _state = VoiceRecordState.recorded);
    } else {
      await _playerController.startPlayer();
      setState(() => _state = VoiceRecordState.playing);
      _playerController.onCompletion.listen((_) {
        if (mounted) setState(() => _state = VoiceRecordState.recorded);
      });
    }
  }

  Future<void> _deleteRecording() async {
    await _playerController.stopPlayer();
    if (_recordedPath != null) {
      final file = File(_recordedPath!);
      if (await file.exists()) await file.delete();
    }
    setState(() {
      _state = VoiceRecordState.idle;
      _recordedPath = null;
      _recordingSeconds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MantraScaffold(
      showAmbientGlow: true,
      glowAlignment: Alignment.topCenter,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push('/onboarding/photos'),
            child: Text(
              'Skip for now',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepBar(current: 4, total: 6),
              const SizedBox(height: 24),

              Text(
                'Your voice,\nyour true presence.',
                style: GoogleFonts.lora(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.25,
                  letterSpacing: -0.3,
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 8),

              Text(
                'In slow dating, tone, cadence, and warmth speak louder than still photos.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ).animate(delay: 100.ms).fadeIn(),

              const SizedBox(height: 24),

              // Editorial prompt card
              MantraCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'PROMPT SUGGESTION',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '"Tell us three things: one belief that grounds you, one curiosity that keeps you up, and one small joy in your week."',
                      style: GoogleFonts.lora(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 150.ms).fadeIn(),

              const SizedBox(height: 32),

              // Audio Waveform / Recording status area
              Center(
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: _state == VoiceRecordState.recording
                        ? AudioWaveforms(
                            size: Size(MediaQuery.of(context).size.width - 80, 70),
                            recorderController: _recorderController,
                            waveStyle: const WaveStyle(
                              waveColor: AppColors.primary,
                              showDurationLabel: false,
                              spacing: 7.0,
                              showBottom: true,
                              extendWaveform: true,
                              showMiddleLine: false,
                            ),
                          )
                        : _state == VoiceRecordState.recorded || _state == VoiceRecordState.playing
                            ? AudioFileWaveforms(
                                size: Size(MediaQuery.of(context).size.width - 80, 70),
                                playerController: _playerController,
                                waveformType: WaveformType.fitWidth,
                                playerWaveStyle: const PlayerWaveStyle(
                                  fixedWaveColor: AppColors.borderSubtle,
                                  liveWaveColor: AppColors.primary,
                                  spacing: 7.0,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.graphic_eq_rounded,
                                    size: 36,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '15 to 45 seconds of genuine voice',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Dynamic Voice Controls
              if (_state == VoiceRecordState.idle)
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _startRecording,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.mic_rounded, color: AppColors.background, size: 34),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to start recording',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

              if (_state == VoiceRecordState.recording)
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _stopRecording,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.stop_rounded, color: Colors.white, size: 36),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Recording... ${_recordingSeconds}s / ${_maxSeconds}s',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

              if (_state == VoiceRecordState.recorded || _state == VoiceRecordState.playing)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surfaceVariant,
                            foregroundColor: AppColors.primary,
                          ),
                          onPressed: _playPreview,
                          icon: Icon(
                            _state == VoiceRecordState.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        TextButton.icon(
                          onPressed: _deleteRecording,
                          icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
                          label: Text(
                            'Re-record',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textSecondary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    MantraButton(
                      label: 'Save & Continue',
                      onPressed: () => context.push('/onboarding/photos'),
                      icon: Icons.arrow_forward_rounded,
                    ),
                  ],
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
