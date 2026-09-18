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
import '../../../services/notification_service.dart';
import '../../../services/property_service.dart';

import 'bottom_nav_bar.dart';
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
          setState(() {
            _currentIndex = index;
          });
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
  final TextEditingController searchController = TextEditingController();

  final PropertyService propertyService = PropertyService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Color accentColor = Color(0xFFFBBF24);

  String _searchText = "";

  /// null = All categories
  String? _selectedCategoryId;

  bool _isLoadingProfile = true;

  UserModel? _currentUser;

  final AuthService _authService = AuthService();

  // ============================================================
  // THEME COLORS
  // ============================================================

  Color get _backgroundColor {
    final colors = Theme.of(context).colorScheme;

    return colors.surface;
  }

  Color get _cardColor {
    final colors = Theme.of(context).colorScheme;

    return colors.surfaceContainer;
  }

  Color get _cardColorHighest {
    final colors = Theme.of(context).colorScheme;

    return colors.surfaceContainerHighest;
  }

  Color get _primaryTextColor {
    final colors = Theme.of(context).colorScheme;

    return colors.onSurface;
  }

  Color get _secondaryTextColor {
    final colors = Theme.of(context).colorScheme;

    return colors.onSurfaceVariant;
  }

  Color get _borderColor {
    final colors = Theme.of(context).colorScheme;

    return colors.outline.withOpacity(0.15);
  }

  Color get _primaryColor {
    final colors = Theme.of(context).colorScheme;

    return colors.primary;
  }

  bool get _isDark {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // ============================================================
  // CATEGORY STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getCategories() {
    return _firestore.collection('categories').orderBy('createdAt').snapshots();
  }

  // ============================================================
  // FILTER PROPERTIES
  // ============================================================

  List<Property> filterProperties(List<Property> properties) {
    return properties.where((property) {
      // --------------------------------------------------------
      // CATEGORY
      // --------------------------------------------------------

      if (_selectedCategoryId != null) {
        if (property.category != _selectedCategoryId) {
          return false;
        }
      }

      // --------------------------------------------------------
      // SEARCH
      // --------------------------------------------------------

      if (_searchText.isEmpty) {
        return true;
      }

      final title = property.title.toLowerCase();

      final location = property.location.toLowerCase();

      final price = property.price.toString();

      final category = property.category.toLowerCase();

      return title.contains(_searchText) ||
          location.contains(_searchText) ||
          price.contains(_searchText) ||
          category.contains(_searchText);
    }).toList();
  }

  // ============================================================
  // SELECT CATEGORY
  // ============================================================

  void _selectCategory(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadRenterProfile();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadRenterProfile() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingProfile = false;
      });

      return;
    }

    try {
      final user = await _authService.getUserData(firebaseUser.uid);

      if (!mounted) {
        return;
      }

      setState(() {
        _currentUser = user;

        _isLoadingProfile = false;
      });
    } catch (e) {
      debugPrint("Failed to load renter profile: $e");

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,

      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: BoxDecoration(gradient: _buildBackgroundGradient()),

        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ==================================================
                // HEADER
                // ==================================================
                _buildHeader(),

                const SizedBox(height: 20),

                // ==================================================
                // SEARCH
                // ==================================================
                _buildSearchBar(),

                const SizedBox(height: 24),

                // ==================================================
                // CATEGORIES
                // ==================================================
                _buildCategories(),

                const SizedBox(height: 28),

                // ==================================================
                // PROPERTIES
                // ==================================================
                StreamBuilder<List<Property>>(
                  stream: propertyService.getPublishedProperties(),

                  builder: (context, snapshot) {
                    // ------------------------------------------------
                    // LOADING
                    // ------------------------------------------------

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                        height: 350,

                        child: Center(
                          child: CircularProgressIndicator(color: accentColor),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(20),

                        child: Text(
                          'Failed to load properties\n${snapshot.error}',

                          style: TextStyle(color: _primaryTextColor),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyProperties();
                    }

                    final properties = snapshot.data!;

                    final filteredProperties = filterProperties(properties);

                    if (filteredProperties.isEmpty) {
                      return _buildNoResults();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        _buildSectionHeader(
                          title: 'Featured Houses',
                          onSeeAll: () {},
                        ),

                        const SizedBox(height: 14),

                        _buildFeaturedProperties(filteredProperties),

                        const SizedBox(height: 32),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),

                          child: Text(
                            "Recommended for you",

                            style: TextStyle(
                              color: _primaryTextColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        _buildRecommendedProperties(filteredProperties),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _buildBackgroundGradient() {
    final colors = Theme.of(context).colorScheme;

    if (_isDark) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF000000),
          Color(0xFF0A0A0A),
        ],
      );
    }

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colors.surface,
        colors.surfaceContainer,
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),

      child: Row(
        children: [
          _buildRenterProfile(),

          const Spacer(),

          Stack(
            clipBehavior: Clip.none,

            children: [
              Container(
                decoration: BoxDecoration(
                  color: _isDark
                      ? Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.7)
                      : _cardColorHighest,

                  borderRadius: BorderRadius.circular(14),

                  border: Border.all(
                    color: _isDark
                        ? Colors.white.withOpacity(0.12)
                        : _borderColor,
                  ),
                ),

                child: IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,

                    color: _isDark ? Colors.white : _primaryTextColor,
                  ),

                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NotificationsScreen()),
                    );
                  },
                ),
              ),

              // Notification badge
              Positioned(right: -2, top: -2, child: _buildNotificationBadge()),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NOTIFICATION BADGE
  // ============================================================

  Widget _buildNotificationBadge() {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<int>(
      stream: NotificationService().getUnreadCount(firebaseUser.uid),

      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        if (count <= 0) {
          return const SizedBox.shrink();
        }

        return Container(
          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),

          padding: const EdgeInsets.symmetric(horizontal: 3),

          decoration: BoxDecoration(
            color: Colors.red,

            borderRadius: BorderRadius.circular(10),

            border: Border.all(
              color: _isDark ? Colors.white : _backgroundColor,

              width: 2,
            ),
          ),

          child: Center(
            child: Text(
              count > 99 ? "99+" : "$count",

              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // RENTER PROFILE
  // ============================================================

  Widget _buildRenterProfile() {
    // ===========================================================
    // LOADING PROFILE
    // ===========================================================

    if (_isLoadingProfile) {
      return Row(
        children: [
          Container(
            width: 46,
            height: 46,

            decoration: BoxDecoration(
              color: _isDark
                  ? Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.7)
                  : _cardColorHighest,

              shape: BoxShape.circle,
            ),

            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,

                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentColor,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Container(
                width: 70,
                height: 9,

                decoration: BoxDecoration(
                  color: _isDark
                      ? Colors.white.withOpacity(0.12)
                      : _cardColorHighest,

                  borderRadius: BorderRadius.circular(5),
                ),
              ),

              const SizedBox(height: 7),

              Container(
                width: 110,
                height: 14,

                decoration: BoxDecoration(
                  color: _isDark
                      ? Colors.white.withOpacity(0.12)
                      : _cardColorHighest,

                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // ===========================================================
    // USER DATA
    // ===========================================================

    final user = _currentUser;

    final String name = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim()
        : "Renter";

    final String imageUrl = user?.profileImage?.trim() ?? "";

    // ===========================================================
    // PROFILE UI
    // ===========================================================

    return Row(
      children: [
        // =======================================================
        // PROFILE IMAGE
        // =======================================================
        Container(
          width: 46,
          height: 46,

          decoration: BoxDecoration(
            shape: BoxShape.circle,

            border: Border.all(
              color: _isDark ? Colors.white.withOpacity(0.20) : _borderColor,

              width: 1.5,
            ),
          ),

          child: ClipOval(
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,

                    width: 46,
                    height: 46,

                    fit: BoxFit.cover,

                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }

                      return Container(
                        color: _isDark
                            ? Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withOpacity(0.7)
                            : _cardColorHighest,

                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,

                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: accentColor,
                            ),
                          ),
                        ),
                      );
                    },

                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultProfileIcon();
                    },
                  )
                : _buildDefaultProfileIcon(),
          ),
        ),

        const SizedBox(width: 10),

        // =======================================================
        // USER NAME
        // =======================================================
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              "WELCOME BACK",

              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 9,
                letterSpacing: 1,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 2),

            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),

              child: Text(
                name,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  color: _primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // DEFAULT PROFILE ICON
  // ============================================================

  Widget _buildDefaultProfileIcon() {
    return Container(
      color: _isDark ? Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withOpacity(0.7) : _cardColorHighest,

      child: Center(
        child: Icon(Icons.person_rounded, color: _secondaryTextColor, size: 25),
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),

      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),

              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),

                child: Container(
                  height: 54,

                  decoration: BoxDecoration(
                    color: _isDark
                        ? Colors.white.withOpacity(0.12)
                        : _cardColorHighest,

                    borderRadius: BorderRadius.circular(16),

                    border: Border.all(
                      color: _isDark
                          ? Colors.white.withOpacity(0.18)
                          : _borderColor,
                    ),
                  ),

                  child: TextField(
                    controller: searchController,

                    onChanged: (value) {
                      setState(() {
                        _searchText = value.trim().toLowerCase();
                      });
                    },

                    style: TextStyle(color: _primaryTextColor, fontSize: 15),

                    decoration: InputDecoration(
                      hintText: 'Search room, location or price...',

                      hintStyle: TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 15,
                      ),

                      prefixIcon: Icon(
                        Icons.search_rounded,

                        color: _secondaryTextColor,
                      ),

                      border: InputBorder.none,

                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Filter button
          Container(
            height: 54,
            width: 54,

            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF2D1B69) : _cardColorHighest,

              borderRadius: BorderRadius.circular(16),

              border: Border.all(
                color: _isDark ? Colors.white.withOpacity(0.12) : _borderColor,
              ),

              boxShadow: [
                BoxShadow(
                  color: _isDark
                      ? Colors.black.withOpacity(0.25)
                      : Colors.black.withOpacity(0.06),

                  blurRadius: 12,

                  offset: const Offset(0, 4),
                ),
              ],
            ),

            child: Icon(
              Icons.tune_rounded,

              color: _isDark ? Colors.white : _primaryColor,

              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Widget _buildCategories() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: getCategories(),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 42,

            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accentColor,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 42,

            child: Center(
              child: Text(
                'Failed to load categories',

                style: TextStyle(color: _secondaryTextColor),
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

            separatorBuilder: (_, __) => const SizedBox(width: 10),

            itemBuilder: (context, index) {
              // ------------------------------------------------
              // ALL
              // ------------------------------------------------

              if (index == 0) {
                return _CategoryChip(
                  label: 'All',

                  isSelected: _selectedCategoryId == null,

                  onTap: () {
                    _selectCategory(null);
                  },
                );
              }

              // ------------------------------------------------
              // FIRESTORE CATEGORY
              // ------------------------------------------------

              final doc = categories[index - 1];

              final data = doc.data();

              final categoryName = data['name']?.toString() ?? 'Unknown';

              return _CategoryChip(
                label: categoryName,

                isSelected: _selectedCategoryId == doc.id,

                onTap: () {
                  _selectCategory(doc.id);
                },
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Text(
            title,

            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _primaryTextColor,
            ),
          ),

          TextButton(
            onPressed: onSeeAll,

            style: TextButton.styleFrom(
              foregroundColor: accentColor,

              padding: EdgeInsets.zero,
            ),

            child: const Text(
              'See all',

              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FEATURED PROPERTIES
  // ============================================================

  Widget _buildFeaturedProperties(List<Property> properties) {
    return SizedBox(
      height: 300,

      child: ListView.builder(
        scrollDirection: Axis.horizontal,

        physics: const BouncingScrollPhysics(),

        padding: const EdgeInsets.symmetric(horizontal: 20),

        itemCount: properties.length,

        itemBuilder: (context, index) {
          final property = properties[index];

          return Padding(
            padding: const EdgeInsets.only(right: 16),

            child: _FeaturedPropertyCard(property: property),
          );
        },
      ),
    );
  }

  // ============================================================
  // RECOMMENDED PROPERTIES
  // ============================================================

  Widget _buildRecommendedProperties(List<Property> properties) {
    return Column(
      children: properties.map((property) {
        return _RecommendedPropertyCard(property: property);
      }).toList(),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyProperties() {
    return Padding(
      padding: const EdgeInsets.all(20),

      child: Text(
        'No rooms available',

        style: TextStyle(color: _primaryTextColor),
      ),
    );
  }

  // ============================================================
  // NO FILTER RESULTS
  // ============================================================

  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),

      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,

              size: 50,

              color: _secondaryTextColor,
            ),

            const SizedBox(height: 12),

            Text(
              'No rooms found',

              style: TextStyle(
                color: _primaryTextColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Try another category or search.',

              style: TextStyle(color: _secondaryTextColor, fontSize: 13),
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
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // bool get

    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),

        curve: Curves.easeOut,

        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),

        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFBBF24)
              : isDark
              ? Colors.white.withOpacity(0.12)
              : colors.surfaceContainerHighest,

          borderRadius: BorderRadius.circular(30),

          border: Border.all(
            color: isSelected
                ? const Color(0xFFFBBF24)
                : isDark
                ? Colors.white.withOpacity(0.18)
                : colors.outline.withOpacity(0.15),
          ),
        ),

        child: Text(
          label,

          style: TextStyle(
            color: isSelected ? const Color(0xFF1A1035) : colors.onSurface,

            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,

            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// FEATURED PROPERTY CARD
// ============================================================

class _FeaturedPropertyCard extends StatelessWidget {
  final Property property;

  const _FeaturedPropertyCard({required this.property});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark
        ? Theme.of(context)
        .colorScheme
        .surfaceContainerHighest
        .withOpacity(0.7)
        : colors.surfaceContainer;

    final borderColor = isDark
        ? Colors.white.withOpacity(0.15)
        : colors.outline.withOpacity(0.12);

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
        width: 270,

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),

          color: cardColor,

          border: Border.all(color: borderColor),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),

              blurRadius: 20,

              offset: const Offset(0, 8),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ==================================================
            // IMAGE
            // ==================================================
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),

                  child: Image.network(
                    property.imageUrl,

                    height: 170,

                    width: double.infinity,

                    fit: BoxFit.cover,

                    errorBuilder: (_, __, ___) {
                      return Container(
                        height: 170,

                        color: isDark
                            ? Colors.white12
                            : colors.surfaceContainerHighest,

                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,

                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ==================================================
                // RATING
                // ==================================================
                Positioned(
                  top: 12,
                  right: 12,

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),

                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,

                          color: Color(0xFFFBBF24),

                          size: 16,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          '4.8',

                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,

                            fontWeight: FontWeight.bold,

                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ==================================================
            // INFORMATION
            // ==================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    property.title,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(
                      fontSize: 16,

                      fontWeight: FontWeight.bold,

                      color: colors.onSurface,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,

                        size: 14,

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

                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    '\$${property.price} /mo',

                    style: const TextStyle(
                      fontSize: 18,

                      fontWeight: FontWeight.bold,

                      color: Color(0xFFFBBF24),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// RECOMMENDED PROPERTY CARD
// ============================================================

class _RecommendedPropertyCard extends StatelessWidget {
  final Property property;

  const _RecommendedPropertyCard({required this.property});

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

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),

        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),

          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),

            child: Container(
              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(
                color: isDark
                    ? Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.7)
                    : colors.surfaceContainer,

                borderRadius: BorderRadius.circular(18),

                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.15)
                      : colors.outline.withOpacity(0.12),
                ),
              ),

              child: Row(
                children: [
                  // ==================================================
                  // IMAGE
                  // ==================================================
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),

                    child: Image.network(
                      property.imageUrl,

                      width: 110,

                      height: 90,

                      fit: BoxFit.cover,

                      errorBuilder: (_, __, ___) {
                        return Container(
                          width: 110,

                          height: 90,

                          color: isDark
                              ? Colors.white12
                              : colors.surfaceContainerHighest,

                          child: Icon(
                            Icons.image_not_supported,

                            color: colors.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 14),

                  // ==================================================
                  // INFORMATION
                  // ==================================================
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          property.title,

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(
                            fontWeight: FontWeight.bold,

                            fontSize: 15.5,

                            color: colors.onSurface,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          property.location,

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(
                            color: colors.onSurfaceVariant,

                            fontSize: 12.5,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            _miniInfo(
                              context,

                              Icons.bed_rounded,

                              '${property.bedrooms}',
                            ),

                            const SizedBox(width: 12),

                            _miniInfo(
                              context,

                              Icons.bathtub_outlined,

                              '${property.bathrooms.toInt()}',
                            ),

                            const SizedBox(width: 12),

                            _miniInfo(
                              context,

                              Icons.home_work_outlined,

                              '${property.amenities.length}',
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Text(
                          '\$${property.price.toInt()} /mo',

                          style: const TextStyle(
                            fontWeight: FontWeight.bold,

                            fontSize: 16,

                            color: Color(0xFFFBBF24),
                          ),
                        ),
                      ],
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
  // MINI INFO
  // ============================================================

  Widget _miniInfo(BuildContext context, IconData icon, String text) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 14, color: colors.onSurfaceVariant),

        const SizedBox(width: 3),

        Text(
          text,

          style: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
