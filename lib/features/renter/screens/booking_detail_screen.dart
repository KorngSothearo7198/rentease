import 'package:flutter/material.dart';
import 'package:rentease/features/renter/screens/chat_list_screen.dart';

class BookingDetailScreen extends StatelessWidget {
  final String title;
  final String date;
  final String status;
  final int price;
  final String address;
  // final String imageUrl;

  const BookingDetailScreen({
    super.key,
    required this.title,
    required this.date,
    required this.status,
    required this.price,
    required this.address,
    // required this imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                // imageUrl,
                'https://photos.zolo.ca/ph01-1-market-street-toronto-C13448008-1-p.jpg?2026-06-15+16%3A06%3A56',
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 60),
                    ),
                  );
                },
              )
            ),

            const SizedBox(height: 20),

            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(address, style: const TextStyle(color: Colors.grey, fontSize: 16)),

            const SizedBox(height: 20),

            Row(
              children: [
                _infoChip(Icons.calendar_today, date),
                const SizedBox(width: 12),
                _infoChip(Icons.attach_money, '\$$price /month'),
              ],
            ),

            const SizedBox(height: 30),

            const Text("Booking Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _detailRow("Status", status, status == "Active" ? Colors.green : Colors.blue),
            _detailRow("Check-in", "July 28, 2026"),
            _detailRow("Check-out", "August 15, 2026"),
            _detailRow("Guests", "2 Adults"),
            _detailRow("Total Amount", "\$${price * 2}"),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatListScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B46C1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("Contact Host", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF6B46C1)),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, [Color? valueColor, bool isBold = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}