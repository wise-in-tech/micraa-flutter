/// A connected participant as reported by the backend
/// (GET /api/live-classes/{id}/participants), which itself relays LiveKit's own
/// connection-time ordering. Used by the teacher's live-room participant panel.
class ParticipantModel {
  final String identity;
  final int? userId;
  final String name;
  final String role; // TEACHER | STUDENT | UNKNOWN
  final int connectedAt; // epoch millis
  final String state;
  final bool microphoneMuted;

  const ParticipantModel({
    required this.identity,
    required this.userId,
    required this.name,
    required this.role,
    required this.connectedAt,
    required this.state,
    required this.microphoneMuted,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) => ParticipantModel(
        identity: json['identity'] as String,
        userId: json['userId'] as int?,
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? 'UNKNOWN',
        connectedAt: json['connectedAt'] as int? ?? 0,
        state: json['state'] as String? ?? '',
        microphoneMuted: json['microphoneMuted'] as bool? ?? true,
      );

  bool get isTeacher => role == 'TEACHER';
}
