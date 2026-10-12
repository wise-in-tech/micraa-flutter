import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micraa_flutter/models/participant_model.dart';
import 'package:micraa_flutter/widgets/participants_panel.dart';

/// Ticket-001: "the teacher participant list is ordered by connection time",
/// "participant additions and removals update the list", "the teacher can
/// mute and unmute a student from the live-room UI".
void main() {
  const teacher = ParticipantModel(
    identity: 'teacher-1',
    userId: 1,
    name: 'Ms. Martin',
    role: 'TEACHER',
    connectedAt: 1000,
    state: 'ACTIVE',
    microphoneMuted: false,
  );
  const alice = ParticipantModel(
    identity: 'student-10',
    userId: 10,
    name: 'Alice',
    role: 'STUDENT',
    connectedAt: 2000,
    state: 'ACTIVE',
    microphoneMuted: false,
  );
  const bob = ParticipantModel(
    identity: 'student-11',
    userId: 11,
    name: 'Bob',
    role: 'STUDENT',
    connectedAt: 3000,
    state: 'ACTIVE',
    microphoneMuted: true,
  );

  Widget pump(List<ParticipantModel> participants, void Function(ParticipantModel) onToggle) {
    return MaterialApp(
      home: Scaffold(
        body: ParticipantsPanel(participants: participants, onToggleMic: onToggle),
      ),
    );
  }

  testWidgets('renders participants in the order given (backend connection-time order)',
      (tester) async {
    await tester.pumpWidget(pump([teacher, alice, bob], (_) {}));

    final names = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .toList();

    final teacherIndex = names.indexOf('Ms. Martin');
    final aliceIndex = names.indexOf('Alice');
    final bobIndex = names.indexOf('Bob');

    expect(teacherIndex, greaterThanOrEqualTo(0));
    expect(teacherIndex, lessThan(aliceIndex));
    expect(aliceIndex, lessThan(bobIndex));
  });

  testWidgets('list updates when a participant is added or removed', (tester) async {
    await tester.pumpWidget(pump([teacher, alice], (_) {}));
    expect(find.text('Bob'), findsNothing);
    expect(find.text('المشاركون (2)'), findsOneWidget);

    // Participant connects.
    await tester.pumpWidget(pump([teacher, alice, bob], (_) {}));
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('المشاركون (3)'), findsOneWidget);

    // Participant disconnects.
    await tester.pumpWidget(pump([teacher, bob], (_) {}));
    expect(find.text('Alice'), findsNothing);
    expect(find.text('المشاركون (2)'), findsOneWidget);
  });

  testWidgets('teacher can mute an unmuted student via the mic button', (tester) async {
    ParticipantModel? toggled;
    await tester.pumpWidget(pump([teacher, alice], (p) => toggled = p));

    // Only students get an interactive mic button (the teacher's own row just
    // shows a decorative, non-tappable icon), so there is exactly one
    // IconButton here even though both rows may render an "Icons.mic" glyph.
    expect(find.byType(IconButton), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    expect(toggled?.identity, 'student-10');
  });

  testWidgets('teacher can unmute a muted student, and the teacher row has no mic control',
      (tester) async {
    ParticipantModel? toggled;
    await tester.pumpWidget(pump([teacher, bob], (p) => toggled = p));

    // The teacher's own row must not expose a mute control (only students do).
    expect(find.byType(IconButton), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    expect(toggled?.identity, 'student-11');
  });

  testWidgets('shows a pending spinner instead of a button while a mic action is in flight',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ParticipantsPanel(
          participants: const [teacher, alice],
          pendingMicActions: const {10},
          onToggleMic: (_) {},
        ),
      ),
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);
  });
}
