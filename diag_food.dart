import 'dart:convert';
import 'dart:io';

void main() async {
  const supabaseUrl = 'https://boylzidmvvldouxtrpiv.supabase.co';
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4NDQ0NjgsImV4cCI6MjA3OTQyMDQ2OH0.k-YInG1GfcBK6GQCjOuGMYcP_m2Eq7yTQSPuspCExr0';
  const svcKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mzg0NDQ2OCwiZXhwIjoyMDc5NDIwNDY4fQ.GnddzO4SFff1ze0pdvmk-X-FKxpn9ajdm5Q4hjbiGoY';

  final client = HttpClient();

  // 1. Test anon key — read food_items
  print('=== TEST 1: Read food_items with ANON key ===');
  await testQuery(client, supabaseUrl, anonKey, 'food_items', 'ANON');

  // 2. Test anon key — read categories
  print('\n=== TEST 2: Read categories with ANON key ===');
  await testQuery(client, supabaseUrl, anonKey, 'categories', 'ANON');

  // 3. Test service role key — read food_items
  print('\n=== TEST 3: Read food_items with SERVICE ROLE key ===');
  await testQuery(client, supabaseUrl, svcKey, 'food_items', 'SERVICE');

  // 4. Check RLS policies
  print('\n=== TEST 4: Check food_items category field values ===');
  await checkCategories(client, supabaseUrl, svcKey);

  client.close();
}

Future<void> testQuery(HttpClient c, String url, String key, String table, String label) async {
  try {
    final uri = Uri.parse('$url/rest/v1/$table?select=*&limit=5');
    final req = await c.getUrl(uri);
    req.headers.set('apikey', key);
    req.headers.set('Authorization', 'Bearer $key');
    req.headers.set('Content-Type', 'application/json');
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();

    if (resp.statusCode == 200) {
      final List data = jsonDecode(body);
      print('✅ $label → HTTP 200 OK, got ${data.length} rows');
      if (data.isNotEmpty) {
        final first = data.first as Map;
        print('   Fields: ${first.keys.toList()}');
        print('   id type: ${first['id'].runtimeType} = ${first['id']}');
        print('   name: ${first['name']}');
        print('   category: ${first['category']}');
        print('   is_available: ${first['is_available'].runtimeType} = ${first['is_available']}');
        print('   price type: ${first['price'].runtimeType} = ${first['price']}');
      }
    } else {
      print('❌ $label → HTTP ${resp.statusCode}');
      print('   Body: $body');
    }
  } catch (e) {
    print('❌ $label → Exception: $e');
  }
}

Future<void> checkCategories(HttpClient c, String url, String key) async {
  try {
    final uri = Uri.parse('$url/rest/v1/food_items?select=category&limit=100');
    final req = await c.getUrl(uri);
    req.headers.set('apikey', key);
    req.headers.set('Authorization', 'Bearer $key');
    req.headers.set('Content-Type', 'application/json');
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();

    if (resp.statusCode == 200) {
      final List data = jsonDecode(body);
      final categories = data.map((e) => e['category']).toSet();
      print('✅ Unique category values in DB (${categories.length} unique):');
      for (final cat in categories) {
        print('   → "$cat"');
      }
    } else {
      print('❌ HTTP ${resp.statusCode}: $body');
    }
  } catch (e) {
    print('❌ Exception: $e');
  }
}
