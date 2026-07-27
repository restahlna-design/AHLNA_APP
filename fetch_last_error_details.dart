import 'dart:convert';
import 'dart:io';

void main() async {
  const cmToken = 'nShy8ettIIu6hqQ7yi7Hvv4OTumsVvsntfPpBP7MMfE';
  String buildId = '6a67ca551a715f69cde4c952';
  final file = File('active_build.txt');
  if (await file.exists()) {
    final lines = await file.readAsLines();
    if (lines.length >= 2) buildId = lines[1].trim();
    else if (lines.isNotEmpty) buildId = lines[0].trim();
  }
  print('Checking logs for buildId: $buildId');
  final client = HttpClient();

  try {
    final url = Uri.parse('https://api.codemagic.io/builds/$buildId');
    final req = await client.getUrl(url);
    req.headers.set('x-auth-token', cmToken);
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();
    final data = jsonDecode(body);
    final build = data['build'] ?? data;
    print('Build status: ${build['status']}');
    print('Status message / error: ${build['statusMessage'] ?? build['error'] ?? build['message'] ?? 'None'}');
    
    final List steps = build['steps'] ?? [];
    print('Total steps found: ${steps.length}');
    for (var s in steps) {
      print('=== STEP: ${s['name']} | STATUS: ${s['status']} ===');
      if (s['status'] != 'successful' && s['status'] != 'passed' && s['status'] != 'skipped') {
        final logUrl = s['logUrl'] ?? (s['_id'] != null ? 'https://api.codemagic.io/builds/$buildId/logs/${s['_id']}' : null);
        if (logUrl != null) {
          print('FETCHING LOG FOR ${s['name']} FROM: $logUrl');
          final logReq = await client.getUrl(Uri.parse(logUrl));
          logReq.headers.set('x-auth-token', cmToken);
          final logResp = await logReq.close();
          final logBody = await logResp.transform(utf8.decoder).join();
          print('\n--- LOG CONTENTS ---');
          print(logBody);
        } else {
          print('No logUrl available for this step: $s');
        }
      }
    }
    if (steps.isEmpty) {
      print('Full response keys: ${build.keys.toList()}');
      if (build.containsKey('configError')) {
        print('Config Error: ${build['configError']}');
      }
    }
  } catch (e) {
    print('Exception: $e');
  } finally {
    client.close();
  }
}
