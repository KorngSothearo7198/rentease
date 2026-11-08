import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/booking_model.dart';
import '../../../models/user_model.dart';
import '../../../services/booking_service.dart';
import 'owner_booking_detail.dart';

class BookingRequestsScreen extends StatefulWidget {
  const BookingRequestsScreen({super.key});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  final BookingService _bookingService = BookingService();

  final String ownerId = FirebaseAuth.instance.currentUser!.uid;

  final Map<String, String> _propertyNames = {};
  final Map<String, UserModel> _renters = {};

  int _selectedFilterIndex = 0;

  final List<String> _filters = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
    'Cancelled',
  ];

  static const Color _primary = Color(0xFF4F46E5);
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _card = Colors.white;
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  // ============================================================
  // DATE
  // ============================================================

  String formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();

    return "${date.day}/${date.month}/${date.year}";
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color getStatusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case "approved":
        return const Color(0xFFD1FAE5);

      case "pending":
        return const Color(0xFFFEF3C7);

      case "rejected":
        return const Color(0xFFFEE2E2);

      case "cancelled":
        return const Color(0xFFF1F5F9);

      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color getStatusTextColor(String status) {
    switch (status.trim().toLowerCase()) {
      case "approved":
        return const Color(0xFF059669);

      case "pending":
        return const Color(0xFFD97706);

      case "rejected":
        return const Color(0xFFDC2626);

      case "cancelled":
        return const Color(0xFF64748B);

      default:
        return _textSecondary;
    }
  }

  // ============================================================
  // LOAD PROPERTY NAME
  // ============================================================

  Future<void> _loadPropertyName(String houseId) async {
    if (_propertyNames.containsKey(houseId)) {
      return;
    }

    final name = await _bookingService.getHouseName(houseId);

    if (!mounted) {
      return;
    }

    setState(() {
      _propertyNames[houseId] = name ?? 'Unknown house';
    });
  }

  // ============================================================
  // LOAD RENTER
  // ============================================================

  Future<void> _loadRenter(String renterId) async {
    if (_renters.containsKey(renterId)) {
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(renterId)
          .get();

      if (!doc.exists || doc.data() == null) {
        return;
      }

      final renter = UserModel.fromMap(doc.data()!);

      if (!mounted) {
        return;
      }

      setState(() {
        _renters[renterId] = renter;
      });
    } catch (e) {
      debugPrint("Load renter error: $e");
    }
  }

  // ============================================================
  // OPEN RENTER PROFILE
  // ============================================================

  Future<void> _openRenterProfile(String renterId) async {
    try {
      UserModel? renter = _renters[renterId];

      if (renter == null) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator(color: _primary)),
            );
          },
        );

        final doc = await FirebaseFirestore.instance
            .collection("users")
            .doc(renterId)
            .get();

        if (!mounted) {
          return;
        }

        Navigator.pop(context);

        if (!doc.exists || doc.data() == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Renter profile not found"),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          return;
        }

        renter = UserModel.fromMap(doc.data()!);

        _renters[renterId] = renter;
      }

      if (!mounted || renter == null) {
        return;
      }

      final UserModel renterUser = renter;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: _border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Profile image
                  _buildLargeProfileImage(renterUser),

                  const SizedBox(height: 14),

                  // Name
                  Text(
                    renterUser.fullName.isNotEmpty
                        ? renterUser.fullName
                        : "Unknown Renter",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    "Renter",
                    style: TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Phone
                  _profileInfoRow(
                    Icons.phone_outlined,
                    renterUser.phone.isNotEmpty ? renterUser.phone : "No phone",
                  ),

                  const SizedBox(height: 12),

                  // Email
                  _profileInfoRow(
                    Icons.email_outlined,
                    renterUser.email.isNotEmpty ? renterUser.email : "No email",
                  ),

                  // Occupation
                  if (renterUser.occupation.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _profileInfoRow(
                      Icons.work_outline_rounded,
                      renterUser.occupation,
                    ),
                  ],

                  // Gender / age
                  if (renterUser.gender.isNotEmpty || renterUser.age > 0) ...[
                    const SizedBox(height: 12),
                    _profileInfoRow(
                      Icons.person_outline_rounded,
                      [
                        if (renterUser.gender.isNotEmpty) renterUser.gender,
                        if (renterUser.age > 0) "${renterUser.age} years",
                      ].join(" • "),
                    ),
                  ],

                  // Address
                  if (renterUser.address.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _profileInfoRow(
                      Icons.location_on_outlined,
                      renterUser.address,
                    ),
                  ],

                  // Bio
                  if (renterUser.bio.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "About",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            renterUser.bio,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Close
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint("Open renter profile error: $e");

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ============================================================
  // LARGE PROFILE IMAGE
  // ============================================================

  Widget _buildLargeProfileImage(UserModel renter) {
    final imageUrl = renter.profileImage?.trim() ?? '';

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _primary.withOpacity(0.1),
        border: Border.all(color: _primary.withOpacity(0.15), width: 2),
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                width: 84,
                height: 84,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return const Icon(
                    Icons.person_rounded,
                    size: 42,
                    color: _primary,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primary,
                    ),
                  );
                },
              )
            : const Icon(Icons.person_rounded, size: 42, color: _primary),
      ),
    );
  }

  // ============================================================
  // PROFILE INFO ROW
  // ============================================================

  Widget _profileInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: _primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: _textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTER BOOKINGS
  // ============================================================

  List<BookingModel> _filterBookings(List<BookingModel> bookings) {
    if (_selectedFilterIndex == 0) {
      return bookings;
    }

    final selectedStatus = _filters[_selectedFilterIndex].toLowerCase();

    return bookings.where((booking) {
      return booking.status.trim().toLowerCase() == selectedStatus;
    }).toList();
  }

  // ============================================================
  // FILTER COUNT
  // ============================================================

  int _getFilterCount(List<BookingModel> bookings, String filter) {
    if (filter == "All") {
      return bookings.length;
    }

    return bookings.where((booking) {
      return booking.status.trim().toLowerCase() == filter.toLowerCase();
    }).length;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: _textPrimary,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          "Booking Requests",
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),

        centerTitle: true,
      ),

      body: StreamBuilder<List<BookingModel>>(
        stream: _bookingService.getOwnerBookings(ownerId),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _textSecondary),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _emptyState("No booking requests yet");
          }

          final allBookings = snapshot.data!;

          final bookings = _filterBookings(allBookings);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ====================================================
              // FILTERS
              // ====================================================
              SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];

                    final selected = _selectedFilterIndex == index;

                    final count = _getFilterCount(allBookings, filter);

                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilterIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? _primary : _card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: selected ? _primary : _border,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: _primary.withOpacity(0.20),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                filter,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : _textPrimary,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.white.withOpacity(0.18)
                                      : _bg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  count.toString(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? Colors.white
                                        : _textSecondary,
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
              ),

              const SizedBox(height: 8),

              // ====================================================
              // TITLE
              // ====================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  _selectedFilterIndex == 0
                      ? "All Requests"
                      : "${_filters[_selectedFilterIndex]} Requests",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  "Swipe left on a card to view renter profile",
                  style: TextStyle(fontSize: 12, color: _textSecondary),
                ),
              ),

              // ====================================================
              // LIST
              // ====================================================
              Expanded(
                child: bookings.isEmpty
                    ? _emptyState("No requests in this filter")
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                        physics: const BouncingScrollPhysics(),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];

                          // Load property
                          if (!_propertyNames.containsKey(booking.houseId)) {
                            _loadPropertyName(booking.houseId);
                          }

                          // Load renter
                          if (!_renters.containsKey(booking.renterId)) {
                            _loadRenter(booking.renterId);
                          }

                          final houseName =
                              _propertyNames[booking.houseId] ?? 'Loading...';

                          final renter = _renters[booking.renterId];

                          final renterName =
                              renter?.fullName.trim().isNotEmpty == true
                              ? renter!.fullName
                              : 'Loading...';

                          final profileImage = renter?.profileImage;

                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(
                              milliseconds: 320 + (index * 50).clamp(0, 300),
                            ),
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
                            child: _SwipeBookingCard(
                              booking: booking,
                              houseName: houseName,
                              renterName: renterName,
                              renterProfileImage: profileImage,
                              dateRange:
                                  "${formatDate(booking.startDate)} – "
                                  "${formatDate(booking.endDate)}",
                              statusBgColor: getStatusColor(booking.status),
                              statusTextColor: getStatusTextColor(
                                booking.status,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OwnerBookingDetailsScreen(
                                      booking: booking,
                                    ),
                                  ),
                                );
                              },
                              onViewProfile: () {
                                _openRenterProfile(booking.renterId);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState(String message) {
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
            child: const Icon(Icons.inbox_outlined, size: 36, color: _primary),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SWIPEABLE BOOKING CARD
// ============================================================

class _SwipeBookingCard extends StatefulWidget {
  final BookingModel booking;

  final String renterName;
  final String houseName;
  final String? renterProfileImage;

  final String dateRange;

  final Color statusBgColor;
  final Color statusTextColor;

  final VoidCallback onTap;
  final VoidCallback onViewProfile;

  const _SwipeBookingCard({
    required this.booking,
    required this.renterName,
    required this.houseName,
    required this.renterProfileImage,
    required this.dateRange,
    required this.statusBgColor,
    required this.statusTextColor,
    required this.onTap,
    required this.onViewProfile,
  });

  @override
  State<_SwipeBookingCard> createState() => _SwipeBookingCardState();
}

class _SwipeBookingCardState extends State<_SwipeBookingCard>
    with SingleTickerProviderStateMixin {
  static const double _actionWidth = 88.0;

  double _dragExtent = 0.0;

  late AnimationController _controller;
  late Animation<double> _animation;

  static const Color _primary = Color(0xFF4F46E5);

  static const Color _card = Colors.white;

  static const Color _textPrimary = Color(0xFF0F172A);

  static const Color _textSecondary = Color(0xFF64748B);

  static const Color _border = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ============================================================
  // CLOSE
  // ============================================================

  void _close() {
    _animation =
        Tween<double>(begin: _dragExtent, end: 0.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        )..addListener(() {
          if (mounted) {
            setState(() {
              _dragExtent = _animation.value;
            });
          }
        });

    _controller.forward(from: 0);
  }

  // ============================================================
  // OPEN
  // ============================================================

  void _open() {
    _animation =
        Tween<double>(begin: _dragExtent, end: -_actionWidth).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        )..addListener(() {
          if (mounted) {
            setState(() {
              _dragExtent = _animation.value;
            });
          }
        });

    _controller.forward(from: 0);
  }

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  Widget _buildAvatar() {
    final imageUrl = widget.renterProfileImage?.trim() ?? '';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person_rounded,
                    color: _primary,
                    size: 24,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primary,
                    ),
                  );
                },
              )
            : const Icon(Icons.person_rounded, color: _primary, size: 24),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 92,
        child: Stack(
          children: [
            Positioned.fill(
              child: Row(
                children: [
                  const Spacer(),

                  GestureDetector(
                    onTap: () {
                      _close();
                      widget.onViewProfile();
                    },
                    child: Container(
                      width: _actionWidth,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Profile",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // FOREGROUND CARD
            // ==================================================
            GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragExtent = (_dragExtent + details.delta.dx).clamp(
                    -_actionWidth,
                    0.0,
                  );
                });
              },
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;

                if (velocity < -400 || _dragExtent < -_actionWidth / 2) {
                  _open();
                } else {
                  _close();
                }
              },
              child: Transform.translate(
                offset: Offset(_dragExtent, 0),
                child: Material(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (_dragExtent < -10) {
                        _close();
                        return;
                      }

                      widget.onTap();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border.withOpacity(0.8)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // ==================================================
                          // AVATAR
                          // ==================================================
                          _buildAvatar(),

                          const SizedBox(width: 12),

                          // ==================================================
                          // INFO
                          // ==================================================
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.renterName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  widget.houseName,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: _textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 3),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 12,
                                      color: _textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        widget.dateRange,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // ==================================================
                          // STATUS + PRICE
                          // ==================================================
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.statusBgColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget.booking.status.toUpperCase(),
                                  style: TextStyle(
                                    color: widget.statusTextColor,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                "\$${widget.booking.totalAmount.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
