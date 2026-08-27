import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../core/supabase_client.dart';
import '../../models/category_model.dart';
import '../../core/repos/category_repository.dart';
import '../repos/admin_category_repository.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final _catRepo = CategoryRepository();
  final _adminRepo = AdminCategoryRepository();
  List<CategoryModel> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final list = await _catRepo.getAllCategories();
    if (mounted) {
      setState(() {
        _categories = list;
        _loading = false;
      });
    }
  }

  void _showAddEditDialog({CategoryModel? category}) {
    final nameEnCtrl = TextEditingController(text: category?.nameEn);
    final nameArCtrl = TextEditingController(text: category?.nameAr);
    final imageCtrl = TextEditingController(text: category?.imageUrl ?? '');
    int? selectedParentId = category?.parentId;
    bool uploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final parents = _categories.where((c) => c.parentId == null && c.id != category?.id).toList();

          return AlertDialog(
            title: Text(category == null ? 'إضافة قسم' : 'تعديل قسم'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameEnCtrl,
                    decoration: const InputDecoration(labelText: 'الاسم (إنجليزي) - المفتاح'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameArCtrl,
                    decoration: const InputDecoration(labelText: 'الاسم (عربي)'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: imageCtrl,
                          decoration: const InputDecoration(labelText: 'رابط الصورة (اختياري)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: uploading
                            ? null
                            : () async {
                                final res = await FilePicker.platform.pickFiles(type: FileType.image);
                                if (res == null || res.files.isEmpty) return;
                                final f = res.files.first;
                                final path = f.path;
                                if (path == null) return;
                                final client = SupabaseManager.client;
                                if (client == null) return;
                                uploading = true;
                                setState(() {});
                                try {
                                  final file = File(path);
                                  final name = f.name.replaceAll(' ', '_');
                                  final key = 'food-images/categories/${DateTime.now().millisecondsSinceEpoch}_$name';
                                  await client.storage.from('food-images').upload(key, file);
                                  final publicUrl = client.storage.from('food-images').getPublicUrl(key);
                                  imageCtrl.text = publicUrl;
                                } finally {
                                  uploading = false;
                                  setState(() {});
                                }
                              },
                        child: Text(uploading ? 'جارٍ الرفع...' : 'رفع صورة'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedParentId,
                    decoration: const InputDecoration(labelText: 'القسم الرئيسي (اختياري)'),
                    items: [
                      const DropdownMenuItem<int>(value: null, child: Text('بدون (قسم رئيسي)')),
                      ...parents.map((p) => DropdownMenuItem<int>(
                        value: p.id,
                        child: Text('${p.nameAr} (${p.nameEn})'),
                      )),
                    ],
                    onChanged: (val) => setState(() => selectedParentId = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  if (nameEnCtrl.text.isEmpty || nameArCtrl.text.isEmpty) return;

                  final newCat = CategoryModel(
                    id: category?.id ?? 0, // 0 for new, ignored by insert
                    nameEn: nameEnCtrl.text,
                    nameAr: nameArCtrl.text,
                    parentId: selectedParentId,
                    imageUrl: imageCtrl.text.isNotEmpty ? imageCtrl.text : null,
                  );

                  try {
                    if (category == null) {
                      await _adminRepo.addCategory(newCat);
                    } else {
                      await _adminRepo.updateCategory(newCat);
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      _loadCategories();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                    }
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteCategory(int id) async {
    // Check if has children
    final hasChildren = _categories.any((c) => c.parentId == id);
    if (hasChildren) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن حذف قسم يحتوي على أقسام فرعية')));
      return;
    }

    // الحصول على معلومات القسم لمعرفة اسمه
    final cat = _categories.firstWhere((c) => c.id == id, orElse: () => _categories.first);
    final catNameEn = cat.nameEn;
    final catNameAr = cat.nameAr;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا القسم؟\n\nتنبيه: سيتم حذف القسم وجميع الوجبات الموجودة بداخله من قاعدة البيانات بشكل نهائي.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف نهائي', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final svc = SupabaseManager.client;
        if (svc != null) {
          // حذف الوجبات المرتبطة بالقسم من قاعدة البيانات نهائياً
          await svc
              .from('food_items')
              .delete()
              .or('category.eq.$catNameEn,category.eq.$catNameAr');
        }
      } catch (e) {
        debugPrint('⚠️ خطأ حذف الوجبات: $e');
      }
      
      // حذف القسم
      await _adminRepo.deleteCategory(id);
      _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    // Build Tree
    final parents = _categories.where((c) => c.parentId == null).toList();
    
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الأقسام')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: parents.length,
        itemBuilder: (context, index) {
          final parent = parents[index];
          final children = _categories.where((c) => c.parentId == parent.id).toList();

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ExpansionTile(
              title: Text('${parent.nameAr} (${parent.nameEn})', style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showAddEditDialog(category: parent)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteCategory(parent.id)),
                  const Icon(Icons.expand_more),
                ],
              ),
              children: children.map((child) => ListTile(
                title: Text('${child.nameAr} (${child.nameEn})'),
                leading: const Icon(Icons.subdirectory_arrow_right),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.blue), onPressed: () => _showAddEditDialog(category: child)),
                    IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _deleteCategory(child.id)),
                  ],
                ),
              )).toList(),
            ),
          );
        },
      ),
    );
  }
}
