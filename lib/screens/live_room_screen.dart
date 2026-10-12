import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/live_class_model.dart';
import '../models/join_class_response.dart';
import '../models/user_model.dart';
import '../models/participant_model.dart';
import '../services/livekit_service.dart';
import '../services/api_service.dart';
import '../widgets/participants_panel.dart';
import '../config/app_config.dart';

class LiveRoomScreen extends StatefulWidget {
  final LiveClassModel liveClass;
  final JoinClassResponse joinResponse;
  final UserModel currentUser;
  final ApiService? apiService;

  const LiveRoomScreen({
    super.key,
    required this.liveClass,
    required this.joinResponse,
    required this.currentUser,
    this.apiService,
  });

  @override
  State<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends State<LiveRoomScreen> {
  final LiveClassRoomService _roomService = LiveClassRoomService();
  late final ApiService _apiService = widget.apiService ?? ApiService();
  bool _isConnecting = true;
  String? _connectError;
  Duration _elapsed = Duration.zero;
  late final Stopwatch _stopwatch;

  // Teacher-only: backend-provided, ordered participant roster + moderation.
  List<ParticipantModel> _participants = [];
  String? _participantsError;
  Timer? _participantsPollTimer;
  final Set<int> _pendingMicActions = {};

  bool get _isTeacher => widget.currentUser.isTeacher;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _roomService.addListener(_onRoomUpdate);
    _connect();
    // Mettre à jour le compteur toutes les secondes
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _elapsed = _stopwatch.elapsed);
      return mounted;
    });

    if (_isTeacher) {
      _roomService.onParticipantsChanged = _refreshParticipants;
      _refreshParticipants();
      _participantsPollTimer =
          Timer.periodic(const Duration(seconds: 5), (_) => _refreshParticipants());
    }
  }

  void _onRoomUpdate() => setState(() {});

  Future<void> _connect() async {
    // Sur web, le navigateur gère lui-même la permission micro
    // Sur mobile, on demande explicitement
    if (!kIsWeb) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        setState(() {
          _connectError = 'تم رفض إذن الميكروفون';
          _isConnecting = false;
        });
        return;
      }
    }

    try {
      // Normaliser l'URL selon la plateforme
      String url = widget.joinResponse.livekitUrl;
      if (url.contains('livekit:') || url.contains('localhost')) {
        url = kLiveKitWsUrl; // ws://localhost:7880 ou ws://192.168.x.x:7880
      }
      if (url.startsWith('http://')) url = url.replaceFirst('http://', 'ws://');
      if (url.startsWith('https://')) url = url.replaceFirst('https://', 'wss://');

      await _roomService.connect(url, widget.joinResponse.accessToken);
      setState(() => _isConnecting = false);
    } catch (e) {
      setState(() {
        _connectError = e.toString();
        _isConnecting = false;
      });
    }
  }

  Future<void> _refreshParticipants() async {
    try {
      final participants = await _apiService.getParticipants(widget.liveClass.id);
      if (!mounted) return;
      setState(() {
        _participants = participants;
        _participantsError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _participantsError = e.toString());
    }
  }

  Future<void> _toggleParticipantMic(ParticipantModel participant) async {
    final userId = participant.userId;
    if (userId == null || _pendingMicActions.contains(userId)) return;

    setState(() => _pendingMicActions.add(userId));
    try {
      if (participant.microphoneMuted) {
        await _apiService.unmuteParticipant(widget.liveClass.id, userId);
      } else {
        await _apiService.muteParticipant(widget.liveClass.id, userId);
      }
      await _refreshParticipants();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الميكروفون: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _pendingMicActions.remove(userId));
      }
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h == '00' ? '$m:$s' : '$h:$m:$s';
  }

  Future<void> _leaveRoom() async {
    await _roomService.disconnect();
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _roomService.disconnect();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(kBackgroundColor),
        appBar: AppBar(
          backgroundColor: const Color(kSurfaceColor),
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.liveClass.title,
                style: const TextStyle(fontSize: 15),
              ),
              if (_roomService.isConnected)
                Text(
                  '🔴 جارية الآن  ${_formatDuration(_elapsed)}',
                  style: const TextStyle(fontSize: 11, color: Color(kSuccessColor)),
                ),
            ],
          ),
          // No custom `leading`: the AppBar's automatic back button already
          // calls Navigator.maybePop(), which the PopScope above intercepts -
          // and it renders the correctly RTL-mirrored arrow automatically.
        ),
        body: _buildBody(),
        bottomNavigationBar: _roomService.isConnected ? _buildControls() : null,
      ),
    );
  }

  Widget _buildBody() {
    if (_isConnecting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text('جارٍ الاتصال بجلسة الصوت...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (_connectError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Color(kDangerColor)),
              const SizedBox(height: 16),
              const Text(
                'تعذّر الانضمام إلى الجلسة',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _connectError!,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() { _isConnecting = true; _connectError = null; });
                  _connect();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    // Room connectée
    return Column(
      children: [
        // Info room
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: const Color(kSurfaceColor),
          child: Row(
            children: [
              const Icon(Icons.meeting_room, color: Colors.white54, size: 16),
              const SizedBox(width: 8),
              Text(
                widget.joinResponse.roomName,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),

        if (_isTeacher)
          ParticipantsPanel(
            participants: _participants,
            errorMessage: _participantsError,
            pendingMicActions: _pendingMicActions,
            onToggleMic: _toggleParticipantMic,
          ),

        // Participants
        Expanded(
          child: _ParticipantsGrid(
            localUser: widget.currentUser,
            localMicEnabled: _roomService.isMicEnabled,
            remoteParticipants: _roomService.participants,
          ),
        ),
      ],
    );
  }

  Widget _buildControls() => Container(
        padding: const EdgeInsets.all(20),
        color: const Color(kSurfaceColor),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // كتم/تفعيل الميكروفون
            _ControlButton(
              icon: _roomService.isForceMuted
                  ? Icons.mic_off
                  : (_roomService.isMicEnabled ? Icons.mic : Icons.mic_off),
              label: _roomService.isForceMuted
                  ? 'كتمه المعلم'
                  : (_roomService.isMicEnabled ? 'الميكروفون يعمل' : 'الميكروفون مغلق'),
              color: _roomService.isForceMuted
                  ? Colors.grey
                  : (_roomService.isMicEnabled
                      ? const Color(kSuccessColor)
                      : const Color(kDangerColor)),
              onPressed: _roomService.isForceMuted
                  ? () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'قام المعلم بكتم ميكروفونك، ولا يمكن إعادة تفعيله محليًا.'),
                        ),
                      )
                  : () => _roomService.toggleMic(),
            ),
            // مغادرة
            _ControlButton(
              icon: Icons.call_end,
              label: 'مغادرة',
              color: const Color(kDangerColor),
              onPressed: _leaveRoom,
            ),
          ],
        ),
      );

  @override
  void dispose() {
    _participantsPollTimer?.cancel();
    _roomService.onParticipantsChanged = null;
    _roomService.removeListener(_onRoomUpdate);
    _roomService.dispose();
    super.dispose();
  }
}

