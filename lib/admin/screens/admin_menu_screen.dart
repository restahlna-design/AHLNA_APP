import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../core/supabase_client.dart';
import '../../models/food_item.dart';
import '../../core/repos/food_repository.dart';
import '../repos/admin_food_repository.dart';
import '../../core/repos/category_repository.dart';
import '../../models/category_model.dart';
import 'admin_categories_screen.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  late List<FoodItem> items;
  final repo = FoodRepository();
  final adminFoodRepo = AdminFoodRepository();
  final catRepo = CategoryRepository();

  List<CategoryModel> _allCategories = [];
  String? selectedCategory;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    items = [];
    selectedCategory = '__ALL__';
    _loadData();
  }

  Future<void> _loadData() async {
    final cats = await catRepo.getAllCategories();
    if (cats.isNotEmpty) {
      _allCategories = cats;
      // selectedCategory is already set to __ALL__ by default
    } else {
      final allItemsForCats = await repo.fetchAllFresh();
      final distinct = allItemsForCats
          .map((e) => e.category)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();
      if (distinct.isNotEmpty) {
        _allCategories = List.generate(
          distinct.length,
          (i) => CategoryModel(
            id: i + 1,
            nameEn: distinct[i],
            nameAr: distinct[i],
          ),
        );
      } else {
        _allCategories = [
          const CategoryModel(
            id: 1,
            nameEn: 'Lahm Bi Ajeen',
            nameAr: 'لحم بعجين',
          ),
          const CategoryModel(id: 2, nameEn: 'Pizza', nameAr: 'بيتزا'),
          const CategoryModel(id: 3, nameEn: 'Drinks', nameAr: 'مشروبات'),
        ];
      }
    }
    await _loadAllItems();
  }

  List<FoodItem> byCat(String c) {
    final found = _allCategories.firstWhere(
      (m) => m.nameAr == c || m.nameEn == c,
      orElse: () => CategoryModel(id: -1, nameEn: c, nameAr: c),
    );
    final names = {found.nameAr, found.nameEn};

    // Filter
    final filtered = items.where((e) => names.contains(e.category)).toList();

    // Sort based on local persistent order
    final order = adminFoodRepo.getCategoryOrder(found.nameAr); // Try Arabic name first
    if (order.isEmpty && found.nameAr != found.nameEn) {
      // Try English name if empty
      // Actually we save using selectedCategory which is Arabic name in UI usually
    }

    // If order exists, sort filtered list
    if (order.isNotEmpty) {
      // Create a map for O(1) lookup
      final orderMap = {for (var i = 0; i < order.length; i++) order[i]: i};
      filtered.sort((a, b) {
        final idxA = orderMap[a.id] ?? 999999;
        final idxB = orderMap[b.id] ?? 999999;
        if (idxA == idxB) return a.name.compareTo(b.name);
        return idxA.compareTo(idxB);
      });
    }

    return filtered;
  }

  Future<void> _loadAllItems() async {
    if (mounted) setState(() => _isLoading = true);
    final allItems = await repo.fetchAllFresh();
    if (mounted) {
      setState(() {
        items = allItems;
        _isLoading = false;
      });
    }
  }

  void _addItem() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final imageCtrl = TextEditingController();

    // Fix: Find the correct initial English name for the dropdown
    String? dialogSelectedCat;
    if (selectedCategory != null && selectedCategory != '__ALL__') {
      try {
        final cat = _allCategories.firstWhere(
          (c) => c.nameAr == selectedCategory || c.nameEn == selectedCategory,
        );
        dialogSelectedCat = cat.nameEn;
      } catch (_) {
        // If not found or selectedCategory is invalid, leave as null (or default to first)
        if (_allCategories.isNotEmpty) {
          dialogSelectedCat = _allCategories.first.nameEn;
        }
      }
    } else if (_allCategories.isNotEmpty) {
      // Default to first category if 'All' is selected
      dialogSelectedCat = _allCategories.first.nameEn;
    }

    bool uploading = false;
    Future<void> pickAndUpload() async {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: false,
      );
      if (res == null || res.files.isEmpty) return;
      final f = res.files.first;
      final path = f.path;
      if (path == null) return;
      final client = SupabaseManager.client;
      if (client == null) return;
      final file = File(path);
      final name = f.name.replaceAll(' ', '_');
      final key = 'items/${DateTime.now().millisecondsSinceEpoch}_$name';
      uploading = true;
      try {
        await client.storage.from('food-images').upload(key, file);
        final publicUrl = client.storage.from('food-images').getPublicUrl(key);
        imageCtrl.text = publicUrl;
      } finally {
        uploading = false;
      }
    }

    bool isActive = true;
    showDialog(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cs.surface,
              title: const Text('إضافة صنف جديد'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: dialogSelectedCat,
                        items: _allCategories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.nameEn,
                                child: Text('${c.nameAr} (${c.nameEn})'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            dialogSelectedCat = v ?? dialogSelectedCat,
                        decoration: const InputDecoration(labelText: 'القسم'),
                      ),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'الاسم'),
                      ),
                      TextField(
                        controller: priceCtrl,
                        decoration: const InputDecoration(labelText: 'السعر'),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: descCtrl,
                        decoration: const InputDecoration(labelText: 'الوصف'),
                        maxLines: 3,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: imageCtrl,
                              decoration: const InputDecoration(
                                labelText: 'رابط الصورة',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: uploading ? null : pickAndUpload,
                            child: Text(
                              uploading ? 'جارٍ الرفع...' : 'رفع صورة',
                            ),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        value: isActive,
                        onChanged: (v) {
                          setDialogState(() {
                            isActive = v;
                          });
                        },
                        title: const Text('متاح؟'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (dialogSelectedCat == null) return;
                    final price = double.tryParse(priceCtrl.text) ?? 0;
                    final newItem = FoodItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameCtrl.text,
                      price: price,
                      description: descCtrl.text,
                      imageUrl: imageCtrl.text,
                      category: dialogSelectedCat!,
                      isAvailable: isActive,
                    );
                    final ok = await adminFoodRepo.add(newItem);
                    if (!ok) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تعذر حفظ الصنف')),
                        );
                      }
                      return;
                    }
                    await _loadAllItems();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editItem(FoodItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(text: item.price.toString());
    final descCtrl = TextEditingController(text: item.description);
    final imageCtrl = TextEditingController(text: item.imageUrl);
    bool uploading = false;
    Future<void> pickAndUpload() async {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: false,
      );
      if (res == null || res.files.isEmpty) return;
      final f = res.files.first;
      final path = f.path;
      if (path == null) return;
      final client = SupabaseManager.client;
      if (client == null) return;
      final file = File(path);
      final name = f.name.replaceAll(' ', '_');
      final key = 'items/${DateTime.now().millisecondsSinceEpoch}_$name';
      uploading = true;
      try {
        await client.storage.from('food-images').upload(key, file);
        final publicUrl = client.storage.from('food-images').getPublicUrl(key);
        imageCtrl.text = publicUrl;
      } finally {
        uploading = false;
      }
    }

    bool isActive = item.isAvailable;
    showDialog(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cs.surface,
              title: const Text('تعديل الصنف'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'الاسم'),
                      ),
                      TextField(
                        controller: priceCtrl,
                        decoration: const InputDecoration(labelText: 'السعر'),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: descCtrl,
                        decoration: const InputDecoration(labelText: 'الوصف'),
                        maxLines: 3,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: imageCtrl,
                              decoration: const InputDecoration(
                                labelText: 'رابط الصورة',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: uploading ? null : pickAndUpload,
                            child: Text(
                              uploading ? 'جارٍ الرفع...' : 'رفع صورة',
                            ),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        value: isActive,
                        onChanged: (v) {
                          setDialogState(() {
                            isActive = v;
                          });
                        },
                        title: const Text('متاح؟'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final updated = item.copyWith(
                      name: nameCtrl.text,
                      price: double.tryParse(priceCtrl.text) ?? item.price,
                      description: descCtrl.text,
                      imageUrl: imageCtrl.text,
                      isAvailable: isActive,
                    );
                    setState(() {
                      final idx = items.indexWhere((e) => e.id == item.id);
                      items[idx] = updated;
                    });
                    final ok = await adminFoodRepo.update(updated);
                    if (!ok) {
                      setState(() {
                        final idx = items.indexWhere((e) => e.id == item.id);
                        items[idx] = item;
                      });
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تعذر حفظ التغيير')),
                      );
                      return;
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    await _loadAllItems();
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<FoodItem> _getSortedList() {
    if (selectedCategory == null) return [];

    List<FoodItem> rawList;
    if (selectedCategory == '__ALL__') {
      rawList = List.from(items);
    } else {
      rawList = byCat(selectedCategory!);
    }

    // Default to sorting by ID descending (Newest first) since we removed manual reordering
    // This matches the "Publishing Order" request (Added first -> appears last in list? No, Newest First is usually desired)
    // User said: "Anything I add first... appears last".
    // If list is [Newest, ..., Oldest], then Oldest is last.
    // So Descending ID sort is correct.
    rawList.sort((a, b) => b.id.compareTo(a.id));

    return rawList;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final list = _getSortedList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 240,
            child: ListView(
              children: [
                ListTile(
                  title: const Text('كل العناصر'),
                  selected: selectedCategory == '__ALL__',
                  onTap: () => setState(() => selectedCategory = '__ALL__'),
                ),
                ..._allCategories.map((cat) {
                  return ListTile(
                    title: Text(cat.nameAr),
                    selected: selectedCategory == cat.nameAr,
                    onTap: () => setState(() => selectedCategory = cat.nameAr),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: _addItem,
                        child: const Text('إضافة صنف'),
                      ),
                      const SizedBox(width: 12),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.category),
                        label: const Text('إدارة الأقسام'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminCategoriesScreen(),
                            ),
                          );
                          _loadData();
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : list.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.inbox,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد عناصر في هذا القسم',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadAllItems,
                                child: const Text('تحديث البيانات'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final it = list[index];
                            return Container(
                              key: ValueKey(it.id),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    it.imageUrl,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 56,
                                      height: 56,
                                      color: Colors.black26,
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                                title: Text(it.name),
                                subtitle: Text(
                                  '${it.price % 1 == 0 ? it.price.toInt() : it.price} IQD',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const Icon(Icons.drag_handle),
                                    ),
                                    Switch(
                                      value: it.isAvailable,
                                      onChanged: (v) async {
                                        final updated = it.copyWith(
                                          isAvailable: v,
                                        );
                                        setState(() {
                                          final idx = items.indexWhere(
                                            (e) => e.id == it.id,
                                          );
                                          if (idx != -1) items[idx] = updated;
                                          final li = list.indexWhere(
                                            (e) => e.id == it.id,
                                          );
                                          if (li != -1) list[li] = updated;
                                        });
                                        final ok = await adminFoodRepo.update(updated);
                                        if (!ok) {
                                          setState(() {
                                            final idx = items.indexWhere(
                                              (e) => e.id == it.id,
                                            );
                                            if (idx != -1) items[idx] = it;
                                            final li = list.indexWhere(
                                              (e) => e.id == it.id,
                                            );
                                            if (li != -1) list[li] = it;
                                          });
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('تعذر حفظ التغيير'),
                                            ),
                                          );
                                        } else {
                                          await _loadAllItems();
                                        }
                                      },
                                    ),
                                    IconButton(
                                      onPressed: () => _editItem(it),
                                      icon: const Icon(Icons.edit),
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        final ok = await showDialog<bool>(
                                          context: context,
                                          builder: (context) {
                                            final cs2 = Theme.of(
                                              context,
                                            ).colorScheme;
                                            return AlertDialog(
                                              backgroundColor: cs2.surface,
                                              title: const Text('حذف الصنف'),
                                              content: const Text(
                                                'هل تريد حذف هذا الصنف بشكل نهائي؟',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('إلغاء'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text('حذف'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                        if (ok == true) {
                                          final success = await adminFoodRepo.delete(
                                            it.id,
                                          );
                                          if (success) {
                                            setState(() {
                                              items.removeWhere(
                                                (e) => e.id == it.id,
                                              );
                                            });
                                          } else {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'تعذر حذف العنصر (قد يكون مرتبط بطلبات سابقة)',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.delete),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
