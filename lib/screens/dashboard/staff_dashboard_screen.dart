import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/employee.dart';
import '../../models/attendance.dart';
import '../../models/leave_request.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../services/leave_service.dart';
import '../attendance/attendance_list_screen.dart';
import '../attendance/checkout_sheets.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  int _selectedIndex = 0;
  int _homeRefreshToken = 0;

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah kamu yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employee = ModalRoute.of(context)!.settings.arguments as Employee;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(employee: employee, refreshToken: _homeRefreshToken),
          AttendanceListScreen(employee: employee),
          _PlaceholderTab(
            label: 'Reimburs',
            icon: Icons.receipt_long_outlined,
          ),
          _PlaceholderTab(
            label: 'Cuti',
            icon: Icons.timelapse_outlined,
          ),
          _ProfileTab(employee: employee, onLogout: _handleLogout),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF007EE9),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.grid_view_rounded,
                isActive: _selectedIndex == 0,
                onTap: () => setState(() {
                  if (_selectedIndex != 0) _homeRefreshToken++;
                  _selectedIndex = 0;
                }),
              ),
              _NavItem(
                icon: Icons.event_available_outlined,
                isActive: _selectedIndex == 1,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                isActive: _selectedIndex == 2,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              _NavItem(
                icon: Icons.timelapse_outlined,
                isActive: _selectedIndex == 3,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
              _NavItem(
                icon: Icons.person_outline,
                isActive: _selectedIndex == 4,
                onTap: () => setState(() => _selectedIndex = 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Nav Item ───────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Container(
              width: 12,
              height: 2,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  final Employee employee;
  final int refreshToken;

  const _HomeTab({required this.employee, this.refreshToken = 0});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  Attendance? _attendance;
  List<LeaveRequest> _leaveRequests = [];
  bool _isLoading = true;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(_HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        AttendanceService.getTodayAttendance(widget.employee.id),
        LeaveService.getMyLeaveRequests(widget.employee.id),
      ]);
      if (mounted) {
        setState(() {
          _attendance = results[0] as Attendance?;
          _leaveRequests = results[1] as List<LeaveRequest>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAttendanceAction() async {
    if (_attendance?.clockIn == null) {
      // Navigate to the full check-in flow
      await Navigator.pushNamed(
        context,
        '/checkin/location',
        arguments: widget.employee,
      );
      // Reload attendance data when returning from check-in flow
      _loadData();
    } else if (_attendance?.clockOut == null) {
      final todayHours = _calcTodayHours();
      await showCheckoutConfirmSheet(
        context,
        todayHours: todayHours,
        onConfirm: () async {
          Navigator.pop(context);
          setState(() => _isActionLoading = true);
          try {
            final result = await AttendanceService.clockOut(_attendance!.id);
            if (mounted) setState(() => _attendance = result);
            if (mounted) {
              await showCheckoutSuccessSheet(
                context,
                onClose: () {
                  Navigator.pop(context);
                  _loadData();
                },
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString().replaceFirst('Exception: ', '')),
                  backgroundColor: Colors.red.shade600,
                ),
              );
            }
          } finally {
            if (mounted) setState(() => _isActionLoading = false);
          }
        },
      );
    }
  }

  String _calcTodayHours() {
    final att = _attendance;
    if (att == null || att.clockIn == null) return '00:00';
    final start = DateTime.parse(att.clockIn!).toLocal();
    final end =
        att.clockOut != null
            ? DateTime.parse(att.clockOut!).toLocal()
            : DateTime.now();
    final diff = end.difference(start);
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '--:--';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--:--';
    }
  }

  String _getButtonLabel() {
    if (_attendance?.clockIn == null) return 'Check In Absensi';
    if (_attendance?.clockOut == null) return 'Check Out Absensi';
    return 'Sudah Absen Hari Ini';
  }

  bool _isAbsenceDone() => _attendance?.clockOut != null;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // Dark gradient header background
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: topPadding + 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1C1C2E), Color(0xFF141414)],
              ),
            ),
          ),
        ),
        // Scrollable content
        SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: const Color(0xFF007EE9),
            child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 19),
                  child: _buildProfileRow(),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 19),
                  child: _buildAttendanceCard(),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 19),
                  child: _buildQuickActions(),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 19),
                  child: _buildActivitySection(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileRow() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              widget.employee.fullName.isNotEmpty
                  ? widget.employee.fullName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.employee.positionLabel,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                widget.employee.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: Color(0xFF101828),
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Column(
              children: [
                const Text(
                  'Absensi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF09090B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Shift Kerja: 08:00 - 17:00',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // Clock In / Clock Out
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeColumn(
                  'Clock In',
                  _formatTime(_attendance?.clockIn),
                ),
                const SizedBox(width: 36),
                _buildTimeColumn(
                  'Clock Out',
                  _formatTime(_attendance?.clockOut),
                ),
              ],
            ),
          ),
          // Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed:
                    _isActionLoading || _isAbsenceDone()
                        ? null
                        : _handleAttendanceAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isAbsenceDone()
                          ? Colors.grey.shade300
                          : const Color(0xFF007EE9),
                  disabledBackgroundColor:
                      _isAbsenceDone() ? Colors.grey.shade200 : null,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.grey.shade500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child:
                    _isActionLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          _getButtonLabel(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, String time) {
    return Column(
      children: [
        Text(
          time,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: Color(0xFF09090B),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Color(0xFF09090B)),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    const actions = [
      _QuickActionData(
        icon: Icons.event_available_outlined,
        label: 'Absensi',
        color: Color(0xFF007EE9),
      ),
      _QuickActionData(
        icon: Icons.receipt_long_outlined,
        label: 'Reimburs',
        color: Color(0xFF007EE9),
      ),
      _QuickActionData(
        icon: Icons.timelapse_outlined,
        label: 'Cuti',
        color: Color(0xFFFF8744),
      ),
      _QuickActionData(
        icon: Icons.monetization_on_outlined,
        label: 'Slip Gaji',
        color: Color(0xFFE4BA13),
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          actions.map((a) => _buildQuickActionItem(a.icon, a.label, a.color)).toList(),
    );
  }

  Widget _buildQuickActionItem(IconData icon, String label, Color color) {
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF09090B)),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection() {
    final pendingCount =
        _leaveRequests.where((r) => r.status == 'pending').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pembaharuan Aktivitas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        _buildLeaveActivityCard(pendingCount),
      ],
    );
  }

  Widget _buildLeaveActivityCard(int pendingCount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header
            Row(
              children: [
                const Text(
                  'Pembaharuan Cuti Terbaru',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF101828),
                  ),
                ),
                const SizedBox(width: 4),
                if (pendingCount > 0)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE6F2FD),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF007EE9),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'Detail pembaharuan pengajuan cuti',
              style: TextStyle(fontSize: 12, color: Color(0xFF475467)),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFF007EE9)),
                ),
              )
            else if (_leaveRequests.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEAECF0)),
                ),
                child: const Center(
                  child: Text(
                    'Belum ada pengajuan cuti',
                    style: TextStyle(fontSize: 14, color: Color(0xFF475467)),
                  ),
                ),
              )
            else
              Column(
                children:
                    _leaveRequests
                        .map(
                          (leave) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildLeaveItemCard(leave),
                          ),
                        )
                        .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveItemCard(LeaveRequest leave) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date row
          Row(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                size: 20,
                color: Color(0xFF007EE9),
              ),
              const SizedBox(width: 4),
              Text(
                _formatDisplayDate(leave.createdAt),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF101828),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEAECF0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tanggal Pengajuan Cuti',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF667085),
                        ),
                      ),
                      Text(
                        _formatDateRange(leave.startDate, leave.endDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF344054),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Cuti',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF667085),
                        ),
                      ),
                      Text(
                        '${leave.totalDays} Hari',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF344054),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Status + Approver
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      _statusIcon(leave.status),
                      size: 16,
                      color: _statusColor(leave.status),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      leave.statusLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ],
                ),
              ),
              if (leave.approverName != null) ...[
                const Text(
                  'Oleh ',
                  style: TextStyle(fontSize: 12, color: Color(0xFF101828)),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF007EE9).withValues(alpha: 0.15),
                    border: Border.all(color: Colors.white, width: 0.75),
                  ),
                  child: Center(
                    child: Text(
                      leave.approverName![0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007EE9),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  leave.approverName!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF101828),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.timelapse_outlined;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return const Color(0xFF007EE9);
    }
  }

  String _formatDisplayDate(String isoString) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoString;
    }
  }

  String _formatDateRange(String start, String end) {
    const short = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      return '${s.day} ${short[s.month - 1]} - ${e.day} ${short[e.month - 1]}';
    } catch (_) {
      return '$start - $end';
    }
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.color,
  });
}

// ─── Placeholder Tab ───────────────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  final String label;
  final IconData icon;

  const _PlaceholderTab({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fitur ini akan segera tersedia',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  final Employee employee;
  final VoidCallback onLogout;

  const _ProfileTab({required this.employee, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profil',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      employee.fullName.isNotEmpty
                          ? employee.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    employee.fullName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${employee.positionLabel} · ${employee.departmentLabel}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Staff',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _ProfileItem(label: 'ID Karyawan', value: employee.employeeId),
            _ProfileItem(label: 'Email', value: employee.email),
            if (employee.phone != null)
              _ProfileItem(label: 'Telepon', value: employee.phone!),
            _ProfileItem(label: 'Departemen', value: employee.departmentLabel),
            _ProfileItem(label: 'Jabatan', value: employee.positionLabel),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Keluar',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.secondary),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
