import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/session_service.dart';
import '../../auth/renter/loginScreen.dart';
import 'help_support_screen.dart';
import 'owner_booking_request_screen.dart';
import 'owner_earnings_screen.dart';
import 'owner_edit_profile_screen.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final AuthService authService = AuthService();
  final ScrollController _scrollController = ScrollController();

  UserModel? user;
  bool isLoading = true;
  double _scrollOffset = 0.0;

  final int propertyCount = 8;
  final double rating = 4.9;

  static const double _expandedHeight = 280.0;

  static const Color _primary = Color(0xFF4F46E5);
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _card = Colors.white;
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double get _collapseProgress {
    final range = _expandedHeight - kToolbarHeight;
    return (_scrollOffset / range).clamp(0.0, 1.0);
  }

  Future<void> _loadUserData() async {
    try {
      final localUser = await SessionService.getUser();
      if (localUser != null && mounted) {
        setState(() => user = UserModel.fromJson(localUser));
      }

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final firebaseData = await authService.getUserData(firebaseUser.uid);
        if (firebaseData != null && mounted) {
          setState(() => user = firebaseData);
          await SessionService.saveUser(firebaseData.toJson());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load profile: $e"),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _onEditProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Navigate to Edit Profile Screen'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Navigate to Settings Screen'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _onLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 30,
                    color: Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Log out?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "You’ll need to sign in again to manage your properties and bookings.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _textPrimary,
                            side: const BorderSide(color: _border, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Log out",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm == true) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) =>
              const Center(child: CircularProgressIndicator(color: _primary)),
        );

        await authService.logout();
        await SessionService.clear();

        if (!mounted) return;
        Navigator.pop(context); // close loading

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: _bg,
        body: const Center(child: Text("Profile not found")),
      );
    }

    final progress = _collapseProgress;
    final avatarSize = 100.0 - (progress * 52); // 100 → 48
    final headerOpacity = (1.0 - progress * 1.35).clamp(0.0, 1.0);
    final appBarTitleOpacity = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);

    final hasImage =
        user!.profileImage != null && user!.profileImage!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Collapsing profile header ──────────────────────────
          SliverAppBar(
            expandedHeight: _expandedHeight,
            pinned: true,
            stretch: true,
            backgroundColor: _bg,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: _textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Opacity(
              opacity: appBarTitleOpacity,
              child: Text(
                user!.fullName,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            centerTitle: true,
            actions: [
              Opacity(
                opacity: appBarTitleOpacity,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: _primary.withOpacity(0.1),
                    backgroundImage: hasImage
                        ? NetworkImage(user!.profileImage!)
                        : null,
                    child: hasImage
                        ? null
                        : const Icon(Icons.person, size: 18, color: _primary),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.fadeTitle,
              ],
              background: Container(
                color: _bg,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),

                      // Animated avatar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 40),
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withOpacity(
                                0.12 * (1 - progress),
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipOval(
                              child: hasImage
                                  ? Image.network(
                                      user!.profileImage!,
                                      width: avatarSize,
                                      height: avatarSize,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _defaultAvatar(avatarSize),
                                    )
                                  : _defaultAvatar(avatarSize),
                            ),
                            // Verified badge (fades with header)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Opacity(
                                opacity: headerOpacity,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified_rounded,
                                    color: _primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Name + contact (fade out on scroll)
                      Opacity(
                        opacity: headerOpacity,
                        child: Column(
                          children: [
                            Text(
                              user!.fullName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (user!.email.trim().isNotEmpty)
                              Text(
                                user!.email,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (user!.phone.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                user!.phone,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            // Stats chips
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _statChip(
                                  Icons.home_outlined,
                                  "$propertyCount Properties",
                                  const Color(0xFF059669),
                                  const Color(0xFFD1FAE5),
                                ),
                                const SizedBox(width: 10),
                                _statChip(
                                  Icons.star_rounded,
                                  "$rating Rating",
                                  const Color(0xFFD97706),
                                  const Color(0xFFFEF3C7),
                                ),
                              ],
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

          // ── Content ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                children: [
                  // Menu card
                  Container(
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // ============================================================
                        // ACCOUNT
                        // ============================================================
                        _buildSectionTitle('ACCOUNT'),

                        _buildMenuItem(
                          icon: Icons.edit_outlined,
                          title: 'Edit Profile',
                          subtitle: 'Update your personal details',
                          iconBgColor: _primary.withOpacity(0.1),
                          iconColor: _primary,
                          onTap: () async {
                            if (user == null) return;

                            final updatedUser = await Navigator.push<UserModel>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProfileScreen(user: user!),
                              ),
                            );

                            if (updatedUser != null && mounted) {
                              setState(() {
                                user = updatedUser;
                              });

                              await SessionService.saveUser(
                                updatedUser.toJson(),
                              );
                            }
                          },
                        ),

                        const Divider(height: 1, indent: 70, color: _border),

                        _buildMenuItem(
                          icon: Icons.home_work_outlined,
                          title: 'My Properties',
                          subtitle: 'Manage your rental properties',
                          iconBgColor: const Color(0xFF7C3AED).withOpacity(0.1),
                          iconColor: const Color(0xFF7C3AED),
                          onTap: () {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (_) => const MyPropertiesScreen(),
                            //   ),
                            // );
                          },
                        ),

                        const Divider(height: 1, indent: 70, color: _border),

                        _buildMenuItem(
                          icon: Icons.calendar_month_outlined,
                          title: 'Booking Requests',
                          subtitle: 'View and manage renter requests',
                          iconBgColor: const Color(0xFF0891B2).withOpacity(0.1),
                          iconColor: const Color(0xFF0891B2),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BookingRequestsScreen(),
                              ),
                            );
                          },
                        ),

                        // ============================================================
                        // OWNER BUSINESS
                        // ============================================================
                        const SizedBox(height: 20),

                        _buildSectionTitle('OWNER BUSINESS'),

                        _buildMenuItem(
                          icon: Icons.payments_outlined,
                          title: 'Earnings & Payments',
                          subtitle: 'View your rental income',
                          iconBgColor: const Color(0xFF059669).withOpacity(0.1),
                          iconColor: const Color(0xFF059669),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EarningsScreen(),
                              ),
                            );
                          },
                        ),

                        const Divider(height: 1, indent: 70, color: _border),

                        _buildMenuItem(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          subtitle: 'Booking and account updates',
                          iconBgColor: const Color(0xFFD97706).withOpacity(0.1),
                          iconColor: const Color(0xFFD97706),
                          onTap: () {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (_) => const NotificationsScreen(),
                            //   ),
                            // );
                          },
                        ),

                        const SizedBox(height: 20),

                        _buildSectionTitle('APP'),

                        _buildMenuItem(
                          icon: Icons.settings_outlined,
                          title: 'Settings',
                          subtitle: 'App preferences & security',
                          iconBgColor: const Color(0xFF2563EB).withOpacity(0.1),
                          iconColor: const Color(0xFF2563EB),
                          onTap: () {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (_) => const SettingsScreen(),
                            //   ),
                            // );
                          },
                        ),

                        const Divider(height: 1, indent: 70, color: _border),

                        _buildMenuItem(
                          icon: Icons.help_outline_rounded,
                          title: 'Help & Support',
                          subtitle: 'Get help or report a problem',
                          iconBgColor: const Color(0xFF64748B).withOpacity(0.1),
                          iconColor: const Color(0xFF64748B),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HelpSupportScreen(),
                              ),
                            );
                          },
                        ),

                        const Divider(height: 1, indent: 70, color: _border),

                        _buildMenuItem(
                          icon: Icons.logout_rounded,
                          title: 'Logout',
                          subtitle: 'End your current session',
                          titleColor: const Color(0xFFDC2626),
                          iconBgColor: const Color(0xFFFEE2E2),
                          iconColor: const Color(0xFFDC2626),
                          onTap: _onLogout,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Help banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need Help?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Our support team is available 24/7 for owners.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.support_agent_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "RentEase  •  Owner",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _textSecondary,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar(double size) {
    return Container(
      width: size,
      height: size,
      color: _primary.withOpacity(0.08),
      child: Icon(Icons.person_rounded, size: size * 0.45, color: _primary),
    );
  }

  Widget _statChip(IconData icon, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
    Color titleColor = _textPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
