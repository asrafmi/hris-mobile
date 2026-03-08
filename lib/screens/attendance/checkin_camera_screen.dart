import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/employee.dart';

class CheckinCameraScreen extends StatefulWidget {
  const CheckinCameraScreen({super.key});

  @override
  State<CheckinCameraScreen> createState() => _CheckinCameraScreenState();
}

class _CheckinCameraScreenState extends State<CheckinCameraScreen> {
  bool _isCapturing = false;

  Future<void> _capturePhoto(Employee employee) async {
    setState(() => _isCapturing = true);
    // Simulate capture delay
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/checkin/review',
        arguments: employee,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final employee = ModalRoute.of(context)!.settings.arguments as Employee;

    // Force portrait & dark status bar for camera feel
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera viewfinder placeholder
          _CameraViewfinder(),
          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(onClose: () => Navigator.pop(context)),
          ),
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomControls(
              isCapturing: _isCapturing,
              onCapture: () => _capturePhoto(employee),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Camera Viewfinder ────────────────────────────────────────────────────────

class _CameraViewfinder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2A2A2A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Face outline guide
            Container(
              width: 200,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.face,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Posisikan wajah Anda\ndi sini',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  const _TopBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: ClipRect(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 1, color: Colors.white12),
              SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Flash button (left)
                    Positioned(
                      left: 16,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        child: const Icon(
                          Icons.flash_off,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    // Title
                    const Text(
                      'Camera',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    // Close button (right)
                    Positioned(
                      right: 16,
                      child: GestureDetector(
                        onTap: onClose,
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Controls ──────────────────────────────────────────────────────────

class _BottomControls extends StatelessWidget {
  final bool isCapturing;
  final VoidCallback onCapture;

  const _BottomControls({
    required this.isCapturing,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 2x zoom button
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '2x',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                // Shutter button
                GestureDetector(
                  onTap: isCapturing ? null : onCapture,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: isCapturing
                          ? const SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Container(
                              width: 54,
                              height: 54,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                  ),
                ),
                // Flip camera button
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bolt,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
            // Home indicator bar
            const SizedBox(height: 12),
            Container(
              width: 128,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
