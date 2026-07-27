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
    const primaryGreen = Color(0xFF23AA49);
    const bgGrey = Color(0xFFF6F7F9);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'لوحة الإدارة',

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: primaryGreen,
        scaffoldBackgroundColor: bgGrey,

        colorScheme: const ColorScheme.light(
          primary: primaryGreen,
          secondary: primaryGreen,
          surface: Colors.white,
          onSurface: Color(0xFF1B1B1B),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: bgGrey,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.black87),
        ),

        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: TextStyle(color: Colors.black87),
        ),

        iconTheme: const IconThemeData(color: Colors.black87),
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
    final primaryGreen = theme.primaryColor;

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
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: primaryGreen.withValues(alpha: 0.1),
                        backgroundImage: const AssetImage('assets/logo.PNG'),
                      ),
                      const SizedBox(height: 15), // زدنا المسافة قليلاً
                      const Text(
                        'أهلنا داقوق',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5), // مسافة صغيرة
                      Text(
                        'لوحة التحكم',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),

                const Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Color(0xFFEEEEEE),
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
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.admin_panel_settings_outlined,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Admin Panel v1.0",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showAboutDialog,
                          icon: const Icon(Icons.info_outline_rounded),
                          label: const Text('حول التطبيق'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
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
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.grey[700],
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
    final primaryGreen = theme.primaryColor;

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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryGreen.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? primaryGreen.withValues(alpha: 0.2)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: (Platform.isIOS && index != 0)
                    ? Colors.grey[400]
                    : (isSelected ? primaryGreen : Colors.grey[600]),
                size: 22,
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  color: (Platform.isIOS && index != 0)
                      ? Colors.grey[400]
                      : (isSelected ? primaryGreen : Colors.grey[700]),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: primaryGreen,
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
