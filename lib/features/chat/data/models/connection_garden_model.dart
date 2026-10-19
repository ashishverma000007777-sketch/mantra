// lib/features/chat/data/models/connection_garden_model.dart

class GardenMilestoneItem {
  final String milestoneType;
  final String title;
  final String description;
  final String achievedAt;

  const GardenMilestoneItem({
    required this.milestoneType,
    required this.title,
    required this.description,
    required this.achievedAt,
  });

  factory GardenMilestoneItem.fromJson(Map<String, dynamic> json) => GardenMilestoneItem(
        milestoneType: json['milestone_type'] ?? 'moment',
        title: json['title'] ?? 'Connection Milestone',
        description: json['description'] ?? '',
        achievedAt: json['achieved_at'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'milestone_type': milestoneType,
        'title': title,
        'description': description,
        'achieved_at': achievedAt,
      };
}

class ConnectionGardenModel {
  final String connectionId;
  final String stage;
  final int growthPoints;
  final String stageDescription;
  final bool isPaused;
  final List<GardenMilestoneItem> milestones;
  final String antiStreakGuarantee;
  final String nextMilestoneSuggestion;

  const ConnectionGardenModel({
    required this.connectionId,
    required this.stage,
    required this.growthPoints,
    required this.stageDescription,
    required this.isPaused,
    required this.milestones,
    required this.antiStreakGuarantee,
    required this.nextMilestoneSuggestion,
  });

  factory ConnectionGardenModel.fromJson(Map<String, dynamic> json) {
    List<GardenMilestoneItem> milestonesList = [];
    final rawMilestones = json['milestones'];
    if (rawMilestones is List) {
      milestonesList = rawMilestones
          .map((m) => m is Map<String, dynamic> ? GardenMilestoneItem.fromJson(m) : null)
          .whereType<GardenMilestoneItem>()
          .toList();
    }

    return ConnectionGardenModel(
      connectionId: json['connection_id'] ?? '',
      stage: json['stage'] ?? 'seed',
      growthPoints: (json['growth_points'] as num?)?.toInt() ?? 10,
      stageDescription: json['stage_description'] ?? 'A gentle slow connection begins.',
      isPaused: json['is_paused'] ?? false,
      milestones: milestonesList,
      antiStreakGuarantee: json['anti_streak_guarantee'] ??
          'Connection Gardens reflect mutual milestones, not compulsive daily streaks.',
      nextMilestoneSuggestion: json['next_milestone_suggestion'] ??
          'Answer a Conversation Quest together to grow deeper roots.',
    );
  }

  Map<String, dynamic> toJson() => {
        'connection_id': connectionId,
        'stage': stage,
        'growth_points': growthPoints,
        'stage_description': stageDescription,
        'is_paused': isPaused,
        'milestones': milestones.map((m) => m.toJson()).toList(),
        'anti_streak_guarantee': antiStreakGuarantee,
        'next_milestone_suggestion': nextMilestoneSuggestion,
      };
}
