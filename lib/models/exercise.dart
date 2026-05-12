class Exercise {
  final String id;
  final String name;
  final String? category;
  final String? description;
  final String? videoUrl;
  final String createdAt;

  Exercise({
    required this.id,
    required this.name,
    this.category,
    this.description,
    this.videoUrl,
    required this.createdAt,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      description: json['description'] as String?,
      videoUrl: json['video_url'] as String?,
      createdAt: json['created_at'] as String,
    );
  }
}

/// Treść `PUT /api/training-plans/{id}/items` (jak `TrainingPlanBuilder.vue`).
class PlanItemPutPayload {
  final int dayOfWeek;
  final String? exerciseId;
  final String customExerciseName;
  final int? sets;
  final int? reps;
  final double? intensityPercent;
  final double? weightKg;
  final String notes;
  final int sortOrder;

  PlanItemPutPayload({
    required this.dayOfWeek,
    this.exerciseId,
    this.customExerciseName = '',
    this.sets,
    this.reps,
    this.intensityPercent,
    this.weightKg,
    this.notes = '',
    required this.sortOrder,
  });

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'exercise_id': exerciseId,
        'custom_exercise_name': customExerciseName,
        'sets': sets,
        'reps': reps,
        'intensity_percent': intensityPercent,
        'weight_kg': weightKg,
        'notes': notes,
        'sort_order': sortOrder,
      };
}
