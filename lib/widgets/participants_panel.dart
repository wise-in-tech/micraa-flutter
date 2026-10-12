import 'package:flutter/material.dart';
import '../models/participant_model.dart';
import '../config/app_config.dart';

/// Teacher-only roster of connected participants, ordered exactly as returned
/// by the backend (earliest connection first - see
/// `LiveClassService.getConnectedParticipants`), with per-student mute/unmute
/// control (ticket-001).
///
/// Kept as its own stateless widget (rather than inline in LiveRoomScreen) so
/// it can be tested without a live LiveKit connection.
class ParticipantsPanel extends StatelessWidget {
  final List<ParticipantModel> participants;
  final String? errorMessage;
  final Set<int> pendingMicActions;
  final void Function(ParticipantModel participant) onToggleMic;

  const ParticipantsPanel({
    super.key,
    required this.participants,
    required this.onToggleMic,
    this.errorMessage,
    this.pendingMicActions = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('participants-panel'),
      constraints: const BoxConstraints(maxHeight: 190),
      decoration: const BoxDecoration(
        color: Color(kSurfaceColor),
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.groups, color: Color(kAccentColor), size: 16),
                const SizedBox(width: 8),
                Text(
                  'المشاركون (${participants.length})',
                  style: const TextStyle(color: Color(kTextSecondaryColor), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Color(kDangerColor), fontSize: 11),
              ),
            ),
          Flexible(
            child: participants.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'لا يوجد مشاركون متصلون حاليًا.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: participants.length,
                    itemBuilder: (_, i) => _ParticipantRow(
                      participant: participants[i],
                      isPending: participants[i].userId != null &&
                          pendingMicActions.contains(participants[i].userId),
                      onToggleMic: onToggleMic,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  final ParticipantModel participant;
  final bool isPending;
  final void Function(ParticipantModel participant) onToggleMic;

  const _ParticipantRow({
    required this.participant,
    required this.isPending,
    required this.onToggleMic,
  });

  String get _roleLabel {
    switch (participant.role) {
      case 'TEACHER':
        return 'معلم';
      case 'STUDENT':
        return 'طالب';
      default:
        return 'غير معروف';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = participant.role == 'STUDENT' && participant.userId != null;

    return ListTile(
      dense: true,
      leading: Icon(
        participant.isTeacher ? Icons.school : Icons.person,
        color: Colors.white54,
        size: 20,
      ),
      title: Text(
        participant.name,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      subtitle: Text(
        _roleLabel,
        style: const TextStyle(color: Colors.white38, fontSize: 11),
      ),
      trailing: isStudent
          ? (isPending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                )
              : IconButton(
                  icon: Icon(
                    participant.microphoneMuted ? Icons.mic_off : Icons.mic,
                    color: participant.microphoneMuted
                        ? const Color(kDangerColor)
                        : const Color(kSuccessColor),
                  ),
                  tooltip: participant.microphoneMuted
                      ? 'إعادة تفعيل الميكروفون'
                      : 'كتم الميكروفون',
                  onPressed: () => onToggleMic(participant),
                ))
          : Icon(
              participant.microphoneMuted ? Icons.mic_off : Icons.mic,
              color: Colors.white24,
              size: 18,
            ),
    );
  }
}
