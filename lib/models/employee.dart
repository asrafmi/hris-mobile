class Employee {
  final String id;
  final String userId;
  final String employeeId;
  final String fullName;
  final String email;
  final String? phone;
  final String position;
  final String department;
  final String role;
  final String? avatarUrl;
  final String hireDate;
  final bool isActive;

  const Employee({
    required this.id,
    required this.userId,
    required this.employeeId,
    required this.fullName,
    required this.email,
    this.phone,
    required this.position,
    required this.department,
    required this.role,
    this.avatarUrl,
    required this.hireDate,
    required this.isActive,
  });

  bool get isAdmin => role == 'admin';

  String get positionLabel {
    const labels = {
      'staff': 'Staff',
      'supervisor': 'Supervisor',
      'manager': 'Manager',
      'director': 'Director',
    };
    return labels[position] ?? position;
  }

  String get departmentLabel {
    const labels = {
      'hr': 'HR',
      'finance': 'Finance',
      'it': 'IT',
      'marketing': 'Marketing',
      'operations': 'Operations',
    };
    return labels[department] ?? department;
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      employeeId: json['employee_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      position: json['position'] as String,
      department: json['department'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatar_url'] as String?,
      hireDate: json['hire_date'] as String,
      isActive: json['is_active'] as bool,
    );
  }
}
