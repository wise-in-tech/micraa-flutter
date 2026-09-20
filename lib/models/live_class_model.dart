class LiveClassModel {
  final int id;
  final String title;
  final int teacherId;
  final String teacherName;
  final String status; // SCHEDULED | LIVE | ENDED
  final String? scheduledAt;
  final String? startedAt;
  final String? endedAt;

  const LiveClassModel({
    required this.id,
    required this.title,
    required this.teacherId,
    required this.teacherName,
    required this.status,
    this.scheduledAt,
    this.startedAt,
    this.endedAt,
  });

  factory LiveClassModel.fromJson(Map<String, dynamic> json) => LiveClassModel(
        id: json['id'] as int,
        title: json['title'] as String,
        teacherId: json['teacherId'] as int,
        teacherName: json['teacherName'] as String? ?? '',
        status: json['status'] as String,
        scheduledAt: json['scheduledAt'] as String?,
        startedAt: json['startedAt'] as String?,
        endedAt: json['endedAt'] as String?,
      );

  bool get isLive => status == 'LIVE';
  bool get isScheduled => status == 'SCHEDULED';
  bool get isEnded => status == 'ENDED';
}
