import 'package:flutter/material.dart';
import '../../core/repos/offers_repository.dart';

class AdminOffersScreen extends StatefulWidget {
  const AdminOffersScreen({super.key});

  @override
  State<AdminOffersScreen> createState() => _AdminOffersScreenState();
}

class _AdminOffersScreenState extends State<AdminOffersScreen> {
  final repo = OffersRepository();
  final ctrl = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final link = await repo.getLink();
    ctrl.text = link ?? '';
    setState(() => loading = false);
  }

  Future<void> _save() async {
    setState(() => loading = true);
    await repo.setLink(ctrl.text.trim());
    setState(() => loading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم الحفظ'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _delete() async {
    setState(() => loading = true);
    await repo.deleteLink();
    ctrl.clear();
    setState(() => loading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم الحذف'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'رابط العروض',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'https://example.com/banner.png أو رابط صفحة',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: loading ? null : _save,
                      child: const Text('حفظ'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: loading ? null : _load,
                      child: const Text('تحديث'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: loading ? null : _delete,
                      child: const Text('حذف'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final link = ctrl.text.trim();
                    if (link.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final lower = link.toLowerCase();
                    final isImage =
                        lower.endsWith('.png') ||
                        lower.endsWith('.jpg') ||
                        lower.endsWith('.jpeg') ||
                        lower.endsWith('.webp');
                    if (isImage) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            link,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Text(link),
                          ),
                        ),
                      );
                    }
                    return Text(
                      link,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
