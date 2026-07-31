import 'package:flutter/material.dart';

class PaymentDetailScreen extends StatelessWidget {
  const PaymentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment Details',
          style: TextStyle(
            color: Color(0xFF6B46C1),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                'https://source.unsplash.com/random/100x100/?woman',
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Success Header
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Payment Successful',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Your rental payment has been confirmed.',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),

            const SizedBox(height: 28),

            // Merchant Info
            Text(
              'MERCHANT INFORMATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Rentify Inc.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '123 Tech Plaza, San Francisco, CA 94105',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const Text(
              'support@rentify.com',
              style: TextStyle(
                color: Color(0xFF6B46C1),
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 24),

            // Transaction Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction ID
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TRANSACTION ID',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '#RT-99201482',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.receipt_long, size: 18),
                        label: const Text('Official Receipt'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6B46C1),
                          side: const BorderSide(color: Color(0xFF6B46C1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),

                  // Date & Auth
                  Row(
                    children: [
                      Expanded(
                        child: _infoItem(
                          'DATE & TIME',
                          'Oct 24, 2023 • 14:32',
                        ),
                      ),
                      Expanded(
                        child: _infoItem(
                          'AUTH CODE',
                          'AUTH-882910',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Payment Method & Reference
                  Row(
                    children: [
                      Expanded(
                        child: _infoItem(
                          'PAYMENT METHOD',
                          'Visa •••• 4242',
                          icon: Icons.credit_card,
                        ),
                      ),
                      Expanded(
                        child: _infoItem(
                          'REFERENCE',
                          'REF-9920-X',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),

                  // Property
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          'https://photos.zolo.ca/ph01-1-market-street-toronto-C13448008-1-p.jpg?2026-06-15+16%3A06%3A56',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Skyline View Penthouse',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Monthly Rental Payment',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Process Log
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'PROCESS LOG',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),

            _processStep(
              title: 'Payment Completed',
              time: 'Oct 24, 14:32',
              isActive: true,
              isLast: false,
            ),
            _processStep(
              title: 'Bank Authorization',
              time: 'Oct 24, 14:31',
              isActive: false,
              isLast: false,
            ),
            _processStep(
              title: 'Payment Initiated',
              time: 'Oct 24, 14:30',
              isActive: false,
              isLast: true,
            ),

            const SizedBox(height: 28),

            // Billing Summary
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'BILLING SUMMARY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),

            _billingRow('Monthly Rent', '\$3,200.00'),
            _billingRow('Service Fee', '\$45.00'),
            _billingRow('Processing Tax (1.5%)', '\$48.67'),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Paid',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.green, size: 22),
                    const SizedBox(width: 6),
                    Text(
                      '\$3,293.67',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B46C1),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Buttons
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: const Text(
                  'Download PDF Receipt',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.headset_mic),
                label: const Text(
                  'Contact Support',
                  style: TextStyle(fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  'Secured by Rentify Payment Systems',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 6),
            ],
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _processStep({
    required String title,
    required String time,
    required bool isActive,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF6B46C1) : Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            Text(
              time,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _billingRow(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}