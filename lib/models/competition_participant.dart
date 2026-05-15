/// Zawodnik przypisany do zawodów (`competition_participants` — jak na WWW).
class CompetitionParticipantBrief {
  final String athleteId;
  final String fullName;

  const CompetitionParticipantBrief({
    required this.athleteId,
    required this.fullName,
  });

  factory CompetitionParticipantBrief.fromJson(Map<String, dynamic> json) {
    return CompetitionParticipantBrief(
      athleteId: json['athlete_id'] as String,
      fullName: json['full_name'] as String,
    );
  }
}
