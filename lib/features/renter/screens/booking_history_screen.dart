import 'package:flutter/material.dart';
import 'booking_detail_screen.dart';   // ← New

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text('Booking History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Active Bookings",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _buildBookingCard(
            context,
            title: "The Griffith Residences",
            date: "Jul 28 - Aug 15, 2026",
            status: "Active",
            price: 3200,
            address: "1420 N Vermont Ave, Los Angeles, CA",
            color: Colors.green,
          ),

          const SizedBox(height: 24),
          const Text(
            "Past Bookings",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _buildBookingCard(
            context,
            title: "Ocean Avenue Estates",
            date: "Jun 10 - Jun 25, 2026",
            status: "Completed",
            price: 6100,
            address: "100 Ocean Ave, Santa Monica, CA",
            color: Colors.blue,
          ),

          _buildBookingCard(
            context,
            title: "Arts District Lofts",
            date: "May 5 - May 20, 2026",
            status: "Completed",
            price: 4500,
            address: "800 E 3rd St, Los Angeles, CA",
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(
      BuildContext context, {
        required String title,
        required String date,
        required String status,
        required int price,
        required String address,
        required Color color,
      }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingDetailScreen(
                title: title,
                date: date,
                status: status,
                price: price,
                address: address,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: color, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(address, style: const TextStyle(color: Colors.grey)),
              Text(date, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$$price /mo',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "View Details →",
                    style: TextStyle(color: Color(0xFF6B46C1), fontWeight: FontWeight.w600),
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