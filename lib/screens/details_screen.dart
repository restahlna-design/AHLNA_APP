import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/food_item.dart';
import '../widgets/elastic_button.dart';
import '../core/cart.dart';
import '../core/ui_utils.dart';

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
                                    final connectivityResult = await Connectivity().checkConnectivity();
                                    if (connectivityResult.contains(ConnectivityResult.none)) {
                                      showModernSnackBar(context, 'يرجى التحقق من اتصال الإنترنت للطلب 🌐', color: Colors.redAccent, icon: Icons.wifi_off);
                                      return;
                                    }

                                    final qty =
                                        int.tryParse(_qtyController.text) ?? 1;
                                    final finalQty = qty < 1 ? 1 : qty;
                                    cart.setQuantity(widget.item, finalQty);
                                    // ScaffoldMessenger.of(context).showSnackBar(
                                    //   SnackBar(
                                    //     content: const Text(
                                    //       'تمت الإضافة إلى السلة',
                                    //     ),
                                    //     duration: const Duration(
                                    //       milliseconds: 500,
                                    //     ),
                                    //     behavior: SnackBarBehavior.floating,
                                    //     margin: const EdgeInsets.symmetric(
                                    //       horizontal: 100,
                                    //       vertical: 20,
                                    //     ),
                                    //     shape: RoundedRectangleBorder(
                                    //       borderRadius: BorderRadius.circular(
                                    //         12,
                                    //       ),
                                    //     ),
                                    //   ),
                                    // );
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
