class Attendance {
  final String id;
  final String employeeId;
  final String workDate;
  final String? clockIn;
  final String? clockOut;
  final String? status;
  final String? notes;

  const Attendance({
    required this.id,
    required this.employeeId,
    required this.workDate,
    this.clockIn,
    this.clockOut,
    this.status,
    this.notes,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      workDate: json['work_date'] as String,
      clockIn: json['clock_in'] as String?,
      clockOut: json['clock_out'] as String?,
      status: json['status'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
