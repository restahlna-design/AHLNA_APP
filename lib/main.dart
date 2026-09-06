import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/storage.dart';
import 'core/supabase_client.dart';
import 'core/theme_controller.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'dart:async';
import 'core/cart.dart';
import 'core/profile.dart';
import 'core/repos/profile_repository.dart';
import 'core/repos/notifications_repository.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Hive.initFlutter();
  final foodBox = await Hive.openBox('food_cache_v2');
  final offersBox = await Hive.openBox('offers_cache');
  try {
    await foodBox
        .clear(); // مسح الكاش القديم فوراً لضمان الجلب المباشر واللحظي من قاعدة البيانات
    await offersBox.clear();
  } catch (_) {}

  await SupabaseManager.init();
  final client = SupabaseManager.client;
  final user = client?.auth.currentUser;
  Map<String, String>? initialProfile;
  bool showLogin = true;
  if (user == null) {
    final registered = await Storage.isRegistered();
    if (registered) {
      final local = await Storage.loadProfile();
      initialProfile = {
        'name': (local['name'] ?? '').toString(),
        'phone': (local['phone'] ?? '').toString(),
        'address': (local['address'] ?? '').toString(),
      };
      showLogin = false;
    } else {
      showLogin = true;
    }
  } else {
    final pr = ProfileRepository();
    final data = await pr.getByUser(user.id);
    if (data != null) {
      showLogin = false;
      initialProfile = {
        'name': (data['name'] ?? '').toString(),
        'phone': (data['phone'] ?? '').toString(),
        'address': (data['address'] ?? '').toString(),
      };
    } else {
      final registered = await Storage.isRegistered();
      if (registered) {
        final local = await Storage.loadProfile();
        initialProfile = {
          'name': (local['name'] ?? '').toString(),
          'phone': (local['phone'] ?? '').toString(),
          'address': (local['address'] ?? '').toString(),
        };
        showLogin = false;
      } else {
        showLogin = true;
      }
    }
  }
  final themeController = ThemeController();

  // Add 0.5s delay before removing splash screen
  await Future.delayed(const Duration(milliseconds: 500));
  FlutterNativeSplash.remove();

  

  runApp(
    AhlnaDaquqApp(
      showLoginFirst: showLogin,
      initialProfile: initialProfile,
      themeController: themeController,
    ),
  );
}

class AhlnaDaquqApp extends StatelessWidget {
  final bool showLoginFirst;
  final Map<String, String>? initialProfile;
  final ThemeController themeController;

