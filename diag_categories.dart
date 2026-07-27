import 'dart:convert';
import 'dart:io';

void main() async {
  const supabaseUrl = 'https://boylzidmvvldouxtrpiv.supabase.co';
  const svcKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mzg0NDQ2OCwiZXhwIjoyMDc5NDIwNDY4fQ.GnddzO4SFff1ze0pdvmk-X-FKxpn9ajdm5Q4hjbiGoY';

  final client = HttpClient();

  // Get all categories
  print('=== All categories from DB ===');
  final catUri = Uri.parse('$supabaseUrl/rest/v1/categories?select=id,name_en,name_ar,parent_id&order=id');
  final catReq = await client.getUrl(catUri);
  catReq.headers.set('apikey', svcKey);
  catReq.headers.set('Authorization', 'Bearer $svcKey');
  final catResp = await catReq.close();
  final catBody = await catResp.transform(utf8.decoder).join();
  final List cats = jsonDecode(catBody);
  for (final c in cats) {
    print('  id=${c['id']}, name_en="${c['name_en']}", name_ar="${c['name_ar']}", parent_id=${c['parent_id']}');
  }

  // Get all food_items categories
  print('\n=== Unique category values in food_items ===');
  final foodUri = Uri.parse('$supabaseUrl/rest/v1/food_items?select=category&order=category');
  final foodReq = await client.getUrl(foodUri);
  foodReq.headers.set('apikey', svcKey);
  foodReq.headers.set('Authorization', 'Bearer $svcKey');
  final foodResp = await foodReq.close();
  final foodBody = await foodResp.transform(utf8.decoder).join();
  final List food = jsonDecode(foodBody);
  final cats2 = food.map((e) => e['category']).toSet().toList();
  for (final c in cats2) {
    print('  "$c"');
  }

  client.close();
}
