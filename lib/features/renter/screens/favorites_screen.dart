import 'package:flutter/material.dart';
import 'package:rentease/features/renter/screens/property_detail_screen.dart';

import '../../../models/property_model.dart';
import '../../../services/favorite_service.dart';
import '../../../services/property_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoriteService favoriteService = FavoriteService();
  final PropertyService propertyService = PropertyService();

  List<Property> favorites = [];
  bool loading = false;

  static const Color _primary = Color(0xFF4F46E5);
  static const Color _danger = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    if (mounted) {
      setState(() => loading = true);
    }

    final ids = await favoriteService.getFavoriteIds();
    final allProperties = await propertyService.getProperties();

    favorites = allProperties
        .where((property) => ids.contains(property.id))
        .toList();

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> removeFavorite(String propertyId) async {
    await favoriteService.removeFavorite(propertyId);
    await loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,

      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,

        // leading: IconButton(
        //   icon: Icon(
        //     Icons.arrow_back_ios_new_rounded,
        //     size: 20,
        //     color: colors.onSurface,
        //   ),
        //   onPressed: () => Navigator.pop(context),
        // ),
        title: Text(
          "Favorites",
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),

        centerTitle: true,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : favorites.isEmpty
          ? _emptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              physics: const BouncingScrollPhysics(),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final property = favorites[index];

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(
                    milliseconds: 300 + (index * 50).clamp(0, 300),
                  ),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 16 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: _favoriteCard(property),
                );
              },
            ),
    );
  }

  // ============================================================
  // FAVORITE CARD
  // ============================================================

  Widget _favoriteCard(Property property) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Dismissible(
      key: Key(property.id),

      direction: DismissDirection.endToStart,

      background: const SizedBox(),

      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: _danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
            SizedBox(height: 4),
            Text(
              "Delete",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),

      confirmDismiss: (direction) async {
        return await _showRemoveDialog(property);
      },

      onDismissed: (_) async {
        await removeFavorite(property.id);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Removed “${property.title}”"),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: colors.inverseSurface,
            action: SnackBarAction(
              label: "OK",
              textColor: colors.onInverseSurface,
              onPressed: () {},
            ),
          ),
        );
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 12),

        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.04,
              ),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),

        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),

          child: InkWell(
            borderRadius: BorderRadius.circular(16),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PropertyDetailScreen(property: property),
                ),
              );
            },

            child: Padding(
              padding: const EdgeInsets.all(10),

              child: Row(
                children: [
                  // ==================================================
                  // IMAGE
                  // ==================================================
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),

                    child: Image.network(
                      property.imageUrl,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,

                      errorBuilder: (_, __, ___) {
                        return Container(
                          width: 88,
                          height: 88,
                          color: colors.surfaceContainerHighest,
                          child: Icon(
                            Icons.home_rounded,
                            color: colors.onSurfaceVariant,
                            size: 32,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ==================================================
                  // PROPERTY INFO
                  // ==================================================
                  Expanded(
                    child: SizedBox(
                      height: 88,

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          Text(
                            property.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: colors.onSurfaceVariant,
                              ),

                              const SizedBox(width: 3),

                              Expanded(
                                child: Text(
                                  property.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,

                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Text(
                                "\$${property.price.toStringAsFixed(0)}",

                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _primary,
                                ),
                              ),

                              const SizedBox(width: 2),

                              Text(
                                "/mo",

                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const Spacer(),

                              Text(
                                "${property.bedrooms}B · ${property.bathrooms}Ba",

                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.only(left: 6),

                    child: Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFEF4444),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REMOVE FAVORITE DIALOG
  // ============================================================

  Future<bool> _showRemoveDialog(Property property) async {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final result = await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surface,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),

          content: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              Container(
                width: 52,
                height: 52,

                decoration: BoxDecoration(
                  color: _danger.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.favorite_border_rounded,
                  color: _danger,
                  size: 26,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "Remove favorite?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "“${property.title}” will be removed from your favorites.",

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 14,
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,

                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, false);
                        },

                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.onSurface,

                          side: BorderSide(
                            color: colors.outline.withOpacity(0.5),
                            width: 1.5,
                          ),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),

                        child: const Text(
                          "Cancel",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: SizedBox(
                      height: 46,

                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, true);
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: _danger,
                          foregroundColor: Colors.white,
                          elevation: 0,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),

                        child: const Text(
                          "Remove",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    return result ?? false;
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          Container(
            width: 72,
            height: 72,

            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.favorite_border_rounded,
              size: 36,
              color: _primary,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            "No favorites yet",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Properties you like will appear here",

            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
