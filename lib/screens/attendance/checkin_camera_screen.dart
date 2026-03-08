import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/employee.dart';

class CheckinCameraScreen extends StatefulWidget {
  const CheckinCameraScreen({super.key});

  @override
  State<CheckinCameraScreen> createState() => _CheckinCameraScreenState();
}

class _CheckinCameraScreenState extends State<CheckinCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _flashOn = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
      if (mounted) setState(() => _isInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _errorMessage = 'Tidak ada kamera yang tersedia.');
        return;
      }
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _errorMessage = null;
      });
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Gagal membuka kamera.');
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !_isInitialized) return;
    final newFlash = !_flashOn;
    try {
      await controller.setFlashMode(newFlash ? FlashMode.torch : FlashMode.off);
      setState(() => _flashOn = newFlash);
    } catch (_) {}
  }

  Future<void> _capturePhoto(
    Employee employee, {
    double? lat,
    double? lng,
  }) async {
    final controller = _controller;
    if (controller == null || !_isInitialized || _isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      if (_flashOn) await controller.setFlashMode(FlashMode.off);
      final xFile = await controller.takePicture();
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/checkin/review',
          arguments: {
            'employee': employee,
            'imagePath': xFile.path,
            'lat': lat,
            'lng': lng,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final employee = args['employee'] as Employee;
    final lat = args['lat'] as double?;
    final lng = args['lng'] as double?;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera preview ─────────────────────────────────────────────
          if (_isInitialized && _controller != null)
            _CameraPreviewFit(controller: _controller!)
          else
            const SizedBox.shrink(),

          // ── Face oval overlay ──────────────────────────────────────────
          const _FaceOverlay(),

          // ── Loading / error state (above overlay) ─────────────────────
          if (!_isInitialized && _errorMessage == null)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
            ),

          // ── Top bar ────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(
              flashOn: _flashOn,
              onToggleFlash: _toggleFlash,
              onClose: () => Navigator.pop(context),
            ),
          ),

          // ── Bottom controls ────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomControls(
              isCapturing: _isCapturing,
              onCapture: _isInitialized ? () => _capturePhoto(employee, lat: lat, lng: lng) : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Camera Preview (cover fit, mirrors for front camera) ─────────────────────

class _CameraPreviewFit extends StatelessWidget {
  final CameraController controller;
  const _CameraPreviewFit({required this.controller});

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return const SizedBox.shrink();
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          // previewSize width/height are in sensor orientation — swap for portrait
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

// ─── Face Oval Overlay ────────────────────────────────────────────────────────

class _FaceOverlay extends StatelessWidget {
  const _FaceOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          painter: _OvalMaskPainter(),
          child: const SizedBox.expand(),
        ),
        Align(
          alignment: const Alignment(0, 0.32),
          child: Text(
            'Posisikan wajah Anda di sini',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _OvalMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: size.width * 0.68,
      height: size.height * 0.38,
    );

    // Semi-dark overlay with oval cutout
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      overlayPath,
      Paint()
        ..color = const Color(0x66000000)
        ..style = PaintingStyle.fill,
    );

    // Oval border
    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = const Color(0xCCFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool flashOn;
  final VoidCallback onToggleFlash;
  final VoidCallback onClose;

  const _TopBar({
    required this.flashOn,
    required this.onToggleFlash,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1, color: Colors.white12),
            SizedBox(
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Flash toggle (left)
                  Positioned(
                    left: 16,
                    child: GestureDetector(
                      onTap: onToggleFlash,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: flashOn
                                ? Colors.yellow.withValues(alpha: 0.9)
                                : Colors.white.withValues(alpha: 0.6),
                          ),
                          color: flashOn
                              ? Colors.yellow.withValues(alpha: 0.15)
                              : Colors.transparent,
                        ),
                        child: Icon(
                          flashOn ? Icons.flash_on : Icons.flash_off,
                          color: flashOn ? Colors.yellow : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  // Title
                  const Text(
                    'Foto Selfie',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  // Close (right)
                  Positioned(
                    right: 16,
                    child: GestureDetector(
                      onTap: onClose,
                      child: const Icon(Icons.close, color: Colors.white, size: 24),
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

// ─── Bottom Controls ──────────────────────────────────────────────────────────

class _BottomControls extends StatelessWidget {
  final bool isCapturing;
  final VoidCallback? onCapture;

  const _BottomControls({
    required this.isCapturing,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    final ready = onCapture != null && !isCapturing;
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: ready ? onCapture : null,
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ready ? Colors.white : Colors.white38,
                        width: 4,
                      ),
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
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: ready ? Colors.white : Colors.white38,
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
