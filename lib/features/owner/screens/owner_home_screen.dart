import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
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

  List<String> _chartOrder = ['booking', 'room', 'income', 'user'];

  // Map to store clean display titles
  final Map<String, String> _chartTitles = {
    'booking': 'Booking Analytics',
    'room': 'Room Categories',
    'income': 'Income Breakdown',
    'user': 'User Engagement',
  };

  UserModel? user;
  bool isLoading = true;
  double orbitAngle = 0;

  // Chart Palette Colors
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
        setState(() {
          user = UserModel.fromJson(localUser);
        });
      }

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final data = await authService.getUserData(firebaseUser.uid);
        if (data != null) {
          setState(() {
            user = data;
          });
          await SessionService.saveUser(data.toJson());
        }
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
          height: MediaQuery.of(context).size.height * 0.55,
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
              Expanded(
                child: _buildChartContent(type),
              ),
            ],
          ),
        );
      },
    );
  }

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
                child: Text("No booking records found", style: TextStyle(color: Colors.white54)),
              );
            }

            Map<String, int> statusCounts = {};
            for (var doc in docs) {
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
                child: Text("No properties found", style: TextStyle(color: Colors.white54)),
              );
            }

            Map<String, int> categoryCounts = {};
            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final cat = data['category']?.toString() ?? 'General';
              categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
            }

            return _buildPieChart(
              data: categoryCounts,
              total: docs.length,
              unit: "Properties",
            );
          },
        );

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
                child: Text(
                  "Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(
                child: Text("No payment records found", style: TextStyle(color: Colors.white54)),
              );
            }

            Map<String, double> incomeByStatus = {};
            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status']?.toString() ?? 'Pending';
              final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;
              incomeByStatus[status] = (incomeByStatus[status] ?? 0) + amt;
            }

            return _buildIncomePieChart(data: incomeByStatus);
          },
        );

      case 'user':
      default:
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
                child: Text("No user activity found", style: TextStyle(color: Colors.white54)),
              );
            }

            Map<String, int> renterBookingCounts = {};
            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final rId = data['renterId']?.toString() ?? 'Anonymous';
              renterBookingCounts[rId] = (renterBookingCounts[rId] ?? 0) + 1;
            }

            Map<String, int> chartData = {};
            int index = 1;
            renterBookingCounts.forEach((renterId, count) {
              chartData['Renter $index'] = count;
              index++;
            });

            return _buildPieChart(
              data: chartData,
              total: docs.length,
              unit: "Bookings",
            );
          },
        );
    }
  }

// ================= PIE CHART FOR NUMERIC COUNTS =================
  Widget _buildPieChart({
    required Map<String, int> data,
    required int total,
    required String unit,
  }) {
    if (data.isEmpty || total == 0) {
      return const Center(
        child: Text("No data available", style: TextStyle(color: Colors.white54)),
      );
    }

    final entries = data.entries.toList();

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
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      "${entry.value} $unit (${percentage.toStringAsFixed(1)}%)",
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

// ================= PIE CHART FOR MONETARY INCOME =================
  Widget _buildIncomePieChart({
    required Map<String, double> data,
  }) {
    final totalIncome = data.values.fold(0.0, (sum, item) => sum + item);

    if (data.isEmpty || totalIncome == 0) {
      return const Center(
        child: Text("No income records found", style: TextStyle(color: Colors.white54)),
      );
    }

    final entries = data.entries.toList();

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
                final value = entry.value;
                final percentage = (value / totalIncome) * 100;
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
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final color = _chartPalette[index % _chartPalette.length];
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
                      "\$${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(2)}%)",
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: SafeArea(
          child: Column(
            children: [
              // ================= TOP BAR =================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.home_work_rounded,
                      color: Color(0xFFFBBF24),
                      size: 28,
                    ),
                    const SizedBox(width: 10),
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                                    builder: (_) => const OwnerNotificationsScreen(),
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
                    const SizedBox(width: 10),
                    _topIcon(
                      Icons.logout_rounded,
                      onTap: () {
                        // logout
                      },
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ================= TOP STATISTICS CARDS WITH STREAMS =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    // ROW 1: BOOKING & ROOMS
                    Row(
                      children: [
                        // BOOKINGS CARD
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('bookings')
                                .where('ownerId', isEqualTo: currentUid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
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

                        // ROOMS CARD
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('properties')
                                .where('ownerId', isEqualTo: currentUid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
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

                    // ROW 2: USERS & INCOME
                    Row(
                      children: [
                        // UNIQUE USERS CARD
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('bookings')
                                .where('ownerId', isEqualTo: currentUid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final uniqueRenters = <String>{};
                              if (snapshot.hasData) {
                                for (var doc in snapshot.data!.docs) {
                                  final rId = (doc.data() as Map<String, dynamic>)['renterId'];
                                  if (rId != null) uniqueRenters.add(rId);
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

                        // INCOME CARD
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('payments')
                                .where('ownerId', isEqualTo: currentUid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              double totalIncome = 0;
                              if (snapshot.hasData) {
                                for (var doc in snapshot.data!.docs) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;
                                  totalIncome += amt;
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

              // ================= ORBIT AREA =================
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
                        // CENTER PROFILE
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
                                    color: const Color(0xFFA78BFA).withOpacity(.8),
                                    blurRadius: 45,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundImage: user?.profileImage != null &&
                                    user!.profileImage!.isNotEmpty
                                    ? NetworkImage(user!.profileImage!)
                                    : null,
                                child: user?.profileImage == null ||
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

                        // ROTATING MENU
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
                                          builder: (_) => const OwnerProfileScreen(),
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
                                    label: "Manage",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const ManageHousesScreen(),
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
                                  child: _actionButton(
                                    icon: Icons.chat_bubble_rounded,
                                    label: "Chat",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const OwnerChatList(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 130,
                                child: _rotateBack(
                                  child: _actionButton(
                                    icon: Icons.calendar_month_rounded,
                                    label: "Booking",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const BookingRequestsScreen(),
                                        ),
                                      );
                                    },
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
                                          builder: (_) => const EarningsScreen(),
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
      ),
    );
  }

  Widget _rotateBack({required Widget child}) {
    return Transform.rotate(angle: -orbitAngle, child: child);
  }

  Widget _topIcon(
      IconData icon, {
        VoidCallback? onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

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
          key: ValueKey(type), // Required for drag-and-drop
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
                // Drag Handle & Card Header
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
                // Chart Content
                SizedBox(
                  height: 280, // Gives chart & legend explicit room
                  child: _buildChartContent(type),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
