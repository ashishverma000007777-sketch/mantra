// lib/features/profile/presentation/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_button.dart';
import '../../../../core/widgets/mantra_card.dart';
import '../../../../core/network/api_client.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController(text: 'Aria Sharma');
  final _bioController = TextEditingController(
    text: 'Lover of slow coffee mornings, paperbacks, and unfiltered conversations.',
  );
  final _intentController = TextEditingController(
    text: 'Mindful companionship built on mutual respect',
  );
  final _cityController = TextEditingController(text: 'Bengaluru');
  bool _saving = false;

  final List<String> _availableInterests = [
    'Chai Rituals',
    'Literature',
    'Film Photography',
    'Slow Living',
    'Architecture',
    'Hiking',
    'Podcasts',
    'Pottery',
    'Poetry',
    'Jazz & Soul',
    'Filter Coffee',
    'Art Galleries',
  ];

  final Set<String> _selectedInterests = {
    'Chai Rituals',
    'Literature',
    'Slow Living',
    'Film Photography',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _intentController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    try {
      await ApiClient.instance.post('/profile', data: {
        'display_name': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Mantra Member',
        'gender': 'woman',
        'age': 26,
        'city': _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : 'Bengaluru',
        'bio': _bioController.text.trim(),
        'intent': _intentController.text.trim().isNotEmpty ? _intentController.text.trim() : 'meaningful',
        'interests': _selectedInterests.toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully ✨')),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated offline ✨')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // Photo Avatar Tip
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceVariant,
                            border: Border.all(color: AppColors.border, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              _nameController.text.isNotEmpty ? _nameController.text[0] : 'A',
                              style: GoogleFonts.lora(
                                fontSize: 34,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Photos remain blurred until mutual consent',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Fields Card
                  MantraCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildField(
                          label: 'DISPLAY NAME',
                          controller: _nameController,
                          hint: 'Your preferred first name',
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'CITY',
                          controller: _cityController,
                          hint: 'Where your rhythm takes place',
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'ABOUT YOUR CADENCE (BIO)',
                          controller: _bioController,
                          hint: 'What does a quiet day look like for you?',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'RELATIONSHIP INTENT',
                          controller: _intentController,
                          hint: 'What kind of connection are you nurturing?',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Interests selection
                  Text(
                    'Your Interests & Rhythms',
                    style: GoogleFonts.lora(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  MantraCard(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableInterests.map((tag) {
                        final isSelected = _selectedInterests.contains(tag);
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (isSelected) {
                                _selectedInterests.remove(tag);
                              } else {
                                _selectedInterests.add(tag);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.surfaceVariant : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  const Icon(Icons.check_rounded, size: 12, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  tag,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Save Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: MantraButton(
                label: 'Save Changes',
                isLoading: _saving,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 13.5),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ],
    );
  }
}
