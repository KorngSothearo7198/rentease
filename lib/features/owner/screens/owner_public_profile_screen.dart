import 'package:flutter/material.dart';

import '../../../models/user_model.dart';

class OwnerPublicProfileScreen extends StatefulWidget {
  final UserModel owner;

  const OwnerPublicProfileScreen({super.key, required this.owner});

  @override
  State<OwnerPublicProfileScreen> createState() =>
      _OwnerPublicProfileScreenState();
}

class _OwnerPublicProfileScreenState extends State<OwnerPublicProfileScreen> {
  // ============================================================
  // CONSTANTS
  // ============================================================

  static const Color _primary = Color(0xFF4F46E5);

  static const Color _success = Color(0xFF059669);

  // Which sections are expanded
  bool _identityExpanded = true;
  bool _detailsExpanded = false;
  bool _aboutExpanded = false;

  UserModel get owner => widget.owner;

  // ============================================================
  // THEME COLORS
  // ============================================================

  Color get _background {
    final colorScheme = Theme.of(context).colorScheme;

    return colorScheme.surface;
  }

  Color get _card {
    final colorScheme = Theme.of(context).colorScheme;

    return colorScheme.surfaceContainerHighest;
  }

  Color get _textPrimary {
    final colorScheme = Theme.of(context).colorScheme;

    return colorScheme.onSurface;
  }

  Color get _textSecondary {
    final colorScheme = Theme.of(context).colorScheme;

    return colorScheme.onSurfaceVariant;
  }

  Color get _border {
    final colorScheme = Theme.of(context).colorScheme;

    return colorScheme.outlineVariant;
  }

  bool get _isDarkMode {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final String profileImage = owner.profileImage?.trim() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: _background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // ==================================================
            // SCROLLABLE CONTENT
            // ==================================================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ==================================================
                    // DRAG HANDLE
                    // ==================================================
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // HEADER
                    // ==================================================
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Owner Profile',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),

                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.close_rounded, color: _textPrimary),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // PROFILE IMAGE
                    // ==================================================
                    Container(
                      width: 108,
                      height: 108,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _card,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              _isDarkMode ? 0.25 : 0.08,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: profileImage.isNotEmpty
                            ? Image.network(
                                profileImage,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) {
                                    return child;
                                  }

                                  return Center(
                                    child: SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: _primary,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) {
                                  return _defaultProfileImage();
                                },
                              )
                            : _defaultProfileImage(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ==================================================
                    // NAME
                    // ==================================================
                    Text(
                      owner.fullName.trim().isNotEmpty
                          ? owner.fullName
                          : 'Unknown Owner',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ==================================================
                    // ROLE CHIP
                    // ==================================================
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(_isDarkMode ? 0.18 : 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        owner.role.trim().isNotEmpty
                            ? owner.role.toUpperCase()
                            : 'OWNER',
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ==================================================
                    // IDENTITY
                    // ==================================================
                    _expandableSection(
                      title: 'Identity',
                      icon: Icons.person_outline_rounded,
                      isExpanded: _identityExpanded,
                      onTap: () {
                        setState(() {
                          _identityExpanded = !_identityExpanded;
                        });
                      },
                      children: [
                        _infoTile(
                          icon: Icons.badge_outlined,
                          label: 'Full Name',
                          value: _valueOrDefault(owner.fullName),
                        ),
                        _infoTile(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: _valueOrDefault(owner.email),
                        ),
                        _infoTile(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: _valueOrDefault(owner.phone),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // PERSONAL DETAILS
                    // ==================================================
                    _expandableSection(
                      title: 'Personal Details',
                      icon: Icons.info_outline_rounded,
                      isExpanded: _detailsExpanded,
                      onTap: () {
                        setState(() {
                          _detailsExpanded = !_detailsExpanded;
                        });
                      },
                      children: [
                        _infoTile(
                          icon: Icons.wc_outlined,
                          label: 'Gender',
                          value: _nullableString(owner.gender),
                        ),
                        _infoTile(
                          icon: Icons.cake_outlined,
                          label: 'Age',
                          value: _ageValue(),
                        ),
                        _infoTile(
                          icon: Icons.work_outline_rounded,
                          label: 'Occupation',
                          value: _nullableString(owner.occupation),
                        ),
                        _infoTile(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: _nullableString(owner.address),
                        ),
                        _infoTile(
                          icon: Icons.verified_outlined,
                          label: 'Account',
                          value: _accountStatus(),
                          valueColor: _success,
                        ),
                      ],
                    ),

                    // ==================================================
                    // ABOUT
                    // ==================================================
                    if (_hasBio()) ...[
                      const SizedBox(height: 12),

                      _expandableSection(
                        title: 'About',
                        icon: Icons.notes_rounded,
                        isExpanded: _aboutExpanded,
                        onTap: () {
                          setState(() {
                            _aboutExpanded = !_aboutExpanded;
                          });
                        },
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            child: Text(
                              owner.bio!.trim(),
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.55,
                                color: _textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ==================================================
            // STICKY CHAT BUTTON
            // ==================================================
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: _card,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isDarkMode ? 0.25 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      debugPrint('Chat owner: ${owner.uid}');
                    },
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 20,
                    ),
                    label: const Text(
                      'Chat with Owner',
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EXPANDABLE SECTION
  // ============================================================

  Widget _expandableSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border.withOpacity(_isDarkMode ? 0.5 : 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.15 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ==================================================
          // HEADER
          // ==================================================
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(_isDarkMode ? 0.18 : 0.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(icon, color: _primary, size: 20),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                    ),

                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _textSecondary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ==================================================
          // CONTENT
          // ==================================================
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                Divider(height: 1, color: _border),
                ...children,
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO TILE
  // ============================================================

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _textSecondary),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? _textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DEFAULT PROFILE IMAGE
  // ============================================================

  Widget _defaultProfileImage() {
    return Container(
      color: _isDarkMode ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
      child: Center(
        child: Icon(Icons.person_rounded, size: 52, color: _primary),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _nullableString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Not provided';
    }

    return value.trim();
  }

  String _valueOrDefault(String value) {
    if (value.trim().isEmpty) {
      return 'Not provided';
    }

    return value.trim();
  }

  String _ageValue() {
    if (owner.age <= 0) {
      return 'Not provided';
    }

    return '${owner.age} years';
  }

  String _accountStatus() {
    final status = owner.accountStatus.trim();

    if (status.isEmpty) {
      return 'Active';
    }

    if (status.toLowerCase() == 'active') {
      return 'Verified';
    }

    return status;
  }

  bool _hasBio() {
    return owner.bio != null && owner.bio!.trim().isNotEmpty;
  }
}
