import 'package:flutter/material.dart';
import 'package:rentease/features/renter/screens/payment_detail_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  String selectedFilter = "This Month";

  final List<Map<String, dynamic>> payments = [
    {
      "title": "Skyline Penthouse",
      "date": "Oct 12 - Oct 15, 2023",
      "amount": 2450.00,
      "status": "PAID",
      "image": "https://photos.zolo.ca/ph01-1-market-street-toronto-C13448008-1-p.jpg?2026-06-15+16%3A06%3A56",
    },
    {
      "title": "The Emerald Estate",
      "date": "Oct 01, 2023",
      "amount": 4200.00,
      "status": "PAID",
      "image": "https://photos.zolo.ca/ph01-1-market-street-toronto-C13448008-1-p.jpg?2026-06-15+16%3A06%3A56",
    },
    {
      "title": "Urban Brick Studio",
      "date": "Sep 24, 2023",
      "amount": 1850.00,
      "status": "REFUNDED",
      "image": "https://photos.zolo.ca/ph01-1-market-street-toronto-C13448008-1-p.jpg?2026-06-15+16%3A06%3A56",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // title: const Text(
        //   'Payment',
        //   style: TextStyle(
        //     color: Color(0xFF6B46C1),
        //     fontWeight: FontWeight.bold,
        //   ),
        // ),
        // centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D1B69)), // Deep purple for light bg
          onPressed: () => Navigator.pop(context),
        ),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Payment History',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Filter Chips
          SizedBox(
            height: 45,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _filterChip("This Month"),
                _filterChip("Last 3 Months"),
                _filterChip("Year"),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Payment List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return _paymentCard(payment);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF6B46C1),
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        onSelected: (_) {
          setState(() => selectedFilter = label);
        },
      ),
    );
  }



  Widget _paymentCard(Map<String, dynamic> payment) {
    final isRefunded = payment['status'] == 'REFUNDED';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PaymentDetailScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                payment['image'],
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          payment['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isRefunded
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          payment['status'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isRefunded
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    payment['date'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${payment['amount'].toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isRefunded
                          ? Colors.grey
                          : const Color(0xFF6B46C1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}