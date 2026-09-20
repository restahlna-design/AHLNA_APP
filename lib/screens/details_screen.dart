import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/food_item.dart';
import '../widgets/elastic_button.dart';
import '../core/cart.dart';
import '../core/ui_utils.dart';

// ✅ دالة مساعدة لعرض toast أنيق عند إضافة المنتج للسلة (1 ثانية)
void _showAddedToCartToast(BuildContext context) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => Positioned(
      top: 70,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: _CartToastBubble(
          onDismiss: () {
            if (entry.mounted) entry.remove();
          },
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 1200), () {
    if (entry.mounted) entry.remove();
  });
}

class DetailsScreen extends StatefulWidget {
  final FoodItem item;
  const DetailsScreen({super.key, required this.item});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _qtyController;
  bool _initialized = false;
  late final AnimationController _rotController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '1');
    _rotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _rotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cart = CartProvider.of(context);
    if (!_initialized) {
      final existing = cart.quantityFor(widget.item.id);
      _qtyController.text = (existing > 0 ? existing : 1).toString();
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Hero(
                    tag: widget.item.id,
                    child: RotationTransition(
                      turns: _rotController,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.58,
                        height: MediaQuery.of(context).size.width * 0.58,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        clipBehavior: Clip.antiAlias,
                        child: CachedNetworkImage(
                          imageUrl: widget.item.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) {
                            return Container(
                              color: Colors.black26,
                              child: const Center(
                                child: Icon(Icons.broken_image),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.item.price % 1 == 0 ? widget.item.price.toInt() : widget.item.price} IQD',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: cs.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.item.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'الكمية',
                              hintText: 'اكتب العدد المطلوب',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElasticButton(
                            onPressed: widget.item.isAvailable
                                ? () async {
                                    final ctx = context;
                                    final connectivityResult = await Connectivity().checkConnectivity();
                                    if (connectivityResult.contains(ConnectivityResult.none)) {
                                      if (ctx.mounted) {
                                        showModernSnackBar(ctx, 'يرجى التحقق من اتصال الإنترنت للطلب 🌐', color: Colors.redAccent, icon: Icons.wifi_off);
                                      }
                                      return;
                                    }

                                    final qty =
                                        int.tryParse(_qtyController.text) ?? 1;
                                    final finalQty = qty < 1 ? 1 : qty;
                                    cart.setQuantity(widget.item, finalQty);

                                    // ✅ عرض رسالة Toast أنيقة: "تمت الإضافة إلى السلة" لمدة 1 ثانية
                                    if (ctx.mounted) {
                                      _showAddedToCartToast(ctx);
                                    }
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: widget.item.isAvailable
                                    ? cs.primary
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  widget.item.isAvailable
                                      ? 'أضف إلى السلة'
                                      : 'تم نفاذ الكمية',
                                  style: TextStyle(
                                    color: widget.item.isAvailable
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w700,
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
            ],
          ),
        ),
      ),
    );
  }
}

// 🎨 ودجت فقاعة Toast الأنيقة لإضافة المنتج إلى السلة
class _CartToastBubble extends StatefulWidget {
  final VoidCallback onDismiss;
  const _CartToastBubble({required this.onDismiss});

  @override
  State<_CartToastBubble> createState() => _CartToastBubbleState();
}

class _CartToastBubbleState extends State<_CartToastBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();

    // بعد 900ms نبدأ بالإخفاء
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        _ctrl.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withValues(alpha: 0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart_checkout_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 10),
              const Text(
                'تمت الإضافة إلى السلة ✓',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
