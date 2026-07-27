import 'dart:convert';
import 'dart:io';

void main() async {
  const cmToken = 'nShy8ettIIu6hqQ7yi7Hvv4OTumsVvsntfPpBP7MMfE';
  const buildId = '6a6752572acdc51c11f87906';
  final client = HttpClient();

  try {
    final url = Uri.parse('https://api.codemagic.io/builds/$buildId');
    final req = await client.getUrl(url);
    req.headers.set('x-auth-token', cmToken);
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();
    await File('build_details.json').writeAsString(body);
    print('Saved build details to build_details.json (Length: ${body.length} bytes)');
  } catch (e) {
    print('Exception: $e');
  } finally {
    client.close();
  }
}
