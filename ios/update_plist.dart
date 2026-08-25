import 'dart:io';

void main() {
  final plistPath = 'ios/Runner/Info.plist';
  final file = File(plistPath);
  if (!file.existsSync()) {
    stderr.writeln('Info.plist not found at $plistPath');
    exit(1);
  }
  String content = file.readAsStringSync();
  bool changed = false;

  String ensureStringKey(String text, String key, String value) {
    final regex = RegExp('<key>$key</key>\\s*<string>[^<]*</string>', multiLine: true);
    if (regex.hasMatch(text)) {
      text = text.replaceAll(regex, '<key>$key</key>\n    <string>$value</string>');
      changed = true;
    } else {
      final insertPoint = text.lastIndexOf('</dict>');
      if (insertPoint != -1) {
        final injection = '  <key>$key</key>\n  <string>$value</string>\n';
        text = text.substring(0, insertPoint) + injection + text.substring(insertPoint);
        changed = true;
      }
    }
    return text;
  }

  content = ensureStringKey(content, 'NSLocalNetworkUsageDescription', 'نحتاج الوصول للشبكة للاتصال بقاعدة البيانات والخادم');
  content = ensureStringKey(content, 'NSLocationWhenInUseUsageDescription', 'موقعك مطلوب لتوصيل الطلب');
  content = ensureStringKey(content, 'NSPhotoLibraryUsageDescription', 'نحتاج الوصول للصور لاختيار وحفظ الصور');

  if (changed) {
    file.writeAsStringSync(content);
    stdout.writeln('Info.plist updated successfully.');
  }
}
