import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/employee.dart';

// Office coordinates & check-in radius — update to real office location
const _officeLatLng = LatLng(-6.2088, 106.8456);
const _checkinRadiusMeters = 200.0;

class CheckinLocationScreen extends StatefulWidget {
  const CheckinLocationScreen({super.key});

  @override
  State<CheckinLocationScreen> createState() => _CheckinLocationScreenState();
}

class _CheckinLocationScreenState extends State<CheckinLocationScreen> {
  final _mapController = MapController();

  Position? _position;
  _LocationState _locationState = _LocationState.loading;
  bool _isInsideZone = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    // Check if location service is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setError('Layanan lokasi tidak aktif. Aktifkan GPS pada pengaturan.');
      return;
    }

    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // This triggers the SYSTEM permission popup
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _setError('Izin lokasi ditolak.');
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      _setError('Izin lokasi ditolak permanen. Aktifkan dari Pengaturan aplikasi.');
      return;
    }

    // Permission granted — get actual position
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      final distanceMeters = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        _officeLatLng.latitude,
        _officeLatLng.longitude,
      );

      setState(() {
        _position = pos;
        _isInsideZone = distanceMeters <= _checkinRadiusMeters;
        _locationState = _LocationState.ready;
      });

      // Move map to user's real location
      _mapController.move(LatLng(pos.latitude, pos.longitude), 16.5);
    } catch (e) {
      _setError('Gagal mendapatkan lokasi. Coba lagi.');
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() => _locationState = _LocationState.error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employee = ModalRoute.of(context)!.settings.arguments as Employee;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _BottomButton(
        label: 'Foto Selfie Check In',
        icon: Icons.camera_alt_outlined,
        onTap: () => Navigator.pushNamed(
          context,
          '/checkin/camera',
          arguments: employee,
        ),
      ),
      body: Column(
        children: [
          _Header(
            onBack: () => Navigator.pop(context),
            onRefresh: _initLocation,
          ),
          Expanded(child: _MapArea(
            mapController: _mapController,
            userPosition: _position,
          )),
          _BottomPopup(
            employee: employee,
            position: _position,
            locationState: _locationState,
            isInsideZone: _isInsideZone,
          ),
        ],
      ),
    );
  }
}

