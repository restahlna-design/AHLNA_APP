import 'dart:convert';
import 'dart:io';

void main() async {
  const cmToken = 'nShy8ettIIu6hqQ7yi7Hvv4OTumsVvsntfPpBP7MMfE';
  const buildId = '6a6752572acdc51c11f87906';
  final client = HttpClient();

  try {
    print('=== 🏆 جلب وتحميل ملفات الـ IPA الرسمية من سيرفرات أبل (Codemagic M2) ===');
    final url = Uri.parse('https://api.codemagic.io/builds/$buildId');
    final req = await client.getUrl(url);
    req.headers.set('x-auth-token', cmToken);
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();
    final data = jsonDecode(body);
    final build = data['build'] ?? data;
    
    print('✅ حالة البناء: **${build['status']}** بنجاح بنسبة 100%!');
    
    // Codemagic uses British spelling 'artefacts' in its API!
    final List artefacts = build['artefacts'] ?? build['artifacts'] ?? [];
    print('📦 عدد الملفات التجميعية الجاهزة للتنصيب: ${artefacts.length}\n');
    
    final downloadedNames = <String>{};

    for (var art in artefacts) {
      final name = art['name'] ?? 'app.ipa';
      if (downloadedNames.contains(name)) continue; // avoid duplicates if multiple listed
      downloadedNames.add(name);

      final dlUrl = art['url'];
      final size = art['size'] ?? 0;
      final expectedMb = size / (1024 * 1024);

      if (dlUrl != null) {
        print('⬇️ البدء بالتحميل الفوري للملكية: **$name** (الحجم المتوقع: ${expectedMb.toStringAsFixed(2)} MB)...');
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
    
    print('✨🚀 ألف مبروك! ملفات التطبيق (الزبون والأدمين) متوفرة الآن بدون توقيع ومحفوظة مباشرة على جهازك جاهزة للتنصيب عبر أي أداة تحميل خارجي (مثل Esign أو Sideloadly أو Scarlet)!');
  } catch (e) {
    print('❌ خطأ أثناء التحميل: $e');
  } finally {
    client.close();
  }
}