// ─── Participants Grid ─────────────────────────────────────────
class _ParticipantsGrid extends StatelessWidget {
  final UserModel localUser;
  final bool localMicEnabled;
  final List<RemoteParticipant> remoteParticipants;

  const _ParticipantsGrid({
    required this.localUser,
    required this.localMicEnabled,
    required this.remoteParticipants,
  });

  @override
  Widget build(BuildContext context) {
    final all = <Widget>[
      _ParticipantTile(
        name: '${localUser.name} (أنا)',
        isLocal: true,
        isSpeaking: false,
        micEnabled: localMicEnabled,
      ),
      ...remoteParticipants.map(
        (p) => _ParticipantTile(
          name: p.name.isNotEmpty ? p.name : p.identity,
          isLocal: false,
          isSpeaking: p.isSpeaking,
          micEnabled: !(p.isMuted),
        ),
      ),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: all.length <= 2 ? 1 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: all.length,
      itemBuilder: (_, i) => all[i],
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final String name;
  final bool isLocal;
  final bool isSpeaking;
  final bool micEnabled;

  const _ParticipantTile({
    required this.name,
    required this.isLocal,
    required this.isSpeaking,
    required this.micEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: const Color(kSurfaceVariantColor),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSpeaking
              ? const Color(kSuccessColor)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar avec animation speaking
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSpeaking ? 72 : 64,
                height: isSpeaking ? 72 : 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLocal
                      ? const Color(kPrimaryColor)
                      : const Color(kAccentColor),
                  boxShadow: isSpeaking
                      ? [BoxShadow(
                          color: const Color(kSuccessColor).withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 4,
                        )]
                      : [],
                ),
                child: Center(
                  child: Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Icône micro
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(kSurfaceColor),
                ),
                child: Icon(
                  micEnabled ? Icons.mic : Icons.mic_off,
                  size: 14,
                  color: micEnabled
                      ? const Color(kSuccessColor)
                      : const Color(kDangerColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (isSpeaking) ...[
            const SizedBox(height: 4),
            const Text(
              '🎙 يتحدث الآن...',
              style: TextStyle(color: Color(kSuccessColor), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Control Button ────────────────────────────────────────────
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onPressed,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      );
}