  const AhlnaDaquqApp({
    super.key,
    this.showLoginFirst = true,
    this.initialProfile,
    required this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    final cart = CartController();
    final profile = ProfileController();

    if (initialProfile != null) {
      final name = initialProfile!["name"] ?? '';
      final phone = initialProfile!["phone"] ?? '';
      final address = initialProfile!["address"] ?? '';
      if (name.isNotEmpty || phone.isNotEmpty || address.isNotEmpty) {
        profile.set(name: name, phone: phone, address: address);
      }
    }

    // تحميل صورة البروفايل عند بدء التطبيق
    Storage.loadProfileImage().then((path) {
      if (path != null && path.isNotEmpty) {
        profile.set(imagePath: path);
      }
    });

    return CartProvider(
      controller: cart,
      child: ProfileProvider(
        controller: profile,
        child: ThemeProvider(
          controller: themeController,
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: themeController,
            builder: (context, mode, _) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                themeMode: mode,
                darkTheme: ThemeData(
                  useMaterial3: true,
                  brightness: Brightness.dark,
                  fontFamily: 'Tajawal',
                  fontFamilyFallback: const ['Tajawal', 'sans-serif'],
                  primaryColor: const Color(0xFF23AA49),
                  scaffoldBackgroundColor: const Color(0xFF121212),
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF23AA49),
                    secondary: Color(0xFF23AA49),
                    surface: Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                    onPrimary: Colors.white,
                    outline: Color(0xFF424242),
                  ),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Color(0xFF1E1E1E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    centerTitle: true,
                    surfaceTintColor: Colors.transparent,
                    iconTheme: IconThemeData(color: Colors.white),
                    titleTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                    backgroundColor: Color(0xFF1E1E1E),
                    selectedItemColor: Color(0xFF23AA49),
                    unselectedItemColor: Colors.grey,
                    elevation: 15,
                    type: BottomNavigationBarType.fixed,
                    showUnselectedLabels: true,
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: const Color(0xFF2C2C2C),
                    hintStyle: const TextStyle(color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    prefixIconColor: const Color(0xFF23AA49),
                    suffixIconColor: Colors.grey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF23AA49),
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 1,
                      ),
                    ),
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF23AA49),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  textTheme: ThemeData.dark().textTheme.apply(
                    fontFamily: 'Tajawal',
                    bodyColor: Colors.white,
                    displayColor: Colors.white,
                  ).copyWith(
                    headlineSmall: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                    titleLarge: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                    bodyLarge: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
                    bodyMedium: const TextStyle(color: Colors.white70, fontFamily: 'Tajawal'),
                  ),
                  primaryTextTheme: ThemeData.dark().primaryTextTheme.apply(
                    fontFamily: 'Tajawal',
                  ),
                  dialogTheme: DialogThemeData(
                    backgroundColor: const Color(0xFF1E1E1E),
                    surfaceTintColor: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    titleTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // ============================================================
                // 🎨 ثيم HyperMart (أخضر عصري + خلفية نظيفة)
                // ============================================================
                theme: ThemeData(
                  useMaterial3: true,
                  brightness: Brightness.light,
                  fontFamily: 'Tajawal',
                  fontFamilyFallback: const ['Tajawal', 'sans-serif'],

                  // 1. اللون الرئيسي (HyperMart Green)
                  // اذا كان اللون في الرابط مختلف، فقط غير هذا الكود (0xFF23AA49) للون الذي تريده
                  primaryColor: const Color(0xFF23AA49),

                  // خلفية رمادية فاتحة جداً (Cool Gray)
                  scaffoldBackgroundColor: const Color(0xFFF6F7F9),

                  // 2. مخطط الألوان
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF23AA49), // الأخضر
                    secondary: Color(0xFF23AA49),
                    surface: Colors.white, // لون البطاقات أبيض ناصع
                    onSurface: Color(0xFF1B1B1B), // لون النصوص أسود غامق
                    onPrimary: Colors.white, // لون النص داخل الزر الأخضر
                    outline: Color(0xFFE1E1E1), // لون الحدود فاتح
                  ),

                  // 3. شريط العنوان (AppBar)
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.white, // خلفية بيضاء
                    foregroundColor: Color(0xFF1B1B1B), // أيقونات ونص أسود
                    elevation: 0,
                    centerTitle: true,
                    surfaceTintColor: Colors.transparent,
                    iconTheme: IconThemeData(color: Color(0xFF1B1B1B)),
                    titleTextStyle: TextStyle(
                      color: Color(0xFF1B1B1B),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal', // اذا كنت تستخدم خط معين
                    ),
                  ),

                  // 4. الشريط السفلي (Bottom Navigation)
                  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                    backgroundColor: Colors.white,
                    selectedItemColor: Color.fromARGB(
                      255,
                      67,
                      179,
                      33,
                    ), // أخضر عند الاختيار
                    unselectedItemColor: Color(
                      0xFF9E9E9E,
                    ), // رمادي عند عدم الاختيار
                    elevation: 15,
                    type: BottomNavigationBarType.fixed,
                    showUnselectedLabels: true,
                  ),

                  // 5. حقول الإدخال (Inputs) - مثل تصميم فيجما
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: const Color(0xFFF3F3F3), // رمادي فاتح جداً
                    hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    prefixIconColor: const Color(0xFF23AA49),
                    suffixIconColor: const Color(0xFFBDBDBD),

                    // الحدود
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none, // بدون حدود افتراضية
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF23AA49),
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 1,
                      ),
                    ),
                  ),

                  // 6. الأزرار (Buttons)
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF23AA49),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  // 7. النصوص (Typography)
                  textTheme: ThemeData.light().textTheme.apply(
                    fontFamily: 'Tajawal',
                    bodyColor: const Color(0xFF1B1B1B),
                    displayColor: const Color(0xFF1B1B1B),
                  ).copyWith(
                    headlineSmall: const TextStyle(
                      color: Color(0xFF1B1B1B),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                    titleLarge: const TextStyle(
                      color: Color(0xFF1B1B1B),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                    bodyLarge: const TextStyle(color: Color(0xFF1B1B1B), fontFamily: 'Tajawal'),
                    bodyMedium: const TextStyle(color: Color(0xFF424242), fontFamily: 'Tajawal'),
                  ),
                  primaryTextTheme: ThemeData.light().primaryTextTheme.apply(
                    fontFamily: 'Tajawal',
                  ),

                  // 8. القوائم
                  dialogTheme: DialogThemeData(
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    titleTextStyle: const TextStyle(
                      color: Color(0xFF1B1B1B),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // ============================================================
                locale: const Locale('ar'),
                supportedLocales: const [Locale('ar'), Locale('en')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: showLoginFirst
                    ? const LoginScreen()
                    : const RootScaffold(),
              );
            },
          ),
        ),
      ),
    );
  }
}

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      const HomeScreen(key: ValueKey('tab_menu')),
      const NotificationsScreen(key: ValueKey('tab_notifications')),
      const ProfileScreen(key: ValueKey('tab_profile')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: FloatingPillNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class FloatingPillNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingPillNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<FloatingPillNavBar> createState() => _FloatingPillNavBarState();
}

