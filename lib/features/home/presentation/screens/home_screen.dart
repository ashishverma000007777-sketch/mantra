import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_badge.dart';
import '../../../../core/widgets/mantra_card.dart';
import '../../../../core/widgets/mantra_button.dart';
import '../../../community/data/models/room_model.dart';
import '../../../community/providers/rooms_provider.dart';
import '../../../auth/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Layered Cinematic Hero Area
          SliverToBoxAdapter(
            child: _CinematicHeroHeader(
              userName: 'Seeker',
              trustScore: 88.0,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // 2. Mindful Check-in
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _MindfulCheckIn(),
            ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.05, end: 0),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 3. Featured Spark Showcase (Visual & Editorial)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _FeaturedSparkCard(onTap: () => context.go('/sparks')),
            ).animate(delay: 140.ms).fadeIn().slideY(begin: 0.05, end: 0),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // 4. Mystery Match Feature (Values First)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _MysteryMatchCard(onTap: () => context.push('/mystery-match')),
            ).animate(delay: 180.ms).fadeIn().slideY(begin: 0.05, end: 0),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // 5. Daily Question Quest Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _DailyQuestCard(onTap: () => context.push('/quest/daily')),
            ).animate(delay: 220.ms).fadeIn().slideY(begin: 0.05, end: 0),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // 6. Connection Garden Highlight
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ConnectionGardenTeaser(onTap: () => context.push('/garden/active')),
            ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.05, end: 0),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // 7. Slow Communities Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Slow Communities',
                        style: GoogleFonts.lora(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Thoughtful discussions without superficial swiping',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.go('/rooms'),
                    child: Text(
                      'View All',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 280.ms).fadeIn(),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // 8. Community Rooms Preview
          roomsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            ),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
            data: (rooms) {
              final previewRooms = rooms.take(3).toList();
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: _HomeRoomCard(
                      room: previewRooms[i],
                      index: i,
                      onTap: () => context.push('/rooms/${previewRooms[i].id}'),
                    ).animate(delay: Duration(milliseconds: 300 + i * 50)).fadeIn(duration: 200.ms),
                  ),
                  childCount: previewRooms.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 36)),
        ],
      ),
    );
  }
}

/// Atmospheric Layered Hero Header with dark photography, Lora greeting, and safety quick-controls.
class _CinematicHeroHeader extends StatelessWidget {
  final String userName;
  final double trustScore;

