import 'dart:convert';
import 'dart:io';

void main() async {
  const cmToken = 'nShy8ettIIu6hqQ7yi7Hvv4OTumsVvsntfPpBP7MMfE';
  final file = File('active_build.txt');
  if (!await file.exists()) return;
  final lines = await file.readAsLines();
  final buildId = lines[1].trim();

  final client = HttpClient();
  final buildUrl = Uri.parse('https://api.codemagic.io/builds/$buildId');
  final req = await client.getUrl(buildUrl);
  req.headers.set('x-auth-token', cmToken);
  final resp = await req.close();
  final body = await resp.transform(utf8.decoder).join();
  final data = jsonDecode(body);
  final build = data['build'] ?? {};
  final List actions = build['buildActions'] ?? [];

  for (var act in actions) {
    print('Step: ${act['name']} -> ${act['status']}');
    final List subs = act['subactions'] ?? [];
    for (var s in subs) {
      final logUrl = s['logUrl'];
      if (logUrl != null) {
        final lReq = await client.getUrl(Uri.parse(logUrl));
        lReq.headers.set('x-auth-token', cmToken);
        final lResp = await lReq.close();
        final lBody = await lResp.transform(utf8.decoder).join();
        print('--- LOG FOR ${act['name']} ---');
        final lines = lBody.split('\n');
        for (var line in lines) {
          if (line.contains('Error') || line.contains('failed') || line.contains('Customer') || line.contains('IPA')) {
            print(line);
          }
        }
      }
    }
  }
  client.close();
}
