
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:rentease/features/renter/screens/profile_screen.dart';
import 'package:rentease/features/renter/screens/property_detail_screen.dart';
import 'package:rentease/features/renter/screens/search_screen.dart';

import '../../../models/property_model.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/property_service.dart';

import 'bottom_nav_bar.dart';
import 'chat_list_screen.dart';
import 'favorites_screen.dart';
import 'notification_screen.dart';

class RenterHomeScreen extends StatefulWidget {
  const RenterHomeScreen({super.key});

  @override
  State<RenterHomeScreen> createState() => _RenterHomeScreenState();
}

class _RenterHomeScreenState extends State<RenterHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeFeedScreen(),
    SearchScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: CapsuleBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

// ============================================================
// HOME FEED
// ============================================================

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  static const Color accentColor = Color(0xFFFBBF24);
  static const int _pageSize = 6;

  final TextEditingController searchController = TextEditingController();
  final PropertyService propertyService = PropertyService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String _searchText = '';
  String? _selectedCategoryId;

  double? _minPrice;
  double? _maxPrice;

  int _visibleCount = _pageSize;

  bool _isLoadingProfile = true;
  UserModel? _currentUser;

  bool get _isDark =>
      Theme.of(context).brightness == Brightness.dark;

  Color get _backgroundColor =>
      Theme.of(context).colorScheme.surface;

  Color get _cardColor =>
      Theme.of(context).colorScheme.surfaceContainer;

  Color get _primaryTextColor =>
      Theme.of(context).colorScheme.onSurface;

  Color get _secondaryTextColor =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  Color get _borderColor =>
      Theme.of(context).colorScheme.outline.withOpacity(0.15);

  Stream<QuerySnapshot<Map<String, dynamic>>> getCategories() {
    return _firestore
        .collection('categories')
        .orderBy('createdAt')
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    _loadRenterProfile();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // PROFILE
  // ============================================================

  Future<void> _loadRenterProfile() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
      return;
    }

    try {
      final user = await _authService.getUserData(firebaseUser.uid);

      if (!mounted) return;

      setState(() {
        _currentUser = user;
        _isLoadingProfile = false;
      });
    } catch (e) {
      debugPrint('Failed to load renter profile: $e');

      if (!mounted) return;

      setState(() => _isLoadingProfile = false);
    }
  }

  // ============================================================
  // SEARCH AND FILTER
  // ============================================================

  List<Property> filterProperties(List<Property> properties) {
    return properties.where((property) {
      if (_selectedCategoryId != null &&
          property.category != _selectedCategoryId) {
        return false;
      }

      final price = property.price.toDouble();

      if (_minPrice != null && price < _minPrice!) {
        return false;
      }

      if (_maxPrice != null && price > _maxPrice!) {
        return false;
      }

      if (_searchText.isEmpty) return true;

      final query = _searchText.toLowerCase();

      return property.title.toLowerCase().contains(query) ||
          property.location.toLowerCase().contains(query) ||
          property.price.toString().contains(query) ||
          property.category.toLowerCase().contains(query);
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value.trim().toLowerCase();
      _visibleCount = _pageSize;
    });
  }

  void _selectCategory(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _visibleCount = _pageSize;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _minPrice = null;
      _maxPrice = null;
      _searchText = '';
      searchController.clear();
      _visibleCount = _pageSize;
    });
  }

  Future<void> _showFilterSheet() async {
    final minController = TextEditingController(
      text: _minPrice?.toStringAsFixed(0) ?? '',
    );
    final maxController = TextEditingController(
      text: _maxPrice?.toStringAsFixed(0) ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        double? parsePrice(String value) {
          if (value.trim().isEmpty) return null;
          return double.tryParse(value.trim());
        }

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colors = Theme.of(context).colorScheme;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.outline.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Filter properties',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Set your monthly rental budget.',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: _priceInput(
                              controller: minController,
                              label: 'Minimum price',
                              colors: colors,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _priceInput(
                              controller: maxController,
                              label: 'Maximum price',
                              colors: colors,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                minController.clear();
                                maxController.clear();
                                setSheetState(() {});
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 50),
                                foregroundColor: colors.onSurface,
                                side: BorderSide(
                                  color: colors.outline.withOpacity(0.3),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final min = parsePrice(minController.text);
                                final max = parsePrice(maxController.text);

                                if ((min != null && min < 0) ||
                                    (max != null && max < 0)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Price cannot be negative.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (min != null &&
                                    max != null &&
                                    min > max) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Minimum price cannot exceed maximum price.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setState(() {
                                  _minPrice = min;
                                  _maxPrice = max;
                                  _visibleCount = _pageSize;
                                });

                                Navigator.pop(sheetContext);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: const Color(0xFF241A05),
                                minimumSize: const Size(0, 50),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Apply filters',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
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
            );
          },
        );
      },
    );

    minController.dispose();
    maxController.dispose();
  }

  Widget _priceInput({
    required TextEditingController controller,
    required String label,
    required ColorScheme colors,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: colors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixText: '\$ ',
        labelStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
        filled: true,
        fillColor: colors.surfaceContainerHighest.withOpacity(0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colors.outline.withOpacity(0.15),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MAIN UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: _buildBackgroundGradient(),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 22),
                    _buildSearchBar(),
                    const SizedBox(height: 24),
                    _buildCategories(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              StreamBuilder<List<Property>>(
                stream: propertyService.getPublishedProperties(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverToBoxAdapter(
                      child: SizedBox(
                        height: 280,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: accentColor,
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: _buildError(snapshot.error.toString()),
                    );
                  }

                  final allProperties = snapshot.data ?? [];

                  if (allProperties.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _buildEmptyProperties(),
                    );
                  }

                  final filtered = filterProperties(allProperties);
                  final visible = filtered.take(_visibleCount).toList();
                  final hasMore = visible.length < filtered.length;

                  if (filtered.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _buildNoResults(),
                    );
                  }

                  return SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _searchText.isNotEmpty ||
                                      _selectedCategoryId != null ||
                                      _minPrice != null ||
                                      _maxPrice != null
                                      ? 'Search results'
                                      : 'Featured properties',
                                  style: TextStyle(
                                    color: _primaryTextColor,
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                '${filtered.length} rooms',
                                style: TextStyle(
                                  color: _secondaryTextColor,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // FEATURED HORIZONTAL LIST
                      if (_searchText.isEmpty &&
                          _selectedCategoryId == null &&
                          _minPrice == null &&
                          _maxPrice == null)
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 292,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              physics: const BouncingScrollPhysics(),
                              itemCount: visible.length,
                              separatorBuilder: (_, __) =>
                              const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                return _FeaturedPropertyCard(
                                  property: visible[index],
                                );
                              },
                            ),
                          ),
                        ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                          child: Text(
                            _searchText.isNotEmpty ||
                                _selectedCategoryId != null ||
                                _minPrice != null ||
                                _maxPrice != null
                                ? 'Available rooms'
                                : 'Recommended for you',
                            style: TextStyle(
                              color: _primaryTextColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // RECOMMENDED LIST
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _RecommendedPropertyCard(
                                  property: visible[index],
                                ),
                              );
                            },
                            childCount: visible.length,
                          ),
                        ),
                      ),

                      // LOAD MORE
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                          child: Column(
                            children: [
                              if (hasMore)
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _visibleCount += _pageSize;
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _primaryTextColor,
                                      side: BorderSide(
                                        color: _borderColor,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Load more properties',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  'You have reached the end',
                                  style: TextStyle(
                                    color: _secondaryTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(height: 90),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _buildBackgroundGradient() {
    final colors = Theme.of(context).colorScheme;

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: _isDark
          ? const [Color(0xFF101014), Color(0xFF08080A)]
          : [colors.surface, colors.surfaceContainer],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Expanded(child: _buildRenterProfile()),
          const SizedBox(width: 10),
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
            badge: _buildUnreadMessageBadge(),
          ),
          const SizedBox(width: 9),
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
            badge: _buildNotificationBadge(),
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _borderColor),
          ),
          child: IconButton(
            onPressed: onPressed,
            tooltip: tooltip,
            icon: Icon(icon, color: _primaryTextColor, size: 22),
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

  Widget _buildUnreadMessageBadge() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<int>(
      stream: ChatService().getRenterUnreadMessageCount(user.uid),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        if (count <= 0) return const SizedBox.shrink();

        return _countBadge(count);
      },
    );
  }

  Widget _buildNotificationBadge() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<int>(
      stream: NotificationService().getUnreadCount(user.uid),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        if (count <= 0) return const SizedBox.shrink();

        return _countBadge(count);
      },
    );
  }

  Widget _countBadge(int count) {
    return Container(
      constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _backgroundColor,
          width: 1.5,
        ),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // RENTER PROFILE
  // ============================================================

  Widget _buildRenterProfile() {
    if (_isLoadingProfile) {
      return Row(
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 115,
            height: 12,
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
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
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _borderColor, width: 1.5),
          ),
          child: ClipOval(
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _defaultProfileIcon(),
            )
                : _defaultProfileIcon(),
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
                  color: _secondaryTextColor,
                  fontSize: 9,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _defaultProfileIcon() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.person_rounded,
        size: 25,
        color: _secondaryTextColor,
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    final hasFilters = _selectedCategoryId != null ||
        _minPrice != null ||
        _maxPrice != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: _borderColor),
              ),
              child: TextField(
                controller: searchController,
                onChanged: _onSearchChanged,
                style: TextStyle(
                  color: _primaryTextColor,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search rooms or location',
                  hintStyle: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _secondaryTextColor,
                  ),
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                    onPressed: () {
                      searchController.clear();
                      _onSearchChanged('');
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: _secondaryTextColor,
                      size: 19,
                    ),
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: hasFilters
                    ? accentColor
                    : _cardColor,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _showFilterSheet,
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: Icon(
                      Icons.tune_rounded,
                      color: hasFilters
                          ? const Color(0xFF241A05)
                          : _primaryTextColor,
                    ),
                  ),
                ),
              ),
              if (hasFilters)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Categories',
                  style: TextStyle(
                    color: _primaryTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_selectedCategoryId != null ||
                  _minPrice != null ||
                  _maxPrice != null)
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text(
                    'Clear all',
                    style: TextStyle(color: accentColor),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: getCategories(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Unable to load categories.',
                  style: TextStyle(color: _secondaryTextColor),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 42,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor,
                    ),
                  ),
                ),
              );
            }

            final categories = snapshot.data?.docs ?? [];

            return SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 9),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _CategoryChip(
                      label: 'All',
                      isSelected: _selectedCategoryId == null,
                      onTap: () => _selectCategory(null),
                    );
                  }

                  final doc = categories[index - 1];
                  final name = doc.data()['name']?.toString() ?? 'Unknown';

                  return _CategoryChip(
                    label: name,
                    isSelected: _selectedCategoryId == doc.id,
                    onTap: () => _selectCategory(doc.id),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // STATES
  // ============================================================

  Widget _buildError(String error) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 45,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to load properties',
            style: TextStyle(
              color: _primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProperties() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 55,
              color: _secondaryTextColor,
            ),
            const SizedBox(height: 14),
            Text(
              'No rooms available',
              style: TextStyle(
                color: _primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'New properties will appear here when available.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _secondaryTextColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 54,
              color: _secondaryTextColor,
            ),
            const SizedBox(height: 14),
            Text(
              'No rooms found',
              style: TextStyle(
                color: _primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try another search or adjust your filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _secondaryTextColor),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _clearFilters,
              child: const Text(
                'Clear search and filters',
                style: TextStyle(color: accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CATEGORY CHIP
// ============================================================

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFBBF24)
                : isDark
                ? Colors.white.withOpacity(0.07)
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFBBF24)
                  : colors.outline.withOpacity(0.14),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF241A05)
                  : colors.onSurface,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// FEATURED PROPERTY CARD — NO RATING
// ============================================================

class _FeaturedPropertyCard extends StatelessWidget {
  final Property property;

  const _FeaturedPropertyCard({required this.property});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PropertyDetailScreen(property: property),
          ),
        );
      },
      child: Container(
        width: 265,
        decoration: BoxDecoration(
          color: isDark
              ? colors.surfaceContainerHighest.withOpacity(0.65)
              : colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: colors.outline.withOpacity(0.13),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _propertyImage(
                  property.imageUrl,
                  height: 158,
                  width: double.infinity,
                  context: context,
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.62),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Text(
                      'AVAILABLE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        letterSpacing: 0.7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            '\$${property.price}/mo',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFF0AD16),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 19,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// RECOMMENDED PROPERTY CARD — NO RATING
// ============================================================

class _RecommendedPropertyCard extends StatelessWidget {
  final Property property;

  const _RecommendedPropertyCard({required this.property});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailScreen(property: property),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: isDark
                ? colors.surfaceContainerHighest.withOpacity(0.55)
                : colors.surface,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: colors.outline.withOpacity(0.13),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.12 : 0.025),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _propertyImage(
                  property.imageUrl,
                  width: 108,
                  height: 112,
                  context: context,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: SizedBox(
                  height: 112,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
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
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 5,
                        children: [
                          _miniInfo(
                            context,
                            Icons.bed_outlined,
                            '${property.bedrooms} beds',
                          ),
                          _miniInfo(
                            context,
                            Icons.bathtub_outlined,
                            '${property.bathrooms.toInt()} baths',
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '\$${property.price.toInt()} / month',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFF0AD16),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniInfo(BuildContext context, IconData icon, String text) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colors.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PROPERTY IMAGE
// ============================================================

Widget _propertyImage(
    String imageUrl, {
      required double width,
      required double height,
      required BuildContext context,
    }) {
  final colors = Theme.of(context).colorScheme;

  if (imageUrl.trim().isEmpty) {
    return Container(
      width: width,
      height: height,
      color: colors.surfaceContainerHighest,
      child: Icon(
        Icons.home_work_outlined,
        color: colors.onSurfaceVariant,
        size: 32,
      ),
    );
  }

  return Image.network(
    imageUrl,
    width: width,
    height: height,
    fit: BoxFit.cover,
    loadingBuilder: (context, child, progress) {
      if (progress == null) return child;

      return Container(
        width: width,
        height: height,
        color: colors.surfaceContainerHighest,
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFFBBF24),
            ),
          ),
        ),
      );
    },
    errorBuilder: (_, __, ___) {
      return Container(
        width: width,
        height: height,
        color: colors.surfaceContainerHighest,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: colors.onSurfaceVariant,
          size: 30,
        ),
      );
    },
  );
}
