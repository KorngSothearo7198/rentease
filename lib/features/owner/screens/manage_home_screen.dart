import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/property_model.dart';
import '../../../services/property_service.dart';
import '../../../services/subscription_plans_services.dart';
import '../../../services/subscription_service.dart';
import 'OwnerSubscriptionScreen.dart';
import 'add_room_screen.dart';
import 'edit_room_screen.dart';

class ManageHousesScreen extends StatefulWidget {
  const ManageHousesScreen({super.key});

  @override
  State<ManageHousesScreen> createState() => _ManageHousesScreenState();
}

class _ManageHousesScreenState extends State<ManageHousesScreen> {
  final PropertyService propertyService = PropertyService();

  final SubscriptionPlansService _plansService = SubscriptionPlansService();

  final SubscriptionService _subscriptionService = SubscriptionService();


  String? ownerId;

  static const Color _primary = Color(0xFF4F46E5);
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _card = Colors.white;
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    loadOwner();
  }

  Future<void> loadOwner() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => ownerId = user.uid);
    }
  }

  Future<void> _onAdd() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4F46E5),
        ),
      ),
    );

    try {
      final subscriptionService = SubscriptionService();
      final result = await subscriptionService.canAddProperty(user.uid);

      if (!mounted) return;

      Navigator.pop(context);

      debugPrint('========== SUBSCRIPTION CHECK ==========');
      debugPrint('Owner ID: ${user.uid}');
      debugPrint('Can Add: ${result['canAdd']}');
      debugPrint('Reason: ${result['reason']}');
      debugPrint('Current Count: ${result['currentCount']}');
      debugPrint('Limit: ${result['limit']}');
      debugPrint('Plan ID: ${result['planId']}');
      debugPrint('Plan Name: ${result['planName']}');
      debugPrint('========================================');

      if (result['canAdd'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddRoomScreen(),
          ),
        );
        return;
      }

      _showSubscriptionLimitDialog(
        reason: result['reason']?.toString() ??
            'You need an active subscription to add properties.',
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to check subscription: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSubscriptionLimitDialog({
    required String reason,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 36,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Subscription Limit Reached',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const OwnerSubscriptionScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Upgrade Plan',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
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
  }



  void _onEdit(Property property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditRoomScreen(property: property),
      ),
    );
  }

  void _onDelete(Property property) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Listing"),
        content: Text('Are you sure you want to delete "${property.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await propertyService.deleteProperty(property.id);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Listing deleted"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: _textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Properties",
          style: TextStyle(
            color: _textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _onAdd,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
      body: ownerId == null
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : StreamBuilder<List<Property>>(
        stream: propertyService.getOwnerProperties(ownerId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final properties = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.68, // adjust this if cards feel too tall/short
            ),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 350 + (index * 70)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.85 + (0.15 * value),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: PropertyCard(
                  property: properties[index],
                  onEdit: () => _onEdit(properties[index]),
                  onDelete: () => _onDelete(properties[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.home_work_outlined,
              size: 42,
              color: _primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No properties yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Tap the + button to add your first room",
            style: TextStyle(fontSize: 14, color: _textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text("Add Property"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PROPERTY CARD (Grid Style)
// -----------------------------------------------------------------------------
class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onEdit,
    required this.onDelete,
  });

  static const Color _primary = Color(0xFF4F46E5);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final isPublished = property.status == PropertyStatus.published;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= IMAGE + LOADING =================
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: property.imageUrl.isNotEmpty
                      ? Image.network(
                    property.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    // Loading placeholder
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: _primary.withOpacity(0.7),
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.home_rounded,
                        size: 42,
                        color: Colors.grey,
                      ),
                    ),
                  )
                      : Container(
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.home_rounded,
                      size: 42,
                      color: Colors.grey,
                    ),
                  ),
                ),

                // Status badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isPublished ? Colors.greenAccent : Colors.amber,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isPublished ? "Published" : "Draft",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _circleBtn(Icons.edit_rounded, _primary, onEdit),
                      const SizedBox(width: 6),
                      _circleBtn(Icons.delete_outline_rounded, Colors.red, onDelete),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ================= CONTENT =================
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      property.category.isEmpty ? "Room" : property.category,
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    property.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: _primary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          property.location,
                          style: const TextStyle(color: _textSecondary, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Price + Beds
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "\$${property.price.toInt()}/mo",
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.king_bed_outlined, size: 14, color: _textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            "${property.bedrooms}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}