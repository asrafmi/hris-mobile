import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/register/register_screen.dart';
import 'screens/dashboard/staff_dashboard_screen.dart';
import 'screens/dashboard/admin_dashboard_screen.dart';
import 'screens/attendance/checkin_location_screen.dart';
import 'screens/attendance/checkin_camera_screen.dart';
import 'screens/attendance/checkin_review_screen.dart';
import 'constants/colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swift HRIS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        fontFamily: 'Heebo',
      ),
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard/staff': (context) => const StaffDashboardScreen(),
        '/dashboard/admin': (context) => const AdminDashboardScreen(),
        '/checkin/location': (context) => const CheckinLocationScreen(),
        '/checkin/camera': (context) => const CheckinCameraScreen(),
        '/checkin/review': (context) => const CheckinReviewScreen(),
      },
    );
  }
}
