import 'package:flutter/material.dart';
import '../core/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeProvider.of(context);
    final mode = themeController.value;
    final isDark =
        mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'المظهر',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Theme Mode Selection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // 1. System Mode Option
                SwitchListTile(
                  title: const Text(
                    'تلقائي (حسب النظام)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'سيتم تفعيل الوضع الداكن/الفاتح حسب إعدادات هاتفك',
                  ),
                  value: mode == ThemeMode.system,
                  activeThumbColor: Theme.of(context).primaryColor,
                  onChanged: (val) {
                    if (val) {
                      themeController.setTheme(ThemeMode.system);
                    } else {
                      // Default to current system brightness if turning off system mode
                      final brightness = MediaQuery.platformBrightnessOf(
                        context,
                      );
                      themeController.setTheme(
                        brightness == Brightness.dark
                            ? ThemeMode.dark
                            : ThemeMode.light,
                      );
                    }
                  },
                ),

                const Divider(),
                const SizedBox(height: 16),

                // 2. Manual Toggle (Only if System Mode is OFF)
                Opacity(
                  opacity: mode == ThemeMode.system ? 0.5 : 1.0,
                  child: IgnorePointer(
                    ignoring: mode == ThemeMode.system,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          if (mode == ThemeMode.system) return;
                          final newMode = mode == ThemeMode.dark
                              ? ThemeMode.light
                              : ThemeMode.dark;
                          themeController.setTheme(newMode);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 200,
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: (mode == ThemeMode.dark)
                                ? const Color(0xFF1F2937)
                                : const Color(0xFFFFF4E6),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: (mode == ThemeMode.dark)
                                  ? Colors.grey[800]!
                                  : const Color(0xFFFFE0B2),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (mode == ThemeMode.dark)
                                    ? Colors.black26
                                    : Colors.orange.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Sun Icon (Left)
                              Align(
                                alignment: const Alignment(-0.8, 0),
                                child: Icon(
                                  Icons.wb_sunny_rounded,
                                  color: (mode == ThemeMode.dark)
                                      ? Colors.grey[700]
                                      : Colors.orange,
                                  size: 28,
                                ),
                              ),

                              // Moon Icon (Right)
                              Align(
                                alignment: const Alignment(0.8, 0),
                                child: Icon(
                                  Icons.nightlight_round,
                                  color: (mode == ThemeMode.dark)
                                      ? Colors.blue[300]
                                      : Colors.grey[400],
                                  size: 28,
                                ),
                              ),

                              // The Toggle Button
                              AnimatedAlign(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOutBack,
                                alignment: (mode == ThemeMode.dark)
                                    ? const Alignment(1.0, 0)
                                    : const Alignment(-1.0, 0),
                                child: Container(
                                  width: 100,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: (mode == ThemeMode.dark)
                                        ? const Color(0xFF3B82F6)
                                        : const Color(0xFFFDB813),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            ((mode == ThemeMode.dark)
                                                    ? Colors.blue
                                                    : Colors.orange)
                                                .withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        (mode == ThemeMode.dark)
                                            ? Icons.dark_mode
                                            : Icons.light_mode,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        (mode == ThemeMode.dark)
                                            ? 'Dark'
                                            : 'Light',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
