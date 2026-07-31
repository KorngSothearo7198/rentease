import 'package:flutter/material.dart';
import 'package:rentease/features/renter/screens/payment_history_screen.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../auth/renter/loginScreen.dart';
import 'booking_history_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService authService = AuthService();
  UserModel? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = authService.currentUser;
      if (currentUser != null) {
        final fetchedUser = await authService.getUserData(currentUser.uid);
        setState(() {
          user = fetchedUser;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {


      try {


        await authService.logout();


        if(!mounted) return;


        Navigator.of(context).pushAndRemoveUntil(

          MaterialPageRoute(
            builder: (context)=>const LoginScreen(),
          ),

              (route)=>false,

        );
      }catch(e){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                e.toString()
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // title: const Text(
        //   'Rentify',
        //   style: TextStyle(
        //     color: Color(0xFF6B46C1),
        //     fontWeight: FontWeight.bold,
        //     fontSize: 24,
        //   ),
        // ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D1B69)), // Deep purple for light bg
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: user?.profileImage != null
                  ? NetworkImage(user!.profileImage!)
                  : const AssetImage('assets/default_avatar.png'),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Large Profile Avatar with Edit Button
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundImage: user?.profileImage != null
                      ? NetworkImage(user!.profileImage!)
                      : const AssetImage('assets/default_avatar.png'),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF6B46C1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Name & Member Info
            Text(
              user?.fullName ?? 'Alex Thompson',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Text(
            //   'Premium Member since ${user?.createdAt?.year ?? 2022}',
            //   style: const TextStyle(
            //     fontSize: 15,
            //     color: Colors.grey,
            //   ),
            // ),

            const SizedBox(height: 40),

            // Account Settings
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ACCOUNT SETTINGS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 12),

            _buildSettingTile(
              icon: Icons.person_outline,
              color: Colors.purple.withOpacity(0.1),
              title: 'Personal Info',
              subtitle: 'Manage your identity and details',
              onTap: () {},
            ),
            _buildSettingTile(
              icon: Icons.credit_card_outlined,
              color: Colors.orange.withOpacity(0.1),
              title: 'Payments',
              subtitle: 'Connected cards and payment history',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PaymentHistoryScreen()),
                );
              },
            ),
            _buildSettingTile(
              icon: Icons.history,
              color: Colors.blue.withOpacity(0.1),
              title: 'Booking History',
              subtitle: 'View your past and active bookings',
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
              color: Colors.green.withOpacity(0.1),
              title: 'Security',
              subtitle: 'Password, 2FA, and login history',
              onTap: () {},
            ),

            const SizedBox(height: 30),

            // Preferences
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'PREFERENCES',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 12),

            _buildSwitchTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              value: true,
              onChanged: (val) {},
            ),
            _buildSwitchTile(icon: Icons.dark_mode_outlined, title: 'Dark Mode', value: false, onChanged: (val) {},
            ),

            const SizedBox(height: 40),

            // Logout Button
            TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text(
              'Rentify Version 2.4.1',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.black87),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.black87),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Switch(
          value: value,
          activeColor: const Color(0xFF6B46C1),
          onChanged: onChanged,
        ),
      ),
    );
  }
}