  const _CinematicHeroHeader({
    required this.userName,
    required this.trustScore,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 260 + topPadding,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Atmospheric Photography
          Image.asset(
            'assets/images/home_hero_bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: AppColors.backgroundSecondary),
          ),

          // Cinematic Vignette Scrim
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withOpacity(0.4),
                  AppColors.background.withOpacity(0.75),
                  AppColors.background,
                ],
                stops: const [0.0, 0.65, 1.0],
              ),
            ),
          ),

          // Top Header Bar
          Positioned(
            top: topPadding + 10,
            left: 20,
            right: 20,
            child: Row(
              children: [
                // Brand Monogram
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      'M',
                      style: GoogleFonts.lora(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Trust Score Pill
                InkWell(
                  onTap: () => context.push('/profile/trust-score'),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  child: MantraBadge.trust(
                    score: trustScore,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                // Safety Center Button
                _HeaderIconButton(
                  icon: Icons.shield_outlined,
                  tooltip: 'Safety Center',
                  color: AppColors.trust,
                  onTap: () => context.push('/safety'),
                ),
                const SizedBox(width: 8),
                // SOS Emergency Shortcut
                _HeaderIconButton(
                  icon: Icons.emergency_outlined,
                  tooltip: 'Emergency SOS',
                  color: AppColors.error,
                  onTap: () => context.push('/safety/sos'),
                ),
              ],
            ),
          ),

          // Hero Typography and Prompt
          Positioned(
            left: 20,
            right: 20,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SLOW DATING',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome, $userName',
                  style: GoogleFonts.lora(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Know them before you show yourself.',
                  style: GoogleFonts.lora(
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.85),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

/// Mindful Mood Arrival Check-in
class _MindfulCheckIn extends StatefulWidget {
  @override
  State<_MindfulCheckIn> createState() => _MindfulCheckInState();
}

class _MindfulCheckInState extends State<_MindfulCheckIn> {
  final _states = [
    ('Reflective', Icons.auto_stories_outlined),
    ('Grounded', Icons.spa_outlined),
    ('Curious', Icons.explore_outlined),
    ('Warm', Icons.coffee_outlined),
    ('Cozy', Icons.weekend_outlined),
  ];
  int? _selected = 0;

  @override
  Widget build(BuildContext context) {
    return MantraCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mindful Check-in',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _selected != null ? _states[_selected!].$1 : 'How are you arriving?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: _selected != null ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: _selected != null ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _states.asMap().entries.map((e) {
              final isSel = _selected == e.key;
              return GestureDetector(
                onTap: () => setState(() => _selected = e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primary.withOpacity(0.15) : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                    border: Border.all(
                      color: isSel ? AppColors.primary : AppColors.borderSubtle,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        e.value.$2,
                        size: 14,
                        color: isSel ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        e.value.$1,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                          color: isSel ? AppColors.primaryLight : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Today's Sparks Featured Editorial Card with portrait photography and gradual reveal indicator
class _FeaturedSparkCard extends StatelessWidget {
  final VoidCallback onTap;
  const _FeaturedSparkCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Portrait
                Image.asset(
                  'assets/images/portrait_aanya.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: AppColors.surfaceVariant),
                ),
                // Gradient Scrim
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Colors.transparent,
                        AppColors.background.withOpacity(0.75),
                        AppColors.background.withOpacity(0.95),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  "TODAY'S SPARKS",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: AppColors.background.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              '7 Curated Matches',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Aanya, 25',
                                style: GoogleFonts.lora(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              MantraBadge.compatibility(score: 92, fontSize: 10),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Literature • 35mm Photography • Chai Rituals',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mystery Match (Values Before Face)
class _MysteryMatchCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MysteryMatchCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/mystery_match_silhouette.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: AppColors.surface),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        AppColors.background.withOpacity(0.3),
                        AppColors.background.withOpacity(0.85),
                        AppColors.background,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Mystery Match',
                                  style: GoogleFonts.lora(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const MantraBadge(
                                  label: 'Values First',
                                  variant: MantraBadgeVariant.soft,
                                  fontSize: 10,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Discover a connection through values and voice before seeing their face.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.8),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Daily Question Quest Card
class _DailyQuestCard extends StatelessWidget {
  final VoidCallback onTap;
  const _DailyQuestCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MantraCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.trust.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.trust.withOpacity(0.25)),
            ),
            child: const Icon(Icons.psychology_outlined, color: AppColors.trust, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Today\'s Question Quest',
                      style: GoogleFonts.lora(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '"What is a habit or belief you grew out of this year?"',
                  style: GoogleFonts.lora(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
        ],
      ),
    );
  }
}

/// Connection Garden Teaser
class _ConnectionGardenTeaser extends StatelessWidget {
  final VoidCallback onTap;
  const _ConnectionGardenTeaser({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/garden_flourish.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: AppColors.surface),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        AppColors.background.withOpacity(0.3),
                        AppColors.background.withOpacity(0.85),
                        AppColors.background,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_florist_outlined, color: AppColors.secondary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connection Garden',
                              style: GoogleFonts.lora(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Stage 3 • Sprouting new leaves with every exchange',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Community Room Card in Home
class _HomeRoomCard extends StatelessWidget {
  final RoomModel room;
  final int index;
  final VoidCallback onTap;

  const _HomeRoomCard({
    required this.room,
    required this.index,
    required this.onTap,
  });

  String get _roomImage {
    if (room.name.toLowerCase().contains('book') || room.name.toLowerCase().contains('read')) {
      return 'assets/images/community_literature.jpg';
    }
    return 'assets/images/community_chai.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return MantraCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: Image.asset(
                _roomImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.groups_rounded, color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        room.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (room.isWomenOnly) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Women Only',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${room.memberCount} members • ${room.latestPost ?? room.description}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
        ],
      ),
    );
  }
}
