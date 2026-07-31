import 'package:flutter/material.dart';

class OwnerBookingDetailsScreen extends StatefulWidget {
  const OwnerBookingDetailsScreen({super.key});

  @override
  State<OwnerBookingDetailsScreen> createState() => _OwnerBookingDetailsScreenState();
}

class _OwnerBookingDetailsScreenState extends State<OwnerBookingDetailsScreen> {
  String status = 'PENDING'; // PENDING, APPROVED, REJECTED

  void _onApprove() {
    setState(() {
      status = 'APPROVED';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking request approved!'),
        backgroundColor: Color(0xFF1E5631),
      ),
    );
  }

  void _onReject() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Request'),
        content: const Text('Are you sure you want to reject this booking request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                status = 'REJECTED';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking request rejected'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8FD), // Soft background
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
          'Booking Details',
          style: TextStyle(
            color: Color(0xFF5338F5),
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
                icon: const Icon(Icons.more_horiz, color: Color(0xFF5338F5), size: 20),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // -----------------------------------------------------------------
            // 1. BOOKING ID & TIMELINE CARD
            // -----------------------------------------------------------------
            _buildCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Text(
                            'Booking ID: ',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'BK-2026-00021',
                            style: TextStyle(
                              color: Color(0xFF14142B),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Status Badge
                      _buildStatusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Booking Date', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text('25 July 2026', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Period', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text('01 Aug - 31 Aug 2026', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('(30 Days)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // 2. TENANT INFORMATION CARD
            // -----------------------------------------------------------------
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tenant Information',
                    style: TextStyle(
                      color: Color(0xFF5338F5),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tenant Avatar
                      const CircleAvatar(
                        radius: 36,
                        backgroundImage: NetworkImage('https://images.unsplash.com/photo-1500648767791-00dcc994a43e'),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'John Smith',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF14142B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.verified, color: Color(0xFF5338F5), size: 18),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: const [
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  '4.9',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Male, 22 years old\nSoftware Engineer',
                              style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.3),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.email_outlined, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'johnsmith@gmail.com',
                                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.phone_outlined, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 6),
                                Text(
                                  '+855 12 345 678',
                                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // 3. PROPERTY DETAILS CARD
            // -----------------------------------------------------------------
            _buildCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Banner with Overlay Title
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267',
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        height: 170,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Luxury Apartment',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Skyline View Penthouse',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Rent', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 2),
                                Row(
                                  children: const [
                                    Text(
                                      '\$350',
                                      style: TextStyle(
                                        color: Color(0xFF5338F5),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text('/mo', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: const [
                                Text('Location', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                SizedBox(height: 2),
                                Text(
                                  'Phnom Penh, Room A-503',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  'Floor 5th',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Facilities',
                          style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildFacilityItem(Icons.wifi, 'WiFi'),
                            _buildFacilityItem(Icons.local_parking, 'Parking'),
                            _buildFacilityItem(Icons.ac_unit, 'AC'),
                            _buildFacilityItem(Icons.kitchen, 'Kitchen'),
                            _buildFacilityItem(Icons.local_laundry_service, 'Laundry'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // 4. RENTAL DETAILS CARD
            // -----------------------------------------------------------------
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rental Details',
                    style: TextStyle(
                      color: Color(0xFF5338F5),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailPair('Tenants', '2 Persons'),
                      _buildDetailPair('Type', 'Monthly'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBE8FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Special Request',
                          style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '"Need parking space."',
                          style: TextStyle(
                            color: Color(0xFF14142B),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // 5. PAYMENT CARD
            // -----------------------------------------------------------------
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment',
                    style: TextStyle(
                      color: Color(0xFF5338F5),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildPaymentRow('Rent (1 Month)', '\$350.00'),
                  const SizedBox(height: 8),
                  _buildPaymentRow('Security Deposit', '\$350.00'),
                  const SizedBox(height: 8),
                  _buildPaymentRow('Service Fee', '\$10.00'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Method: ABA KHQR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 2),
                          Text('Status: Pending', style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text('Total Payment', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          SizedBox(height: 2),
                          Text(
                            '\$710.00',
                            style: TextStyle(
                              color: Color(0xFF5338F5),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // -----------------------------------------------------------------
            // 6. BOTTOM ACTION BUTTONS
            // -----------------------------------------------------------------
            if (status == 'PENDING')
              Row(
                children: [
                  // Reject Button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _onReject,
                        child: const Text(
                          'Reject',
                          style: TextStyle(
                            color: Color(0xFF14142B),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Approve Button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E5631), // Dark Green
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: _onApprove,
                        child: const Text(
                          'Approve Request',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- HELPER BUILDERS ---

  Widget _buildCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16.0),
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
      child: child,
    );
  }

  Widget _buildStatusBadge(String currentStatus) {
    Color bgColor;
    Color textColor;

    switch (currentStatus) {
      case 'APPROVED':
        bgColor = const Color(0xFFD1FADF);
        textColor = const Color(0xFF027A48);
        break;
      case 'REJECTED':
        bgColor = const Color(0xFFFDEEEE);
        textColor = const Color(0xFFE53935);
        break;
      default:
        bgColor = const Color(0xFFFDE8E1);
        textColor = const Color(0xFFB84832);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        currentStatus,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFacilityItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 22, color: const Color(0xFF14142B)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDetailPair(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF14142B),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String title, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}