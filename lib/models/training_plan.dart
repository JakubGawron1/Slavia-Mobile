class TrainingPlan {
  final String id;
  final String athleteId;
  final String title;
  final String? goal;
  final String weekStart;
  final String status;
  final String? coachNote;
  final String? athleteNote;
  final int progressPercent;
  final String? createdBy;
  final String createdAt;
  final String updatedAt;

  TrainingPlan({
    required this.id,
    required this.athleteId,
    required this.title,
    this.goal,
    required this.weekStart,
    required this.status,
    this.coachNote,
    this.athleteNote,
    required this.progressPercent,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainingPlan.fromJson(Map<String, dynamic> json) {
    return TrainingPlan(
      id: json['id'] as String,
      athleteId: json['athlete_id'] as String,
      title: json['title'] as String,
      goal: json['goal'] as String?,
      weekStart: json['week_start'] as String,
      status: json['status'] as String? ?? 'planned',
      coachNote: json['coach_note'] as String?,
      athleteNote: json['athlete_note'] as String?,
      progressPercent: (json['progress_percent'] as num?)?.round() ?? 0,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

class TrainingPlanItem {
  final String id;
  final String planId;
  final int dayOfWeek;
  final String? exerciseId;
  final String? customExerciseName;
  final int? sets;
  final int? reps;
  final double? intensityPercent;
  final double? weightKg;
  final String? notes;
  final int sortOrder;
  final String? exerciseName;

  TrainingPlanItem({
    required this.id,
    required this.planId,
    required this.dayOfWeek,
    this.exerciseId,
    this.customExerciseName,
    this.sets,
    this.reps,
    this.intensityPercent,
    this.weightKg,
    this.notes,
    required this.sortOrder,
    this.exerciseName,
  });

  factory TrainingPlanItem.fromJson(Map<String, dynamic> json) {
    return TrainingPlanItem(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      dayOfWeek: (json['day_of_week'] as num).toInt(),
      exerciseId: json['exercise_id'] as String?,
      customExerciseName: json['custom_exercise_name'] as String?,
      sets: (json['sets'] as num?)?.toInt(),
      reps: (json['reps'] as num?)?.toInt(),
      intensityPercent: (json['intensity_percent'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      sortOrder: (json['sort_order'] as num).toInt(),
      exerciseName: json['exercise_name'] as String?,
    );
  }

  String get displayName =>
      (customExerciseName != null && customExerciseName!.trim().isNotEmpty)
          ? customExerciseName!.trim()
          : (exerciseName != null && exerciseName!.trim().isNotEmpty)
              ? exerciseName!.trim()
              : 'Ćwiczenie';
}
