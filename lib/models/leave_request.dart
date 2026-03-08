class LeaveRequest {
  final String id;
  final String employeeId;
  final String leaveType;
  final String startDate;
  final String endDate;
  final String? approverId;
  final String? reason;
  final String status;
  final String? rejectionReason;
  final String createdAt;
  final String updatedAt;
  final String? approverName;

  const LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    this.approverId,
    this.reason,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.approverName,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    String? approverName;
    final approver = json['approver'];
    if (approver is Map<String, dynamic>) {
      approverName = approver['full_name'] as String?;
    }
    return LeaveRequest(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      leaveType: json['leave_type'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      approverId: json['approver_id'] as String?,
      reason: json['reason'] as String?,
      status: json['status'] as String,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      approverName: approverName,
    );
  }

  int get totalDays {
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      return end.difference(start).inDays + 1;
    } catch (_) {
      return 0;
    }
  }

  String get statusLabel {
    const labels = {
      'pending': 'Sedang Ditinjau',
      'approved': 'Disetujui',
      'rejected': 'Ditolak',
    };
    return labels[status] ?? status;
  }

  String get leaveTypeLabel {
    const labels = {
      'tahunan': 'Cuti Tahunan',
      'tidak_berbayar': 'Cuti Tidak Berbayar',
      'sakit': 'Cuti Sakit',
      'menikah': 'Cuti Menikah',
      'melahirkan': 'Cuti Melahirkan',
      'lainnya': 'Lainnya',
    };
    return labels[leaveType] ?? leaveType;
  }
}
