
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart'; // Adjust path as needed

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  // Sample user data matching your UserModel
  late UserModel user;

  // Additional display stats shown in the screenshot
  final int propertyCount = 8;
  final double rating = 4.9;

  @override
  void initState() {
    super.initState();
    user = UserModel(
      uid: 'user_12345',
      fullName: 'Alex Rivers',
      email: 'alex.rivers@rentify.com',
      phone: '+1 234 567 890',
      profileImage: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
      role: 'Owner',
      accountStatus: 'Active',
      createdAt: Timestamp.now(),
    );
  }

  void _onEditProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Edit Profile Screen')),
    );
  }

  void _onSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Settings Screen')),
    );
  }

  void _onLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to end your current session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8FD), // Ultra-light lavender background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D1B69)), // Deep purple for light bg
          onPressed: () => Navigator.pop(context),
        ),
        // title: const Text(
        //   'Owner Profile',
        //   style: TextStyle(
        //     color: Color(0xFF2D1B69), // Deep purple for contrast on light lavender
        //     fontSize: 22,
        //     fontWeight: FontWeight.bold,
        //     height: 1.1,
        //   ),
        // ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 12),


              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: (user.profileImage != null && user.profileImage!.isNotEmpty)
                            ? NetworkImage(user.profileImage!)
                            : null,
                        child: (user.profileImage == null || user.profileImage!.isEmpty)
                            ? const Icon(Icons.person, size: 56, color: Colors.grey)
                            : null,
                      ),
                    ),
                    // Verified Checkmark Badge
                    Container(
                      margin: const EdgeInsets.only(right: 4, bottom: 4),
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Color(0xFF5338F5),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),


              Text(
                user.fullName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF14142B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Email Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email_outlined, size: 16, color: Color(0xFF4A4A6A)),
                  const SizedBox(width: 6),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: Color(0xFF4A4A6A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Phone Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF4A4A6A)),
                  const SizedBox(width: 6),
                  Text(
                    user.phone,
                    style: const TextStyle(
                      color: Color(0xFF4A4A6A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),


              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Properties Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5EF),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.home_outlined, size: 16, color: Color(0xFF1F7A4D)),
                        const SizedBox(width: 6),
                        Text(
                          '$propertyCount Properties',
                          style: const TextStyle(
                            color: Color(0xFF1F7A4D),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Rating Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF0ED),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Color(0xFFB84832)),
                        const SizedBox(width: 6),
                        Text(
                          '$rating Rating',
                          style: const TextStyle(
                            color: Color(0xFFB84832),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),


              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.edit_outlined,
                      title: 'Edit Profile',
                      subtitle: 'Update your personal details',
                      iconBgColor: const Color(0xFFF2EFFF),
                      iconColor: const Color(0xFF5338F5),
                      onTap: _onEditProfile,
                    ),
                    const Divider(height: 1, indent: 72, endIndent: 20),
                    _buildMenuItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'App preferences & security',
                      iconBgColor: const Color(0xFFEBF1FF),
                      iconColor: const Color(0xFF386BF5),
                      onTap: _onSettings,
                    ),
                    const Divider(height: 1, indent: 72, endIndent: 20),
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      subtitle: 'End your current session',
                      titleColor: const Color(0xFFD32F2F),
                      iconBgColor: const Color(0xFFFDEEEE),
                      iconColor: const Color(0xFFE53935),
                      onTap: _onLogout,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ---------------------------------------------------------------
              // NEED HELP? BANNER
              // ---------------------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5D40F5), Color(0xFF4221EE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5338F5).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Need Help?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Our premium support team is available 24/7 for owners.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Customer Support Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.support_agent,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget for Custom Menu Items
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
    Color titleColor = const Color(0xFF14142B),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            // Rounded Square Icon Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),

            // Title & Subtitle Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Trailing Chevron
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

