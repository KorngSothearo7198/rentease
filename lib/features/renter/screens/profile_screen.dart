import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rentease/features/renter/screens/payment_history_screen.dart';
import '../../../color/theme/app_theme.dart';
import '../../../color/theme/theme_controller.dart';
import '../../../main.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/session_service.dart';
import '../../auth/renter/loginScreen.dart';
import 'PersonalInfoScreen.dart';
import 'booking_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
  final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  final AuthService authService = AuthService();
  final ScrollController _scrollController = ScrollController();

  UserModel? user;
  bool isLoading = true;

  // Animation values
  double _scrollOffset = 0.0;
  static const double _expandedHeight = 280.0;
  static const double _collapsedHeight = kToolbarHeight + 20;

  // Design system
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
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    debugPrint('🔄 ProfileScreen visible again → Reload Firebase');
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      if (mounted) setState(() => isLoading = true);

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        if (!mounted) return;
        setState(() {
          user = null;
          isLoading = false;
        });
        return;
      }

      final fetchedUser = await authService.getUserData(firebaseUser.uid);
      if (!mounted) return;

      if (fetchedUser != null) {
        setState(() {
          user = fetchedUser;
          isLoading = false;
        });
        await SessionService.saveUser(fetchedUser.toJson());
      } else {
        setState(() {
          user = null;
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Load profile failed: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor:
          Theme.of(context).colorScheme.surface,
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
                Text(
                  "Log out?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "You’ll need to sign in again to access your account and bookings.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
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
                            foregroundColor: const Color(0xFF0F172A),
                            side: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
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
            backgroundColor: const Color(0xFF0F172A),
          ),
        );
      }
    }
  }

  // Progress from 0.0 (expanded) → 1.0 (collapsed)
  double get _collapseProgress {
    final range = _expandedHeight - _collapsedHeight;
    return (_scrollOffset / range).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _collapseProgress;
    final avatarSize = 110.0 - (progress * 60); // 110 → 50
    final nameOpacity = (1.0 - progress * 1.4).clamp(0.0, 1.0);
    final appBarTitleOpacity = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Collapsing Header ──────────────────────────────
                SliverAppBar(
                  expandedHeight: _expandedHeight,
                  pinned: true,
                  stretch: true,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: const SizedBox(), // no back button on tab root
                  actions: [
                    // Small avatar appears in app bar when collapsed
                    Opacity(
                      opacity: appBarTitleOpacity,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: _primary.withOpacity(0.1),
                          backgroundImage: _getProfileImageProvider(),
                          child:
                              user?.profileImage == null ||
                                  user!.profileImage!.trim().isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 18,
                                  color: _primary,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                  title: Opacity(
                    opacity: appBarTitleOpacity,
                    child: Text(
                    user?.fullName ?? 'Profile',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),

                    ),
                  ),
                  centerTitle: true,
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [
                      StretchMode.zoomBackground,
                      StretchMode.fadeTitle,
                    ],
                    background: Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),

                            // Animated Avatar
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 50),
                              width: avatarSize,
                              height: avatarSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _primary.withOpacity(0.08),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primary.withOpacity(
                                      0.15 * (1 - progress),
                                    ),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  ClipOval(
                                    child: SizedBox(
                                      width: avatarSize,
                                      height: avatarSize,
                                      child: _buildProfileImage(avatarSize),
                                    ),
                                  ),
                                  // Edit button (fades out on scroll)
                                  Opacity(
                                    opacity: nameOpacity,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: _primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.5,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.edit_rounded,
                                        color: Colors.white,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Name (fades out)
                            Opacity(
                              opacity: nameOpacity,
                              child: Column(
                                children: [
                                  Text(
                                    user?.fullName ?? 'User',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.occupation?.isNotEmpty == true
                                        ? user!.occupation!
                                        : (user?.email ?? ''),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
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

                // ── Content ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Account Settings
                        _sectionLabel('ACCOUNT'),
                        const SizedBox(height: 12),

                        _buildSettingTile(
                          icon: Icons.person_outline_rounded,
                          iconColor: _primary,
                          title: 'Personal Info',
                          subtitle: 'Manage your identity and details',
                          onTap: () async {
                            if (user == null) return;

                            final updatedUser = await Navigator.push<UserModel>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PersonalInfoScreen(user: user!),
                              ),
                            );

                            if (!mounted) return;

                            if (updatedUser != null) {
                              setState(() => user = updatedUser);
                              await SessionService.saveUser(
                                updatedUser.toJson(),
                              );
                            }
                            await _loadUserData();
                          },
                        ),

                        _buildSettingTile(
                          icon: Icons.credit_card_outlined,
                          iconColor: const Color(0xFFD97706),
                          title: 'Payments',
                          subtitle: 'Payment history and methods',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PaymentHistoryScreen(),
                              ),
                            );
                          },
                        ),

                        _buildSettingTile(
                          icon: Icons.history_rounded,
                          iconColor: const Color(0xFF2563EB),
                          title: 'Booking History',
                          subtitle: 'Past and active bookings',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BookingHistoryScreen(),
                              ),
                            );
                          },
                        ),

                        _buildSettingTile(
                          icon: Icons.security_outlined,
                          iconColor: const Color(0xFF059669),
                          title: 'Security',
                          subtitle: 'Password, 2FA, and login history',
                          onTap: () {},
                        ),

                        const SizedBox(height: 28),

                        // Preferences
                        _sectionLabel('PREFERENCES'),
                        const SizedBox(height: 12),

                        _buildSwitchTile(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          value: true,
                          onChanged: (val) {},
                        ),

                        _buildSwitchTile(
                          icon: Icons.dark_mode_outlined,
                          title: 'Dark Mode',
                          value: Theme.of(context).brightness == Brightness.dark,
                          onChanged: (value) {
                            MyApp.themeController.toggleTheme(value);
                          },
                        ),


                        const SizedBox(height: 36),

                        // Logout
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout_rounded, size: 20),
                            label: const Text(
                              'Log out',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(
                                color: Color(0xFFFECACA),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Center(
                          child: Text(
                            'RentEase  •  v2.4.1',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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


  ImageProvider? _getProfileImageProvider() {
    final image = user?.profileImage;
    if (image != null && image.trim().isNotEmpty) {
      return NetworkImage(image);
    }
    return null;
  }

  Widget _buildProfileImage(double size) {
    final image = user?.profileImage;

    if (image == null || image.trim().isEmpty) {
      return Center(
        child: Icon(Icons.person_rounded, size: size * 0.5, color: _primary),
      );
    }

    return Image.network(
      image,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(
        child: Icon(Icons.person_rounded, size: size * 0.5, color: _primary),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: CircularProgressIndicator(color: _primary, strokeWidth: 2),
        );
      },
    );
  }

  Widget _sectionLabel(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Theme.of(context)
            .colorScheme
            .onSurfaceVariant,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant, fontSize: 13),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant,
          size: 22,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withOpacity(0.15),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),

        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 22,
          ),
        ),

        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),

        trailing: Switch(
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
