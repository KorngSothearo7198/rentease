import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../../../services/chat_service.dart';
import '../../renter/screens/chat_detail_screen.dart';

class OwnerPublicProfileScreen extends StatefulWidget {
  final UserModel owner;

  // ============================================================
  // PROPERTY INFORMATION
  // ============================================================

  final String houseId;
  final String propertyName;

  const OwnerPublicProfileScreen({
    super.key,
    required this.owner,
    required this.houseId,
    required this.propertyName,
  });

  @override
  State<OwnerPublicProfileScreen> createState() =>
      _OwnerPublicProfileScreenState();
}

class _OwnerPublicProfileScreenState
    extends State<OwnerPublicProfileScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color _primary = Color(0xFF4F46E5);
  static const Color _success = Color(0xFF059669);

  // ============================================================
  // EXPANDED SECTIONS
  // ============================================================

  bool _identityExpanded = true;
  bool _detailsExpanded = false;
  bool _aboutExpanded = false;

  // ============================================================
  // OWNER
  // ============================================================

  UserModel get owner => widget.owner;

  // ============================================================
  // PROPERTY
  // ============================================================

  String get houseId => widget.houseId;

  String get propertyName => widget.propertyName;

  // ============================================================
  // CHAT SERVICE
  // ============================================================

  final ChatService chatService = ChatService();

  // ============================================================
  // THEME
  // ============================================================

  Color get _background {
    return Theme.of(context).colorScheme.surface;
  }

  Color get _card {
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  Color get _textPrimary {
    return Theme.of(context).colorScheme.onSurface;
  }

  Color get _textSecondary {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  Color get _border {
    return Theme.of(context).colorScheme.outlineVariant;
  }

  bool get _isDarkMode {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // ============================================================
  // OPEN CHAT
  // ============================================================

  Future<void> _openChat() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    // ------------------------------------------------------------
    // Check login
    // ------------------------------------------------------------

    if (currentUser == null) {
      return;
    }

    // ------------------------------------------------------------
    // Prevent chatting with yourself
    // ------------------------------------------------------------

    if (currentUser.uid == owner.uid) {
      return;
    }

    try {
      // ----------------------------------------------------------
      // Clean property data
      // ----------------------------------------------------------

      final currentHouseId = houseId.trim();
      final currentPropertyName = propertyName.trim();

      // ----------------------------------------------------------
      // Property ID is required
      // ----------------------------------------------------------

      if (currentHouseId.isEmpty) {
        throw Exception('Property ID is empty');
      }

      // ----------------------------------------------------------
      // Create unique conversation
      //
      // One conversation =
      // renter + owner + property
      // ----------------------------------------------------------

      final conversationId = chatService.createConversationId(
        currentUser.uid,
        owner.uid,
        currentHouseId,
      );

      // ----------------------------------------------------------
      // Create conversation if it does not exist
      // ----------------------------------------------------------

      await chatService.createConversation(
        conversationId: conversationId,
        renterId: currentUser.uid,
        ownerId: owner.uid,
        houseId: currentHouseId,
        propertyName: currentPropertyName.isNotEmpty
            ? currentPropertyName
            : 'Property',
      );

      // ----------------------------------------------------------
      // Check widget still exists
      // ----------------------------------------------------------

      if (!mounted) return;

      // ----------------------------------------------------------
      // Open Chat Detail
      // ----------------------------------------------------------

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            conversationId: conversationId,
            hostName: owner.fullName.trim().isNotEmpty
                ? owner.fullName.trim()
                : 'Owner',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error opening chat: $e');

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
    final String profileImage =
        owner.profileImage?.trim() ?? '';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(24),
      ),
      child: Container(
        color: _background,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // ==================================================
              // SCROLLABLE CONTENT
              // ==================================================

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    12,
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // ==================================================
                      // DRAG HANDLE
                      // ==================================================

                      Container(
                        width: 34,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _border,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ==================================================
                      // HEADER
                      // ==================================================

                      SizedBox(
                        height: 42,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Owner Profile',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: _textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),

                            // ------------------------------------------------
                            // CLOSE BUTTON
                            // ------------------------------------------------

                            SizedBox(
                              width: 36,
                              height: 36,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                splashRadius: 18,
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: _textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ==================================================
                      // PROFILE IMAGE
                      // ==================================================

                      Container(
                        width: 84,
                        height: 84,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: _card,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _primary.withOpacity(0.15),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                _isDarkMode ? 0.20 : 0.06,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: profileImage.isNotEmpty
                              ? Image.network(
                            profileImage,
                            width: 78,
                            height: 78,
                            fit: BoxFit.cover,
                            loadingBuilder:
                                (context, child, progress) {
                              if (progress == null) {
                                return child;
                              }

                              return Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                  CircularProgressIndicator(
                                    strokeWidth: 2,
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

                      const SizedBox(height: 10),

                      // ==================================================
                      // OWNER NAME
                      // ==================================================

                      Text(
                        owner.fullName.trim().isNotEmpty
                            ? owner.fullName.trim()
                            : 'Unknown Owner',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),

                      const SizedBox(height: 5),

                      // ==================================================
                      // ROLE CHIP
                      // ==================================================

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(
                            _isDarkMode ? 0.16 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 12,
                              color: _primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              owner.role.trim().isNotEmpty
                                  ? owner.role.toUpperCase()
                                  : 'OWNER',
                              style: const TextStyle(
                                color: _primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // IDENTITY
                      // ==================================================

                      _expandableSection(
                        title: 'Identity',
                        icon: Icons.person_outline_rounded,
                        isExpanded: _identityExpanded,
                        onTap: () {
                          setState(() {
                            _identityExpanded =
                            !_identityExpanded;
                          });
                        },
                        children: [
                          _infoTile(
                            icon: Icons.badge_outlined,
                            label: 'Full Name',
                            value: _valueOrDefault(
                              owner.fullName,
                            ),
                          ),
                          _infoTile(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: _valueOrDefault(
                              owner.email,
                            ),
                          ),
                          _infoTile(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: _valueOrDefault(
                              owner.phone,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ==================================================
                      // PERSONAL DETAILS
                      // ==================================================

                      _expandableSection(
                        title: 'Personal Details',
                        icon: Icons.info_outline_rounded,
                        isExpanded: _detailsExpanded,
                        onTap: () {
                          setState(() {
                            _detailsExpanded =
                            !_detailsExpanded;
                          });
                        },
                        children: [
                          _infoTile(
                            icon: Icons.wc_outlined,
                            label: 'Gender',
                            value: _nullableString(
                              owner.gender,
                            ),
                          ),
                          _infoTile(
                            icon: Icons.cake_outlined,
                            label: 'Age',
                            value: _ageValue(),
                          ),
                          _infoTile(
                            icon: Icons.work_outline_rounded,
                            label: 'Occupation',
                            value: _nullableString(
                              owner.occupation,
                            ),
                          ),
                          _infoTile(
                            icon: Icons.location_on_outlined,
                            label: 'Address',
                            value: _nullableString(
                              owner.address,
                            ),
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
                        const SizedBox(height: 8),
                        _expandableSection(
                          title: 'About',
                          icon: Icons.notes_rounded,
                          isExpanded: _aboutExpanded,
                          onTap: () {
                            setState(() {
                              _aboutExpanded =
                              !_aboutExpanded;
                            });
                          },
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                4,
                                14,
                                14,
                              ),
                              child: Text(
                                owner.bio!.trim(),
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: _textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // ==================================================
              // STICKY CHAT BUTTON
              // ==================================================

              Container(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  12,
                ),
                decoration: BoxDecoration(
                  color: _background,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        _isDarkMode ? 0.18 : 0.05,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _openChat,
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Chat with Owner',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(13),
                        ),
                      ),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _border.withOpacity(
            _isDarkMode ? 0.35 : 0.55,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              _isDarkMode ? 0.08 : 0.02,
            ),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ==================================================
          // SECTION HEADER
          // ==================================================

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // ------------------------------------------------
                    // ICON
                    // ------------------------------------------------

                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(
                          _isDarkMode ? 0.15 : 0.08,
                        ),
                        borderRadius:
                        BorderRadius.circular(9),
                      ),
                      child: Icon(
                        icon,
                        color: _primary,
                        size: 17,
                      ),
                    ),

                    const SizedBox(width: 10),

                    // ------------------------------------------------
                    // TITLE
                    // ------------------------------------------------

                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                    ),

                    // ------------------------------------------------
                    // ARROW
                    // ------------------------------------------------

                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration:
                      const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _textSecondary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ==================================================
          // SECTION CONTENT
          // ==================================================

          AnimatedCrossFade(
            firstChild:
            const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                Divider(
                  height: 1,
                  color: _border.withOpacity(0.6),
                ),
                ...children,
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration:
            const Duration(milliseconds: 180),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------------
          // ICON
          // --------------------------------------------------------

          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              icon,
              size: 16,
              color: _textSecondary,
            ),
          ),

          const SizedBox(width: 10),

          // --------------------------------------------------------
          // TEXT
          // --------------------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color:
                    valueColor ?? _textPrimary,
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
      color: _isDarkMode
          ? const Color(0xFF1E1B4B)
          : const Color(0xFFEEF2FF),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 40,
          color: _primary,
        ),
      ),
    );
  }

  // ============================================================
  // NULLABLE STRING
  // ============================================================

  String _nullableString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Not provided';
    }

    return value.trim();
  }

  // ============================================================
  // VALUE OR DEFAULT
  // ============================================================

  String _valueOrDefault(String value) {
    if (value.trim().isEmpty) {
      return 'Not provided';
    }

    return value.trim();
  }

  // ============================================================
  // AGE
  // ============================================================

  String _ageValue() {
    if (owner.age <= 0) {
      return 'Not provided';
    }

    return '${owner.age} years';
  }

  // ============================================================
  // ACCOUNT STATUS
  // ============================================================

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

  // ============================================================
  // BIO
  // ============================================================

  bool _hasBio() {
    return owner.bio != null &&
        owner.bio!.trim().isNotEmpty;
  }
}