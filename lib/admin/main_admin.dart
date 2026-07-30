import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:window_manager/window_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/supabase_client.dart';
import 'screens/admin_home_screen.dart';
import 'screens/admin_menu_screen.dart';
import 'screens/admin_records_screen.dart';
import 'screens/admin_offers_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and clear old cache
  await Hive.initFlutter();
  try {
    final b1 = await Hive.openBox('food_cache');
    final b2 = await Hive.openBox('food_cache_v2');
    await b1.clear();
    await b2.clear();
  } catch (e) {
    print('⚠️ Hive initialization failed (likely file lock): $e');
  }

  await SupabaseManager.init();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    await localNotifier.setup(
      appName: 'Ahlna Daquq Admin',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  }

  runApp(const AhlnaAdminApp());
}

class AhlnaAdminApp extends StatelessWidget {
  const AhlnaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF161F33);
    const secondaryNavy = Color(0xFF111827);
    const accentBronze = Color(0xFFC89B7B);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'لوحة الإدارة',

      theme: ThemeData(
        fontFamily: 'AlMohanad',
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: accentBronze,
        scaffoldBackgroundColor: primaryNavy,

        colorScheme: const ColorScheme.dark(
          primary: accentBronze,
          secondary: accentBronze,
          surface: secondaryNavy,
          onSurface: Colors.white,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: accentBronze,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: accentBronze),
        ),

        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: TextStyle(color: Colors.white70),
        ),

        iconTheme: const IconThemeData(color: accentBronze),
      ),

      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AdminRoot(),
    );
  }
}

class AdminRoot extends StatefulWidget {
  const AdminRoot({super.key});

  @override
  State<AdminRoot> createState() => _AdminRootState();
}

class _AdminRootState extends State<AdminRoot> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentBronze = theme.primaryColor;
    final secondaryNavy = theme.colorScheme.surface;

    // final isIOS = Platform.isIOS; // Removed unused variable
    final isWindows = Platform.isWindows;
    final screens = [
      const AdminHomeScreen(),
      const AdminMenuScreen(),
      const AdminRecordsScreen(),
      const AdminOffersScreen(),
    ];

    final titles = [
      'الطلبات الحالية',
      'إدارة المنيو',
      'سجل الطلبات',
      'العروضات',
    ];

    if (!isWindows) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('قائمة التوصيل'),
          backgroundColor: Colors.transparent,
          centerTitle: false,
        ),
        body: const Padding(
          padding: EdgeInsets.all(16.0),
          child: AdminHomeScreen(restrictActions: true, compactMobile: true),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // القائمة الجانبية (Sidebar) - تبقى على ويندوز كلوحة إدارة
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: secondaryNavy,
              border: Border(
                left: BorderSide(
                  color: accentBronze.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(4, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // ✅✅✅ تم تعديل الارتفاع هنا من 140 إلى 180 ✅✅✅
                Container(
                  height: 180,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accentBronze, width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.transparent,
                          backgroundImage: AssetImage('assets/logo.PNG'),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'أهلنا داقوق',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'لوحة التحكم',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: accentBronze.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 20),

                // عناصر القائمة
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildMenuItem(
                        0,
                        'الطلبات الحالية',
                        Icons.receipt_long_rounded,
                      ),
                      const SizedBox(height: 5),
                      _buildMenuItem(
                        1,
                        'إدارة المنيو',
                        Icons.restaurant_menu_rounded,
                      ),
                      const SizedBox(height: 5),
                      _buildMenuItem(2, 'سجل الطلبات', Icons.history_rounded),
                      const SizedBox(height: 5),
                      _buildMenuItem(3, 'العروضات', Icons.local_offer_rounded),
                    ],
                  ),
                ),

                // تذييل القائمة
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showAboutDialog,
                      icon: Icon(Icons.info_outline_rounded, color: accentBronze, size: 20),
                      label: Text('حول التطبيق', style: TextStyle(color: accentBronze, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accentBronze.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar(
                title: Text(
                  titles[_index],
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                centerTitle: false,
                backgroundColor: Colors.transparent,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentBronze,
                        boxShadow: [
                          BoxShadow(
                            color: accentBronze.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Color(0xFF161F33),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.all(20.0),
                child: IndexedStack(index: _index, children: screens),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, String title, IconData icon) {
    final isSelected = _index == index;
    final theme = Theme.of(context);
    final accentBronze = theme.primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (Platform.isIOS && index != 0) return;
          setState(() => _index = index);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1B2439)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? accentBronze.withValues(alpha: 0.2)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: (Platform.isIOS && index != 0)
                    ? Colors.grey[700]
                    : (isSelected ? accentBronze : Colors.grey[400]),
                size: 22,
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  color: (Platform.isIOS && index != 0)
                      ? Colors.grey[700]
                      : (isSelected ? accentBronze : Colors.grey[300]),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cs.surface,
          title: const Text('حول التطبيق'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'هذا التطبيق تم تطويره وبرمجته بالكامل من قبل المطوّر: حسين ناصر.',
                ),
                SizedBox(height: 8),
                Text(
                  'تم تصميم التطبيق بعناية لتقديم أفضل تجربة للمستخدم، مع التركيز على السهولة والسرعة والدقة في عرض المحتوى.',
                ),
                SizedBox(height: 8),
                Text(
                  'يتم تحديث التطبيق وتحسينه بشكل مستمر لضمان أداء أفضل وتوفير مزايا جديدة تلائم احتياجات المستخدمين.',
                ),
                SizedBox(height: 8),
                Text('حقوق الملكية محفوظة © 2025 – حسين ناصر'),
                SizedBox(height: 8),
                Text(
                  'جميع حقوق التصميم والبرمجة والتطوير محفوظة ولا يسمح بإعادة نشر التطبيق أو تعديله دون إذن.',
                ),
                SizedBox(height: 12),
                Text('للتواصل'),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Instagram',
                  onPressed: () async {
                    final uri = Uri.parse('https://www.instagram.com/ev2m/');
                    if (await canLaunchUrl(uri)) {
                      try {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (_) {
                        await launchUrl(uri);
                      }
                    }
                  },
                  icon: const FaIcon(FontAwesomeIcons.instagram),
                ),
                IconButton(
                  tooltip: 'Facebook',
                  onPressed: () async {
                    final uri = Uri.parse(
                      'https://www.facebook.com/abu.ghada.785116?locale=ar_AR',
                    );
                    if (await canLaunchUrl(uri)) {
                      try {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (_) {
                        await launchUrl(uri);
                      }
                    }
                  },
                  icon: const FaIcon(FontAwesomeIcons.facebook),
                ),
              ],
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }
}
