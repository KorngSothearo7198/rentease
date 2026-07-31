import 'dart:ui';
import 'package:flutter/material.dart';

import 'manage_home_screen.dart';
import 'owner_booking_request_screen.dart';
import '../../chat/screens/owner_chat_list.dart';
import 'owner_profile_screen.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  double orbitAngle = 0;

  @override
  Widget build(BuildContext context) {
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Good Morning",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            "Sarah Jenkins",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _topIcon(Icons.notifications_outlined),
                    const SizedBox(width: 10),
                    _topIcon(Icons.logout_rounded),
                  ],
                ),
              ),

              const Spacer(),

              // ================= TOP STATISTICS =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // ================= FIRST ROW =================
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            icon: Icons.home_work_rounded,
                            value: "128",
                            label: "Booking",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            icon: Icons.meeting_room,
                            value: "128",
                            label: "Rooms",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ================= SECOND ROW =================
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            icon: Icons.people_alt_rounded,
                            value: "350",
                            label: "Users",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            icon: Icons.payments_rounded,
                            value: "\$12.5K",
                            label: "Income",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ================= ORBIT AREA =================
              Transform.translate(
                // Move whole orbit area upward
                offset: const Offset(0, -70),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      // Drag vertically to rotate
                      orbitAngle += details.delta.dy * 0.01;
                    });
                  },
                  child: SizedBox(
                    width: 350,
                    height: 340,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // ================= CENTER PROFILE =================
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
                                  )
                                ],
                              ),
                              child: const CircleAvatar(
                                radius: 45,
                                backgroundImage: NetworkImage(
                                  "https://static.wikia.nocookie.net/oggyandthecockroaches/images/d/d9/OGGY_PERSO.png/revision/latest?cb=20181112161051",
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Sarah Jenkins",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        // ================= ROTATING MENU =================
                        Transform.rotate(
                          angle: orbitAngle,
                          child: Stack(
                            children: [
                              // TOP
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

                              // LEFT TOP
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
                                          builder: (_) => OwnerProfileScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              // RIGHT TOP
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
                                          builder: (_) => ManageHousesScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              // LEFT BOTTOM
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
                                          builder: (_) => OwnerChatList(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              // BOTTOM CENTER
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
                                          builder: (_) => BookingRequestsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              // RIGHT BOTTOM
                              Positioned(
                                right: 20,
                                bottom: 60,
                                child: _rotateBack(
                                  child: _actionButton(
                                    icon: Icons.swap_horiz_rounded,
                                    label: "Transfers",
                                    onTap: () {},
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

  // Keep button text normal when rotating
  Widget _rotateBack({required Widget child}) {
    return Transform.rotate(
      angle: -orbitAngle,
      child: child,
    );
  }

  Widget _topIcon(IconData icon) {
    return Container(
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
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: const Color(0xFFFBBF24),
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
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
              filter: ImageFilter.blur(
                sigmaX: 12,
                sigmaY: 12,
              ),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.14),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withOpacity(.25),
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 30,
                ),
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

  Widget _navIcon(IconData icon, bool active) {
    return Icon(
      icon,
      size: 26,
      color: active ? Colors.white : Colors.white54,
    );
  }
}















//
// import 'package:flutter/material.dart';
// import 'dart:ui';
//
// class OwnerHomeScreen extends StatefulWidget {
//   const OwnerHomeScreen({super.key});
//
//   @override
//   State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
// }
//
// class _OwnerHomeScreenState extends State<OwnerHomeScreen>
//     with SingleTickerProviderStateMixin {
//
//   late AnimationController controller;
//
//   @override
//   void initState() {
//     super.initState();
//
//     controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 8),
//     )..repeat();
//   }
//
//   @override
//   void dispose() {
//     controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFF1A1035),
//               Color(0xFF2D1B69),
//               Color(0xFF4C1D95),
//               Color(0xFF6B46C1),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // ========== TOP BAR ==========
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.home_work_rounded,
//                         color: Color(0xFFFBBF24), size: 28),
//                     const SizedBox(width: 10),
//                     const Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             "Good Morning",
//                             style: TextStyle(
//                               color: Colors.white70,
//                               fontSize: 13,
//                             ),
//                           ),
//                           Text(
//                             "Sarah Jenkins",
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     _topIcon(Icons.notifications_outlined),
//                     SizedBox(width: 10),
//                     _topIcon(Icons.logout_rounded),
//                   ],
//                 ),
//               ),
//
//               /// Push everything to center
//               const Spacer(),
//
//               const SizedBox(height: 40),
//
//               // ========== ACTION ICONS ==========
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     // LEFT
//                     Expanded(
//                       child: Column(
//                         children: [
//                           _actionButton(
//                             icon: Icons.apartment_rounded,
//                             label: "Houses",
//                             onTap: () {},
//                           ),
//                           const SizedBox(height: 36),
//                           _actionButton(
//                             icon: Icons.qr_code_scanner_rounded,
//                             label: "Scan QR",
//                             onTap: () {},
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(width: 16),
//
//                     // CENTER PROFILE
//                     Column(
//                       children: [
//                         SizedBox(
//                           width: 170,
//                           height: 170,
//                           child: AnimatedBuilder(
//                             animation: controller,
//                             builder: (_, child) {
//                               return Transform.rotate(
//                                 angle: controller.value * 2 * pi,
//                                 child: child,
//                               );
//                             },
//                             child: Stack(
//                               alignment: Alignment.center,
//                               children: [
//                                 Container(
//                                   width: 160,
//                                   height: 160,
//                                   decoration: BoxDecoration(
//                                     shape: BoxShape.circle,
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: Colors.deepPurpleAccent.withOpacity(.45),
//                                         blurRadius: 40,
//                                         spreadRadius: 10,
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//
//                                 Container(
//                                   width: 160,
//                                   height: 160,
//                                   decoration: BoxDecoration(
//                                     shape: BoxShape.circle,
//                                     border: Border.all(
//                                       color: Colors.white24,
//                                       width: 2,
//                                     ),
//                                   ),
//                                 ),
//
//                                 Align(
//                                   alignment: Alignment.topCenter,
//                                   child: Container(
//                                     width: 16,
//                                     height: 16,
//                                     decoration: const BoxDecoration(
//                                       color: Colors.amber,
//                                       shape: BoxShape.circle,
//                                     ),
//                                   ),
//                                 ),
//
//                                 Align(
//                                   alignment: Alignment.bottomCenter,
//                                   child: Container(
//                                     width: 12,
//                                     height: 12,
//                                     decoration: const BoxDecoration(
//                                       color: Colors.cyanAccent,
//                                       shape: BoxShape.circle,
//                                     ),
//                                   ),
//                                 ),
//
//                                 Transform.rotate(
//                                   angle: -(controller.value * 2 * pi),
//                                   child: Container(
//                                     width: 120,
//                                     height: 120,
//                                     decoration: BoxDecoration(
//                                       shape: BoxShape.circle,
//                                       border: Border.all(
//                                         color: Colors.white,
//                                         width: 3,
//                                       ),
//                                     ),
//                                     child: const CircleAvatar(
//                                       backgroundImage: NetworkImage(
//                                         "https://static.wikia.nocookie.net/oggyandthecockroaches/images/d/d9/OGGY_PERSO.png/revision/latest?cb=20181112161051",
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         const Text(
//                           "Sarah Jenkins",
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 20,
//                           ),
//                         ),
//                         Text(
//                           "Property Owner",
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(.7),
//                           ),
//                         ),
//                       ],
//                     ),
//
//                     const SizedBox(width: 16),
//
//                     // RIGHT
//                     Expanded(
//                       child: Column(
//                         children: [
//                           _actionButton(
//                             icon: Icons.receipt_long_rounded,
//                             label: "Payments",
//                             onTap: () {},
//                           ),
//                           const SizedBox(height: 36),
//                           _actionButton(
//                             icon: Icons.swap_horiz_rounded,
//                             label: "Transfers",
//                             onTap: () {},
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               const SizedBox(height: 28),
//
//               /// Push Bottom Navigation down
//               const Spacer(),
//
//               // ========== BOTTOM NAV ==========
//               Container(
//                 margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(.12),
//                   borderRadius: BorderRadius.circular(28),
//                   border: Border.all(
//                     color: Colors.white.withOpacity(.18),
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     _navIcon(Icons.home_rounded, true),
//                     _navIcon(Icons.chat_bubble_outline_rounded, false),
//                     _navIcon(Icons.calendar_month_rounded, false),
//                     _navIcon(Icons.person_outline_rounded, false),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Top right icons
//   Widget _topIcon(IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(9),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.12),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Icon(icon, color: Colors.white, size: 22),
//     );
//   }
//
//   // Main action buttons
//   Widget _actionButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(22),
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//               child: Container(
//                 width: 72,
//                 height: 72,
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.14),
//                   borderRadius: BorderRadius.circular(22),
//                   border: Border.all(color: Colors.white.withOpacity(0.22)),
//                 ),
//                 child: Icon(icon, color: Colors.white, size: 30),
//               ),
//             ),
//           ),
//           const SizedBox(height: 10),
//           Text(
//             label,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Stats boxes
//   Widget _statBox(String value, String label) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(16),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 14),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.12),
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: Colors.white.withOpacity(0.18)),
//           ),
//           child: Column(
//             children: [
//               Text(
//                 value,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 label,
//                 style: TextStyle(
//                   color: Colors.white.withOpacity(0.7),
//                   fontSize: 12,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Bottom nav icons
//   Widget _navIcon(IconData icon, bool isActive) {
//     return Icon(
//       icon,
//       color: isActive ? Colors.white : Colors.white54,
//       size: 26,
//     );
//   }
// }