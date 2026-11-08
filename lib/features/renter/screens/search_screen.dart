
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../../../models/property_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/session_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/property_service.dart';

import 'package:rentease/features/renter/screens/notification_screen.dart';
import 'package:rentease/features/renter/screens/property_detail_screen.dart';

import 'chat_list_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final PropertyService propertyService = PropertyService();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;

  bool _isLoadingProfile = true;
  bool _isLoadingFavorites = false;
  bool _isLoadingMore = false;
  bool _isInitialLoading = true;
  bool _hasMore = true;
  bool _isApplyingFilters = false;

  String searchQuery = '';
  String? selectedCategoryId;
  String? selectedCategoryName;

  int minBedrooms = 0;
  double? minPrice;
  double? maxPrice;

  final List<Property> properties = [];
  final Set<String> favoriteIds = {};

  DocumentSnapshot<Map<String, dynamic>>? lastDocument;

  String? errorMessage;
  String? loadMoreError;

  static const int pageSize = 6;

  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textColor = Color(0xFF0F172A);
  static const Color secondaryTextColor = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color favoriteColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();

    _loadRenterProfile();
    loadFirstPage();
    _loadFavorites();

    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    searchController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  void _onScroll() {
    if (!scrollController.hasClients) return;

    final position = scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 400 &&
        !_isLoadingMore &&
        !_isInitialLoading &&
        _hasMore) {
      loadMore();
    }
  }

  Future<void> loadFirstPage() async {
    if (!mounted) return;

    setState(() {
      _isInitialLoading = true;
      errorMessage = null;
      loadMoreError = null;
      properties.clear();
      lastDocument = null;
      _hasMore = true;
    });

    try {
      final result = await propertyService.getPublishedPropertiesPage(
        limit: pageSize,
      );

      if (!mounted) return;

      setState(() {
        properties.addAll(result.properties);
        lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
        _isInitialLoading = false;
      });

      // Load more pages if the current page does not fill the screen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && scrollController.hasClients && _hasMore) {
          if (scrollController.position.maxScrollExtent < 100) {
            loadMore();
          }
        }
      });
    } catch (e) {
      debugPrint('Load properties error: $e');

      if (!mounted) return;

      setState(() {
        _isInitialLoading = false;
        errorMessage = 'Unable to load properties. Please try again.';
      });
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore ||
        !_hasMore ||
        lastDocument == null ||
        _isInitialLoading) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoadingMore = true;
      loadMoreError = null;
    });

    try {
      final previousCursor = lastDocument;

      final result = await propertyService.getPublishedPropertiesPage(
        limit: pageSize,
        startAfter: previousCursor,
      );

      if (!mounted) return;

      setState(() {
        // Avoid adding the same property twice.
        for (final property in result.properties) {
          final exists = properties.any(
                (item) => _favoriteKey(item) == _favoriteKey(property),
          );

          if (!exists) {
            properties.add(property);
          }
        }

        lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !scrollController.hasClients || !_hasMore) return;

        if (scrollController.position.maxScrollExtent < 100) {
          loadMore();
        }
      });
    } catch (e) {
      debugPrint('Load more error: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingMore = false;
        loadMoreError = 'Could not load more properties.';
      });
    }
  }

  Future<void> refreshProperties() async {
    await loadFirstPage();
  }

  // ============================================================
  // RENTER PROFILE
  // ============================================================

  Future<void> _loadRenterProfile() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        if (mounted) {
          setState(() => _isLoadingProfile = false);
        }
        return;
      }

      final savedUser = await SessionService.getUser();

      if (savedUser != null && mounted) {
        setState(() {
          _currentUser = UserModel.fromJson(savedUser);
          _isLoadingProfile = false;
        });
      }

      final userData = await AuthService().getUserData(firebaseUser.uid);

      if (userData != null && mounted) {
        setState(() {
          _currentUser = userData;
          _isLoadingProfile = false;
        });

        await SessionService.saveUser(userData.toJson());
      } else if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      debugPrint('Load renter profile error: $e');

      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  // ============================================================
  // FAVORITES
  // ============================================================
  //
  // Firestore path:
  // users/{uid}/favorites/{encodedPropertyKey}
  //
  // This screen does not require a change to PropertyService.
  // The key is built from existing Property fields because the
  // supplied code does not show a Property document ID field.
  // ============================================================

  String _favoriteKey(Property property) {
    return Uri.encodeComponent(
      '${property.title}_${property.location}_${property.price}',
    );
  }

  Future<void> _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (mounted) {
      setState(() => _isLoadingFavorites = true);
    }

    try {
      final snapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      if (!mounted) return;

      setState(() {
        favoriteIds
          ..clear()
          ..addAll(snapshot.docs.map((doc) => doc.id));

        _isLoadingFavorites = false;
      });
    } catch (e) {
      debugPrint('Load favorites error: $e');

      if (mounted) {
        setState(() => _isLoadingFavorites = false);
      }
    }
  }

  Future<void> _toggleFavorite(Property property) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please sign in to save favorites.');
      return;
    }

    final key = _favoriteKey(property);
    final wasFavorite = favoriteIds.contains(key);

    // Optimistic UI update.
    setState(() {
      if (wasFavorite) {
        favoriteIds.remove(key);
      } else {
        favoriteIds.add(key);
      }
    });

    final favoriteRef = firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(key);

    try {
      if (wasFavorite) {
        await favoriteRef.delete();
      } else {
        await favoriteRef.set({
          'title': property.title,
          'location': property.location,
          'price': property.price,
          'imageUrl': property.imageUrl,
          'category': property.category,
          'savedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Toggle favorite error: $e');

      if (!mounted) return;

      // Restore UI if Firestore fails.
      setState(() {
        if (wasFavorite) {
          favoriteIds.add(key);
        } else {
          favoriteIds.remove(key);
        }
      });

      _showMessage(
        'Could not update favorites. Check your connection or permissions.',
      );
    }
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getCategories() {
    return firestore
        .collection('categories')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // ============================================================
  // SEARCH + FILTER
  // ============================================================

  List<Property> get filteredProperties {
    Iterable<Property> result = properties;

    if (selectedCategoryName != null &&
        selectedCategoryName!.trim().isNotEmpty) {
      result = result.where(
            (property) =>
        property.category.trim().toLowerCase() ==
            selectedCategoryName!.trim().toLowerCase(),
      );
    }

    if (searchQuery.isNotEmpty) {
      result = result.where((property) {
        final title = property.title.toLowerCase();
        final location = property.location.toLowerCase();
        final category = property.category.toLowerCase();
        final price = property.price.toString();

        return title.contains(searchQuery) ||
            location.contains(searchQuery) ||
            category.contains(searchQuery) ||
            price.contains(searchQuery);
      });
    }

    if (minPrice != null) {
      result = result.where((property) => property.price >= minPrice!);
    }

    if (maxPrice != null) {
      result = result.where((property) => property.price <= maxPrice!);
    }

    if (minBedrooms > 0) {
      result = result.where(
            (property) => property.bedrooms >= minBedrooms,
      );
    }

    return result.toList();
  }

  void _clearSearch() {
    searchController.clear();

    setState(() {
      searchQuery = '';
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 18),
            _buildCategoryChips(),
            const SizedBox(height: 16),
            _buildResultHeader(),
            Expanded(child: _buildPropertyResults()),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Row(
        children: [
          Expanded(child: _buildRenterProfile()),
          const SizedBox(width: 8),

          _headerIcon(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: 'Messages',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChatListScreen(),
                ),
              );
            },
            badge: user == null
                ? const SizedBox.shrink()
                : StreamBuilder<int>(
              stream: ChatService()
                  .getRenterUnreadMessageCount(user.uid),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return _buildCountBadge(count);
              },
            ),
          ),

          const SizedBox(width: 8),

          _headerIcon(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationsScreen(),
                ),
              );
            },
            badge: user == null
                ? const SizedBox.shrink()
                : StreamBuilder<int>(
              stream: NotificationService().getUnreadCount(user.uid),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return _buildCountBadge(count);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Widget? badge,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withOpacity(0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outline.withOpacity(0.15)),
          ),
          child: IconButton(
            onPressed: onPressed,
            tooltip: tooltip,
            icon: Icon(icon, color: colors.onSurface, size: 22),
          ),
        ),
        if (badge != null)
          Positioned(
            right: -3,
            top: -3,
            child: badge,
          ),
      ],
    );
  }

  Widget _buildCountBadge(int count) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: const BoxDecoration(
        color: favoriteColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // RENTER PROFILE
  // ============================================================

  Widget _buildRenterProfile() {
    final colors = Theme.of(context).colorScheme;

    if (_isLoadingProfile) {
      return const SizedBox(
        height: 46,
        width: 46,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final user = _currentUser;
    final name = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim()
        : 'Renter';

    final imageUrl = user?.profileImage?.trim() ?? '';

    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.outline.withOpacity(0.25),
            ),
          ),
          child: ClipOval(
            child: imageUrl.isEmpty
                ? _defaultProfileIcon()
                : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _defaultProfileIcon(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WELCOME BACK',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 9,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _defaultProfileIcon() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      color: colors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        color: colors.onSurfaceVariant,
        size: 26,
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withOpacity(0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outline.withOpacity(0.15)),
        ),
        child: TextField(
          controller: searchController,
          onChanged: (value) {
            setState(() {
              searchQuery = value.trim().toLowerCase();
            });
          },
          style: TextStyle(color: colors.onSurface, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search room, location or price...',
            hintStyle: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 13,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: colors.onSurfaceVariant,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (searchQuery.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: _clearSearch,
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.onSurfaceVariant,
                      size: 19,
                    ),
                  ),
                IconButton(
                  tooltip: 'Filters',
                  onPressed: _showFilterBottomSheet,
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY CHIPS
  // ============================================================

  Widget _buildCategoryChips() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: getCategories(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox(
            height: 40,
            child: Center(child: Text('Unable to load categories')),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 40,
            child: Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final categories = snapshot.data?.docs ?? [];

        return SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _categoryChip(
                label: 'All',
                selected: selectedCategoryId == null,
                onTap: () {
                  setState(() {
                    selectedCategoryId = null;
                    selectedCategoryName = null;
                  });
                },
              ),
              ...categories.map((doc) {
                final data = doc.data();
                final name = data['name']?.toString().trim() ?? '';

                if (name.isEmpty) return const SizedBox.shrink();

                return _categoryChip(
                  label: name,
                  selected: selectedCategoryId == doc.id,
                  onTap: () {
                    setState(() {
                      selectedCategoryId = doc.id;
                      selectedCategoryName = name;
                    });
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _categoryChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 9),
      child: Material(
        color: selected ? primaryColor : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: 17,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected
                    ? primaryColor
                    : colors.outline.withOpacity(0.12),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : colors.onSurface,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RESULT HEADER
  // ============================================================

  Widget _buildResultHeader() {
    final colors = Theme.of(context).colorScheme;
    final activeFilterCount = (minPrice != null ? 1 : 0) +
        (maxPrice != null ? 1 : 0) +
        (minBedrooms > 0 ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find your place',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${filteredProperties.length} properties shown',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (activeFilterCount > 0)
            TextButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.restart_alt_rounded, size: 17),
              label: Text('Reset ($activeFilterCount)'),
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // PROPERTY RESULTS
  // ============================================================

  Widget _buildPropertyResults() {
    if (_isInitialLoading) return _buildLoadingGrid();

    if (errorMessage != null) return _buildErrorState();

    final filtered = filteredProperties;

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      color: primaryColor,
      backgroundColor: colors.surface,
      onRefresh: refreshProperties,
      child: GridView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
          childAspectRatio: 0.59,
        ),
        itemCount: filtered.length + (_isLoadingMore ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= filtered.length) {
            return _buildLoadingCard();
          }

          return _buildPropertyCard(filtered[index]);
        },
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    final colors = Theme.of(context).colorScheme;
    final isFavorite = favoriteIds.contains(_favoriteKey(property));

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailScreen(property: property),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outline.withOpacity(0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  Theme.of(context).brightness == Brightness.dark ? 0.12 : 0.035,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Stack(
                children: [
                  _buildPropertyImage(property.imageUrl),
                  Positioned(
                    left: 9,
                    top: 9,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 115),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        property.category.isEmpty
                            ? 'Property'
                            : property.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 9,
                    top: 9,
                    child: Material(
                      color: colors.surface.withOpacity(0.95),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _toggleFavorite(property),
                        child: SizedBox(
                          width: 34,
                          height: 34,
                          child: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite
                                ? favoriteColor
                                : colors.onSurface,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Property details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
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
                                color: colors.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          _miniInfo(
                            Icons.bed_outlined,
                            '${property.bedrooms}',
                          ),
                          const SizedBox(width: 9),
                          _miniInfo(
                            Icons.bathtub_outlined,
                            '${property.bathrooms.toInt()}',
                          ),
                          const SizedBox(width: 9),
                          _miniInfo(
                            Icons.home_work_outlined,
                            '${property.amenities.length}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Divider(
                        height: 1,
                        color: colors.outline.withOpacity(0.12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${property.price.toStringAsFixed(0)} / month',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyImage(String imageUrl) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 132,
      width: double.infinity,
      child: imageUrl.trim().isEmpty
          ? _imagePlaceholder()
          : Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return Container(
            color: colors.surfaceContainerHighest,
            alignment: Alignment.center,
            child: const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      ),
    );
  }

  Widget _imagePlaceholder() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      color: colors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.home_work_outlined,
        size: 36,
        color: colors.onSurfaceVariant,
      ),
    );
  }

  Widget _miniInfo(IconData icon, String value) {
    final colors = Theme.of(context).colorScheme;

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: primaryColor),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.59,
      ),
      itemBuilder: (_, __) => _buildLoadingCard(),
    );
  }

  Widget _buildLoadingCard() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline.withOpacity(0.12)),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  // ============================================================
  // EMPTY + ERROR STATES
  // ============================================================

  Widget _buildEmptyState() {
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: refreshProperties,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        children: [
          const SizedBox(height: 90),
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: colors.onSurfaceVariant.withOpacity(0.65),
          ),
          const SizedBox(height: 16),
          Text(
            'No properties found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try another keyword or adjust your filters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          if (_hasMore) ...[
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                onPressed: loadMore,
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('Load more properties'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _resetFilters,
              child: const Text('Clear search and filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            Text(
              errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: loadFirstPage,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FILTER BOTTOM SHEET
  // ============================================================

  Future<void> _showFilterBottomSheet() async {
    final colors = Theme.of(context).colorScheme;

    final minController = TextEditingController(
      text: minPrice?.toStringAsFixed(0) ?? '',
    );

    final maxController = TextEditingController(
      text: maxPrice?.toStringAsFixed(0) ?? '',
    );

    int draftBedrooms = minBedrooms;
    String? validationError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  22,
                  12,
                  22,
                  22 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.outline.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Filter properties',
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              minController.clear();
                              maxController.clear();

                              setSheetState(() {
                                draftBedrooms = 0;
                                validationError = null;
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Monthly price (USD)',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Minimum',
                                prefixText: '\$ ',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: maxController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Maximum',
                                prefixText: '\$ ',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),
                      Text(
                        'Minimum bedrooms',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        children: [0, 1, 2, 3, 4].map((bedrooms) {
                          final selected = draftBedrooms == bedrooms;

                          return ChoiceChip(
                            label: Text(
                              bedrooms == 0 ? 'Any' : '$bedrooms+',
                            ),
                            selected: selected,
                            onSelected: (_) {
                              setSheetState(() {
                                draftBedrooms = bedrooms;
                              });
                            },
                            selectedColor: primaryColor,
                            labelStyle: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),

                      if (validationError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          validationError!,
                          style: const TextStyle(
                            color: favoriteColor,
                            fontSize: 12,
                          ),
                        ),
                      ],

                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            final parsedMin =
                            double.tryParse(minController.text.trim());
                            final parsedMax =
                            double.tryParse(maxController.text.trim());

                            if (minController.text.trim().isNotEmpty &&
                                (parsedMin == null || parsedMin < 0)) {
                              setSheetState(() {
                                validationError =
                                'Enter a valid minimum price.';
                              });
                              return;
                            }

                            if (maxController.text.trim().isNotEmpty &&
                                (parsedMax == null || parsedMax < 0)) {
                              setSheetState(() {
                                validationError =
                                'Enter a valid maximum price.';
                              });
                              return;
                            }

                            if (parsedMin != null &&
                                parsedMax != null &&
                                parsedMin > parsedMax) {
                              setSheetState(() {
                                validationError =
                                'Minimum price cannot exceed maximum price.';
                              });
                              return;
                            }

                            setState(() {
                              minPrice = parsedMin;
                              maxPrice = parsedMax;
                              minBedrooms = draftBedrooms;
                              _isApplyingFilters = true;
                            });

                            Navigator.pop(sheetContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Apply filters',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
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
        );
      },
    );

    minController.dispose();
    maxController.dispose();

    if (mounted) {
      setState(() => _isApplyingFilters = false);
    }
  }

  void _resetFilters() {
    searchController.clear();
    minPriceController.clear();
    maxPriceController.clear();

    setState(() {
      searchQuery = '';
      selectedCategoryId = null;
      selectedCategoryName = null;
      minPrice = null;
      maxPrice = null;
      minBedrooms = 0;
      _isApplyingFilters = false;
    });
  }
}
