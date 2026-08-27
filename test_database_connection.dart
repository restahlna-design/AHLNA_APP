import 'lib/core/supabase_client.dart';
import 'lib/core/repos/profile_repository.dart';

void main() async {
  print('جاري اختبار اتصال قاعدة البيانات...');
  
  try {
    // تهيئة Supabase
    await SupabaseManager.init();
    print('✓ تم تهيئة Supabase');
    
    // اختبار الاتصال
    final client = SupabaseManager.client;
    if (client == null) {
      print('✗ فشل الاتصال: العميل فارغ');
      return;
    }
    
    print('✓ تم الحصول على عميل Supabase');
    

    // اختبار جدول profiles
    try {
      final result = await client.from('profiles').select().limit(1);
      print('✓ جدول profiles متاح (${result.length} سجل)');
    } catch (e) {
      print('✗ خطأ في الوصول إلى جدول profiles: $e');
    }
    
    // اختبار إدراج بيانات اختبار
    final testPhone = '0501234567';
    final testName = 'اختبار';
    final testAddress = 'عنوان اختبار';
    
    final repo = ProfileRepository();
    final success = await repo.upsert(
      phone: testPhone,
      name: testName,
      address: testAddress,
      user: 'test-user-123',
    );
    
    if (success) {
      print('✓ تم حفظ البيانات الاختبارية بنجاح');
      
      // التحقق من الحفظ
      final savedData = await repo.getByPhone(testPhone);
      if (savedData != null) {
        print('✓ تم التحقق من البيانات المحفوظة:');
        print('  - الاسم: ${savedData['name']}');
        print('  - الهاتف: ${savedData['phone']}');
        print('  - العنوان: ${savedData['address']}');
        
        // حذف البيانات الاختبارية
        await repo.delete(testPhone);
        print('✓ تم حذف البيانات الاختبارية');
      } else {
        print('✗ لم يتم العثور على البيانات المحفوظة');
      }
    } else {
      print('✗ فشل حفظ البيانات الاختبارية');
    }
    
    print('\n=== اختبار الاتصال مكتمل ===');
    
  } catch (e, stackTrace) {
    print('✗ خطأ غير متوقع: $e');
    print('Stack trace: $stackTrace');
  }
}