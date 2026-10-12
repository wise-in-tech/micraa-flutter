import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:micraa_flutter/services/api_service.dart';
import 'package:micraa_flutter/services/auth_service.dart';

/// A no-op AuthService that never touches secure storage (no platform channel
/// needed in tests) and never attaches a token.
class _NoTokenAuthService extends AuthService {
  @override
  Future<String?> getToken() async => null;
}

void main() {
  group('ApiService participants (ticket-001)', () {
    test('getParticipants parses the ordered list returned by the backend', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/live-classes/1/participants');
        return http.Response(
          jsonEncode([
            {
              'identity': 'teacher-1',
              'userId': 1,
              'name': 'Ms. Martin',
              'role': 'TEACHER',
              'connectedAt': 1000,
              'state': 'ACTIVE',
              'microphoneMuted': false,
            },
            {
              'identity': 'student-10',
              'userId': 10,
              'name': 'Alice',
              'role': 'STUDENT',
              'connectedAt': 2000,
              'state': 'ACTIVE',
              'microphoneMuted': true,
            },
          ]),
          200,
        );
      });

      final api = ApiService(client: client, authService: _NoTokenAuthService());
      final result = await api.getParticipants(1);

      expect(result, hasLength(2));
      // Preserves the order the backend already sorted (earliest connection first).
      expect(result[0].identity, 'teacher-1');
      expect(result[1].identity, 'student-10');
      expect(result[1].microphoneMuted, isTrue);
      expect(result[1].userId, 10);
    });

    test('getParticipants surfaces a 403 as an ApiException (not the assigned teacher)', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'Access denied'}), 403);
      });
      final api = ApiService(client: client, authService: _NoTokenAuthService());

      expect(
        () => api.getParticipants(1),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403)),
      );
    });

    test('muteParticipant posts to the mute endpoint', () async {
      String? calledPath;
      final client = MockClient((request) async {
        calledPath = request.url.path;
        expect(request.method, 'POST');
        return http.Response('', 200);
      });
      final api = ApiService(client: client, authService: _NoTokenAuthService());

      await api.muteParticipant(1, 10);

      expect(calledPath, '/api/live-classes/1/participants/10/mute');
    });

    test('unmuteParticipant posts to the unmute endpoint', () async {
      String? calledPath;
      final client = MockClient((request) async {
        calledPath = request.url.path;
        return http.Response('', 200);
      });
      final api = ApiService(client: client, authService: _NoTokenAuthService());

      await api.unmuteParticipant(1, 10);

      expect(calledPath, '/api/live-classes/1/participants/10/unmute');
    });
  });
}
