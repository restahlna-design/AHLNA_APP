import 'dart:convert';
import 'dart:io';

void main() async {
  const cmToken = 'nShy8ettIIu6hqQ7yi7Hvv4OTumsVvsntfPpBP7MMfE';
  const buildId = '6a67500ac34a17691acf9c87';
  final client = HttpClient();

  try {
    final url = Uri.parse('https://api.codemagic.io/builds/$buildId');
    final req = await client.getUrl(url);
    req.headers.set('x-auth-token', cmToken);
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();
    final data = jsonDecode(body);
    final build = data['build'] ?? data;
    
    final List steps = build['steps'] ?? [];
    for (var s in steps) {
      print('=== STEP: ${s['name']} | STATUS: ${s['status']} ===');
      if (s['status'] == 'failed' || s['status'] == 'error' || (s['name'] != null && s['name'].toString().contains('iOS'))) {
        final logUrl = s['logUrl'] ?? (s['_id'] != null ? 'https://api.codemagic.io/builds/$buildId/logs/${s['_id']}' : null);
        if (logUrl != null) {
          print('FETCHING LOG FOR ${s['name']} FROM: $logUrl');
          final logReq = await client.getUrl(Uri.parse(logUrl));
          logReq.headers.set('x-auth-token', cmToken);
          final logResp = await logReq.close();
          final logBody = await logResp.transform(utf8.decoder).join();
          final lines = logBody.split('\n');
          print('Total lines in log: ${lines.length}');
          
          print('\n--- ERRORS DETECTED IN LOG ---');
          for (var l in lines) {
            if (l.contains('Error') || l.contains('error') || l.contains('FAILED') || l.contains('failed') || l.contains('[!]') || l.contains('fatal') || l.contains('Exception') || l.contains('no-codesign') || l.contains('Runner.app')) {
              print(l);
            }
          }
          
          print('\n--- LAST 60 LINES OF LOG ---');
          final start = lines.length > 60 ? lines.length - 60 : 0;
          for (var i = start; i < lines.length; i++) {
            print(lines[i]);
          }
        }
      }
    }
  } catch (e) {
    print('Exception: $e');
  } finally {
    client.close();
  }
}
