class AttendanceBreak {
  final String id;
  final String attendanceId;
  final String breakStart;
  final String? breakEnd;

  const AttendanceBreak({
    required this.id,
    required this.attendanceId,
    required this.breakStart,
    this.breakEnd,
  });

  factory AttendanceBreak.fromJson(Map<String, dynamic> json) {
    return AttendanceBreak(
      id: json['id'] as String,
      attendanceId: json['attendance_id'] as String,
      breakStart: json['break_start'] as String,
      breakEnd: json['break_end'] as String?,
    );
  }

  bool get isActive => breakEnd == null;
}
