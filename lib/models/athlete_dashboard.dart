import 'athlete.dart';
import 'attendance_summary.dart';
import 'competition.dart';
import 'payment.dart';

class CalendarParticipantBrief {
  final String athleteId;
  final String fullName;

  CalendarParticipantBrief({
    required this.athleteId,
    required this.fullName,
  });

  factory CalendarParticipantBrief.fromJson(Map<String, dynamic> json) {
    return CalendarParticipantBrief(
      athleteId: json['athlete_id'] as String,
      fullName: json['full_name'] as String? ?? '',
    );
  }
}

class MyCalendarEntry {
  final Competition competition;
  final List<CalendarParticipantBrief> participants;

  MyCalendarEntry({
    required this.competition,
    required this.participants,
  });

  factory MyCalendarEntry.fromJson(Map<String, dynamic> json) {
    final rawParticipants = json['participants'];
    return MyCalendarEntry(
      competition: Competition.fromJson(
        json['competition'] as Map<String, dynamic>,
      ),
      participants: rawParticipants is List
          ? rawParticipants
              .map(
                (e) => CalendarParticipantBrief.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList()
          : const [],
    );
  }
}

/// Agregowany payload `GET /api/athletes/me/dashboard`.
class AthleteDashboardResponse {
  final Athlete? athlete;
  final int pendingResultsCount;
  final List<MyCalendarEntry> calendarEntries;
  final AttendanceSummary? attendanceSummary;
  final PaymentStatusResponse? paymentStatus;

  AthleteDashboardResponse({
    required this.athlete,
    required this.pendingResultsCount,
    required this.calendarEntries,
    required this.attendanceSummary,
    required this.paymentStatus,
  });

  factory AthleteDashboardResponse.fromJson(Map<String, dynamic> json) {
    final rawCalendar = json['calendar_entries'];
    final rawAttendance = json['attendance_summary'];
    final rawPayment = json['payment_status'];
    final rawAthlete = json['athlete'];

    return AthleteDashboardResponse(
      athlete: rawAthlete is Map<String, dynamic>
          ? Athlete.fromJson(rawAthlete)
          : null,
      pendingResultsCount: (json['pending_results_count'] as num?)?.toInt() ?? 0,
      calendarEntries: rawCalendar is List
          ? rawCalendar
              .map(
                (e) => MyCalendarEntry.fromJson(e as Map<String, dynamic>),
              )
              .toList()
          : const [],
      attendanceSummary: rawAttendance is Map<String, dynamic>
          ? AttendanceSummary.fromJson(rawAttendance)
          : null,
      paymentStatus: rawPayment is Map<String, dynamic>
          ? PaymentStatusResponse.fromJson(rawPayment)
          : null,
    );
  }
}
