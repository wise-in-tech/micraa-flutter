import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

class LiveClassRoomService extends ChangeNotifier {
  Room? _room;
  bool _isConnected = false;
  bool _isMicEnabled = true;
  String? _error;
  final List<RemoteParticipant> _participants = [];

  Room? get room => _room;
  bool get isConnected => _isConnected;
  bool get isMicEnabled => _isMicEnabled;
  String? get error => _error;
  List<RemoteParticipant> get participants => List.unmodifiable(_participants);
  LocalParticipant? get localParticipant => _room?.localParticipant;

  Future<void> connect(String url, String token) async {
    try {
      _error = null;
      _room = Room();

      // Écouter les événements de la room
      _room!.addListener(_onRoomUpdate);

      final opts = RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultAudioPublishOptions: const AudioPublishOptions(
          name: 'microphone',
        ),
      );

      await _room!.connect(url, token, roomOptions: opts);
      await _room!.localParticipant?.setMicrophoneEnabled(true);

      _isConnected = true;
      _isMicEnabled = true;
      _syncParticipants();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isConnected = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleMic() async {
    if (_room?.localParticipant == null) return;
    _isMicEnabled = !_isMicEnabled;
    await _room!.localParticipant!.setMicrophoneEnabled(_isMicEnabled);
    notifyListeners();
  }

  Future<void> disconnect() async {
    if (_room != null) {
      _room!.removeListener(_onRoomUpdate);
      await _room!.disconnect();
      _room!.dispose();
      _room = null;
    }
    _isConnected = false;
    _participants.clear();
    if (hasListeners) notifyListeners();
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
