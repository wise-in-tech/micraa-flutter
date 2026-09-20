class JoinClassResponse {
  final String livekitUrl;
  final String accessToken;
  final String roomName;

  const JoinClassResponse({
    required this.livekitUrl,
    required this.accessToken,
    required this.roomName,
  });

  factory JoinClassResponse.fromJson(Map<String, dynamic> json) =>
      JoinClassResponse(
        livekitUrl: json['livekitUrl'] as String,
        accessToken: json['accessToken'] as String,
        roomName: json['roomName'] as String,
      );
}
