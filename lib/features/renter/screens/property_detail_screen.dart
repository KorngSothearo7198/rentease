import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/property_model.dart';
import '../../../services/chat_service.dart';
import '../../../services/favorite_service.dart';
import 'chat_detail_screen.dart';
import 'request_booking_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailScreen({
    super.key,
    required this.property,
  });

  @override
  State<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState
    extends State<PropertyDetailScreen> {
  final FavoriteService favoriteService = FavoriteService();
  final ChatService chatService = ChatService();

  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();

  bool isFavorite = false;

  int _currentImageIndex = 0;

  double _scrollOffset = 0.0;

  static const double _expandedHeight = 360.0;

  // ============================================================
  // PRIMARY COLOR
  // ============================================================

  static const Color _primary = Color(0xFF4F46E5);

  // ============================================================
  // THEME COLORS
  // ============================================================

  bool get _isDark =>
      Theme.of(context).brightness == Brightness.dark;

  Color get _backgroundColor {
    return _isDark
        ? const Color(0xFF0B0D12)
        : const Color(0xFFF8FAFC);
  }

  Color get _cardColor {
    return _isDark
        ? const Color(0xFF161922)
        : Colors.white;
  }

  Color get _textPrimary {
    return _isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF0F172A);
  }

  Color get _textSecondary {
    return _isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF64748B);
  }

  Color get _borderColor {
    return _isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFE2E8F0);
  }

  Color get _iconBackground {
    return _isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.92);
  }

  Color get _placeholderColor {
    return _isDark
        ? const Color(0xFF20232D)
        : const Color(0xFFE2E8F0);
  }

  Color get _secondaryBackground {
    return _isDark
        ? const Color(0xFF1D2029)
        : const Color(0xFFF1F5F9);
  }

  // ============================================================
  // AMENITY ICONS
  // ============================================================

  final Map<String, IconData> amenityIcons = const {
    "WiFi": Icons.wifi,
    "Parking": Icons.local_parking,
    "AC": Icons.ac_unit,
    "Pool": Icons.pool,
    "Kitchen": Icons.kitchen,
    "Laundry": Icons.local_laundry_service,
    "Gym": Icons.fitness_center,
    "Security": Icons.security,
    "Balcony": Icons.balcony,
  };

  // ============================================================
  // IMAGES
  // ============================================================

  List<String> get _images {
    final list = <String>[];

    if (widget.property.imageUrl.trim().isNotEmpty) {
      list.add(widget.property.imageUrl);
    }

    // Add more images here later if your model supports them.
    //
    // list.addAll(widget.property.images ?? []);

    if (list.isEmpty) {
      list.add('');
    }

    return list;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    checkFavorite();

    _scrollController.addListener(() {
      if (!mounted) return;

      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // COLLAPSE PROGRESS
  // ============================================================

  double get _collapseProgress {
    return (
        _scrollOffset /
            (_expandedHeight - kToolbarHeight)
    ).clamp(0.0, 1.0);
  }

  // ============================================================
  // FAVORITE
  // ============================================================

  Future<void> checkFavorite() async {
    final result =
    await favoriteService.isFavorite(widget.property.id);

    if (!mounted) return;

    setState(() {
      isFavorite = result;
    });
  }

  Future<void> toggleFavorite() async {
    if (isFavorite) {
      await favoriteService.removeFavorite(
        widget.property.id,
      );
    } else {
      await favoriteService.addFavorite(
        widget.property,
      );
    }

    if (!mounted) return;

    setState(() {
      isFavorite = !isFavorite;
    });
  }

  // ============================================================
  // OPEN MAP
  // ============================================================

  Future<void> openMap(String location) async {
    final Uri googleMapUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}",
    );

    try {
      await launchUrl(
        googleMapUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint("MAP ERROR: $e");
    }
  }

  // ============================================================
  // IMAGE VIEWER
  // ============================================================

  void _openImageViewer({
    int initialIndex = 0,
  }) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) {
          return _FullScreenImageViewer(
            images: _images,
            initialIndex: initialIndex,
          );
        },
        transitionsBuilder: (
            _,
            animation,
            __,
            child,
            ) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final progress = _collapseProgress;

    final titleOpacity =
    ((progress - 0.55) / 0.45)
        .clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: _backgroundColor,

      body: Stack(
        children: [
          // ======================================================
          // MAIN SCROLL
          // ======================================================

          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ==================================================
              // HERO IMAGE
              // ==================================================

              SliverAppBar(
                expandedHeight: _expandedHeight,

                pinned: true,

                stretch: true,

                backgroundColor: _backgroundColor,

                elevation: 0,

                scrolledUnderElevation: 0,

                // =================================================
                // BACK BUTTON
                // =================================================

                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: _iconBackground,

                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: _textPrimary,
                      ),

                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),

                // =================================================
                // COLLAPSED TITLE
                // =================================================

                title: Opacity(
                  opacity: titleOpacity,

                  child: Text(
                    widget.property.title,

                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                centerTitle: true,

                // =================================================
                // FAVORITE BUTTON
                // =================================================

                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),

                    child: CircleAvatar(
                      backgroundColor:
                      _iconBackground,

                      child: IconButton(
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,

                          size: 20,

                          color: isFavorite
                              ? const Color(0xFFEF4444)
                              : _textPrimary,
                        ),

                        onPressed: toggleFavorite,
                      ),
                    ),
                  ),
                ],

                // =================================================
                // FLEXIBLE SPACE
                // =================================================

                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],

                  background: Stack(
                    fit: StackFit.expand,

                    children: [
                      // ===========================================
                      // IMAGE PAGE VIEW
                      // ===========================================

                      PageView.builder(
                        controller: _pageController,

                        itemCount: _images.length,

                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },

                        itemBuilder: (
                            context,
                            index,
                            ) {
                          final url = _images[index];

                          return GestureDetector(
                            onTap: () {
                              _openImageViewer(
                                initialIndex: index,
                              );
                            },

                            child: url.isEmpty
                                ? Container(
                              color:
                              _placeholderColor,

                              child: Icon(
                                Icons.home_rounded,
                                size: 64,
                                color:
                                _textSecondary,
                              ),
                            )
                                : Image.network(
                              url,

                              fit: BoxFit.cover,

                              errorBuilder:
                                  (
                                  _,
                                  __,
                                  ___,
                                  ) {
                                return Container(
                                  color:
                                  _placeholderColor,

                                  child: Icon(
                                    Icons.home_rounded,
                                    size: 64,
                                    color:
                                    _textSecondary,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                      // ===========================================
                      // BOTTOM IMAGE GRADIENT
                      // ===========================================

                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 100,

                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient:
                            LinearGradient(
                              begin:
                              Alignment.topCenter,
                              end:
                              Alignment.bottomCenter,

                              colors: [
                                Colors.transparent,

                                Colors.black
                                    .withOpacity(
                                  0.45,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ===========================================
                      // PAGE DOTS
                      // ===========================================

                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,

                        child: Column(
                          children: [
                            if (_images.length > 1)
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment
                                    .center,

                                children:
                                List.generate(
                                  _images.length,
                                      (index) {
                                    final active =
                                        index ==
                                            _currentImageIndex;

                                    return AnimatedContainer(
                                      duration:
                                      const Duration(
                                        milliseconds:
                                        200,
                                      ),

                                      margin:
                                      const EdgeInsets
                                          .symmetric(
                                        horizontal: 3,
                                      ),

                                      width:
                                      active
                                          ? 18
                                          : 7,

                                      height: 7,

                                      decoration:
                                      BoxDecoration(
                                        color: active
                                            ? Colors.white
                                            : Colors.white54,

                                        borderRadius:
                                        BorderRadius
                                            .circular(
                                          4,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                            const SizedBox(
                              height: 10,
                            ),

                            // =====================================
                            // VIEW PHOTOS
                            // =====================================

                            GestureDetector(
                              onTap: () {
                                _openImageViewer(
                                  initialIndex:
                                  _currentImageIndex,
                                );
                              },

                              child: Container(
                                padding:
                                const EdgeInsets
                                    .symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),

                                decoration:
                                BoxDecoration(
                                  color: Colors.black
                                      .withOpacity(
                                    0.45,
                                  ),

                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    20,
                                  ),
                                ),

                                child: const Row(
                                  mainAxisSize:
                                  MainAxisSize.min,

                                  children: [
                                    Icon(
                                      Icons
                                          .photo_library_outlined,
                                      size: 14,
                                      color:
                                      Colors.white,
                                    ),

                                    SizedBox(
                                      width: 6,
                                    ),

                                    Text(
                                      "View photos",

                                      style:
                                      TextStyle(
                                        color:
                                        Colors.white,
                                        fontSize: 12,
                                        fontWeight:
                                        FontWeight
                                            .w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==================================================
              // CONTENT
              // ==================================================

              theContent(),
            ],
          ),

          // ======================================================
          // STICKY BOTTOM BAR
          // ======================================================

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,

            child: Container(
              padding:
              const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                28,
              ),

              decoration: BoxDecoration(
                color: _cardColor,

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      _isDark ? 0.35 : 0.06,
                    ),

                    blurRadius: 20,

                    offset: const Offset(
                      0,
                      -4,
                    ),
                  ),
                ],
              ),

              child: Row(
                children: [
                  // =================================================
                  // PRICE
                  // =================================================

                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    mainAxisSize:
                    MainAxisSize.min,

                    children: [
                      Text(
                        "\$${widget.property.price.toInt()}",

                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight:
                          FontWeight.w800,
                          color: _primary,
                          letterSpacing: -0.4,
                        ),
                      ),

                      Text(
                        "per month",

                        style: TextStyle(
                          fontSize: 12,
                          color:
                          _textSecondary,
                          fontWeight:
                          FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    width: 20,
                  ),

                  // =================================================
                  // BOOK BUTTON
                  // =================================================

                  Expanded(
                    child: SizedBox(
                      height: 52,

                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RequestBookingScreen(
                                    property:
                                    widget.property,
                                  ),
                            ),
                          );
                        },

                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor:
                          _primary,

                          foregroundColor:
                          Colors.white,

                          elevation: 0,

                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),

                        child: const Text(
                          "Book Now",

                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget theContent() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          120,
        ),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            // ==================================================
            // CATEGORY
            // ==================================================

            if (widget.property.category
                .trim()
                .isNotEmpty)
              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),

                decoration: BoxDecoration(
                  color: _primary.withOpacity(
                    0.1,
                  ),

                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),

                child: const Text(
                  "",
                ).buildCategoryText(
                  widget.property.category,
                ),
              ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // TITLE
            // ==================================================

            Text(
              widget.property.title,

              style: TextStyle(
                fontSize: 24,
                fontWeight:
                FontWeight.w800,
                color: _textPrimary,
                letterSpacing: -0.4,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            // ==================================================
            // LOCATION
            // ==================================================

            GestureDetector(
              onTap: () {
                openMap(
                  widget.property.location,
                );
              },

              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: _textSecondary,
                  ),

                  const SizedBox(
                    width: 4,
                  ),

                  Expanded(
                    child: Text(
                      widget.property.location,

                      style: TextStyle(
                        color:
                        _textSecondary,
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  ),

                  const Text(
                    "Map",

                    style: TextStyle(
                      color: _primary,
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // SPECS
            // ==================================================

            Row(
              children: [
                _specChip(
                  Icons.bed_outlined,
                  "${widget.property.bedrooms} Beds",
                ),

                const SizedBox(
                  width: 10,
                ),

                _specChip(
                  Icons.bathtub_outlined,
                  "${widget.property.bathrooms} Baths",
                ),

                const SizedBox(
                  width: 10,
                ),

                _specChip(
                  Icons.payments_outlined,
                  "\$${widget.property.price.toInt()}/mo",
                ),
              ],
            ),

            const SizedBox(
              height: 28,
            ),

            // ==================================================
            // DESCRIPTION
            // ==================================================

            _sectionTitle(
              "Description",
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              widget.property.description
                  .trim()
                  .isEmpty
                  ? "No description provided."
                  : widget.property.description,

              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: _textSecondary,
              ),
            ),

            const SizedBox(
              height: 28,
            ),

            // ==================================================
            // FACILITIES
            // ==================================================

            if (widget.property.amenities
                .isNotEmpty) ...[
              _sectionTitle(
                "Facilities",
              ),

              const SizedBox(
                height: 14,
              ),

              Wrap(
                spacing: 12,
                runSpacing: 12,

                children: widget.property
                    .amenities
                    .map(
                      (amenity) {
                    return _facilityChip(
                      icon: amenityIcons[
                      amenity] ??
                          Icons
                              .check_circle_outline,
                      label: amenity,
                    );
                  },
                )
                    .toList(),
              ),

              const SizedBox(
                height: 28,
              ),
            ],

            // ==================================================
            // HOST
            // ==================================================

            _sectionTitle(
              "Host",
            ),

            const SizedBox(
              height: 12,
            ),

            Container(
              padding:
              const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: _cardColor,

                borderRadius:
                BorderRadius.circular(
                  16,
                ),

                border: Border.all(
                  color: _borderColor,
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(
                      _isDark ? 0.15 : 0.03,
                    ),

                    blurRadius: 12,

                    offset: const Offset(
                      0,
                      3,
                    ),
                  ),
                ],
              ),

              child: Row(
                children: [
                  // ============================================
                  // OWNER ICON
                  // ============================================

                  CircleAvatar(
                    radius: 24,

                    backgroundColor:
                    _primary.withOpacity(
                      0.1,
                    ),

                    child: const Icon(
                      Icons.person_rounded,
                      color: _primary,
                      size: 26,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  // ============================================
                  // OWNER INFO
                  // ============================================

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        Text(
                          "Property Owner",

                          style: TextStyle(
                            fontWeight:
                            FontWeight.w700,
                            fontSize: 15,
                            color:
                            _textPrimary,
                          ),
                        ),

                        const SizedBox(
                          height: 2,
                        ),

                        Text(
                          "Host",

                          style: TextStyle(
                            color:
                            _textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ============================================
                  // CHAT
                  // ============================================

                  _iconAction(
                    Icons
                        .chat_bubble_outline_rounded,
                    onTap: _openChat,
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 28,
            ),

            // ==================================================
            // LOCATION
            // ==================================================

            _sectionTitle(
              "Location",
            ),

            const SizedBox(
              height: 12,
            ),

            GestureDetector(
              onTap: () {
                openMap(
                  widget.property.location,
                );
              },

              child: Container(
                height: 140,

                width: double.infinity,

                decoration: BoxDecoration(
                  color: _cardColor,

                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),

                  border: Border.all(
                    color: _borderColor,
                  ),
                ),

                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,

                  children: [
                    // ==========================================
                    // MAP ICON
                    // ==========================================

                    Container(
                      width: 48,
                      height: 48,

                      decoration:
                      BoxDecoration(
                        color:
                        _primary.withOpacity(
                          0.1,
                        ),

                        shape:
                        BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.map_outlined,
                        color: _primary,
                        size: 24,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // ==========================================
                    // LOCATION TEXT
                    // ==========================================

                    Text(
                      widget.property.location,

                      textAlign:
                      TextAlign.center,

                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w600,
                        color:
                        _textPrimary,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    const Text(
                      "Tap to open in Maps",

                      style: TextStyle(
                        fontSize: 12,
                        color: _primary,
                        fontWeight:
                        FontWeight.w500,
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
  // OPEN CHAT
  // ============================================================

  Future<void> _openChat() async {
    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    final conversationId =
    chatService.createConversationId(
      currentUser.uid,
      widget.property.ownerId,
    );

    await chatService.createConversation(
      conversationId: conversationId,
      renterId: currentUser.uid,
      ownerId: widget.property.ownerId,
      houseId: widget.property.id,
      propertyName: widget.property.title,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          conversationId:
          conversationId,
          hostName: "Owner",
          propertyName:
          widget.property.title,
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
      String title,
      ) {
    return Text(
      title,

      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: _textPrimary,
        letterSpacing: -0.2,
      ),
    );
  }

  // ============================================================
  // SPEC CHIP
  // ============================================================

  Widget _specChip(
      IconData icon,
      String label,
      ) {
    return Expanded(
      child: Container(
        padding:
        const EdgeInsets.symmetric(
          vertical: 12,
        ),

        decoration: BoxDecoration(
          color: _cardColor,

          borderRadius:
          BorderRadius.circular(
            14,
          ),

          border: Border.all(
            color: _borderColor,
          ),

          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withOpacity(
                _isDark ? 0.12 : 0.03,
              ),

              blurRadius: 10,

              offset: const Offset(
                0,
                2,
              ),
            ),
          ],
        ),

        child: Column(
          children: [
            Icon(
              icon,
              color: _primary,
              size: 20,
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              label,

              style: TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w600,
                color: _textPrimary,
              ),

              textAlign:
              TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FACILITY CHIP
  // ============================================================

  Widget _facilityChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),

      decoration: BoxDecoration(
        color: _cardColor,

        borderRadius:
        BorderRadius.circular(
          14,
        ),

        border: Border.all(
          color: _borderColor,
        ),
      ),

      child: Row(
        mainAxisSize:
        MainAxisSize.min,

        children: [
          Icon(
            icon,
            size: 18,
            color: _primary,
          ),

          const SizedBox(
            width: 8,
          ),

          Text(
            label,

            style: TextStyle(
              fontSize: 13,
              fontWeight:
              FontWeight.w600,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ICON ACTION
  // ============================================================

  Widget _iconAction(
      IconData icon, {
        required VoidCallback onTap,
      }) {
    return Material(
      color: _primary.withOpacity(
        0.1,
      ),

      borderRadius:
      BorderRadius.circular(
        12,
      ),

      child: InkWell(
        onTap: onTap,

        borderRadius:
        BorderRadius.circular(
          12,
        ),

        child: Padding(
          padding:
          const EdgeInsets.all(
            10,
          ),

          child: Icon(
            icon,
            color: _primary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// CATEGORY TEXT HELPER
// ================================================================
//
// This is used only to keep the category Text non-const because
// the text comes from the Property model.
// ================================================================

extension _CategoryTextExtension on Text {
  Widget buildCategoryText(
      String category,
      ) {
    return Text(
      category.toUpperCase(),

      style: const TextStyle(
        color: _PropertyDetailScreenState._primary,
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ============================================================
// FULL SCREEN IMAGE VIEWER
// ============================================================

class _FullScreenImageViewer
    extends StatefulWidget {
  final List<String> images;

  final int initialIndex;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer>
  createState() =>
      _FullScreenImageViewerState();
}

class _FullScreenImageViewerState
    extends State<_FullScreenImageViewer> {
  late PageController _controller;

  late int _index;

  @override
  void initState() {
    super.initState();

    _index = widget.initialIndex;

    _controller = PageController(
      initialPage:
      widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      // Image viewer intentionally stays black.
      backgroundColor: Colors.black,

      body: Stack(
        children: [
          // ======================================================
          // IMAGES
          // ======================================================

          PageView.builder(
            controller: _controller,

            itemCount:
            widget.images.length,

            onPageChanged: (index) {
              setState(() {
                _index = index;
              });
            },

            itemBuilder: (
                context,
                index,
                ) {
              final url =
              widget.images[index];

              return InteractiveViewer(
                minScale: 1,

                maxScale: 4,

                child: Center(
                  child: url.isEmpty
                      ? const Icon(
                    Icons.home_rounded,
                    size: 80,
                    color:
                    Colors.white54,
                  )
                      : Image.network(
                    url,

                    fit: BoxFit.contain,

                    errorBuilder:
                        (
                        _,
                        __,
                        ___,
                        ) {
                      return const Icon(
                        Icons
                            .broken_image_outlined,
                        size: 64,
                        color:
                        Colors.white54,
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // ======================================================
          // TOP BAR
          // ======================================================

          SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),

              child: Row(
                children: [
                  // ==============================================
                  // CLOSE
                  // ==============================================

                  IconButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },

                    icon: const Icon(
                      Icons.close_rounded,
                      color:
                      Colors.white,
                      size: 28,
                    ),
                  ),

                  const Spacer(),

                  // ==============================================
                  // IMAGE COUNTER
                  // ==============================================

                  if (widget.images
                      .length >
                      1)
                    Text(
                      "${_index + 1} / ${widget.images.length}",

                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                  const SizedBox(
                    width: 12,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}