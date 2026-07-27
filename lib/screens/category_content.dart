import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/food_item.dart';
import '../core/ui_utils.dart';
import '../core/cart.dart';
import '../core/animations/fly_animation.dart';
import 'details_screen.dart';
import '../core/repos/food_repository.dart';

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
  final repo = FoodRepository();
  late List<FoodItem> _items = widget.initialItems;
  late PageController _pageController;
  double _currentPage = 0.0;
  String _query = '';
  bool _loaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.stream.listen((data) {
      if (mounted) {
        if (data.isNotEmpty || _items.isEmpty) {
          setState(() {
            _items = data;
            _loaded = true;
          });
        }
      }
    });
    _query = widget.search.value;
    widget.search.addListener(() {
      if (mounted) setState(() => _query = widget.search.value);
    });
    _pageController = PageController(viewportFraction: 1.0);
    _currentPage = _pageController.initialPage.toDouble();
    _pageController.addListener(() {
      final p = _pageController.page;
      if (p != null && mounted) setState(() => _currentPage = p);
    });
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('جاري مزامنة القائمة مع قاعدة البيانات...', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final fresh = await repo.fetchAllFresh();
                if (mounted) {
                  setState(() {
                    _items = fresh;
                    _loaded = true;
                  });
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث البيانات الآن'),
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
                  color: Colors.black.withOpacity(0.05),
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
                  color: disabled ? Colors.grey : theme.textTheme.bodyLarge?.color,
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
                  showModernSnackBar(context, 'تم نفاذ الكمية ⚠️', color: Colors.grey, icon: Icons.warning_amber_rounded);
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
                                    width: MediaQuery.of(context).size.width * 0.62,
                                    height: MediaQuery.of(context).size.width * 0.62,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: CachedNetworkImage(
                                      imageUrl: item.imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
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

                    _buildBottomDetailCard(
                      context,
                      item,
                      dimmed,
                      theme,
                      cardTranslate,
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

  Widget _buildBottomDetailCard(
    BuildContext context,
    FoodItem item,
    bool dimmed,
    ThemeData theme,
    Offset cardTranslate,
  ) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Transform.translate(
        offset: cardTranslate,
        child: SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: dimmed ? Colors.grey : null,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.price % 1 == 0 ? item.price.toInt() : item.price} IQD',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: dimmed ? Colors.grey : theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Builder(
                      builder: (btnContext) => IconButton(
                        onPressed: dimmed
                            ? null
                            : () {
                                FlyAnimation.run(
                                  context,
                                  cartKey: widget.cartKey,
                                  buttonContext: btnContext,
                                  imageUrl: item.imageUrl,
                                  onComplete: () {
                                    CartProvider.of(context).add(item);
                                  },
                                );
                              },
                        icon: Icon(
                          Icons.add_circle,
                          color: dimmed ? Colors.grey : theme.primaryColor,
                          size: 34,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
            color: Colors.black.withOpacity(0.05),
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
                        color: theme.primaryColor.withOpacity(0.5),
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
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.3),
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
                color: theme.primaryColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
