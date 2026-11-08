import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/property_model.dart';
import '../../../services/chat_service.dart';
import '../../../services/favorite_service.dart';
import 'chat_detail_screen.dart';
import 'request_booking_screen.dart';

import '../../../models/user_model.dart';
import '../../../services/user_service.dart';


class PropertyDetailScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen>
    with SingleTickerProviderStateMixin {
  final FavoriteService favoriteService = FavoriteService();
  final ChatService chatService = ChatService();

  final UserService _userService = UserService();

  UserModel? _owner;
  bool _ownerLoading = true;

  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _animationController;

  bool isFavorite = false;
  bool _descriptionExpanded = false;

  int _currentImageIndex = 0;

  double _scrollOffset = 0;

  static const double _expandedHeight = 380;

  static const Color _primary = Color(0xFF4F46E5);
  static const Color _success = Color(0xFF10B981);
  static const Color _danger = Color(0xFFEF4444);

  // ============================================================
  // THEME
  // ============================================================

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _backgroundColor {
    return _isDark ? const Color(0xFF0B0D12) : const Color(0xFFF8FAFC);
  }

  Color get _cardColor {
    return _isDark ? const Color(0xFF151821) : Colors.white;
  }

  Color get _secondaryColor {
    return _isDark ? const Color(0xFF1D212B) : const Color(0xFFF1F5F9);
  }

  Color get _textPrimary {
    return _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  }

  Color get _textSecondary {
    return _isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B);
  }

  Color get _borderColor {
    return _isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
  }

  Color get _overlayButton {
    return Colors.black.withOpacity(0.35);
  }

  // ============================================================
  // AMENITY ICONS
  // ============================================================

  final Map<String, IconData> amenityIcons = const {
    "WiFi": Icons.wifi_rounded,
    "Parking": Icons.local_parking_rounded,
    "AC": Icons.ac_unit_rounded,
    "Pool": Icons.pool_rounded,
    "Kitchen": Icons.kitchen_rounded,
    "Laundry": Icons.local_laundry_service_rounded,
    "Gym": Icons.fitness_center_rounded,
    "Security": Icons.security_rounded,
    "Balcony": Icons.balcony_rounded,
  };

  // ============================================================
  // IMAGES
  // ============================================================

  List<String> get _images {
    final images = <String>[];

    if (widget.property.imageUrl.trim().isNotEmpty) {
      images.add(widget.property.imageUrl.trim());
    }

    if (images.isEmpty) {
      images.add('');
    }

    return images;
  }

  late List<Map<String, dynamic>> _specItems;

  @override
  void initState() {
    super.initState();

    _specItems = [
      {
        'icon': Icons.bed_outlined,
        'value': '${widget.property.bedrooms}',
        'label': 'Bedrooms',
      },
      {
        'icon': Icons.bathtub_outlined,
        'value': '${widget.property.bathrooms}',
        'label': 'Bathrooms',
      },
      {
        'icon': Icons.payments_outlined,
        'value': '\$${widget.property.price.toInt()}',
        'label': 'Monthly',
      },
    ];


    _loadOwner();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _animationController.forward();

    checkFavorite();

    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!mounted) return;

    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  Future<void> _loadOwner() async {
    debugPrint('========================================');
    debugPrint('[OWNER] Loading owner...');
    debugPrint(
      '[OWNER] ownerId = ${widget.property.ownerId}',
    );

    final owner = await _userService.getOwnerById(
      widget.property.ownerId,
    );

    if (owner == null) {
      debugPrint('[OWNER] ❌ Owner not found');
    } else {
      debugPrint('[OWNER] ✅ Owner found');
      debugPrint('[OWNER] UID = ${owner.uid}');
      debugPrint('[OWNER] Name = ${owner.fullName}');
      debugPrint('[OWNER] Role = ${owner.role}');
    }

    if (!mounted) return;

    setState(() {
      _owner = owner;
      _ownerLoading = false;
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();

    super.dispose();
  }

  // ============================================================
  // SCROLL PROGRESS
  // ============================================================

  double get _collapseProgress {
    final value = _scrollOffset / (_expandedHeight - kToolbarHeight);

    return value.clamp(0.0, 1.0);
  }

  // ============================================================
  // FAVORITE
  // ============================================================

  Future<void> checkFavorite() async {
    try {
      final result = await favoriteService.isFavorite(widget.property.id);

      if (!mounted) return;

      setState(() {
        isFavorite = result;
      });
    } catch (e) {
      debugPrint('Favorite check error: $e');
    }
  }

  Future<void> toggleFavorite() async {
    try {
      if (isFavorite) {
        await favoriteService.removeFavorite(widget.property.id);
      } else {
        await favoriteService.addFavorite(widget.property);
      }

      if (!mounted) return;

      setState(() {
        isFavorite = !isFavorite;
      });
    } catch (e) {
      debugPrint('Favorite error: $e');
    }
  }

  // ============================================================
  // OPEN GOOGLE MAP
  // ============================================================

  Future<void> openMap(String location) async {
    if (location.trim().isEmpty) return;

    final Uri googleMapUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1"
          "&query=${Uri.encodeComponent(location)}",
    );

    try {
      await launchUrl(googleMapUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("MAP ERROR: $e");
    }
  }

  // ============================================================
  // IMAGE VIEWER
  // ============================================================

  void _openImageViewer({int initialIndex = 0}) {
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
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // ============================================================
  // CHAT
  // ============================================================

  // ============================================================
// CHAT
// ============================================================

  Future<void> _openChat() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    try {
      // ==========================================================
      // VALIDATE OWNER
      // ==========================================================

      final ownerId = widget.property.ownerId.trim();

      if (ownerId.isEmpty) {
        throw Exception("Owner ID is missing.");
      }

      // ==========================================================
      // VALIDATE PROPERTY
      // ==========================================================

      final houseId = widget.property.id.trim();

      if (houseId.isEmpty) {
        throw Exception("Property ID is missing.");
      }

      // ==========================================================
      // GET OWNER NAME
      // ==========================================================

      final String ownerName =
      _owner?.fullName.trim().isNotEmpty == true
          ? _owner!.fullName.trim()
          : 'Property Owner';

      debugPrint('========================================');
      debugPrint('[CHAT] Current User UID: ${currentUser.uid}');
      debugPrint('[CHAT] Owner UID: $ownerId');
      debugPrint('[CHAT] Owner Name: $ownerName');
      debugPrint('[CHAT] House ID: $houseId');
      debugPrint('[CHAT] Property: ${widget.property.title}');

      // ==========================================================
      // CREATE PROPERTY-SPECIFIC CONVERSATION ID
      // ==========================================================

      final conversationId = chatService.createConversationId(
        currentUser.uid,
        ownerId,
        houseId,
      );

      debugPrint('[CHAT] Conversation ID: $conversationId');

      // ==========================================================
      // CREATE / UPDATE CONVERSATION
      // ==========================================================

      await chatService.createConversation(
        conversationId: conversationId,
        renterId: currentUser.uid,
        ownerId: ownerId,
        houseId: houseId,
        propertyName: widget.property.title,
      );

      if (!mounted) return;

      // ==========================================================
      // OPEN CHAT
      // ==========================================================

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            conversationId: conversationId,
            hostName: ownerName,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[CHAT] ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open chat. Please try again.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final progress = _collapseProgress;

    final titleOpacity = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [_buildHero(progress, titleOpacity), _buildContent()],
          ),

          _buildBottomBar(),
        ],
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero(double progress, double titleOpacity) {
    return SliverAppBar(
      expandedHeight: _expandedHeight,
      pinned: true,
      stretch: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _backgroundColor,

      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _circleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () {
            Navigator.pop(context);
          },
        ),
      ),

      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: titleOpacity,
        child: Text(
          widget.property.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      centerTitle: true,

      actions: [
        Padding(padding: const EdgeInsets.all(8), child: _favoriteButton()),
      ],

      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: _buildHeroImage(),
      ),
    );
  }

  // ============================================================
  // HERO IMAGE
  // ============================================================

  Widget _buildHeroImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: _images.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final url = _images[index];

            return GestureDetector(
              onTap: () {
                _openImageViewer(initialIndex: index);
              },
              child: Hero(
                tag: "property-image-${widget.property.id}",
                child: url.isEmpty
                    ? _imagePlaceholder()
                    : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return _imagePlaceholder();
                  },
                ),
              ),
            );
          },
        ),

        // Dark gradient
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 150,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                ),
              ),
            ),
          ),
        ),

        // Bottom information
        Positioned(
          left: 20,
          right: 20,
          bottom: 18,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _heroPrice()),
              _photoCounter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroPrice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.property.category.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "\$${widget.property.price.toInt()}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),

        const Text(
          "per month",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableSpecCard({
    required Key key,
    required int index,
    required IconData icon,
    required String value,
    required String label,
  }) {
    return ReorderableDelayedDragStartListener(
      key: key,
      index: index,

      child: Padding(
        padding: EdgeInsets.only(
          right: index == _specItems.length - 1 ? 0 : 10,
        ),

        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 250,
          ),
          curve: Curves.easeOut,

          width: 105,

          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 8,
          ),

          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _borderColor,
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 0.85,
                  end: 1.0,
                ),

                duration: const Duration(
                  milliseconds: 350,
                ),

                curve: Curves.easeOutBack,

                builder: (
                    context,
                    scale,
                    child,
                    ) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },

                child: Container(
                  width: 36,
                  height: 36,

                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),

                  child: Icon(
                    icon,
                    color: _primary,
                    size: 19,
                  ),
                ),
              ),

              const SizedBox(height: 7),

              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 2),

              // ==================================================
              // LABEL
              // ==================================================

              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),

                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _photoCounter() {
    return GestureDetector(
      onTap: () {
        _openImageViewer(initialIndex: _currentImageIndex);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 15,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
            Text(
              "${_currentImageIndex + 1}/${_images.length}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FAVORITE
  // ============================================================

  Widget _favoriteButton() {
    return AnimatedScale(
      scale: isFavorite ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 200),
      child: _circleButton(
        icon: isFavorite
            ? Icons.favorite_rounded
            : Icons.favorite_border_rounded,
        iconColor: isFavorite ? _danger : _textPrimary,
        onTap: toggleFavorite,
      ),
    );
  }

  // ============================================================
  // CIRCLE BUTTON
  // ============================================================

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.black.withOpacity(0.35),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 135),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _animatedSection(delay: 0, child: _buildTitleSection()),

            const SizedBox(height: 20),

            _animatedSection(delay: 150, child: _buildDescription()),

            const SizedBox(height: 28),

            _animatedSection(delay: 100, child: _buildSpecs()),

            if (widget.property.amenities.isNotEmpty) ...[
              const SizedBox(height: 28),

              _animatedSection(delay: 200, child: _buildFacilities()),
            ],

            const SizedBox(height: 28),

            _animatedSection(delay: 250, child: _buildHost()),

            const SizedBox(height: 28),

            _animatedSection(delay: 300, child: _buildLocation()),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ANIMATED SECTION
  // ============================================================

  Widget _animatedSection({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.property.title,
          style: TextStyle(
            color: _textPrimary,
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),

        const SizedBox(height: 9),

        GestureDetector(
          onTap: () {
            openMap(widget.property.location);
          },
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded, color: _primary, size: 18),

              const SizedBox(width: 5),

              Expanded(
                child: Text(
                  widget.property.location,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              const Icon(
                Icons.chevron_right_rounded,
                color: _primary,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SPECS
  // ============================================================

  Widget _buildSpecs() {
    return SizedBox(
      height: 118,
      child: ReorderableListView(
        scrollDirection: Axis.horizontal,

        padding: EdgeInsets.zero,

        buildDefaultDragHandles: false,

        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }

            final item = _specItems.removeAt(oldIndex);

            _specItems.insert(
              newIndex,
              item,
            );
          });
        },

        children: [
          for (int index = 0; index < _specItems.length; index++)
            _buildDraggableSpecCard(
              key: ValueKey(
                _specItems[index]['label'],
              ),
              index: index,
              icon: _specItems[index]['icon'] as IconData,
              value: _specItems[index]['value'] as String,
              label: _specItems[index]['label'] as String,
            ),
        ],
      ),
    );
  }



  // ============================================================
  // DESCRIPTION
  // ============================================================

  Widget _buildDescription() {
    final description = widget.property.description.trim().isEmpty
        ? "No description provided."
        : widget.property.description.trim();

    final longText = description.length > 180;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Description",
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 13),

          AnimatedCrossFade(
            firstChild: Text(
              description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14,
                height: 1.65,
              ),
            ),

            secondChild: Text(
              description,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14,
                height: 1.65,
              ),
            ),

            crossFadeState: _descriptionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,

            duration: const Duration(
              milliseconds: 250,
            ),
          ),

          if (longText) ...[
            const SizedBox(height: 8),

            GestureDetector(
              onTap: () {
                setState(() {
                  _descriptionExpanded =
                  !_descriptionExpanded;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _descriptionExpanded
                        ? "Show less"
                        : "Read more",
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(width: 2),

                  Icon(
                    _descriptionExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // FACILITIES
  // ============================================================

  Widget _buildFacilities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(icon: Icons.grid_view_rounded, title: "Facilities"),

        const SizedBox(height: 14),

        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: widget.property.amenities.map((amenity) {
            return _facilityChip(
              icon: amenityIcons[amenity] ?? Icons.check_circle_outline_rounded,
              label: amenity,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _facilityChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _primary, size: 17),

          const SizedBox(width: 7),

          Text(
            label,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HOST
  // ============================================================

  Widget _buildHost() {
    final owner = _owner;

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact with Owner',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 14),

          // ======================================================
          // LOADING
          // ======================================================

          if (_ownerLoading)
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 130,
                        decoration: BoxDecoration(
                          color: _textSecondary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        height: 11,
                        width: 90,
                        decoration: BoxDecoration(
                          color: _textSecondary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )

          // ======================================================
          // OWNER NOT FOUND
          // ======================================================

          else if (owner == null)
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _textSecondary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_off_outlined,
                    color: _textSecondary,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    'Owner information unavailable',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            )

          // ======================================================
          // OWNER INFORMATION
          // ======================================================

          else
            Row(
              children: [
                // ==================================================
                // PROFILE IMAGE
                // ==================================================

                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _primary.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: owner.profileImage?.trim().isNotEmpty == true
                      ? Image.network(
                    owner.profileImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (
                        context,
                        error,
                        stackTrace,
                        ) {
                      return const Icon(
                        Icons.person_rounded,
                        color: _primary,
                        size: 25,
                      );
                    },
                  )
                      : const Icon(
                    Icons.person_rounded,
                    color: _primary,
                    size: 25,
                  ),
                ),

                const SizedBox(width: 12),

                // ==================================================
                // OWNER NAME
                // ==================================================

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        owner.fullName.trim().isNotEmpty
                            ? owner.fullName.trim()
                            : 'Property Owner',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: _success,
                            size: 14,
                          ),

                          const SizedBox(width: 4),

                          Text(
                            'Verified owner',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // CHAT
                // ==================================================

                _iconAction(
                  Icons.chat_bubble_outline_rounded,
                  _openChat,
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Widget _buildLocation() {
    final location = widget.property.location.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(icon: Icons.location_on_outlined, title: "Location"),

        const SizedBox(height: 13),

        GestureDetector(
          onTap: () {
            openMap(location);
          },
          child: Container(
            height: 190,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _secondaryColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _borderColor),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // =================================================
                // MAP-STYLE BACKGROUND
                // =================================================
                CustomPaint(painter: _MapPreviewPainter(isDark: _isDark)),

                // =================================================
                // LOCATION PIN
                // =================================================
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.7, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: _primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),

                // =================================================
                // LOCATION LABEL
                // =================================================
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _cardColor.withOpacity(0.94),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          color: _primary,
                          size: 18,
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            location.isEmpty
                                ? "Location not available"
                                : location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        const Icon(
                          Icons.open_in_new_rounded,
                          color: _primary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "Tap the map to open this location in Google Maps",
          style: TextStyle(color: _textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: child,
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _sectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primary, size: 18),
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: TextStyle(
            color: _textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ICON ACTION
  // ============================================================

  Widget _iconAction(IconData icon, VoidCallback onTap) {
    return Material(
      color: _primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            Icons.chat_bubble_outline_rounded,
            color: _primary,
            size: 19,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE PLACEHOLDER
  // ============================================================

  Widget _imagePlaceholder() {
    return Container(
      color: _isDark ? const Color(0xFF20232D) : const Color(0xFFE2E8F0),
      child: Center(
        child: Icon(Icons.home_rounded, size: 70, color: _textSecondary),
      ),
    );
  }

  // ============================================================
  // BOTTOM BOOKING BAR
  // ============================================================

  Widget _buildBottomBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: _cardColor,
            border: Border(top: BorderSide(color: _borderColor)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isDark ? 0.3 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Monthly rent",
                    style: TextStyle(color: _textSecondary, fontSize: 11),
                  ),

                  const SizedBox(height: 1),

                  Text(
                    "\$${widget.property.price.toInt()}",
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 18),

              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RequestBookingScreen(property: widget.property),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 19),

                        SizedBox(width: 8),

                        Text(
                          "Book Now",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// MAP PREVIEW PAINTER
// ================================================================
//
// This is only a visual map-style background.
// It does NOT represent a real geographic position.
//
// For a real Google Map, add latitude/longitude to Property.
// ================================================================

class _MapPreviewPainter extends CustomPainter {
  final bool isDark;

  _MapPreviewPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = isDark ? const Color(0xFF20242D) : const Color(0xFFE8EDF2);

    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF3A404B) : Colors.white
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;

    final thinRoadPaint = Paint()
      ..color = isDark ? const Color(0xFF4A505B) : const Color(0xFFD5DCE3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Main roads
    final path1 = Path()
      ..moveTo(-20, size.height * 0.25)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.45,
        size.width + 30,
        size.height * 0.2,
      );

    final path2 = Path()
      ..moveTo(size.width * 0.15, size.height + 20)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.55,
        size.width * 0.85,
        -20,
      );

    canvas.drawPath(path1, roadPaint);

    canvas.drawPath(path2, roadPaint);

    // Smaller roads
    final path3 = Path()
      ..moveTo(0, size.height * 0.72)
      ..lineTo(size.width, size.height * 0.65);

    final path4 = Path()
      ..moveTo(size.width * 0.65, 0)
      ..lineTo(size.width * 0.35, size.height);

    canvas.drawPath(path3, thinRoadPaint);

    canvas.drawPath(path4, thinRoadPaint);
  }

  @override
  bool shouldRepaint(covariant _MapPreviewPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

// ================================================================
// FULL SCREEN IMAGE VIEWER
// ================================================================

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();

    _index = widget.initialIndex;

    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _index = index;
              });
            },
            itemBuilder: (context, index) {
              final url = widget.images[index];

              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: url.isEmpty
                      ? const Icon(
                    Icons.home_rounded,
                    size: 80,
                    color: Colors.white54,
                  )
                      : Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.broken_image_outlined,
                        size: 64,
                        color: Colors.white54,
                      );
                    },
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  const Spacer(),

                  if (widget.images.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${_index + 1} / ${widget.images.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
