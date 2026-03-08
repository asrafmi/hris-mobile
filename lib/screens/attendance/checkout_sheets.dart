import 'package:flutter/material.dart';

// ── Public helpers to show checkout sheets ────────────────────────────────────

Future<void> showCheckoutConfirmSheet(
  BuildContext context, {
  required String todayHours,
  required VoidCallback onConfirm,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    clipBehavior: Clip.none,
    builder: (_) => CheckoutConfirmSheet(
      todayHours: todayHours,
      onConfirm: onConfirm,
    ),
  );
}

Future<void> showCheckoutSuccessSheet(
  BuildContext context, {
  required VoidCallback onClose,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    clipBehavior: Clip.none,
    isDismissible: false,
    builder: (_) => CheckoutSuccessSheet(onClose: onClose),
  );
}

// ── Confirm Sheet ─────────────────────────────────────────────────────────────

class CheckoutConfirmSheet extends StatelessWidget {
  final String todayHours;
  final VoidCallback onConfirm;

  const CheckoutConfirmSheet({
    super.key,
    required this.todayHours,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return _BottomSheetWithIcon(
      icon: Icons.access_time_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Konfirmasi Check Out',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF101828),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Setelah Anda check out, Anda tidak akan dapat mengedit waktu ini. Harap periksa jam Anda sebelum melanjutkan.',
            style: TextStyle(fontSize: 14, color: Color(0xFF475467)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatBox(label: 'Hari Ini', value: '$todayHours Hrs'),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _StatBox(label: 'Lembur', value: '00:00:00 Hrs'),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007EE9),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Ya, Check Out',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF007EE9),
                side: const BorderSide(color: Color(0xFF007EE9)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Kembali, biar saya periksa',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success Sheet ─────────────────────────────────────────────────────────────

class CheckoutSuccessSheet extends StatelessWidget {
  final VoidCallback onClose;

  const CheckoutSuccessSheet({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return _BottomSheetWithIcon(
      icon: Icons.access_time_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Check Out Berhasil!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF101828),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Anda telah resmi keluar untuk hari ini. Terima kasih atas kerja keras Anda! Saatnya bersantai dan menikmati istirahat Anda.',
            style: TextStyle(fontSize: 14, color: Color(0xFF475467)),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007EE9),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Tutup Pesan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Sheet with Floating Icon ──────────────────────────────────────────

class _BottomSheetWithIcon extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _BottomSheetWithIcon({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          height: screenHeight * 0.5,
          margin: const EdgeInsets.only(top: 50),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.fromLTRB(31, 65, 31, 32),
          child: child,
        ),
        Positioned(
          top: 0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: -6,
                child: Container(
                  width: 58,
                  height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007EE9),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF007EE9).withValues(alpha: 0.6),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF007EE9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF54A9F0)),
                ),
              ),
              Icon(icon, color: Colors.white, size: 48),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Stat Box ──────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
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
                style: const TextStyle(fontSize: 12, color: Color(0xFF475467)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF161B23),
            ),
          ),
        ],
      ),
    );
  }
}
