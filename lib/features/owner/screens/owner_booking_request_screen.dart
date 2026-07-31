import 'package:flutter/material.dart';
import 'owner_booking_detail.dart';

class BookingRequestsScreen extends StatefulWidget {
  const BookingRequestsScreen({super.key});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  int _selectedFilterIndex = 0;

  final List<String> _filters = ['All (12)', 'Pending (5)', 'Approved (7)'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8FD), // Matching light lavender background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFEBE8FF),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF5338F5), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Booking Requests',
          style: TextStyle(
            color: Color(0xFF5338F5),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFEBE8FF),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.filter_list, color: Color(0xFF5338F5), size: 20),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Tabs
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final isSelected = _selectedFilterIndex == index;
                  return ChoiceChip(
                    label: Text(_filters[index]),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilterIndex = index);
                    },
                    selectedColor: const Color(0xFF5338F5),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF4A4A6A),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF5338F5) : Colors.grey[200]!,
                    ),
                    showCheckmark: false,
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Section Header
            const Text(
              'Recent Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF14142B),
              ),
            ),
            const SizedBox(height: 14),

            // Booking Request Cards List
            BookingCard(
              avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
              name: 'John Smith',
              property: 'Skyline View Penthouse',
              dateRange: '01 Aug - 31 Aug 2026',
              status: 'PENDING',
              statusBgColor: const Color(0xFFFDE8E1),
              statusTextColor: const Color(0xFFB84832),
              isActionable: true,
              onTap: () => _navigateToDetails(context),
            ),
            BookingCard(
              avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
              name: 'Alex Rivers',
              property: 'Urban Brick Studio',
              dateRange: '10 Aug - 10 Sep 2026',
              status: 'APPROVED',
              statusBgColor: const Color(0xFFD1FADF),
              statusTextColor: const Color(0xFF027A48),
              isActionable: false,
              onTap: () => _navigateToDetails(context),
            ),
            BookingCard(
              avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
              name: 'Marcus Thorne',
              property: 'Modern Studio Apartment',
              dateRange: '15 Aug - 15 Sep 2026',
              status: 'PENDING',
              statusBgColor: const Color(0xFFFDE8E1),
              statusTextColor: const Color(0xFFB84832),
              isActionable: true,
              onTap: () => _navigateToDetails(context),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OwnerBookingDetailsScreen()),
    );
  }
}

class BookingCard extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final String property;
  final String dateRange;
  final String status;
  final Color statusBgColor;
  final Color statusTextColor;
  final bool isActionable;
  final VoidCallback onTap;

  const BookingCard({
    super.key,
    required this.avatarUrl,
    required this.name,
    required this.property,
    required this.dateRange,
    required this.status,
    required this.statusBgColor,
    required this.statusTextColor,
    required this.isActionable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top Row Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Image with Verified Check
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          avatarUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified,
                            color: Color(0xFF5338F5),
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Booking Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF14142B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          property,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5338F5),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 13,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                dateRange,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Buttons
              isActionable
                  ? Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Reject',
                          style: TextStyle(
                            color: Color(0xFF14142B),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E5631), // Dark Green matching detail screen
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Approve',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              )
                  : Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text('Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEBE8FF),
                          foregroundColor: const Color(0xFF5338F5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Details',
                          style: TextStyle(
                            color: Color(0xFF14142B),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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
      ),
    );
  }
}