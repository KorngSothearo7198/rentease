import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/session_service.dart';

import 'package:rentease/features/renter/screens/notification_screen.dart';
import 'package:rentease/features/renter/screens/property_detail_screen.dart';

import '../../../models/property_model.dart';
import '../../../services/notification_service.dart';
import '../../../services/property_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController searchController = TextEditingController();

  final ScrollController scrollController = ScrollController();

  // ============================================================
  // SERVICES
  // ============================================================

  final PropertyService propertyService = PropertyService();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // ============================================================
  // USER
  // ============================================================

  UserModel? _currentUser;

  bool _isLoadingProfile = true;

  // ============================================================
  // SEARCH
  // ============================================================

  String searchQuery = '';

  // ============================================================
  // CATEGORY
  // ============================================================

  String? selectedCategoryId;

  String? selectedCategoryName;

  // ============================================================
  // FILTER
  // ============================================================

  String selectedFilter = 'All';

  // ============================================================
  // PAGINATION
  // ============================================================

  final List<Property> properties = [];

  DocumentSnapshot<Map<String, dynamic>>? lastDocument;

  bool isInitialLoading = true;

  bool isLoadingMore = false;

  bool hasMore = true;

  String? errorMessage;

  // ============================================================
  // PAGE SIZE
  // ============================================================

  static const int pageSize = 6;

  // ============================================================
  // CONSTANT COLORS
  // ============================================================

  static const Color accentColor = Color(0xFFFBBF24);

  static const Color dangerColor = Color(0xFFEF4444);

  static const Color categoryColor = Color(0xFF10B981);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadRenterProfile();

    loadFirstPage();

    scrollController.addListener(_onScroll);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    searchController.dispose();

    scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // SCROLL
  // ============================================================

  void _onScroll() {
    if (!scrollController.hasClients) {
      return;
    }

    final position = scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 500 &&
        !isLoadingMore &&
        hasMore) {
      loadMore();
    }
  }

  // ============================================================
  // LOAD FIRST PAGE
  // ============================================================

  Future<void> loadFirstPage() async {
    if (!mounted) {
      return;
    }

    setState(() {
      isInitialLoading = true;

      errorMessage = null;

      properties.clear();

      lastDocument = null;

      hasMore = true;
    });

    try {
      final result =
      await propertyService.getPublishedPropertiesPage(
        limit: pageSize,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        properties.addAll(result.properties);

        lastDocument = result.lastDocument;

        hasMore = result.hasMore;

        isInitialLoading = false;
      });
    } catch (e) {
      debugPrint('Load properties error: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        isInitialLoading = false;

        errorMessage = 'Failed to load properties';
      });
    }
  }

  // ============================================================
  // LOAD RENTER PROFILE
  // ============================================================

  Future<void> _loadRenterProfile() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        if (mounted) {
          setState(() {
            _isLoadingProfile = false;
          });
        }

        return;
      }

      // ----------------------------------------------------------
      // FIRST: LOCAL SESSION
      // ----------------------------------------------------------

      final savedUser = await SessionService.getUser();

      if (savedUser != null && mounted) {
        setState(() {
          _currentUser = UserModel.fromJson(savedUser);

          _isLoadingProfile = false;
        });
      }

      // ----------------------------------------------------------
      // SECOND: FIREBASE
      // ----------------------------------------------------------

      final userData =
      await AuthService().getUserData(firebaseUser.uid);

      if (userData != null && mounted) {
        setState(() {
          _currentUser = userData;

          _isLoadingProfile = false;
        });

        await SessionService.saveUser(
          userData.toJson(),
        );
      }
    } catch (e) {
      debugPrint(
        'Load renter profile error: $e',
      );

      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  // ============================================================
  // LOAD MORE
  // ============================================================

  Future<void> loadMore() async {
    if (isLoadingMore ||
        !hasMore ||
        lastDocument == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isLoadingMore = true;
    });

    try {
      final result =
      await propertyService.getPublishedPropertiesPage(
        limit: pageSize,
        startAfter: lastDocument,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        properties.addAll(result.properties);

        lastDocument = result.lastDocument;

        hasMore = result.hasMore;

        isLoadingMore = false;
      });
    } catch (e) {
      debugPrint(
        'Load more error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isLoadingMore = false;
      });
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshProperties() async {
    await loadFirstPage();
  }

  // ============================================================
  // CATEGORY STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getCategories() {
    return firestore
        .collection('categories')
        .orderBy(
      'createdAt',
      descending: false,
    )
        .snapshots();
  }

  // ============================================================
  // FILTERED PROPERTIES
  // ============================================================

  List<Property> get filteredProperties {
    Iterable<Property> result = properties;

    // ----------------------------------------------------------
    // CATEGORY
    // ----------------------------------------------------------

    if (selectedCategoryId != null) {
      result = result.where(
            (property) {
          return property.category ==
              selectedCategoryName;
        },
      );
    }

    // ----------------------------------------------------------
    // SEARCH
    // ----------------------------------------------------------

    if (searchQuery.isNotEmpty) {
      result = result.where(
            (property) {
          final title =
          property.title.toLowerCase();

          final location =
          property.location.toLowerCase();

          final category =
          property.category.toLowerCase();

          final price =
          property.price.toString();

          return title.contains(searchQuery) ||
              location.contains(searchQuery) ||
              category.contains(searchQuery) ||
              price.contains(searchQuery);
        },
      );
    }

    return result.toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            _buildHeader(),

            // ==================================================
            // SEARCH
            // ==================================================

            _buildSearchBar(),

            const SizedBox(height: 18),

            // ==================================================
            // CATEGORY
            // ==================================================

            _buildCategoryChips(),

            const SizedBox(height: 12),

            // ==================================================
            // RESULT COUNT
            // ==================================================

            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                12,
              ),
              child: Row(
                children: [
                  Text(
                    '${filteredProperties.length} Properties',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Spacer(),

                  if (isLoadingMore)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    ),
                ],
              ),
            ),

            // ==================================================
            // RESULTS
            // ==================================================

            Expanded(
              child: _buildPropertyResults(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final colors =
        Theme.of(context).colorScheme;

    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        20,
        16,
        20,
        8,
      ),
      child: Row(
        children: [
          // ==================================================
          // RENTER PROFILE
          // ==================================================

          _buildRenterProfile(),

          const Spacer(),

          // ==================================================
          // NOTIFICATION
          // ==================================================

          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color:
                  colors.surfaceContainerHighest,

                  borderRadius:
                  BorderRadius.circular(14),

                  border: Border.all(
                    color: colors.outline
                        .withOpacity(0.15),
                  ),
                ),

                child: IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: colors.onSurface,
                  ),

                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            NotificationsScreen(),
                      ),
                    );
                  },
                ),
              ),

              Positioned(
                right: -2,
                top: -2,
                child:
                _buildNotificationBadge(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RENTER PROFILE
  // ============================================================

  Widget _buildRenterProfile() {
    final colors =
        Theme.of(context).colorScheme;

    // ----------------------------------------------------------
    // LOADING
    // ----------------------------------------------------------

    if (_isLoadingProfile) {
      return Row(
        children: [
          Container(
            width: 46,
            height: 46,

            decoration: BoxDecoration(
              color:
              colors.surfaceContainerHighest,

              shape: BoxShape.circle,
            ),

            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,

                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 70,
                height: 9,

                decoration:
                BoxDecoration(
                  color: colors
                      .surfaceContainerHighest,

                  borderRadius:
                  BorderRadius.circular(5),
                ),
              ),

              const SizedBox(height: 7),

              Container(
                width: 110,
                height: 14,

                decoration:
                BoxDecoration(
                  color: colors
                      .surfaceContainerHighest,

                  borderRadius:
                  BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // ----------------------------------------------------------
    // USER DATA
    // ----------------------------------------------------------

    final user = _currentUser;

    final String name =
    user?.fullName.trim().isNotEmpty == true
        ? user!.fullName
        : 'Renter';

    final String imageUrl =
        user?.profileImage?.trim() ?? '';

    return Row(
      children: [
        // ======================================================
        // PROFILE IMAGE
        // ======================================================

        Container(
          width: 46,
          height: 46,

          decoration: BoxDecoration(
            shape: BoxShape.circle,

            border: Border.all(
              color:
              colors.outline.withOpacity(0.3),
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

              loadingBuilder: (
                  context,
                  child,
                  loadingProgress,
                  ) {
                if (loadingProgress ==
                    null) {
                  return child;
                }

                return Container(
                  color: colors
                      .surfaceContainerHighest,

                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,

                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                        colors.primary,
                      ),
                    ),
                  ),
                );
              },

              errorBuilder: (
                  context,
                  error,
                  stackTrace,
                  ) {
                return _buildDefaultProfileIcon();
              },
            )
                : _buildDefaultProfileIcon(),
          ),
        ),

        const SizedBox(width: 10),

        // ======================================================
        // USER NAME
        // ======================================================

        Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'WELCOME BACK',

              style: TextStyle(
                color:
                colors.onSurfaceVariant,

                fontSize: 9,

                letterSpacing: 1,

                fontWeight:
                FontWeight.w500,
              ),
            ),

            const SizedBox(height: 2),

            ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 180,
              ),

              child: Text(
                name,

                maxLines: 1,

                overflow:
                TextOverflow.ellipsis,

                style: TextStyle(
                  color:
                  colors.onSurface,

                  fontSize: 16,

                  fontWeight:
                  FontWeight.bold,
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
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      color:
      colors.surfaceContainerHighest,

      child: Icon(
        Icons.person_rounded,

        color:
        colors.onSurfaceVariant,

        size: 25,
      ),
    );
  }

  // ============================================================
  // NOTIFICATION BADGE
  // ============================================================

  Widget _buildNotificationBadge() {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox();
    }

    final colors =
        Theme.of(context).colorScheme;

    return StreamBuilder<int>(
      stream: NotificationService()
          .getUnreadCount(user.uid),

      builder: (
          context,
          snapshot,
          ) {
        final count =
            snapshot.data ?? 0;

        if (count <= 0) {
          return const SizedBox();
        }

        return Container(
          constraints:
          const BoxConstraints(
            minWidth: 18,
            minHeight: 18,
          ),

          padding:
          const EdgeInsets.symmetric(
            horizontal: 4,
          ),

          decoration: BoxDecoration(
            color: dangerColor,

            borderRadius:
            BorderRadius.circular(10),

            border: Border.all(
              color: colors.surface,
              width: 2,
            ),
          ),

          child: Center(
            child: Text(
              count > 99
                  ? '99+'
                  : '$count',

              style:
              const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    final colors =
        Theme.of(context).colorScheme;

    return Padding(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 20,
      ),

      child: Container(
        height: 54,

        decoration: BoxDecoration(
          color:
          colors.surfaceContainerHighest,

          borderRadius:
          BorderRadius.circular(16),

          border: Border.all(
            color:
            colors.outline.withOpacity(0.15),
          ),
        ),

        child: TextField(
          controller:
          searchController,

          style: TextStyle(
            color:
            colors.onSurface,

            fontSize: 15,
          ),

          onChanged: (value) {
            setState(() {
              searchQuery =
                  value.trim().toLowerCase();
            });
          },

          decoration:
          InputDecoration(
            hintText:
            'Search room, location or price...',

            hintStyle:
            TextStyle(
              color:
              colors.onSurfaceVariant,

              fontSize: 14,
            ),

            prefixIcon:
            Icon(
              Icons.search_rounded,

              color:
              colors.onSurfaceVariant,
            ),

            suffixIcon:
            IconButton(
              icon: Icon(
                Icons.tune_rounded,

                color:
                colors.primary,
              ),

              onPressed:
              _showFilterBottomSheet,
            ),

            border:
            InputBorder.none,

            contentPadding:
            const EdgeInsets.symmetric(
              vertical: 17,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY CHIPS
  // ============================================================

  Widget _buildCategoryChips() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: getCategories(),

      builder: (
          context,
          snapshot,
          ) {
        final colors =
            Theme.of(context).colorScheme;

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return SizedBox(
            height: 42,

            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,

                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
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

                style: TextStyle(
                  color:
                  colors.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        final categories =
            snapshot.data?.docs ?? [];

        return SizedBox(
          height: 42,

          child: ListView(
            scrollDirection:
            Axis.horizontal,

            padding:
            const EdgeInsets.symmetric(
              horizontal: 20,
            ),

            children: [
              // ==================================================
              // ALL
              // ==================================================

              _buildCategoryChip(
                label: 'All',

                isSelected:
                selectedCategoryId ==
                    null,

                onTap: () {
                  setState(() {
                    selectedCategoryId =
                    null;

                    selectedCategoryName =
                    null;
                  });
                },
              ),

              // ==================================================
              // FIRESTORE CATEGORIES
              // ==================================================

              ...categories.map(
                    (doc) {
                  final data =
                  doc.data();

                  final name =
                      data['name']
                          ?.toString() ??
                          'Unknown';

                  return _buildCategoryChip(
                    label: name,

                    isSelected:
                    selectedCategoryId ==
                        doc.id,

                    onTap: () {
                      setState(() {
                        selectedCategoryId =
                            doc.id;

                        selectedCategoryName =
                            name;
                      });
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // CATEGORY CHIP
  // ============================================================

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors =
        Theme.of(context).colorScheme;

    return Padding(
      padding:
      const EdgeInsets.only(
        right: 10,
      ),

      child: GestureDetector(
        onTap: onTap,

        child: AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 200,
          ),

          padding:
          const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),

          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary
                : colors
                .surfaceContainerHighest,

            borderRadius:
            BorderRadius.circular(30),

            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.outline
                  .withOpacity(0.15),
            ),
          ),

          child: Text(
            label,

            style: TextStyle(
              color: isSelected
                  ? colors.onPrimary
                  : colors.onSurface,

              fontWeight: isSelected
                  ? FontWeight.w700
                  : FontWeight.w500,

              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTER CHIP
  // ============================================================

  Widget _buildFilterChip(
      String label,
      ) {
    final colors =
        Theme.of(context).colorScheme;

    final isSelected =
        selectedFilter == label;

    return Padding(
      padding:
      const EdgeInsets.only(
        right: 10,
      ),

      child: FilterChip(
        selected: isSelected,

        label: Text(label),

        onSelected: (_) {
          setState(() {
            selectedFilter =
                label;
          });
        },

        backgroundColor:
        colors.surfaceContainerHighest,

        selectedColor:
        colors.primary,

        side: BorderSide(
          color: isSelected
              ? colors.primary
              : colors.outline
              .withOpacity(0.15),
        ),

        labelStyle: TextStyle(
          color: isSelected
              ? colors.onPrimary
              : colors.onSurface,

          fontWeight: isSelected
              ? FontWeight.bold
              : FontWeight.w500,

          fontSize: 13,
        ),
      ),
    );
  }

  // ============================================================
  // PROPERTY RESULTS
  // ============================================================

  Widget _buildPropertyResults() {
    final colors =
        Theme.of(context).colorScheme;

    // ----------------------------------------------------------
    // INITIAL LOADING
    // ----------------------------------------------------------

    if (isInitialLoading) {
      return _buildInitialLoading();
    }

    // ----------------------------------------------------------
    // ERROR
    // ----------------------------------------------------------

    if (errorMessage != null) {
      return _buildError();
    }

    // ----------------------------------------------------------
    // FILTER
    // ----------------------------------------------------------

    final filtered =
        filteredProperties;

    // ----------------------------------------------------------
    // EMPTY
    // ----------------------------------------------------------

    if (filtered.isEmpty) {
      return _buildEmpty();
    }

    // ----------------------------------------------------------
    // GRID
    // ----------------------------------------------------------

    return RefreshIndicator(
      color: colors.primary,

      backgroundColor:
      colors.surfaceContainer,

      onRefresh:
      refreshProperties,

      child: GridView.builder(
        controller:
        scrollController,

        physics:
        const AlwaysScrollableScrollPhysics(),

        padding:
        const EdgeInsets.fromLTRB(
          20,
          4,
          20,
          100,
        ),

        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,

          crossAxisSpacing: 12,

          mainAxisSpacing: 14,

          childAspectRatio: 0.64,
        ),

        itemCount:
        filtered.length,

        itemBuilder: (
            context,
            index,
            ) {
          final property =
          filtered[index];

          return _buildGridPropertyCard(
            property,
          );
        },
      ),
    );
  }

  // ============================================================
  // PROPERTY CARD
  // ============================================================

  Widget _buildGridPropertyCard(
      Property property,
      ) {
    final colors =
        Theme.of(context).colorScheme;

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,

          MaterialPageRoute(
            builder: (_) =>
                PropertyDetailScreen(
                  property: property,
                ),
          ),
        );
      },

      child: Container(
        decoration: BoxDecoration(
          color:
          colors.surfaceContainer,

          borderRadius:
          BorderRadius.circular(20),

          border: Border.all(
            color:
            colors.outline.withOpacity(
              0.12,
            ),
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                isDark ? 0.20 : 0.05,
              ),

              blurRadius: 16,

              offset:
              const Offset(0, 7),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            // ==================================================
            // IMAGE
            // ==================================================

            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(
                    top:
                    Radius.circular(20),
                  ),

                  child:
                  _buildPropertyImage(
                    property.imageUrl,
                  ),
                ),

                // ------------------------------------------------
                // CATEGORY
                // ------------------------------------------------

                Positioned(
                  top: 10,
                  left: 10,

                  child:
                  _buildCategoryTag(
                    property.category,
                  ),
                ),

                // ------------------------------------------------
                // FAVORITE
                // ------------------------------------------------

                Positioned(
                  top: 10,
                  right: 10,

                  child:
                  _buildFavoriteButton(),
                ),
              ],
            ),

            // ==================================================
            // INFORMATION
            // ==================================================

            Expanded(
              child: Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  12,
                  10,
                  12,
                  12,
                ),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [
                    // --------------------------------------------
                    // TITLE
                    // --------------------------------------------

                    Text(
                      property.title,

                      maxLines: 1,

                      overflow:
                      TextOverflow.ellipsis,

                      style: TextStyle(
                        color:
                        colors.onSurface,

                        fontSize: 15,

                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    // --------------------------------------------
                    // LOCATION
                    // --------------------------------------------

                    Row(
                      children: [
                        Icon(
                          Icons
                              .location_on_outlined,

                          size: 13,

                          color: colors
                              .onSurfaceVariant,
                        ),

                        const SizedBox(
                          width: 3,
                        ),

                        Expanded(
                          child: Text(
                            property.location,

                            maxLines: 1,

                            overflow:
                            TextOverflow.ellipsis,

                            style:
                            TextStyle(
                              color: colors
                                  .onSurfaceVariant,

                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // --------------------------------------------
                    // DETAILS
                    // --------------------------------------------

                    Row(
                      children: [
                        _buildSmallInfo(
                          Icons
                              .king_bed_rounded,

                          '${property.bedrooms}',
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        _buildSmallInfo(
                          Icons
                              .bathtub_outlined,

                          '${property.bathrooms.toInt()}',
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        _buildSmallInfo(
                          Icons
                              .home_work_outlined,

                          '${property.amenities.length}',
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    // --------------------------------------------
                    // PRICE
                    // --------------------------------------------

                    Text(
                      '\$${property.price.toInt()}/mo',

                      style: TextStyle(
                        color:
                        colors.primary,

                        fontSize: 16,

                        fontWeight:
                        FontWeight.bold,
                      ),
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

  // ============================================================
  // SMALL PROPERTY INFO
  // ============================================================

  Widget _buildSmallInfo(
      IconData icon,
      String text,
      ) {
    final colors =
        Theme.of(context).colorScheme;

    return Row(
      mainAxisSize:
      MainAxisSize.min,

      children: [
        Icon(
          icon,

          size: 13,

          color:
          colors.primary,
        ),

        const SizedBox(
          width: 3,
        ),

        Text(
          text,

          style: TextStyle(
            color:
            colors.onSurfaceVariant,

            fontSize: 11,

            fontWeight:
            FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROPERTY IMAGE
  // ============================================================

  Widget _buildPropertyImage(
      String imageUrl,
      ) {
    final colors =
        Theme.of(context).colorScheme;

    return SizedBox(
      height: 145,

      width: double.infinity,

      child: Image.network(
        imageUrl,

        fit: BoxFit.cover,

        loadingBuilder: (
            context,
            child,
            loadingProgress,
            ) {
          if (loadingProgress ==
              null) {
            return child;
          }

          final expected =
              loadingProgress
                  .expectedTotalBytes;

          final loaded =
              loadingProgress
                  .cumulativeBytesLoaded;

          return Container(
            color: colors
                .surfaceContainerHighest,

            child: Center(
              child:
              CircularProgressIndicator(
                strokeWidth: 2,

                color:
                colors.primary,

                value: expected != null
                    ? loaded / expected
                    : null,
              ),
            ),
          );
        },

        errorBuilder: (
            context,
            error,
            stackTrace,
            ) {
          return Container(
            color:
            colors.surfaceContainerHighest,

            child: Center(
              child: Column(
                mainAxisSize:
                MainAxisSize.min,

                children: [
                  Icon(
                    Icons
                        .image_not_supported_outlined,

                    color: colors
                        .onSurfaceVariant,

                    size: 32,
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    'No image',

                    style: TextStyle(
                      color: colors
                          .onSurfaceVariant,

                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // CATEGORY TAG
  // ============================================================

  Widget _buildCategoryTag(
      String category,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color: categoryColor,

        borderRadius:
        BorderRadius.circular(20),
      ),

      child: Text(
        category.isEmpty
            ? 'Property'
            : category,

        maxLines: 1,

        overflow:
        TextOverflow.ellipsis,

        style:
        const TextStyle(
          color: Colors.white,

          fontSize: 9,

          fontWeight:
          FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // FAVORITE BUTTON
  // ============================================================

  Widget _buildFavoriteButton() {
    return Container(
      width: 34,

      height: 34,

      decoration: BoxDecoration(
        color:
        Colors.black.withOpacity(
          0.45,
        ),

        shape:
        BoxShape.circle,

        border: Border.all(
          color:
          Colors.white.withOpacity(
            0.15,
          ),
        ),
      ),

      child: const Icon(
        Icons.favorite_border,

        color: Colors.white,

        size: 18,
      ),
    );
  }

  // ============================================================
  // INITIAL LOADING
  // ============================================================

  Widget _buildInitialLoading() {
    return GridView.builder(
      padding:
      const EdgeInsets.fromLTRB(
        20,
        4,
        20,
        100,
      ),

      itemCount: 6,

      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,

        crossAxisSpacing: 12,

        mainAxisSpacing: 14,

        childAspectRatio: 0.64,
      ),

      itemBuilder: (
          context,
          index,
          ) {
        return _buildPropertySkeleton();
      },
    );
  }

  // ============================================================
  // SKELETON
  // ============================================================

  Widget _buildPropertySkeleton() {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color:
        colors.surfaceContainer,

        borderRadius:
        BorderRadius.circular(20),

        border: Border.all(
          color:
          colors.outline.withOpacity(
            0.10,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Container(
            height: 145,

            decoration: BoxDecoration(
              color: colors
                  .surfaceContainerHighest,

              borderRadius:
              const BorderRadius.vertical(
                top:
                Radius.circular(20),
              ),
            ),

            child: Center(
              child:
              CircularProgressIndicator(
                strokeWidth: 2,

                color:
                colors.primary,
              ),
            ),
          ),

          Padding(
            padding:
            const EdgeInsets.all(12),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                _skeletonBox(
                  width:
                  double.infinity,

                  height: 15,
                ),

                const SizedBox(
                  height: 8,
                ),

                _skeletonBox(
                  width: 100,

                  height: 11,
                ),

                const SizedBox(
                  height: 20,
                ),

                _skeletonBox(
                  width: 120,

                  height: 11,
                ),

                const SizedBox(
                  height: 10,
                ),

                _skeletonBox(
                  width: 80,

                  height: 17,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SKELETON BOX
  // ============================================================

  Widget _skeletonBox({
    required double width,
    required double height,
  }) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      width: width,

      height: height,

      decoration: BoxDecoration(
        color:
        colors.surfaceContainerHighest,

        borderRadius:
        BorderRadius.circular(6),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    final colors =
        Theme.of(context).colorScheme;

    return RefreshIndicator(
      color:
      colors.primary,

      backgroundColor:
      colors.surfaceContainer,

      onRefresh:
      refreshProperties,

      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),

        children: [
          const SizedBox(
            height: 130,
          ),

          Icon(
            Icons.home_work_outlined,

            size: 60,

            color:
            colors.onSurfaceVariant,
          ),

          const SizedBox(
            height: 16,
          ),

          Center(
            child: Text(
              'No properties found',

              style: TextStyle(
                color:
                colors.onSurface,

                fontSize: 18,

                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Center(
            child: Text(
              'Try another search or filter',

              style: TextStyle(
                color:
                colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    final colors =
        Theme.of(context).colorScheme;

    return RefreshIndicator(
      color:
      colors.primary,

      backgroundColor:
      colors.surfaceContainer,

      onRefresh:
      refreshProperties,

      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),

        children: [
          const SizedBox(
            height: 130,
          ),

          Icon(
            Icons.error_outline_rounded,

            size: 60,

            color:
            colors.onSurfaceVariant,
          ),

          const SizedBox(
            height: 16,
          ),

          Center(
            child: Text(
              errorMessage ??
                  'Something went wrong',

              style: TextStyle(
                color:
                colors.onSurface,

                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          Center(
            child: ElevatedButton(
              onPressed:
              loadFirstPage,

              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                colors.primary,

                foregroundColor:
                colors.onPrimary,

                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
              ),

              child:
              const Text(
                'Try again',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER BOTTOM SHEET
  // ============================================================

  void _showFilterBottomSheet() {
    final colors =
        Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,

      backgroundColor:
      colors.surface,

      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top:
          Radius.circular(24),
        ),
      ),

      builder: (
          bottomSheetContext,
          ) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.all(24),

            child: Column(
              mainAxisSize:
              MainAxisSize.min,

              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                // ==================================================
                // TITLE
                // ==================================================

                Text(
                  'Filters',

                  style: TextStyle(
                    color:
                    colors.onSurface,

                    fontSize: 22,

                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // RESET
                // ==================================================

                ListTile(
                  contentPadding:
                  EdgeInsets.zero,

                  leading: Icon(
                    Icons
                        .restart_alt_rounded,

                    color:
                    colors.primary,
                  ),

                  title: Text(
                    'Reset filters',

                    style: TextStyle(
                      color:
                      colors.onSurface,
                    ),
                  ),

                  onTap: () {
                    Navigator.pop(
                      bottomSheetContext,
                    );

                    setState(() {
                      selectedCategoryId =
                      null;

                      selectedCategoryName =
                      null;

                      selectedFilter =
                      'All';

                      searchController
                          .clear();

                      searchQuery =
                      '';
                    });
                  },
                ),

                const SizedBox(
                  height: 10,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}