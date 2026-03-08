import 'package:flutter/material.dart';
import '../../models/attendance.dart';
import '../../models/attendance_break.dart';
import '../../models/employee.dart';
import '../../services/attendance_service.dart';
import 'checkout_sheets.dart';

class AttendanceListScreen extends StatefulWidget {
  final Employee employee;

  const AttendanceListScreen({super.key, required this.employee});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  Attendance? _todayAttendance;
  AttendanceBreak? _activeBreak;
  List<Attendance> _history = [];
  List<Attendance> _monthlyHistory = [];
  bool _isLoading = true;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final today = await AttendanceService.getTodayAttendance(
        widget.employee.id,
      );
      AttendanceBreak? activeBreak;
      if (today != null && today.clockOut == null) {
        activeBreak = await AttendanceService.getActiveBreak(today.id);
      }
      final results = await Future.wait([
        AttendanceService.getAttendanceHistory(widget.employee.id),
        AttendanceService.getMonthlyAttendance(widget.employee.id),
      ]);
      if (mounted) {
        setState(() {
          _todayAttendance = today;
          _activeBreak = activeBreak;
          _history = results[0];
          _monthlyHistory = results[1];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBreakToggle() async {
    if (_todayAttendance == null) return;
    setState(() => _isActionLoading = true);
    try {
      if (_activeBreak != null) {
        await AttendanceService.endBreak(_activeBreak!.id);
      } else {
        await AttendanceService.startBreak(_todayAttendance!.id);
      }
      await _loadData();
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
  }

  void _showCheckoutConfirmation() {
    showCheckoutConfirmSheet(
      context,
      todayHours: _calcTodayHours(),
      onConfirm: _handleCheckout,
    );
  }

  Future<void> _handleCheckout() async {
    if (_todayAttendance == null) return;
    Navigator.pop(context);
    setState(() => _isActionLoading = true);
    try {
      await AttendanceService.clockOut(_todayAttendance!.id);
      if (mounted) {
        await showCheckoutSuccessSheet(
          context,
          onClose: () => Navigator.pop(context),
        );
        await _loadData();
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
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fmt(String? iso) {
    if (iso == null) return '--:--';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--:--';
    }
  }

  String _calcTodayHours() {
    final att = _todayAttendance;
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

  String _calcPeriodHours() {
    int totalMinutes = 0;
    for (final att in _monthlyHistory) {
      if (att.clockIn == null || att.clockOut == null) continue;
      final start = DateTime.parse(att.clockIn!);
      final end = DateTime.parse(att.clockOut!);
      totalMinutes += end.difference(start).inMinutes;
    }
    final h = totalMinutes ~/ 60;
    final m = totalMinutes.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String _calcAttHours(Attendance att) {
    if (att.clockIn == null || att.clockOut == null) return '--:--:--';
    final start = DateTime.parse(att.clockIn!);
    final end = DateTime.parse(att.clockOut!);
    final diff = end.difference(start);
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    final s = diff.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _fmtDate(String workDate) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    try {
      final dt = DateTime.parse(workDate);
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return workDate;
    }
  }

  String _periodLabel() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final now = DateTime.now();
    final last = DateTime(now.year, now.month + 1, 0);
    return 'Periode 1 ${months[now.month - 1]} ${now.year} - ${last.day} ${months[now.month - 1]} ${now.year}';
  }

  bool get _canCheckout =>
      _todayAttendance?.clockIn != null &&
      _todayAttendance?.clockOut == null &&
      _activeBreak == null;

  bool get _canBreak =>
      _todayAttendance?.clockIn != null && _todayAttendance?.clockOut == null;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: MediaQuery.of(context).padding.top + 180,
            color: const Color(0xFF007EE9),
          ),
        ),
        SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: const Color(0xFF007EE9),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _buildActionCard(),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(
                                color: Color(0xFF007EE9),
                              ),
                            ),
                          )
                        : _buildHistoryList(),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ayo Masuk Kerja!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Jangan lewatkan jadwal masuk kerja Anda',
            style: TextStyle(fontSize: 12, color: Color(0xFFD9D6FE)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionCard() {
    final bool isOnBreak = _activeBreak != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 25,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Total Jam Kerja',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _periodLabel(),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF475467),
              ),
            ),
            const SizedBox(height: 12),
            // Stats row
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    label: 'Hari Ini',
                    value: '${_calcTodayHours()} Jam',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatBox(
                    label: 'Periode Ini',
                    value: '${_calcPeriodHours()} Jam',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: _isActionLoading
                      ? const SizedBox(
                          height: 44,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF007EE9),
                              ),
                            ),
                          ),
                        )
                      : _canBreak
                          ? isOnBreak
                              ? _buildBreakButton(
                                  label: 'Kembali Kerja',
                                  color: const Color(0xFFEF4444),
                                  bgColor: const Color(0xFFFDECEC),
                                  borderColor: const Color(0xFFEF4444),
                                  onTap: _handleBreakToggle,
                                )
                              : _buildBreakButton(
                                  label: 'Ambil Istirahat',
                                  color: const Color(0xFF007EE9),
                                  bgColor: Colors.transparent,
                                  borderColor: const Color(0xFF007EE9),
                                  onTap: _handleBreakToggle,
                                )
                          : _buildBreakButton(
                              label: 'Ambil Istirahat',
                              color: const Color(0xFF007EE9),
                              bgColor: Colors.transparent,
                              borderColor: const Color(0xFF007EE9),
                              onTap: null,
                            ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _canCheckout && !_isActionLoading
                          ? _showCheckoutConfirmation
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007EE9),
                        disabledBackgroundColor: const Color(0xFF007EE9)
                            .withValues(alpha: 0.5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Check Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({required String label, required String value}) {
    return Container(
      height: 72,
      padding: const EdgeInsets.fromLTRB(11, 11, 11, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEBECEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Color(0xFF475467),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475467),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF161B23),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakButton({
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: color,
          side: BorderSide(color: onTap != null ? borderColor : borderColor.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: onTap != null ? color : color.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    // Filter out today from history display
    final today = DateTime.now().toIso8601String().split('T')[0];
    final pastHistory = _history.where((a) => a.workDate != today).toList();

    if (pastHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Belum ada riwayat absensi',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ),
      );
    }

    return Column(
      children: pastHistory.map((att) => _buildHistoryItem(att)).toList(),
    );
  }

  Widget _buildHistoryItem(Attendance att) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Color(0xFF007EE9),
              ),
              const SizedBox(width: 4),
              Text(
                _fmtDate(att.workDate),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF101828),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAECF0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Jam',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475467),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_calcAttHours(att)} jam',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF344054),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Check In & Check Out',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475467),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_fmt(att.clockIn)}  —  ${_fmt(att.clockOut)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF344054),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


