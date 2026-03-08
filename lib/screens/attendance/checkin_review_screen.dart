import 'package:flutter/material.dart';

class CheckinReviewScreen extends StatefulWidget {
  const CheckinReviewScreen({super.key});

  @override
  State<CheckinReviewScreen> createState() => _CheckinReviewScreenState();
}

class _CheckinReviewScreenState extends State<CheckinReviewScreen> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    // Show success bottom sheet
    await _showSuccessSheet();
  }

  Future<void> _showSuccessSheet() async {
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SuccessSheet(
        onGoHome: () {
          // Close sheet and pop back to dashboard
          Navigator.of(ctx).pop();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }

  String _getLocationText() {
    final now = DateTime.now();
    final d = now.day.toString().padLeft(2, '0');
    final mo = now.month.toString().padLeft(2, '0');
    final y = now.year.toString().substring(2);
    final h = now.hour.toString().padLeft(2, '0');
    final mi = now.minute.toString().padLeft(2, '0');
    return '$d/$mo/$y $h:$mi GMT +07:00';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Header
          _ReviewHeader(onBack: () => Navigator.pop(context)),
          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo preview card
                  _PhotoPreviewCard(
                    locationText: _getLocationText(),
                    onRetake: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 12),
                  // Notes field
                  _NotesField(controller: _notesController),
                  // Extra padding for button
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom button
      bottomNavigationBar: _ReviewBottomButton(onCheckIn: _handleCheckIn),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _ReviewHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _ReviewHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F4F7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 14,
                        color: Color(0xFF344054),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Foto Selfie Check In',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2F4F7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.my_location,
                      size: 16,
                      color: Color(0xFF344054),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEAECF0)),
          ],
        ),
      ),
    );
  }
}

// ─── Photo Preview Card ───────────────────────────────────────────────────────

class _PhotoPreviewCard extends StatelessWidget {
  final String locationText;
  final VoidCallback onRetake;

  const _PhotoPreviewCard({
    required this.locationText,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 440,
        width: double.infinity,
        child: Stack(
          children: [
            // Photo placeholder background
            Container(
              color: const Color(0xFF2A2A2A),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                  ),
                ),
              ),
            ),
            // Location info overlay (bottom left)
            Positioned(
              left: 16,
              bottom: 78,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lat : Mendeteksi...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Long : Mendeteksi...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    locationText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // "Ulang Foto" button (centered at bottom of photo)
            Positioned(
              bottom: 12,
              left: 24,
              right: 24,
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: onRetake,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007EE9),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.switch_camera_outlined, size: 20),
                  label: const Text(
                    'Ulang Foto Absensi',
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
      ),
    );
  }
}

// ─── Notes Field ──────────────────────────────────────────────────────────────

class _NotesField extends StatelessWidget {
  final TextEditingController controller;
  const _NotesField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catatan (Opsional)',
          style: TextStyle(fontSize: 12, color: Color(0xFF475467)),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF98A2B3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0x0D101828),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Tuliskan Catatan Anda',
              hintStyle: TextStyle(
                color: Color(0xFF98A2B3),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Bottom Button ────────────────────────────────────────────────────────────

class _ReviewBottomButton extends StatelessWidget {
  final VoidCallback onCheckIn;
  const _ReviewBottomButton({required this.onCheckIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 26),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: onCheckIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007EE9),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.event_available_outlined, size: 20),
            label: const Text(
              'Check In Absensi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Success Bottom Sheet ─────────────────────────────────────────────────────

class _SuccessSheet extends StatelessWidget {
  final VoidCallback onGoHome;
  const _SuccessSheet({required this.onGoHome});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // White sheet
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(31, 85, 31, 32),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Check In Berhasil!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Anda sudah siap! Check-In Anda berhasil. Pergi ke Beranda Anda untuk melihat tugas yang ditugaskan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF475467),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onGoHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007EE9),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Pergi ke Halaman Check In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Floating blue icon badge
        Positioned(
          top: -53,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect
              Container(
                width: 58,
                height: 11,
                decoration: BoxDecoration(
                  color: const Color(0xFF007EE9),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF007EE9),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Blue square badge
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF007EE9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF54A9F0),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
