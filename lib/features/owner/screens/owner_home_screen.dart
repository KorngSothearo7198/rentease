import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/booking_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/owner_notification_service.dart';
import '../../../services/session_service.dart';
import '../../chat/screens/owner_chat_list.dart';
import 'manage_home_screen.dart';
import 'owner_booking_request_screen.dart';
import 'owner_earnings_screen.dart';
import 'owner_notifications_screen.dart';
import 'owner_profile_screen.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  final AuthService authService = AuthService();

  final CloudinaryService cloudinaryService = CloudinaryService();

  final ImagePicker _imagePicker = ImagePicker();

  List<String> _chartOrder = ['booking', 'room', 'income', 'user'];

  final Map<String, String> _chartTitles = {
    'booking': 'Booking Analytics',
    'room': 'Room Categories',
    'income': 'Income Breakdown',
    'user': 'User Engagement',
  };

  UserModel? user;

  bool isLoading = true;
  bool _showProfileImage = true;
  String? _backgroundImageUrl;
  bool _isUploadingBackground = false;
  double orbitAngle = 0;

  static const List<Color> _chartPalette = [
    Color(0xFF818CF8),
    Color(0xFF38BDF8),
    Color(0xFF34D399),
    Color(0xFFA78BFA),
    Color(0xFFFBBF24),
    Color(0xFFF87171),
    Color(0xFFF472B6),
  ];
  @override
  void initState() {
    super.initState();

    _loadOwnerData();
  }
  Future<void> _loadOwnerData() async {
    try {
      final localUser = await SessionService.getUser();

      if (localUser != null) {
        if (mounted) {
          setState(() {
            user = UserModel.fromJson(localUser);
          });
        }
      }
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        final data = await authService.getUserData(firebaseUser.uid);

        if (data != null) {
          if (mounted) {
            setState(() {
              user = data;
            });
          }

          await SessionService.saveUser(data.toJson());
        }

        // --------------------------------------------------------
        // LOAD BACKGROUND IMAGE
        // --------------------------------------------------------

        await _loadBackgroundImage(firebaseUser.uid);
      }
    } catch (e) {
      debugPrint("Error loading owner data: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Build Chat button with a real-time unread message count badge.

  Widget _buildChatButton(String ownerId) {
    return StreamBuilder<int>(
      stream: ChatService().getOwnerUnreadMessageCount(ownerId),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            _actionButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chat',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OwnerChatList(),
                  ),
                );
              },
            ),

            if (unreadCount > 0)
              Positioned(
                right: -3,
                top: -5,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 21,
                    minHeight: 21,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }


  Widget _buildBookingButton(String ownerId) {
    return StreamBuilder<int>(
      stream: BookingService().getOwnerPendingBookingCount(ownerId),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            _actionButton(
              icon: Icons.calendar_month_rounded,
              label: 'Booking',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BookingRequestsScreen(),
                  ),
                );
              },
            ),

            if (pendingCount > 0)
              Positioned(
                right: -4,
                top: -5,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 21,
                    minHeight: 21,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    pendingCount > 99 ? '99+' : '$pendingCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }



  // ============================================================
  // LOAD BACKGROUND IMAGE FROM FIRESTORE
  // ============================================================

  Future<void> _loadBackgroundImage(String ownerId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .get();

      if (!doc.exists) {
        return;
      }

      final data = doc.data();

      if (data == null) {
        return;
      }

      final backgroundUrl = data['backgroundImage']?.toString().trim() ?? '';

      if (!mounted) {
        return;
      }

      setState(() {
        _backgroundImageUrl = backgroundUrl.isNotEmpty ? backgroundUrl : null;
      });
    } catch (e) {
      debugPrint("Error loading background image: $e");
    }
  }

  void _showBackgroundOptions() {
    if (_isUploadingBackground) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          decoration: const BoxDecoration(
            color: Color(0xFF17102F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ------------------------------------------------
                // HANDLE
                // ------------------------------------------------
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 22),

                // ------------------------------------------------
                // HEADER
                // ------------------------------------------------
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.wallpaper_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Home Background',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Customize your dashboard background',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // CURRENT BACKGROUND PREVIEW
                // ------------------------------------------------
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 125,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1A1035),
                          Color(0xFF4C1D95),
                          Color(0xFF6B46C1),
                        ],
                      ),
                      image: _backgroundImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_backgroundImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.10),
                            Colors.black.withOpacity(0.50),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.dashboard_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Dashboard Preview',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // CHOOSE BACKGROUND
                // ------------------------------------------------
                _backgroundOption(
                  icon: Icons.photo_library_rounded,
                  title: _backgroundImageUrl == null
                      ? 'Choose Background'
                      : 'Change Background',
                  subtitle: 'Select an image from your gallery',
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    await _pickBackgroundImage();
                  },
                ),

                // ------------------------------------------------
                // REMOVE BACKGROUND
                // ------------------------------------------------
                if (_backgroundImageUrl != null) ...[
                  const SizedBox(height: 10),
                  _backgroundOption(
                    icon: Icons.delete_outline_rounded,
                    title: 'Remove Background',
                    subtitle: 'Return to the default purple gradient',
                    iconColor: Colors.redAccent,
                    onTap: () async {
                      Navigator.pop(sheetContext);

                      await _removeBackgroundImage();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BACKGROUND OPTION
  // ============================================================

  Widget _backgroundOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PICK BACKGROUND IMAGE
  // ============================================================

  Future<void> _pickBackgroundImage() async {
    if (_isUploadingBackground) {
      return;
    }

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile == null) {
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        _showMessage('Please login first.', isError: true);
        return;
      }

      if (mounted) {
        setState(() {
          _isUploadingBackground = true;
        });
      }

      // ----------------------------------------------------------
      // UPLOAD IMAGE TO CLOUDINARY
      // ----------------------------------------------------------

      final imageFile = File(pickedFile.path);

      final uploadedUrl = await cloudinaryService.uploadImage(imageFile);

      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        throw Exception('Image upload failed.');
      }

      // ----------------------------------------------------------
      // SAVE URL TO FIRESTORE
      // ----------------------------------------------------------

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({
            'backgroundImage': uploadedUrl,
            'backgroundUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // ----------------------------------------------------------
      // UPDATE UI
      // ----------------------------------------------------------

      if (!mounted) {
        return;
      }

      setState(() {
        _backgroundImageUrl = uploadedUrl;
        _isUploadingBackground = false;
      });

      _showMessage('Background updated successfully.');
    } catch (e) {
      debugPrint('Background upload error: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _isUploadingBackground = false;
      });

      _showMessage('Failed to update background.', isError: true);
    }
  }

  // ============================================================
  // REMOVE BACKGROUND IMAGE
  // ============================================================

  Future<void> _removeBackgroundImage() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isUploadingBackground = true;
        });
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({
            'backgroundImage': FieldValue.delete(),
            'backgroundUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }

      setState(() {
        _backgroundImageUrl = null;
        _isUploadingBackground = false;
      });

      _showMessage('Background removed.');
    } catch (e) {
      debugPrint('Remove background error: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _isUploadingBackground = false;
      });

      _showMessage('Failed to remove background.', isError: true);
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ============================================================
  // ANALYTICS BOTTOM SHEET
  // ============================================================

  void _showAnalyticsBottomSheet({
    required BuildContext context,
    required String title,
    required String type,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Color(0xFF1E143B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildChartContent(type)),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // CHART CONTENT
  // ============================================================

  Widget _buildChartContent(String type) {
    final ownerId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (ownerId.isEmpty) {
      return const Center(
        child: Text(
          "User not authenticated",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    switch (type) {
      // ==========================================================
      // BOOKING
      // ==========================================================

      case 'booking':
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('ownerId', isEqualTo: ownerId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  "No booking records found",
                  style: TextStyle(color: Colors.white54),
                ),
              );
            }

            final Map<String, int> statusCounts = {};

            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;

              final status = data['status']?.toString() ?? 'Unknown';

              statusCounts[status] = (statusCounts[status] ?? 0) + 1;
            }

            return _buildPieChart(
              data: statusCounts,
              total: docs.length,
              unit: "Bookings",
            );
          },
        );

      // ==========================================================
      // ROOM
      // ==========================================================

      case 'room':
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('properties')
              .where('ownerId', isEqualTo: ownerId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  "No properties found",
                  style: TextStyle(color: Colors.white54),
                ),
              );
            }

            final Map<String, int> categoryCounts = {};

            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;

              final category = data['category']?.toString() ?? 'General';

              categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
            }

            return _buildPieChart(
              data: categoryCounts,
              total: docs.length,
              unit: "Properties",
            );
          },
        );

      // ==========================================================
      // INCOME
      // ==========================================================

      case 'income':
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('payments')
              .where('ownerId', isEqualTo: ownerId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    "Error: ${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  "No payment records found",
                  style: TextStyle(color: Colors.white54),
                ),
              );
            }

            double paidIncome = 0.0;
            double pendingIncome = 0.0;

            int paidCount = 0;
            int pendingCount = 0;

            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;

              final status =
                  data['status']?.toString().trim().toLowerCase() ?? '';

              // IMPORTANT:
              // Use bookingAmount, not paidAmount/amount.
              final bookingAmount =
                  (data['bookingAmount'] as num?)?.toDouble() ?? 0.0;

              if (bookingAmount <= 0) {
                continue;
              }

              if (status == 'paid') {
                paidIncome += bookingAmount;
                paidCount++;
              } else if (status == 'pending') {
                pendingIncome += bookingAmount;
                pendingCount++;
              }
            }

            final Map<String, double> incomeData = {};

            if (paidIncome > 0) {
              incomeData['Paid'] = paidIncome;
            }

            if (pendingIncome > 0) {
              incomeData['Pending'] = pendingIncome;
            }

            if (incomeData.isEmpty) {
              return const Center(
                child: Text(
                  "No paid or pending income yet",
                  style: TextStyle(color: Colors.white54),
                ),
              );
            }

            return _buildIncomePieChart(
              data: incomeData,
              paidCount: paidCount,
              pendingCount: pendingCount,
            );
          },
        );

      // ==========================================================
      // USER
      // ==========================================================

      case 'user':
      default:
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('ownerId', isEqualTo: ownerId)
              .snapshots(),
          builder: (context, bookingSnapshot) {
            if (bookingSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (bookingSnapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Error: '
                    '${bookingSnapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              );
            }

            final bookingDocs = bookingSnapshot.data?.docs ?? [];

            if (bookingDocs.isEmpty) {
              return const Center(
                child: Text(
                  'No user activity found',
                  style: TextStyle(color: Colors.white54),
                ),
              );
            }

            // ----------------------------------------------------
            // COUNT BOOKINGS BY RENTER
            // ----------------------------------------------------

            final Map<String, int> renterBookingCounts = {};

            final Map<String, String> bookingRenterNames = {};

            for (final doc in bookingDocs) {
              final data = doc.data() as Map<String, dynamic>;

              final renterId = data['renterId']?.toString().trim() ?? '';

              if (renterId.isEmpty) {
                continue;
              }

              renterBookingCounts[renterId] =
                  (renterBookingCounts[renterId] ?? 0) + 1;

              final renterName = data['renterName']?.toString().trim() ?? '';

              if (renterName.isNotEmpty) {
                bookingRenterNames[renterId] = renterName;
              }
            }

            if (renterBookingCounts.isEmpty) {
              return const Center(
                child: Text(
                  'No renter data found',
                  style: TextStyle(color: Colors.white54),
                ),
              );
            }

            // ----------------------------------------------------
            // LOAD USERS
            // ----------------------------------------------------

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (userSnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Error loading users: '
                        '${userSnapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  );
                }

                final userDocs = userSnapshot.data?.docs ?? [];

                // ------------------------------------------------
                // RENTER ID → REAL NAME
                // ------------------------------------------------

                final Map<String, String> renterNames = {};

                for (final userDoc in userDocs) {
                  final userData = userDoc.data() as Map<String, dynamic>;

                  final documentId = userDoc.id.trim();

                  final uid = userData['uid']?.toString().trim() ?? '';

                  final fullName =
                      userData['fullName']?.toString().trim() ?? '';

                  if (fullName.isEmpty) {
                    continue;
                  }

                  if (documentId.isNotEmpty) {
                    renterNames[documentId] = fullName;
                  }

                  if (uid.isNotEmpty) {
                    renterNames[uid] = fullName;
                  }
                }

                // ------------------------------------------------
                // BUILD RENTER LIST
                // ------------------------------------------------

                final List<Map<String, dynamic>> renters = [];

                for (final entry in renterBookingCounts.entries) {
                  final renterId = entry.key;

                  final bookingCount = entry.value;

                  final renterName =
                      renterNames[renterId] ??
                      bookingRenterNames[renterId] ??
                      'Unknown Renter';

                  renters.add({
                    'id': renterId,
                    'name': renterName,
                    'count': bookingCount,
                  });
                }

                renters.sort((a, b) {
                  final countA = a['count'] as int;

                  final countB = b['count'] as int;

                  return countB.compareTo(countA);
                });

                final Map<String, int> chartData = {};

                for (final renter in renters) {
                  final name = renter['name'] as String;

                  final count = renter['count'] as int;

                  chartData[name] = (chartData[name] ?? 0) + count;
                }

                return SafeArea(
                  top: false,
                  bottom: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: _buildPieChart(
                          data: chartData,
                          total: bookingDocs.length,
                          unit: 'Bookings',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            );
          },
        );
    }
  }

  // ============================================================
  // PIE CHART
  // ============================================================

  Widget _buildPieChart({
    required Map<String, int> data,
    required int total,
    required String unit,
  }) {
    if (data.isEmpty || total == 0) {
      return const Center(
        child: Text(
          "No data available",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final entries = data.entries.toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: List.generate(entries.length, (index) {
                  final entry = entries[index];

                  final value = entry.value.toDouble();

                  final percentage = (value / total) * 100;

                  final color = _chartPalette[index % _chartPalette.length];

                  return PieChartSectionData(
                    color: color,
                    value: value,
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 45,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(entries.length, (index) {
              final entry = entries[index];

              final color = _chartPalette[index % _chartPalette.length];

              final percentage = (entry.value / total) * 100;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${entry.value} $unit",
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "(${percentage.toStringAsFixed(1)}%)",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INCOME PIE CHART
  // ============================================================

  Widget _buildIncomePieChart({
    required Map<String, double> data,
    required int paidCount,
    required int pendingCount,
  }) {
    final totalIncome = data.values.fold<double>(
      0.0,
      (sum, item) => sum + item,
    );

    if (data.isEmpty || totalIncome <= 0) {
      return const Center(
        child: Text(
          "No income records found",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final entries = data.entries.toList();

    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'paid':
          return Colors.greenAccent;

        case 'pending':
          return Colors.orangeAccent;

        default:
          return Colors.blueAccent;
      }
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 40,
              sections: List.generate(entries.length, (index) {
                final entry = entries[index];

                final percentage = (entry.value / totalIncome) * 100;

                final color = getStatusColor(entry.key);

                return PieChartSectionData(
                  color: color,
                  value: entry.value,
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: 45,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: _buildIncomeSummaryCard(
                  title: 'Paid',
                  amount: data['Paid'] ?? 0.0,
                  count: paidCount,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildIncomeSummaryCard(
                  title: 'Pending',
                  amount: data['Pending'] ?? 0.0,
                  count: pendingCount,
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];

              final color = getStatusColor(entry.key);

              final percentage = (entry.value / totalIncome) * 100;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      "\$${entry.value.toStringAsFixed(2)} "
                      "(${percentage.toStringAsFixed(2)}%)",
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
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

  // ============================================================
  // INCOME SUMMARY CARD
  // ============================================================

  Widget _buildIncomeSummaryCard({
    required String title,
    required double amount,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$count payment'
            '${count == 1 ? '' : 's'}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    String getGreeting() {
      final hour = DateTime.now().hour;

      if (hour >= 5 && hour < 12) {
        return 'Good Morning';
      } else if (hour >= 12 && hour < 17) {
        return 'Good Afternoon';
      } else if (hour >= 17 && hour < 21) {
        return 'Good Evening';
      } else {
        return 'Good Night';
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          // ======================================================
          // BACKGROUND
          // ======================================================
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A1035),
                    Color(0xFF2D1B69),
                    Color(0xFF4C1D95),
                    Color(0xFF6B46C1),
                  ],
                ),
              ),
              child: _backgroundImageUrl != null
                  ? Image.network(
                      _backgroundImageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox();
                      },
                    )
                  : null,
            ),
          ),

          // ======================================================
          // BACKGROUND DARK OVERLAY
          // ======================================================
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(
                      _backgroundImageUrl != null ? 0.48 : 0.05,
                    ),
                    const Color(
                      0xFF1A1035,
                    ).withOpacity(_backgroundImageUrl != null ? 0.65 : 0.10),
                    const Color(
                      0xFF4C1D95,
                    ).withOpacity(_backgroundImageUrl != null ? 0.78 : 0.15),
                  ],
                ),
              ),
            ),
          ),

          // ======================================================
          // MAIN CONTENT
          // ======================================================
          SafeArea(
            child: Column(
              children: [
                // ==================================================
                // TOP BAR
                // ==================================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      // --------------------------------------------
                      // OWNER AVATAR
                      // --------------------------------------------
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showProfileImage = !_showProfileImage;
                          });
                        },
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white.withOpacity(0.15),
                          backgroundImage:
                              _showProfileImage &&
                                  user?.profileImage != null &&
                                  user!.profileImage!.isNotEmpty
                              ? NetworkImage(user!.profileImage!)
                              : null,
                          child:
                              !_showProfileImage ||
                                  user?.profileImage == null ||
                                  user!.profileImage!.isEmpty
                              ? const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 26,
                                )
                              : null,
                        ),
                      ),

                      const SizedBox(width: 10),

                      // --------------------------------------------
                      // NAME
                      // --------------------------------------------
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getGreeting(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              user?.fullName ?? 'Owner',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // --------------------------------------------
                      // BACKGROUND BUTTON
                      // --------------------------------------------
                      GestureDetector(
                        onTap: _showBackgroundOptions,
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.10),
                            ),
                          ),
                          child: _isUploadingBackground
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  _backgroundImageUrl != null
                                      ? Icons.wallpaper_rounded
                                      : Icons.add_photo_alternate_outlined,
                                  color: Colors.white,
                                  size: 22,
                                ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // --------------------------------------------
                      // NOTIFICATION
                      // --------------------------------------------
                      StreamBuilder<int>(
                        stream: OwnerNotificationService().unreadCount(
                          FirebaseAuth.instance.currentUser!.uid,
                        ),
                        builder: (context, snapshot) {
                          final unreadCount = snapshot.data ?? 0;

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _topIcon(
                                Icons.notifications_outlined,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const OwnerNotificationsScreen(),
                                    ),
                                  );
                                },
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: -3,
                                  top: -5,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFF0C2C55),
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      unreadCount > 99
                                          ? '99+'
                                          : unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
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

                const Spacer(),

                // ==================================================
                // STATISTICS
                // ==================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      // --------------------------------------------
                      // ROW 1
                      // --------------------------------------------
                      Row(
                        children: [
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('bookings')
                                  .where('ownerId', isEqualTo: currentUid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                final count = snapshot.hasData
                                    ? snapshot.data!.docs.length
                                    : 0;

                                return _statCard(
                                  icon: Icons.home_work_rounded,
                                  value: count.toString(),
                                  label: "Booking",
                                  iconColor: const Color(0xFF818CF8),
                                  onTap: () {
                                    _showAnalyticsBottomSheet(
                                      context: context,
                                      title: "Booking Analytics",
                                      type: "booking",
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('properties')
                                  .where('ownerId', isEqualTo: currentUid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                final count = snapshot.hasData
                                    ? snapshot.data!.docs.length
                                    : 0;

                                return _statCard(
                                  icon: Icons.meeting_room_rounded,
                                  value: count.toString(),
                                  label: "Rooms",
                                  iconColor: const Color(0xFF38BDF8),
                                  onTap: () {
                                    _showAnalyticsBottomSheet(
                                      context: context,
                                      title: "Room Categories",
                                      type: "room",
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // --------------------------------------------
                      // ROW 2
                      // --------------------------------------------
                      Row(
                        children: [
                          // USERS
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('bookings')
                                  .where('ownerId', isEqualTo: currentUid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                final uniqueRenters = <String>{};

                                if (snapshot.hasData) {
                                  for (final doc in snapshot.data!.docs) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;

                                    final renterId = data['renterId'];

                                    if (renterId != null &&
                                        renterId.toString().isNotEmpty) {
                                      uniqueRenters.add(renterId.toString());
                                    }
                                  }
                                }

                                return _statCard(
                                  icon: Icons.people_alt_rounded,
                                  value: uniqueRenters.length.toString(),
                                  label: "Users",
                                  iconColor: const Color(0xFFA78BFA),
                                  onTap: () {
                                    _showAnalyticsBottomSheet(
                                      context: context,
                                      title: "User Engagement",
                                      type: "user",
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                          const SizedBox(width: 12),

                          // INCOME
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('payments')
                                  .where('ownerId', isEqualTo: currentUid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                double totalIncome = 0;

                                if (snapshot.hasData) {
                                  for (final doc in snapshot.data!.docs) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;

                                    final status = data['status']
                                        ?.toString()
                                        .trim()
                                        .toLowerCase();

                                    // IMPORTANT:
                                    // Income uses bookingAmount.
                                    // Only Paid counts as real income.
                                    if (status == 'paid') {
                                      final amount =
                                          (data['bookingAmount'] as num?)
                                              ?.toDouble() ??
                                          0.0;

                                      if (amount > 0) {
                                        totalIncome += amount;
                                      }
                                    }
                                  }
                                }

                                return _statCard(
                                  icon: Icons.payments_rounded,
                                  value: "\$${totalIncome.toStringAsFixed(2)}",
                                  label: "Income",
                                  iconColor: const Color(0xFF34D399),
                                  onTap: () {
                                    _showAnalyticsBottomSheet(
                                      context: context,
                                      title: "Income Breakdown",
                                      type: "income",
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                const SizedBox(height: 80),

                // ==================================================
                // ORBIT
                // ==================================================
                Transform.translate(
                  offset: const Offset(0, -70),
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        orbitAngle += details.delta.dy * 0.01;
                      });
                    },
                    child: SizedBox(
                      width: 350,
                      height: 340,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // ------------------------------------------
                          // CENTER PROFILE
                          // ------------------------------------------
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(.5),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFA78BFA,
                                      ).withOpacity(.8),
                                      blurRadius: 45,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 45,
                                  backgroundImage:
                                      user?.profileImage != null &&
                                          user!.profileImage!.isNotEmpty
                                      ? NetworkImage(user!.profileImage!)
                                      : null,
                                  child:
                                      user?.profileImage == null ||
                                          user!.profileImage!.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 45,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                user?.fullName ?? "Owner",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          // ------------------------------------------
                          // ROTATING MENU
                          // ------------------------------------------
                          Transform.rotate(
                            angle: orbitAngle,
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 0,
                                  left: 130,
                                  child: _rotateBack(
                                    child: _actionButton(
                                      icon: Icons.apartment_rounded,
                                      label: "Houses",
                                      onTap: () {},
                                    ),
                                  ),
                                ),

                                Positioned(
                                  left: 10,
                                  top: 70,
                                  child: _rotateBack(
                                    child: _actionButton(
                                      icon: Icons.person,
                                      label: "Profile",
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const OwnerProfileScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                Positioned(
                                  right: 10,
                                  top: 70,
                                  child: _rotateBack(
                                    child: _actionButton(
                                      icon: Icons.house,
                                      label: "Room",
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ManageHousesScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                Positioned(
                                  left: 20,
                                  bottom: 60,
                                  child: _rotateBack(
                                    child: _buildChatButton(
                                      FirebaseAuth.instance.currentUser!.uid,
                                    ),
                                  ),
                                ),

                                Positioned(
                                  bottom: 0,
                                  left: 130,
                                  child: _rotateBack(
                                    child: _buildBookingButton(
                                      FirebaseAuth.instance.currentUser!.uid,
                                    ),
                                  ),
                                ),


                                Positioned(
                                  right: 20,
                                  bottom: 60,
                                  child: _rotateBack(
                                    child: _actionButton(
                                      icon: Icons.swap_horiz_rounded,
                                      label: "Transfers",
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const EarningsScreen(),
                                          ),
                                        );
                                      },
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
                ),
              ],
            ),
          ),

          // ======================================================
          // UPLOADING OVERLAY
          // ======================================================
          if (_isUploadingBackground)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.35),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 22,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 14),
                            Text(
                              'Updating background...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // ROTATE ACTION BACK
  // ============================================================

  Widget _rotateBack({required Widget child}) {
    return Transform.rotate(angle: -orbitAngle, child: child);
  }

  // ============================================================
  // TOP ICON
  // ============================================================

  Widget _topIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.22),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: iconColor.withOpacity(0.22)),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.75),
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
  // REORDERABLE ANALYTICS
  // ============================================================

  Widget _buildReorderableAnalyticsView() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _chartOrder.length,
      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }

          final String item = _chartOrder.removeAt(oldIndex);

          _chartOrder.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final type = _chartOrder[index];

        final title = _chartTitles[type] ?? 'Analytics';

        return Card(
          key: ValueKey(type),
          margin: const EdgeInsets.only(bottom: 16),
          color: const Color(0xFF1E143B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(
                        Icons.drag_handle_rounded,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(height: 280, child: _buildChartContent(type)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ACTION BUTTON
  // ============================================================

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.14),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(.25)),
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
