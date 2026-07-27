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
    final data = jsonDecode(body);
    final build = data['build'] ?? data;

    print('BUILD STATUS: ${build['status']}');
    print('ALL KEYS IN BUILD: ${build.keys.toList()}');

    if (build['artifacts'] != null) {
      print('ARTIFACTS FIELD: ${jsonEncode(build['artifacts'])}');
    }

    // Search anywhere in the json for '.ipa' or '.zip' or 'http'
    void findUrls(dynamic obj, [String path = '']) {
      if (obj is Map) {
        obj.forEach((key, val) => findUrls(val, '$path.$key'));
      } else if (obj is List) {
        for (var i = 0; i < obj.length; i++) {
          findUrls(obj[i], '$path[$i]');
        }
      } else if (obj is String) {
        if (obj.contains('.ipa') ||
            obj.contains('.zip') ||
            obj.contains('artifact') ||
            obj.contains('Customer') ||
            obj.contains('Admin')) {
          print('FOUND MATCH at $path: $obj');
        }
      }
    }

    findUrls(build);

    // Also print out the log of step 4 to confirm what files were exported!
    final List steps = build['steps'] ?? [];
    for (var s in steps) {
      if (s['name'].toString().contains('Manual Packaging')) {
        final logUrl = s['logUrl'];
        if (logUrl != null) {
          print('\n=== FETCHING STEP 4 LOG TO VERIFY CREATED IPA FILES ===');
          final logReq = await client.getUrl(Uri.parse(logUrl));
          logReq.headers.set('x-auth-token', cmToken);
          final logResp = await logReq.close();
          final logBody = await logResp.transform(utf8.decoder).join();
          final lines = logBody.split('\n');
          for (var l in lines) {
            if (l.contains('Customer_App') ||
                l.contains('Admin_App') ||
                l.contains('Success') ||
                l.contains('Error') ||
                l.contains('export directory') ||
                l.contains('.ipa')) {
              print(l);
            }
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
