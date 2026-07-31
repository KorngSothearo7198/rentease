// // bottom_nav_bar.dart
// import 'package:flutter/material.dart';
// import 'dart:math' as math;
//
// class CapsuleBottomNav extends StatefulWidget {
//   final int currentIndex;
//   final Function(int) onTap;
//
//   const CapsuleBottomNav({
//     super.key,
//     required this.currentIndex,
//     required this.onTap,
//   });
//
//   @override
//   State<CapsuleBottomNav> createState() => _CapsuleBottomNavState();
// }
//
// class _CapsuleBottomNavState extends State<CapsuleBottomNav>
//     with SingleTickerProviderStateMixin {
//   bool _isOpen = false;
//   late AnimationController _controller;
//   late Animation<double> _expandAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//     _expandAnimation = CurvedAnimation(
//       parent: _controller,
//       curve: Curves.easeOutBack,
//       reverseCurve: Curves.easeIn,
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   void _toggleMenu() {
//     setState(() {
//       _isOpen = !_isOpen;
//       if (_isOpen) {
//         _controller.forward();
//       } else {
//         _controller.reverse();
//       }
//     });
//   }
//
//   void _onItemTap(int index) {
//     _toggleMenu();
//     widget.onTap(index);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 160,
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           // ===== Radial Items (Right + Top) =====
//           ..._buildRadialItems(),
//
//           // ===== Menu Button (Left) =====
//           Positioned(
//             left: 24,
//             bottom: 28,
//             child: _buildMenuButton(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ---------- Menu Button ----------
//   Widget _buildMenuButton() {
//     return GestureDetector(
//       onTap: _toggleMenu,
//       child: AnimatedBuilder(
//         animation: _expandAnimation,
//         builder: (context, child) {
//           return Transform.rotate(
//             angle: _expandAnimation.value * (math.pi / 4),
//             child: Container(
//               width: 56,
//               height: 56,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 gradient: const LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     Color(0xFFFBBF24),
//                     Color(0xFFF59E0B),
//                   ],
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: const Color(0xFFFBBF24).withOpacity(0.45),
//                     blurRadius: 16,
//                     offset: const Offset(0, 6),
//                   ),
//                 ],
//               ),
//               child: Icon(
//                 _isOpen ? Icons.close_rounded : Icons.menu_rounded,
//                 color: const Color(0xFF1A1035),
//                 size: 28,
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   // ---------- Radial Items → Right + Top ----------
//   List<Widget> _buildRadialItems() {
//     final items = [
//       _RadialItemData(Icons.home_rounded, 'Home', 0),
//       _RadialItemData(Icons.search_rounded, 'Search', 1),
//       _RadialItemData(Icons.favorite_rounded, 'Favorites', 2),
//       _RadialItemData(Icons.person_rounded, 'Profile', 3),
//     ];
//
//     // Angles focused on RIGHT + TOP side
//     final angles = [
//       -math.pi * 0.15, // almost right
//       -math.pi * 0.35, // upper right
//       -math.pi * 0.55, // more top-right
//       -math.pi * 0.75, // top
//     ];
//
//     const double radius = 100.0;
//
//     return List.generate(items.length, (i) {
//       final item = items[i];
//       final angle = angles[i];
//
//       return AnimatedBuilder(
//         animation: _expandAnimation,
//         builder: (context, child) {
//           final progress = _expandAnimation.value;
//
//           final dx = math.cos(angle) * radius * progress;
//           final dy = math.sin(angle) * radius * progress;
//
//           return Positioned(
//             left: 24 + 28 + dx - 28, // from center of menu button
//             bottom: 28 + 28 + dy - 28,
//             child: Opacity(
//               opacity: progress.clamp(0.0, 1.0),
//               child: Transform.scale(
//                 scale: 0.5 + (0.5 * progress),
//                 child: _buildRadialButton(item),
//               ),
//             ),
//           );
//         },
//       );
//     });
//   }
//
//   Widget _buildRadialButton(_RadialItemData item) {
//     final isSelected = widget.currentIndex == item.index;
//
//     return GestureDetector(
//       onTap: () => _onItemTap(item.index),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 54,
//             height: 54,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: isSelected
//                   ? const Color(0xFFFBBF24)
//                   : Colors.white.withOpacity(0.18),
//               border: Border.all(
//                 color: isSelected
//                     ? const Color(0xFFFBBF24)
//                     : Colors.white.withOpacity(0.3),
//                 width: 1.5,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.25),
//                   blurRadius: 12,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Icon(
//               item.icon,
//               color: isSelected ? const Color(0xFF1A1035) : Colors.white,
//               size: 24,
//             ),
//           ),
//           const SizedBox(height: 5),
//           Text(
//             item.label,
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.95),
//               fontSize: 11,
//               fontWeight: FontWeight.w600,
//               shadows: [
//                 Shadow(
//                   color: Colors.black.withOpacity(0.5),
//                   blurRadius: 4,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _RadialItemData {
//   final IconData icon;
//   final String label;
//   final int index;
//
//   _RadialItemData(this.icon, this.label, this.index);
// }


// bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class CapsuleBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CapsuleBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CapsuleBottomNav> createState() => _CapsuleBottomNavState();
}

class _CapsuleBottomNavState extends State<CapsuleBottomNav>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  final List<_NavItem> _items = [
    _NavItem(Icons.home_rounded, 'Home', 0),
    _NavItem(Icons.search_rounded, 'Search', 1),
    _NavItem(Icons.favorite_rounded, 'Favorites', 2),
    _NavItem(Icons.person_rounded, 'Profile', 3),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _select(int index) {
    if (_isOpen) _toggle();
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _isOpen ? 150 : 90,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Arc items
          ..._buildArcItems(),

          // Main button
          Positioned(
            left: 22,
            bottom: 20,
            child: _buildMainButton(),
          ),
        ],
      ),
    );
  }
  // @override
  // Widget build(BuildContext context) {
  //   return SizedBox(
  //     height: 150, // only reserve bottom button space
  //     width: double.infinity,
  //     child: AnimatedBuilder(
  //       animation: _expandAnimation,
  //       builder: (context, child) {
  //         return Stack(
  //           clipBehavior: Clip.none,
  //           children: [
  //             ..._buildArcItems(),
  //
  //             Positioned(
  //               left: 22,
  //               bottom: 20,
  //               child: _buildMainButton(),
  //             ),
  //           ],
  //         );
  //       },
  //     ),
  //   );
  // }

  // ---------- Main Button ----------
  Widget _buildMainButton() {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFBBF24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFBBF24).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _isOpen ? Icons.close_rounded : Icons.menu_rounded,
            key: ValueKey(_isOpen),
            color: const Color(0xFF1A1035),
            size: 28,
          ),
        ),
      ),
    );
  }

  // ---------- Arc Items (clear + higher) ----------
  List<Widget> _buildArcItems() {
    // Clean upward-right arc with good spacing
    final angles = [
      -0.45, // lower
      -0.95, // mid-low
      -1.45, // mid-high
      -1.95, // highest
    ];

    const double radius = 120.0;

    return List.generate(_items.length, (i) {
      final item = _items[i];
      final angle = angles[i];

      return AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          final progress = _expandAnimation.value;

          // Small stagger
          final delay = i * 0.05;
          final t = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);

          // const radiusX = 150.0;
          // const radiusY = -90.0;

          const double radiusX = 110.0;
          const double radiusY = -55.0;

          final dx = math.cos(angle) * radiusX * t;
          final dy = math.sin(angle) * radiusY * t;

          const double buttonLeft = 20;
          const double buttonBottom = 20;
          const double buttonSize = 58;

          final originX = buttonLeft + buttonSize - 6;
          final originY = buttonBottom + buttonSize / 2;

          return Positioned(
              left: originX + dx - 26,
              bottom: originY + dy - 26,
              child: Transform.scale(
                scale: 0.5 + (0.5 * t),
                child: _buildItemButton(item),
              ),
          );
        },
      );
    });
  }

  Widget _buildItemButton(_NavItem item) {
    final isSelected = widget.currentIndex == item.index;

    return GestureDetector(
      onTap: () => _select(item.index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? const Color(0xFFFBBF24)
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              item.icon,
              color: isSelected
                  ? const Color(0xFF1A1035)
                  : const Color(0xFF4C1D95),
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? const Color(0xFFFBBF24)
                  : Colors.white.withOpacity(0.95),
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;

  _NavItem(this.icon, this.label, this.index);
}