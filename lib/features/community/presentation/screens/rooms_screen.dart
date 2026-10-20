// lib/features/community/presentation/screens/rooms_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_card.dart';
import '../../../../core/widgets/mantra_states.dart';
import '../../data/models/room_model.dart';
import '../../providers/rooms_provider.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RoomsHeader(),
            Expanded(
              child: roomsAsync.when(
                loading: () => const _RoomsShimmer(),
                error: (e, _) => MantraErrorState(
                  message: 'Could not load community rooms.\n${e.toString()}',
                  onRetry: () => ref.refresh(roomsProvider),
                ),
                data: (rooms) => _RoomsContent(rooms: rooms),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MINDFUL COMMUNITIES',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Community Rooms',
                      style: GoogleFonts.lora(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Quiet corners to connect over shared interests',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Search box
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search communities & reflections...',
                hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 13.5),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomsContent extends StatelessWidget {
  final List<RoomModel> rooms;
  const _RoomsContent({required this.rooms});

  @override
  Widget build(BuildContext context) {
    final myRooms = rooms.where((r) => r.isMember).toList();
    final featured = rooms.where((r) => r.isFeatured).toList();
    final allRooms = rooms.where((r) => !r.isMember).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        // Filter chips
        _FilterChips().animate().fadeIn(duration: 300.ms),

        const SizedBox(height: 18),

        if (myRooms.isNotEmpty) ...[
          _SectionTitle(title: 'Your Joined Rooms'),
          const SizedBox(height: 10),
          ...myRooms.asMap().entries.map((e) => RoomCard(room: e.value)
              .animate(delay: Duration(milliseconds: e.key * 60))
              .fadeIn(duration: 250.ms)
              .slideX(begin: 0.04, end: 0)),
          const SizedBox(height: 18),
        ],

        if (featured.isNotEmpty) ...[
          _SectionTitle(title: 'Featured Reflections'),
          const SizedBox(height: 10),
          SizedBox(
            height: 148,
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: featured.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) =>
                  _FeaturedRoomCard(room: featured[i], index: i)
                      .animate(delay: Duration(milliseconds: i * 60))
                      .fadeIn(duration: 250.ms),
            ),
          ),
          const SizedBox(height: 20),
        ],

        _SectionTitle(title: 'Discover Communities'),
        const SizedBox(height: 10),

        ...allRooms.asMap().entries.map((e) => RoomCard(room: e.value)
            .animate(delay: Duration(milliseconds: e.key * 60))
            .fadeIn(duration: 250.ms)
            .slideX(begin: 0.04, end: 0)),
      ],
    );
  }
}

class _FilterChips extends StatefulWidget {
  @override
  State<_FilterChips> createState() => _FilterChipsState();
}

class _FilterChipsState extends State<_FilterChips> {
  final _filters = ['All', 'Slow Dating', 'Literature', 'Mindfulness', 'Cinema', 'Creative Arts'];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final active = _selected == i;
          return GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(
                  color: active ? AppColors.accent : AppColors.border,
                ),
              ),
              child: Text(
                _filters[i],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? const Color(0xFF080B0D) : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class RoomCard extends StatelessWidget {
  final RoomModel room;
  const RoomCard({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return MantraCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/rooms/${room.id}'),
      child: Row(
        children: [
          // Room icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(room.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        room.name,
                        style: GoogleFonts.lora(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (room.isWomenOnly)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.trust.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          border: Border.all(color: AppColors.trust.withOpacity(0.4)),
                        ),
                        child: Text(
                          '♀ Women Only',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.trust,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  room.latestPost ?? room.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${room.memberCount}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'members',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              if (room.isMember)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppColors.trust.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(color: AppColors.trust.withOpacity(0.35)),
                  ),
                  child: Text(
                    'Joined',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.trust,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturedRoomCard extends StatelessWidget {
  final RoomModel room;
  final int index;
  const _FeaturedRoomCard({required this.room, required this.index});

  String get _featuredAsset {
    if (index % 2 == 0) {
      return 'assets/images/community_literature.jpg';
    } else {
      return 'assets/images/community_chai.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/rooms/${room.id}'),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                _featuredAsset,
                fit: BoxFit.cover,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.black.withOpacity(0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(room.emoji, style: const TextStyle(fontSize: 16)),
                    ),
                    const Spacer(),
                    Text(
                      room.name,
                      style: GoogleFonts.lora(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${room.memberCount} members',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.lora(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _RoomsShimmer extends StatelessWidget {
  const _RoomsShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
          border: Border.all(color: AppColors.border),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 1200.ms, color: AppColors.surfaceSecondary),
    );
  }
}
