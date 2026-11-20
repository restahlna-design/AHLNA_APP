import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/food_item.dart';
import '../widgets/metallic_rotating_painter.dart';
import '../core/ui_utils.dart';
import '../core/cart.dart';
import '../core/animations/fly_animation.dart';
import 'details_screen.dart';

class CategoryContent extends StatefulWidget {
  final String category;
  final List<FoodItem> initialItems;
  final Stream<List<FoodItem>> stream;
  final ValueListenable<String> search;
  final ValueListenable<String?> offerLink;
  final GlobalKey cartKey;

  const CategoryContent({
    super.key,
    required this.category,
    required this.initialItems,
    required this.stream,
    required this.search,
    required this.offerLink,
    required this.cartKey,
  });

  @override
  State<CategoryContent> createState() => _CategoryContentState();
}

class _CategoryContentState extends State<CategoryContent>
    with AutomaticKeepAliveClientMixin {
  // NOTE: No FoodRepository here — data is fed exclusively from HomeScreen
  // via the `stream` prop. Creating a repo here caused multiple WebSocket
  // connections that iOS (NSURLSession) silently drops, causing empty screens.
  late List<FoodItem> _items = widget.initialItems;
  late PageController _pageController;
  double _currentPage = 0.0;
  String _query = '';
  bool _loaded = false;
  StreamSubscription<List<FoodItem>>? _streamSub;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // نعتبر البيانات محملة دائماً — سواء كان القسم فارغاً أو به منتجات
    _loaded = true;
    _subscribeStream(widget.stream);
    _query = widget.search.value;
    widget.search.addListener(_onSearchChanged);
    _pageController = PageController(viewportFraction: 1.0);
    _currentPage = _pageController.initialPage.toDouble();
    _pageController.addListener(_onPageChanged);
  }

  void _onSearchChanged() {
    if (mounted) setState(() => _query = widget.search.value);
  }

  void _onPageChanged() {
    final p = _pageController.page;
    if (p != null && mounted) setState(() => _currentPage = p);
  }

  void _subscribeStream(Stream<List<FoodItem>> stream) {
    _streamSub?.cancel();
    _streamSub = stream.listen((data) {
      if (mounted) {
        if (data.isNotEmpty || _items.isEmpty) {
          setState(() {
            _items = data;
            _loaded = true;
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(CategoryContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialItems != oldWidget.initialItems ||
        oldWidget.category != widget.category) {
      setState(() {
        _items = widget.initialItems;
        _loaded = true;
      });
    }
    if (oldWidget.stream != widget.stream ||
        oldWidget.category != widget.category) {
      _subscribeStream(widget.stream);
    }
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    widget.search.removeListener(_onSearchChanged);
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final data = _query.isEmpty
        ? _items
        : _items.where((e) {
            final q = _query.toLowerCase();
            return e.name.toLowerCase().contains(q) ||
                e.description.toLowerCase().contains(q);
          }).toList();

    if (data.isEmpty) {
      if (!_loaded) {
        return const Center(child: CircularProgressIndicator());
      }
      // القسم فارغ بالفعل — لا توجد منتجات مضافة لهذا القسم
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'لا توجد منتجات في هذا القسم',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_query.isNotEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = data[index];
          final disabled = !item.isAvailable;
          return Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Opacity(
                  opacity: disabled ? 0.45 : 1.0,
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.fastfood, color: Colors.grey),
                  ),
                ),
              ),
              title: Text(
                item.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: disabled
                      ? Colors.grey
                      : theme.textTheme.bodyLarge?.color,
                ),
              ),
              subtitle: Text(
                '${item.price % 1 == 0 ? item.price.toInt() : item.price} IQD',
                style: TextStyle(
                  color: disabled ? Colors.grey : theme.primaryColor,
                ),
              ),
              trailing: disabled
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('تم نفاذ الكمية'),
                    )
                  : null,
              onTap: () {
                if (disabled) {
                  showModernSnackBar(
                    context,
                    'تم نفاذ الكمية ⚠️',
                    color: Colors.grey,
                    icon: Icons.warning_amber_rounded,
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailsScreen(item: item)),
                );
              },
            ),
          );
        },
      );
    }

    return Stack(
      children: [
        Positioned(
          top: 15,
          left: 16,
          right: 16,
          height: 130,
          child: _buildOffersSectionDynamic(context, widget.offerLink),
        ),

        Positioned.fill(
          child: PageView.builder(
            controller: _pageController,
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              final dimmed = !item.isAvailable;
              final delta = (index - _currentPage);
              final imageScale = 1.0 - 0.06 * delta.abs();
              final imageTranslate = Offset(delta * 40, -10 * delta);
              final cardTranslate = Offset(0, 24 * delta.abs());

              return Container(
                color: Colors.transparent,
                child: Stack(
                  children: [
                    Center(
                      child: Opacity(
                        opacity: dimmed ? 0.45 : 1.0,
                        child: IgnorePointer(
                          ignoring: dimmed,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailsScreen(item: item),
                                ),
                              );
                            },
                            child: Transform.translate(
                              offset: imageTranslate,
                              child: Transform.scale(
                                scale: imageScale.clamp(0.85, 1.0),
                                child: Hero(
                                  tag: item.id,
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.58,
                                    height:
                                        MediaQuery.of(context).size.width *
                                        0.58,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.15,
                                          ),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: CachedNetworkImage(
                                      imageUrl: item.imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    _FoodDetailCard(
                      item: item,
                      dimmed: dimmed,
                      theme: theme,
                      cardTranslate: cardTranslate,
                      cartKey: widget.cartKey,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOffersSectionDynamic(
    BuildContext context,
    ValueListenable<String?> linkController,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ValueListenableBuilder<String?>(
        valueListenable: linkController,
        builder: (context, link, _) {
          bool hasValidLink = false;
          if (link != null && link.isNotEmpty) {
            final lower = link.toLowerCase();
            hasValidLink =
                lower.endsWith('.png') ||
                lower.endsWith('.jpg') ||
                lower.endsWith('.jpeg') ||
                lower.endsWith('.webp');
          }

          if (!hasValidLink) {
            return _buildPlaceholderWidget(theme);
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: link!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorWidget: (context, url, error) {
                return _buildPlaceholderWidget(theme);
              },
              placeholder: (context, url) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildPlaceholderWidget(theme),
                    Center(
                      child: CircularProgressIndicator(
                        color: theme.primaryColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderWidget(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_rounded,
              color: theme.primaryColor,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              "مساحة العروض الحصرية",
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              "قريباً...",
              style: TextStyle(
                color: theme.primaryColor.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodDetailCard extends StatefulWidget {
  final FoodItem item;
  final bool dimmed;
  final ThemeData theme;
  final Offset cardTranslate;
  final GlobalKey cartKey;

  const _FoodDetailCard({
    required this.item,
    required this.dimmed,
    required this.theme,
    required this.cardTranslate,
    required this.cartKey,
  });

  @override
  State<_FoodDetailCard> createState() => _FoodDetailCardState();
}

class _FoodDetailCardState extends State<_FoodDetailCard>
    with TickerProviderStateMixin {
  int _selectedVariant = 0;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_FoodDetailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.id != oldWidget.item.id) {
      _selectedVariant = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasVariants = widget.item.variants.isNotEmpty;
    final activeVariant = hasVariants
        ? widget.item.variants[_selectedVariant.clamp(0, widget.item.variants.length - 1)]
        : null;
    final currentPrice = (activeVariant != null && activeVariant.price > 0)
        ? activeVariant.price
        : widget.item.price;
    final itemToAdd = activeVariant != null
        ? widget.item.copyWith(
            id: '${widget.item.id}_${activeVariant.name}',
            name: '${widget.item.name} (${activeVariant.name})',
            price: currentPrice,
          )
        : widget.item;

    final isDark = widget.theme.brightness == Brightness.dark;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Transform.translate(
        offset: widget.cardTranslate,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 92, left: 14, right: 14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              color: widget.theme.cardColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Text(
                widget.item.name,
                textAlign: TextAlign.center,
                style: widget.theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.dimmed ? Colors.grey : null,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  '${currentPrice % 1 == 0 ? currentPrice.toInt() : currentPrice} IQD',
                  key: ValueKey<double>(currentPrice),
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: widget.dimmed
                        ? Colors.grey
                        : widget.theme.primaryColor,
                  ),
                ),
              ),
              if (widget.item.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.item.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF334155),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                height: 42,
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, _) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. أزرار الأحجام / الخيارات (على اليمين في واجهة RTL)
                        if (hasVariants)
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(widget.item.variants.length, (i) {
                                  final v = widget.item.variants[i];
                                  final isSelected = i == _selectedVariant;

                                  final innerBg = isDark
                                      ? const Color(0xFF13171F).withValues(alpha: 0.90)
                                      : Colors.white.withValues(alpha: 0.95);

                                  Widget pill;
                                  if (isSelected) {
                                    pill = Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(999),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.20),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(999),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Positioned.fill(
                                              child: CustomPaint(
                                                painter: MetallicRotatingPainter(
                                                  progress: _rotationController.value,
                                                  isDark: isDark,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(2.0),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(999),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                                  decoration: BoxDecoration(
                                                    color: innerBg,
                                                    borderRadius: BorderRadius.circular(999),
                                                  ),
                                                  child: Text(
                                                    v.name,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontFamily: 'Tajawal',
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  } else {
                                    pill = InkWell(
                                      onTap: widget.dimmed
                                          ? null
                                          : () {
                                              setState(() {
                                                _selectedVariant = i;
                                              });
                                            },
                                      borderRadius: BorderRadius.circular(999),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF1E293B).withValues(alpha: 0.45)
                                              : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(
                                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Text(
                                          v.name,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  return Padding(
                                    padding: EdgeInsets.only(left: i == widget.item.variants.length - 1 ? 0 : 8),
                                    child: pill,
                                  );
                                }),
                              ),
                            ),
                          )
                        else
                          const Spacer(),

                        const SizedBox(width: 10),

                        // 2. زر (+) مع إطار الستيل الدوار حول حوافه كبقية أزرار التطبيق
                        Builder(
                          builder: (btnContext) {
                            final innerBg = isDark
                                ? const Color(0xFF13171F).withValues(alpha: 0.92)
                                : Colors.white.withValues(alpha: 0.95);

                            return GestureDetector(
                              onTap: widget.dimmed
                                  ? () {
                                      showModernSnackBar(
                                        context,
                                        'تم نفاذ الكمية ⚠️',
                                        color: Colors.grey,
                                        icon: Icons.warning_amber_rounded,
                                      );
                                    }
                                  : () async {
                                      final connectivityResult =
                                          await Connectivity().checkConnectivity();
                                      if (!context.mounted) return;
                                      if (connectivityResult.contains(ConnectivityResult.none)) {
                                        showModernSnackBar(
                                          context,
                                          'يرجى التحقق من اتصال الإنترنت للطلب 🌐',
                                          color: Colors.redAccent,
                                          icon: Icons.wifi_off,
                                        );
                                        return;
                                      }

                                      FlyAnimation.run(
                                        context,
                                        cartKey: widget.cartKey,
                                        buttonContext: btnContext,
                                        imageUrl: widget.item.imageUrl,
                                        onComplete: () {
                                          CartProvider.of(context).add(itemToAdd);
                                        },
                                      );
                                    },
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.40 : 0.25),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: MetallicRotatingPainter(
                                            progress: _rotationController.value,
                                            isDark: isDark,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(2.2),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(999),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: innerBg,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.add,
                                                color: Color(0xFF10B981),
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