class _FloatingPillNavBarState extends State<FloatingPillNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  StreamSubscription<List<dynamic>>? _notifSub;
  bool _hasUnread = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();
    _listenToUnread();
  }

  void _listenToUnread() {
    _notifSub = NotificationsRepository().streamNotifications().listen((list) async {
      final readIds = await Storage.loadReadNotificationIds();
      final hasUnread = list.any((n) => !readIds.contains(n.id));
      if (mounted && _hasUnread != hasUnread) {
        setState(() => _hasUnread = hasUnread);
      }
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium frosted glass background for the inner pill
    final innerCapsuleBg = isDark
        ? const Color(0xFF13171F).withValues(alpha: 0.90)
        : Colors.white.withValues(alpha: 0.92);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 24, right: 24, top: 4),
        child: Center(
          heightFactor: 1.0,
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, _) {
              return Container(
                // Outer subtle ambient glow
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.22),
                      blurRadius: 18,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: isDark
                          ? const Color(0xFFCBD5E1).withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                // Outer wrapper with border-radius: 999px & overflow: hidden
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating Metallic Conic Gradient (equivalent to ::before spin)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MetallicRotatingConicPainter(
                            progress: _rotationController.value,
                            isDark: isDark,
                          ),
                        ),
                      ),

                      // Inner capsule with 2.2px padding to expose the rotating metallic border
                      Padding(
                        padding: const EdgeInsets.all(2.2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: innerCapsuleBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTab(
                                    index: 0,
                                    label: 'الرئيسية',
                                    icon: Icons.storefront_rounded,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildTab(
                                    index: 1,
                                    label: 'الإشعارات',
                                    icon: Icons.notifications_rounded,
                                    isDark: isDark,
                                    hasBadge: _hasUnread,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildTab(
                                    index: 2,
                                    label: 'حسابي',
                                    icon: Icons.person_rounded,
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required String label,
    required IconData icon,
    required bool isDark,
    bool hasBadge = false,
  }) {
    final isSelected = widget.currentIndex == index;
    const activeGreen = Color(0xFF10B981);
    final inactiveBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white;
    final inactiveIconColor = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF64748B);
    final activeBg = isDark
        ? activeGreen.withValues(alpha: 0.22)
        : Colors.white;
    final activeTextColor = isDark
        ? Colors.white
        : const Color(0xFF0F172A);

    return GestureDetector(
      onTap: () => widget.onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
        height: 46,
        width: isSelected ? 128 : 46,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? activeGreen.withValues(alpha: isDark ? 0.7 : 0.5)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeGreen.withValues(alpha: isDark ? 0.3 : 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isSelected ? activeGreen : inactiveIconColor,
                  ),
                  if (hasBadge && !isSelected)
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                ],
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: activeTextColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetallicRotatingConicPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _MetallicRotatingConicPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final rect = Offset.zero & size;

    // Metallic silver, chrome white, steel slate, and emerald green identity
    final colors = isDark
        ? [
            const Color(0xFFCBD5E1), // Steel silver
            const Color(0xFFFFFFFF), // Brilliant chrome reflection
            const Color(0xFF94A3B8), // Metallic slate
            const Color(0xFF10B981), // Emerald green identity
            const Color(0xFF34D399), // Emerald light sheen
            const Color(0xFF059669), // Emerald deep shade
            const Color(0xFF64748B), // Steel dark tone
            const Color(0xFFFFFFFF), // Specular chrome highlight
            const Color(0xFFCBD5E1), // Back to steel silver for seamless loop
          ]
        : [
            const Color(0xFF94A3B8), // Steel slate
            const Color(0xFFFFFFFF), // Chrome white highlight
            const Color(0xFFCBD5E1), // Platinum
            const Color(0xFF10B981), // Emerald green identity
            const Color(0xFF059669), // Rich emerald
            const Color(0xFFCBD5E1), // Steel silver
            const Color(0xFFFFFFFF), // Brilliant chrome specular reflection
            const Color(0xFF94A3B8), // Loop closure
          ];

    final stops = isDark
        ? [0.0, 0.12, 0.25, 0.42, 0.52, 0.64, 0.76, 0.88, 1.0]
        : [0.0, 0.14, 0.28, 0.45, 0.58, 0.72, 0.86, 1.0];

    final paint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: colors,
        stops: stops,
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _MetallicRotatingConicPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
