# Swift HRIS Mobile App

Aplikasi mobile HRIS (Human Resource Information System) berbasis Flutter dengan fitur absensi, delegasi tugas, dan manajemen karyawan.

---

## Requirement

Pastikan tools berikut sudah terinstall sebelum menjalankan project:

| Tool | Versi Minimum |
|------|--------------|
| Flutter | 3.x |
| Dart | 3.11.0 |
| Xcode | 15+ (untuk iOS) |
| Android Studio | Hedgehog+ (untuk Android) |
| CocoaPods | Terbaru (untuk iOS) |

---

## Instalasi

### 1. Clone repository

```bash
git clone <repository-url>
cd hris_mobile_app
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Install iOS dependencies (khusus iOS)

```bash
cd ios && pod install && cd ..
```

---

## Menjalankan Aplikasi

### Lihat semua device yang tersedia

```bash
flutter devices
```

Contoh output:
```
iPhone 16e (mobile)  • C57BEAFD-652A-47F7-A6D7-75F398880988  • ios
macOS (desktop)      • macos                                  • darwin-arm64
Chrome (web)         • chrome                                 • web-javascript
```

### Jalankan di device tertentu

```bash
# iOS Simulator
flutter run -d <device-id>
# Contoh:
flutter run -d C57BEAFD-652A-47F7-A6D7-75F398880988

# macOS
flutter run -d macos

# Android Emulator / device
flutter run -d emulator-5554

# Chrome (web)
flutter run -d chrome
```

### Jalankan di semua device sekaligus

```bash
flutter run -d all
```

---

## Struktur Folder

```
lib/
├── main.dart                  # Entry point aplikasi
├── constants/
│   └── colors.dart            # Definisi warna global
├── screens/
│   ├── splash/
│   │   └── splash_screen.dart
│   ├── onboarding/
│   │   └── onboarding_screen.dart
│   ├── login/
│   │   └── login_screen.dart
│   └── register/
├── services/
│   └── onboarding_service.dart  # SharedPreferences untuk status onboarding
└── widgets/
    └── svg_or_image.dart        # Widget helper render SVG/PNG

assets/
└── images/
    ├── logo.svg
    ├── onboarding-1.png
    ├── onboarding-2.png
    └── onboarding-3.png
```

---

## Dependencies

| Package | Kegunaan |
|---------|---------|
| `flutter_svg` | Render file SVG |
| `shared_preferences` | Simpan status onboarding lokal |
| `cupertino_icons` | Icon gaya iOS |

---

## Tips Development

### Reset onboarding (untuk testing)
Long-press logo **Swift** di halaman Login untuk kembali ke halaman onboarding.

### Hot reload vs Hot restart
- **Hot Reload** (`r`) — perubahan UI kecil
- **Hot Restart** (`R`) — perubahan state, route, atau asset baru

### Build release

```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release
# atau
flutter build appbundle --release
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
