// lib/features/matching/data/models/compatibility_dna_model.dart

class DimensionInsightModel {
  final String dimension;
  final int score;
  final String insight;
  final List<String> contributingFactors;
  final List<String> sharedItems;

  const DimensionInsightModel({
    required this.dimension,
    required this.score,
    required this.insight,
    required this.contributingFactors,
    this.sharedItems = const [],
  });

  factory DimensionInsightModel.fromJson(Map<String, dynamic> json) => DimensionInsightModel(
        dimension: json['dimension'] ?? 'Dimension',
        score: (json['score'] as num?)?.toInt() ?? 70,
        insight: json['insight'] ?? '',
        contributingFactors: List<String>.from(json['contributing_factors'] ?? []),
        sharedItems: List<String>.from(json['shared_values'] ?? json['common_interests'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'dimension': dimension,
        'score': score,
        'insight': insight,
        'contributing_factors': contributingFactors,
        'shared_items': sharedItems,
      };
}

class CompatibilityDnaModel {
  final String targetUserId;
  final int overallAlignment;
  final int evaluatedDimensionsCount;
  final Map<String, DimensionInsightModel> dimensions;
  final String ethicalNotice;

  const CompatibilityDnaModel({
    required this.targetUserId,
    required this.overallAlignment,
    required this.evaluatedDimensionsCount,
    required this.dimensions,
    required this.ethicalNotice,
  });

  factory CompatibilityDnaModel.fromJson(Map<String, dynamic> json) {
    final rawDims = json['dimensions'];
    final dims = <String, DimensionInsightModel>{};
    if (rawDims is Map<String, dynamic>) {
      rawDims.forEach((key, val) {
        if (val is Map<String, dynamic>) {
          dims[key] = DimensionInsightModel.fromJson(val);
        }
      });
    }

    return CompatibilityDnaModel(
      targetUserId: json['target_user_id'] ?? '',
      overallAlignment: (json['overall_alignment'] as num?)?.toInt() ?? 75,
      evaluatedDimensionsCount: (json['evaluated_dimensions_count'] as num?)?.toInt() ?? dims.length,
      dimensions: dims,
      ethicalNotice: json['ethical_notice'] ??
          'These insights reflect self-reported preferences to foster understanding, not a psychological guarantee.',
    );
  }

  Map<String, dynamic> toJson() => {
        'target_user_id': targetUserId,
        'overall_alignment': overallAlignment,
        'evaluated_dimensions_count': evaluatedDimensionsCount,
        'dimensions': dimensions.map((k, v) => MapEntry(k, v.toJson())),
        'ethical_notice': ethicalNotice,
      };
}
