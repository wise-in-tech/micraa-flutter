import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class LiveClassRoomService extends ChangeNotifier {
  Room? _room;
  EventsListener<RoomEvent>? _roomEvents;
  bool _isConnected = false;
  bool _isMicEnabled = true;
  // True while the teacher has force-muted this participant's microphone via
  // LiveKit's server-side track control. Distinct from `_isMicEnabled` (the
  // student's own local mic preference): a server-forced mute always wins, and
  // the student cannot clear it by toggling their own mic.
  bool _forceMuted = false;
  String? _error;
  final List<RemoteParticipant> _participants = [];

  /// Invoked when a remote participant connects or disconnects, so the UI can
  /// refresh the backend-provided (ordered, authorized) participant list
  /// without waiting for its next periodic poll.
  VoidCallback? onParticipantsChanged;

  Room? get room => _room;
  bool get isConnected => _isConnected;
  bool get isMicEnabled => _isMicEnabled;
  bool get isForceMuted => _forceMuted;
  String? get error => _error;
  List<RemoteParticipant> get participants => List.unmodifiable(_participants);
  LocalParticipant? get localParticipant => _room?.localParticipant;

  Future<void> connect(String url, String token) async {
    try {
      _error = null;
      _room = Room();

      // Écouter les événements de la room
      _room!.addListener(_onRoomUpdate);
      _roomEvents = _room!.createListener();
      _roomEvents!
        ..on<TrackMutedEvent>(_onTrackMuted)
        ..on<TrackUnmutedEvent>(_onTrackUnmuted)
        ..on<ParticipantConnectedEvent>((_) => onParticipantsChanged?.call())
        ..on<ParticipantDisconnectedEvent>((_) => onParticipantsChanged?.call());

      final opts = RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultAudioPublishOptions: const AudioPublishOptions(
          name: 'microphone',
        ),
      );

      debugPrint('[LiveClassRoomService] connecting to room at $url ...');
      await _room!.connect(url, token, roomOptions: opts);
      debugPrint('[LiveClassRoomService] room connected, enabling microphone ...');

      await _room!.localParticipant?.setMicrophoneEnabled(true);
      debugPrint('[LiveClassRoomService] microphone published');

      _isConnected = true;
      _isMicEnabled = true;
      _forceMuted = false;
      _syncParticipants();
      // Keep the phone screen on for the duration of the live session. Only
      // enabled once the connection actually succeeds, so a failed connection
      // never leaves the wakelock on. Best-effort: a wakelock hiccup must
      // never be mistaken for (or block) the LiveKit connection itself.
      try {
        await WakelockPlus.enable();
      } catch (e) {
        debugPrint('[LiveClassRoomService] wakelock enable failed (non-fatal): $e');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[LiveClassRoomService] connect() failed: $e');
      _error = e.toString();
      _isConnected = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleMic() async {
    if (_room?.localParticipant == null) return;
    if (_forceMuted) {
      // The teacher has server-muted this microphone: the student cannot
      // override it from the local UI. The button reflects this instead of
      // silently no-op'ing (see LiveRoomScreen).
      return;
    }
    _isMicEnabled = !_isMicEnabled;
    await _room!.localParticipant!.setMicrophoneEnabled(_isMicEnabled);
    notifyListeners();
  }

  Future<void> disconnect() async {
    if (_room != null) {
      await _roomEvents?.dispose();
      _roomEvents = null;
      _room!.removeListener(_onRoomUpdate);
      await _room!.disconnect();
      _room!.dispose();
      _room = null;
    }
    _isConnected = false;
    _forceMuted = false;
    _participants.clear();
    // Always release the wakelock on disconnect, whether the room ends
    // cleanly, the user leaves, or disposal forces a cleanup - redundant
    // calls are a documented no-op in wakelock_plus. Best-effort: must never
    // throw and block leaving the room.
    try {
      await WakelockPlus.disable();
    } catch (e) {
      debugPrint('[LiveClassRoomService] wakelock disable failed (non-fatal): $e');
    }
    if (hasListeners) notifyListeners();
  }

  void _onTrackMuted(TrackMutedEvent event) {
    if (event.participant is LocalParticipant && event.publication.kind == TrackType.AUDIO) {
      applyForceMuteState(true);
    }
  }

  void _onTrackUnmuted(TrackUnmutedEvent event) {
    if (event.participant is LocalParticipant && event.publication.kind == TrackType.AUDIO) {
      applyForceMuteState(false);
    }
  }

  /// Applies a teacher-forced mute/unmute of the local microphone. Split out from the
  /// LiveKit event handlers above so the state transition itself (and `toggleMic`'s
  /// refusal to override it) can be unit-tested without a live Room/connection.
  @visibleForTesting
  void applyForceMuteState(bool muted) {
    _forceMuted = muted;
    _isMicEnabled = !muted;
    notifyListeners();
  }

  void _onRoomUpdate() {
    _syncParticipants();
    notifyListeners();
  }

  void _syncParticipants() {
    _participants.clear();
    _participants.addAll(_room?.remoteParticipants.values ?? []);
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
