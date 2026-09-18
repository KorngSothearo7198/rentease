import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import 'EditPersonalInfoScreen.dart';

class PersonalInfoScreen extends StatefulWidget {
  final UserModel user;

  const PersonalInfoScreen({
    super.key,
    required this.user,
  });

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  UserModel? user;
  bool isLoading = true;

  double _scrollOffset = 0.0;

  static const double _expandedHeight = 260.0;
  static const double _collapsedHeight = kToolbarHeight;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color _primary = Color(0xFF4F46E5);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    user = widget.user;

    _loadUser();

    _scrollController.addListener(_onScroll);
  }

  // ============================================================
  // THEME COLORS
  // ============================================================

  Color get _backgroundColor {
    return Theme.of(context).colorScheme.surface;
  }

  Color get _cardColor {
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  Color get _textPrimary {
    return Theme.of(context).colorScheme.onSurface;
  }

  Color get _textSecondary {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  Color get _borderColor {
    return Theme.of(context).dividerColor;
  }

  // ============================================================
  // SCROLL
  // ============================================================

  void _onScroll() {
    if (!mounted) return;

    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // COLLAPSE PROGRESS
  // ============================================================

  double get _collapseProgress {
    final range = _expandedHeight - _collapsedHeight;

    return (_scrollOffset / range).clamp(0.0, 1.0);
  }

  // ============================================================
  // LOAD USER
  // ============================================================

  Future<void> _loadUser() async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        return;
      }

      final uid = currentUser.uid;

      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get(
        const GetOptions(
          source: Source.server,
        ),
      );

      if (!doc.exists || doc.data() == null) {
        if (!mounted) return;

        setState(() {
          user = null;
          isLoading = false;
        });

        return;
      }

      final loadedUser = UserModel.fromMap(
        doc.data()!,
      );

      if (!mounted) return;

      setState(() {
        user = loadedUser;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'LOAD USER ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final progress = _collapseProgress;

    final avatarSize = 96.0 - (progress * 48);

    final headerOpacity =
    (1.0 - progress * 1.35).clamp(0.0, 1.0);

    final appBarTitleOpacity =
    ((progress - 0.5) / 0.5).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: _backgroundColor,

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: _primary,
        ),
      )
          : user == null
          ? Center(
        child: Text(
          'User information not found',
          style: TextStyle(
            color: _textPrimary,
          ),
        ),
      )
          : CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ====================================================
          // COLLAPSING APP BAR
          // ====================================================

          theSliverAppBar(
            progress: progress,
            avatarSize: avatarSize,
            headerOpacity: headerOpacity,
            appBarTitleOpacity: appBarTitleOpacity,
          ),

          // ====================================================
          // CONTENT
          // ====================================================

          theContent(),
        ],
      ),
    );
  }

  // ============================================================
  // SLIVER APP BAR
  // ============================================================

  Widget theSliverAppBar({
    required double progress,
    required double avatarSize,
    required double headerOpacity,
    required double appBarTitleOpacity,
  }) {
    return CoupledSliverAppBar(
      expandedHeight: _expandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: _backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,

      // ==========================================================
      // BACK BUTTON
      // ==========================================================

      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: _textPrimary,
          size: 20,
        ),
        onPressed: () {
          Navigator.pop(
            context,
            user,
          );
        },
      ),

      // ==========================================================
      // COLLAPSED TITLE
      // ==========================================================

      title: Opacity(
        opacity: appBarTitleOpacity,
        child: Text(
          user?.fullName ?? 'Personal Info',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),

      centerTitle: true,

      // ==========================================================
      // COLLAPSED AVATAR
      // ==========================================================

      actions: [
        Opacity(
          opacity: appBarTitleOpacity,
          child: Padding(
            padding: const EdgeInsets.only(
              right: 12,
            ),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: _primary.withOpacity(0.1),
              backgroundImage: _profileImageProvider(),
              child: _hasProfileImage
                  ? null
                  : const Icon(
                Icons.person,
                size: 16,
                color: _primary,
              ),
            ),
          ),
        ),
      ],

      // ==========================================================
      // FLEXIBLE SPACE
      // ==========================================================

      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        background: Container(
          color: _backgroundColor,

          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 12,
                ),

                // ======================================================
                // AVATAR
                // ======================================================

                AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 40,
                  ),
                  width: avatarSize,
                  height: avatarSize,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primary.withOpacity(0.08),

                    boxShadow: [
                      BoxShadow(
                        color: _primary.withOpacity(
                          0.12 * (1 - progress),
                        ),
                        blurRadius: 20,
                        offset: const Offset(
                          0,
                          6,
                        ),
                      ),
                    ],
                  ),

                  child: ClipOval(
                    child: _buildAvatarImage(
                      avatarSize,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                // ======================================================
                // NAME + EMAIL
                // ======================================================

                Opacity(
                  opacity: headerOpacity,
                  child: Column(
                    children: [
                      Text(
                        user!.fullName.isEmpty
                            ? 'No name'
                            : user!.fullName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        user!.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      // ==================================================
                      // ROLE
                      // ==================================================

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user!.role.toUpperCase(),
                          style: const TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.5,
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
    );
  }

  // ============================================================
  // SLIVER APP BAR WRAPPER
  // ============================================================

  Widget CoupledSliverAppBar({
    required double expandedHeight,
    required bool pinned,
    required bool stretch,
    required Color backgroundColor,
    required double elevation,
    required double scrolledUnderElevation,
    required Widget leading,
    required Widget? title,
    required bool centerTitle,
    required List<Widget>? actions,
    required Widget flexibleSpace,
  }) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: pinned,
      stretch: stretch,

      backgroundColor: backgroundColor,

      elevation: elevation,

      scrolledUnderElevation: scrolledUnderElevation,

      leading: leading,

      title: title,

      centerTitle: centerTitle,

      actions: actions,

      flexibleSpace: flexibleSpace,
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
          8,
          20,
          40,
        ),

        child: Column(
          children: [
            // ========================================================
            // IDENTITY
            // ========================================================

            _section(
              title: 'IDENTITY',
              children: [
                _infoRow(
                  icon: Icons.person_outline_rounded,
                  title: 'Full Name',
                  value: user!.fullName,
                ),

                _infoRow(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  value: user!.email,
                ),

                _infoRow(
                  icon: Icons.phone_outlined,
                  title: 'Phone',
                  value: user!.phone,
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            // ========================================================
            // PERSONAL DETAILS
            // ========================================================

            _section(
              title: 'PERSONAL DETAILS',
              children: [
                _infoRow(
                  icon: Icons.wc_outlined,
                  title: 'Gender',
                  value: user!.gender,
                ),

                _infoRow(
                  icon: Icons.cake_outlined,
                  title: 'Age',
                  value: user!.age == 0
                      ? 'Not provided'
                      : '${user!.age} years old',
                ),

                _infoRow(
                  icon: Icons.work_outline_rounded,
                  title: 'Occupation',
                  value: user!.occupation,
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            // ========================================================
            // CONTACT
            // ========================================================

            _section(
              title: 'CONTACT INFORMATION',
              children: [
                _infoRow(
                  icon: Icons.location_on_outlined,
                  title: 'Address',
                  value: user!.address,
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            // ========================================================
            // ABOUT
            // ========================================================

            _section(
              title: 'ABOUT',
              children: [
                _infoRow(
                  icon: Icons.info_outline_rounded,
                  title: 'Bio',
                  value: user!.bio,
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            // ========================================================
            // ACCOUNT
            // ========================================================

            _section(
              title: 'ACCOUNT',
              children: [
                _infoRow(
                  icon: Icons.badge_outlined,
                  title: 'Role',
                  value: user!.role,
                ),

                _infoRow(
                  icon: Icons.verified_user_outlined,
                  title: 'Account Status',
                  value: user!.accountStatus,
                ),
              ],
            ),

            const SizedBox(
              height: 28,
            ),

            // ========================================================
            // EDIT BUTTON
            // ========================================================

            SizedBox(
              width: double.infinity,
              height: 54,

              child: ElevatedButton.icon(
                onPressed: () async {
                  if (user == null) return;

                  final updatedUser =
                  await Navigator.push<UserModel>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditPersonalInfoScreen(
                            user: user!,
                          ),
                    ),
                  );

                  if (!mounted) return;

                  if (updatedUser != null) {
                    setState(() {
                      user = updatedUser;
                    });
                  }
                },

                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                ),

                label: const Text(
                  'Edit Personal Information',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  bool get _hasProfileImage {
    final image = user?.profileImage;

    return image != null &&
        image.trim().isNotEmpty;
  }

  ImageProvider? _profileImageProvider() {
    if (!_hasProfileImage) {
      return null;
    }

    return NetworkImage(
      user!.profileImage!,
    );
  }

  Widget _buildAvatarImage(
      double size,
      ) {
    if (!_hasProfileImage) {
      return Center(
        child: Icon(
          Icons.person_rounded,
          size: size * 0.5,
          color: _primary,
        ),
      );
    }

    return Image.network(
      user!.profileImage!,
      width: size,
      height: size,
      fit: BoxFit.cover,

      errorBuilder: (
          _,
          __,
          ___,
          ) {
        return Center(
          child: Icon(
            Icons.person_rounded,
            size: size * 0.5,
            color: _primary,
          ),
        );
      },

      loadingBuilder: (
          context,
          child,
          progress,
          ) {
        if (progress == null) {
          return child;
        }

        return const Center(
          child: CircularProgressIndicator(
            color: _primary,
            strokeWidth: 2,
          ),
        );
      },
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _section({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 4,
            bottom: 10,
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ),

        Container(
          width: double.infinity,

          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(18),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  Theme.of(context).brightness ==
                      Brightness.dark
                      ? 0.15
                      : 0.03,
                ),
                blurRadius: 12,
                offset: const Offset(
                  0,
                  3,
                ),
              ),
            ],
          ),

          child: Column(
            children: List.generate(
              children.length,
                  (index) {
                return Column(
                  children: [
                    children[index],

                    if (index <
                        children.length - 1)
                      Divider(
                        height: 1,
                        color: _borderColor,
                        indent: 70,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final displayValue =
    value.trim().isEmpty
        ? 'Not provided'
        : value;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          // ========================================================
          // ICON
          // ========================================================

          Container(
            width: 40,
            height: 40,

            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius:
              BorderRadius.circular(11),
            ),

            child: Icon(
              icon,
              size: 20,
              color: _primary,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          // ========================================================
          // TEXT
          // ========================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}