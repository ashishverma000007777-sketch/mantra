import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/preview/dev_preview.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/network/api_client.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final isPreview = !kReleaseMode && ref.read(devPreviewProvider);
    if (isPreview) {
      setState(() {
        _profile = {
          'display_name': 'Aria Sharma',
          'age': 26,
          'city': 'Bengaluru',
          'trust_score': 88.0,
        };
        _isLoading = false;
      });
      return;
    }

    try {
      final res = await ApiClient.instance.get('/profile');
      if (res.statusCode == 200 && res.data['success'] == true) {
        setState(() {
          _profile = res.data['data'];
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isPreviewActive = !kReleaseMode && ref.watch(devPreviewProvider);
    final name = _profile?['display_name'] ?? 'Mantra Member';
    final age = _profile?['age'] ?? user?.age ?? 25;
    final city = _profile?['city'] ?? user?.city ?? 'India';
    final trustScore = (_profile?['trust_score'] as num?)?.toDouble() ?? 50.0;
    final isPremium = user?.isPremium ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        actions: [
          if (!isPremium)
            TextButton(
              onPressed: () => context.push('/premium'),
              child: Text('⭐ Upgrade', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (isPreviewActive) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gold.withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.explore_outlined, color: AppColors.gold, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Development Preview Mode',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.gold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Exploring offline with mock data • No OTP required',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await ref.read(authControllerProvider.notifier).logout();
                            if (context.mounted) context.go('/auth/phone');
                          },
                          child: const Text(
                            'Exit',
                            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.gold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                    child: Text(
                      name.isNotEmpty ? name[0] : 'M',
                      style: TextStyle(fontSize: 36, color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(child: Text(name, style: Theme.of(context).textTheme.headlineMedium)),
                Center(child: Text('$age · $city', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
                const SizedBox(height: 24),
                ListTile(
                  leading: Icon(Icons.edit_rounded, color: AppColors.primary),
                  title: const Text('Edit Profile'),
                  onTap: () => context.push('/profile/edit'),
                  contentPadding: EdgeInsets.zero,
                ),
                ListTile(
                  leading: Icon(Icons.shield_rounded, color: AppColors.trust),
                  title: const Text('Trust Score'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${trustScore.toInt()}',
                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700),
                    ),
                  ),
                  onTap: () => context.push('/profile/trust-score'),
                  contentPadding: EdgeInsets.zero,
                ),
                ListTile(
                  leading: Icon(Icons.security_rounded, color: AppColors.secondary),
                  title: const Text('Safety Center'),
                  onTap: () => context.push('/safety'),
                  contentPadding: EdgeInsets.zero,
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                  title: Text(isPreviewActive ? 'Exit Preview Mode' : 'Log Out', style: const TextStyle(color: Colors.red)),
                  onTap: () async {
                    await ref.read(authControllerProvider.notifier).logout();
                    if (context.mounted) context.go('/auth/phone');
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
    );
  }
}
