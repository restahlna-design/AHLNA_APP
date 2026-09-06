import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/supabase_client.dart';
import 'screens/admin_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseManager.init(isAdmin: true);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const _AdminAndroidApp());
}

class _AdminAndroidApp extends StatelessWidget {
  const _AdminAndroidApp();
  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF23AA49),
        surface: Color(0xFF121212),
      ),
      scaffoldBackgroundColor: const Color(0xFF0E0E0E),
      fontFamily: 'Tajawal',
      fontFamilyFallback: const ['Tajawal', 'sans-serif'],
      useMaterial3: true,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const AdminHomeScreen(restrictActions: true, compactMobile: true),
    );
  }
}
