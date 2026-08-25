import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../widgets/elastic_button.dart';
import '../core/profile.dart';
import '../core/repos/profile_repository.dart';
import '../core/storage.dart';

import '../screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- المنطق البرمجي (لم يتم تغييره) ---
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _loaded = false;
  File? _localImage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // 1. الحصول على مسار التخزين المحلي الدائم للتطبيق
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(pickedFile.path);
      final savedImage = await File(
        pickedFile.path,
      ).copy('${appDir.path}/$fileName');

      // 2. حفظ المسار في التخزين المحلي
      await Storage.saveProfileImage(savedImage.path);

      // 3. تحديث الواجهة
      if (mounted) {
        setState(() {
          _localImage = savedImage;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() ?? false) {
      final profile = ProfileProvider.of(context);
      profile.set(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );
      final repo = ProfileRepository();
      final ok = await repo.upsert(
        phone: profile.phone,
        name: profile.name,
        address: profile.address,
      );
      await Storage.saveProfile(
        name: profile.name,
        phone: profile.phone,
        address: profile.address,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'تم حفظ البيانات'
                : 'تعذر تحديث قاعدة البيانات، تم الحفظ محليًا',
          ),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await Storage.clearUser();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب نهائياً'),
        content: const Text(
          'هل أنت متأكد من أنك تريد حذف حسابك؟ هذا الإجراء لا يمكن التراجع عنه وسيتم مسح جميع بياناتك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف الحساب'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;

      // إظهار مؤشر تحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final profile = ProfileProvider.of(context);
        final repo = ProfileRepository();

        // حذف من قاعدة البيانات
        await repo.delete(profile.phone);

        // حذف من التخزين المحلي
        await Storage.clearUser();

        if (!mounted) return;
        Navigator.pop(context); // إغلاق مؤشر التحميل

        // الانتقال لشاشة تسجيل الدخول
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // إغلاق مؤشر التحميل
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الحذف: $e')));
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // تحميل الصورة المحلية
      final imagePath = await Storage.loadProfileImage();
      if (imagePath != null) {
        final file = File(imagePath);
        if (await file.exists()) {
          setState(() {
            _localImage = file;
          });
        }
      }

      final profile = ProfileProvider.of(context);
      if (profile.phone.isEmpty ||
          profile.name.isEmpty ||
          profile.address.isEmpty) {
        final local = await Storage.loadProfile();
        profile.set(
          name: local['name'],
          phone: local['phone'],
          address: local['address'],
        );
      }
      _nameController.text = profile.name;
      _phoneController.text = profile.phone;
      _addressController.text = profile.address;
      if (profile.phone.isNotEmpty) {
        final repo = ProfileRepository();
        final remote = await repo.getByPhone(profile.phone);
        if (remote != null) {
          final name = (remote['name'] ?? '') as String;
          final phone = (remote['phone'] ?? '') as String;
          final address = (remote['address'] ?? '') as String;
          profile.set(name: name, phone: phone, address: address);
          _nameController.text = name;
          _phoneController.text = phone;
          _addressController.text = address;
        }
      }
    });
  }
  // ------------------------------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // استبدال الألوان الثابتة بألوان من الثيم
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    // لون البطاقات من الثيم
    final cardColor = Theme.of(context).cardColor;
    // لون الحقول يعتمد على الثيم مع لمسة تمييز (لون باهت من اللون الأساسي)
    final inputColor = cs.primary.withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: backgroundColor,
      // جعلنا الـ AppBar شفافاً لدمج التصميم
      appBar: AppBar(
        title: Text(
          'الملف الشخصي',
          style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true, // للسماح للمحتوى بالظهور خلف الـ AppBar
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          100,
          16,
          24,
        ), // مساحة علوية للـ AppBar
        child: Column(
          children: [
            // --- قسم الهيدر (الصورة والاسم) ---
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cs.primary,
                            width: 2,
                          ), // إطار برتقالي
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: inputColor,
                          backgroundImage: _localImage != null
                              ? FileImage(_localImage!)
                              : null,
                          child: _localImage == null
                              ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: cs.primary.withValues(alpha: 0.7),
                                )
                              : null,
                        ),
                      ),
                      // أيقونة تعديل الصورة (للزينة حالياً)
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: backgroundColor,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // عرض الاسم ورقم الهاتف بشكل جميل
                  AnimatedBuilder(
                    animation: _nameController,
                    builder: (_, __) => Text(
                      _nameController.text.isNotEmpty
                          ? _nameController.text
                          : 'مستخدم جديد',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedBuilder(
                    animation: _phoneController,
                    builder: (_, __) => Text(
                      _phoneController.text.isNotEmpty
                          ? _phoneController.text
                          : '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- بطاقة نموذج البيانات ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildModernTextField(
                      controller: _nameController,
                      label: 'الاسم الكامل',
                      icon: Icons.account_circle_outlined,
                      cs: cs,
                      inputColor: inputColor,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'يرجى إدخال الاسم' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: _phoneController,
                      label: 'رقم الهاتف',
                      icon: Icons.phone_iphone_outlined,
                      cs: cs,
                      inputColor: inputColor,
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'يرجى إدخال رقم الهاتف'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: _addressController,
                      label: 'العنوان التفصيلي',
                      icon: Icons.location_on_outlined,
                      cs: cs,
                      inputColor: inputColor,
                      maxLines: 3,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'يرجى إدخال العنوان'
                          : null,
                    ),
                    const SizedBox(height: 32),

                    // --- أزرار الإجراءات ---
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ElasticButton(
                            onPressed: _save,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.primary.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'حفظ التعديلات',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElasticButton(
                            onPressed: _logout,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(
                                  color: cs.primary.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  'تسجيل خروج',
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- زر حذف الحساب ---
            ElasticButton(
              onPressed: _delete,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.delete_forever_outlined,
                      color: Colors.redAccent,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'حذف الحساب نهائياً',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- ودجت مساعدة لحقول الإدخال العصرية ---
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ColorScheme cs,
    required Color inputColor,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: cs.onSurface), // لون النص المدخل
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
        prefixIcon: Icon(icon, color: cs.primary),
        filled: true,
        fillColor: inputColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      validator: validator,
    );
  }
}