enum _LocationState { loading, ready, error }

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  const _Header({required this.onBack, required this.onRefresh});

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
                      'Lokasi Check In',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ),
                  // Refresh location button
                  GestureDetector(
                    onTap: onRefresh,
                    child: Container(
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

// ─── Map Area ─────────────────────────────────────────────────────────────────

class _MapArea extends StatelessWidget {
  final MapController mapController;
  final Position? userPosition;

  const _MapArea({required this.mapController, required this.userPosition});

  @override
  Widget build(BuildContext context) {
    final userLatLng = userPosition != null
        ? LatLng(userPosition!.latitude, userPosition!.longitude)
        : null;

    return FlutterMap(
      mapController: mapController,
      options: const MapOptions(
        initialCenter: _officeLatLng,
        initialZoom: 16.5,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.porto.hris_mobile_app',
        ),
        // Office check-in zone circle
        CircleLayer(
          circles: [
            CircleMarker(
              point: _officeLatLng,
              radius: _checkinRadiusMeters,
              useRadiusInMeter: true,
              color: const Color(0x1A7A5AF8),
              borderColor: const Color(0xFF7A5AF8),
              borderStrokeWidth: 2,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            // Office center marker
            Marker(
              point: _officeLatLng,
              width: 32,
              height: 32,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7A5AF8).withValues(alpha: 0.2),
                  border: Border.all(color: const Color(0xFF7A5AF8), width: 2),
                ),
                child: const Icon(Icons.business, color: Color(0xFF7A5AF8), size: 16),
              ),
            ),
            // User's current location marker
            if (userLatLng != null)
              Marker(
                point: userLatLng,
                width: 44,
                height: 44,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF007EE9),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x4D007EE9),
                        blurRadius: 8,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 22),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ─── Bottom Popup ─────────────────────────────────────────────────────────────

class _BottomPopup extends StatelessWidget {
  final Employee employee;
  final Position? position;
  final _LocationState locationState;
  final bool isInsideZone;

  const _BottomPopup({
    required this.employee,
    required this.position,
    required this.locationState,
    required this.isInsideZone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(15, 24, 15, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusBanner(locationState: locationState, isInsideZone: isInsideZone),
            const SizedBox(height: 12),
            const Text(
              'Profile Saya',
              style: TextStyle(fontSize: 12, color: Color(0xFF101828)),
            ),
            const SizedBox(height: 8),
            _ProfileCard(employee: employee, position: position, locationState: locationState),
            const SizedBox(height: 12),
            const Text(
              'Jadwal',
              style: TextStyle(fontSize: 12, color: Color(0xFF101828)),
            ),
            const SizedBox(height: 8),
            _ScheduleTiles(),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final _LocationState locationState;
  final bool isInsideZone;

  const _StatusBanner({required this.locationState, required this.isInsideZone});

  @override
  Widget build(BuildContext context) {
    if (locationState == _LocationState.loading) {
      return Container(
        height: 86,
        decoration: BoxDecoration(
          color: const Color(0xFF475467),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Mendeteksi lokasi Anda...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Mohon tunggu sebentar',
                    style: TextStyle(fontSize: 12, color: Color(0xFFD0D5DD)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            )),
          ],
        ),
      );
    }

    if (locationState == _LocationState.error || !isInsideZone) {
      return Container(
        height: 86,
        decoration: BoxDecoration(
          color: const Color(0xFFD92D20),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    locationState == _LocationState.error
                        ? 'Gagal mendapatkan lokasi'
                        : 'Anda di luar area clock-in',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locationState == _LocationState.error
                        ? 'Pastikan GPS aktif dan coba lagi'
                        : 'Pindah ke area kantor untuk check-in',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFFFCDD2)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_off, color: Colors.white, size: 28),
            ),
          ],
        ),
      );
    }

    // Inside zone — success banner
    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: const Color(0xFF007EE9),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Anda berada di area clock-in!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Sekarang Anda dapat menekan clock in di area ini',
                  style: TextStyle(fontSize: 12, color: Color(0xFFEDEAFF)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.access_time, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Employee employee;
  final Position? position;
  final _LocationState locationState;

  const _ProfileCard({
    required this.employee,
    required this.position,
    required this.locationState,
  });

  @override
  Widget build(BuildContext context) {
    final today = _formatToday();

    String locationText;
    if (locationState == _LocationState.loading) {
      locationText = 'Mendeteksi lokasi...';
    } else if (position != null) {
      final lat = position!.latitude.toStringAsFixed(6);
      final lng = position!.longitude.toStringAsFixed(6);
      locationText = '$lat, $lng';
    } else {
      locationText = 'Lokasi tidak tersedia';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF007EE9).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                employee.fullName.isNotEmpty
                    ? employee.fullName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF007EE9),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        employee.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D2D2D),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: Color(0xFF007EE9), size: 16),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  today,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF007EE9)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: Color(0xFF475467),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        locationText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475467),
                        ),
                        overflow: TextOverflow.ellipsis,
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

  String _formatToday() {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    final now = DateTime.now();
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

class _ScheduleTiles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _TimeTile(label: 'Check In', time: '08:00')),
        const SizedBox(width: 12),
        Expanded(child: _TimeTile(label: 'Check Out', time: '17:00')),
      ],
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final String time;
  const _TimeTile({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475467)),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Button ─────────────────────────────────────────────────────────────

class _BottomButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _BottomButton({required this.label, required this.icon, required this.onTap});

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
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007EE9),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(icon, size: 20),
            label: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
