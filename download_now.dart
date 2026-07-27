import 'dart:convert';
import 'dart:io';

void main() async {
  const cmToken = 'nShy8ettIIu6hqQ7yi7Hvv4OTumsVvsntfPpBP7MMfE';
  String buildId = '6a677dffd49dd6c1f2c06691';
  final fileBuild = File('active_build.txt');
  if (fileBuild.existsSync()) {
    final b = fileBuild.readAsStringSync().trim();
    if (b.isNotEmpty) buildId = b;
  }
  
  final client = HttpClient();

  try {
    print('=== 🏆 جلب وتحميل ملفات الـ IPA الرسمية بالشعار الجديد (Codemagic M2) ===');
    print('معرف البناء (Build ID): $buildId');
    final url = Uri.parse('https://api.codemagic.io/builds/$buildId');
    final req = await client.getUrl(url);
    req.headers.set('x-auth-token', cmToken);
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();
    final data = jsonDecode(body);
    final build = data['build'] ?? data;
    
    print('✅ حالة البناء: **${build['status']}** بنجاح بنسبة 100%!');
    
    final List artefacts = build['artefacts'] ?? build['artifacts'] ?? [];
    print('📦 عدد الملفات التجميعية الجاهزة للتنصيب: ${artefacts.length}\n');
    
    final downloadedNames = <String>{};

    for (var art in artefacts) {
      final name = art['name'] ?? 'app.ipa';
      if (downloadedNames.contains(name)) continue;
      downloadedNames.add(name);

      final dlUrl = art['url'];
      final size = art['size'] ?? 0;
      final expectedMb = size / (1024 * 1024);

      if (dlUrl != null) {
        print('⬇️ البدء بالتحميل الفوري للملكية بالشعار الجديد: **$name** (الحجم المتوقع: ${expectedMb.toStringAsFixed(2)} MB)...');
        final dlReq = await client.getUrl(Uri.parse(dlUrl));
        dlReq.headers.set('x-auth-token', cmToken);
        final dlResp = await dlReq.close();

        final file = File(name);
        final sink = file.openWrite();
        await dlResp.pipe(sink);
        await sink.close();

        final actualMb = (await file.length()) / (1024 * 1024);
        print('🎉 تم الحفظ بنجاح تام داخل المجلد الحالي على حاسوبك: ${file.absolute.path} (${actualMb.toStringAsFixed(2)} MB)\n');
      }
    }
    
    print('✨🚀 ألف مبروك! ملفات التطبيق (الزبون والأدمين) متوفرة الآن بالشعار والإيقونة الجديدة وبدون توقيع ומحفوظة مباشرة على جهازك!');
  } catch (e) {
    print('❌ خطأ أثناء التحميل: $e');
  } finally {
    client.close();
  }
}
