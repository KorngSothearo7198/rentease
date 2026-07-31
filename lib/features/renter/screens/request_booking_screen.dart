import 'package:flutter/material.dart';
// import "package:intl/intl.dart";

class RequestBookingScreen extends StatefulWidget {
  const RequestBookingScreen({super.key});

  @override
  State<RequestBookingScreen> createState() => _RequestBookingScreenState();
}

class _RequestBookingScreenState extends State<RequestBookingScreen> {
  DateTime? startDate = DateTime(2024, 10, 12);
  DateTime? endDate = DateTime(2024, 10, 17);
  int guests = 2;
  int infants = 1;

  // Property Info
  final String propertyName = "Azure Bay Residence";
  final String location = "Antibes, France";
  final double pricePerNight = 450.0;

  int get numberOfNights {
    if (startDate == null || endDate == null) return 0;
    return endDate!.difference(startDate!).inDays;
  }

  double get subtotal => pricePerNight * numberOfNights;
  double get cleaningFee => 120.0;
  double get serviceFee => 315.0;
  double get taxes => 45.0;
  double get total => subtotal + cleaningFee + serviceFee + taxes;

  Future<void> _selectDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (startDate ?? DateTime.now()) : (endDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
          if (endDate != null && endDate!.isBefore(startDate!)) {
            endDate = startDate!.add(const Duration(days: 5));
          }
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text('Request Booking'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://cdn.sanity.io/images/k55su7ch/production2/d9e35a73891d43ccb0bc665bf2e0d5d9d6f1ea2b-4200x2363.jpg?w=1920&q=75&auto=format',
                        width: 100,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('LUXURY VILLA', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(propertyName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 18),
                              Text(' 4.92 • $location'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Your Trip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Your Trip', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text('Edit')),
              ],
            ),

            const SizedBox(height: 12),

            // Dates
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _dateTile(
                            title: "START DATE",
                            date: startDate,
                            onTap: () => _selectDate(true),
                          ),
                        ),
                        Expanded(
                          child: _dateTile(
                            title: "END DATE",
                            date: endDate,
                            onTap: () => _selectDate(false),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.people),
                      title: const Text('GUESTS'),
                      subtitle: Text('$guests guests, $infants infant${infants > 1 ? 's' : ''}'),
                      trailing: const Icon(Icons.arrow_drop_down),
                      onTap: () {
                        // TODO: Open guest selector dialog
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Price Details
            const Text('Price Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _priceRow('\$$pricePerNight × $numberOfNights nights', subtotal),
                    _priceRow('Cleaning fee', cleaningFee),
                    _priceRow('LuxeRent service fee', serviceFee),
                    _priceRow('Taxes', taxes),
                    const Divider(),
                    _priceRow('Total (USD)', total, isTotal: true),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Host Info
            const Text('Meet your host, Sarah', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Text('Host since 2019', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),

            // Message to host
            const Text('Introduce yourself'),
            const SizedBox(height: 8),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Tell Sarah about your trip and who's coming with you...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),

            // Cancellation Policy
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Free cancellation for 48 hours\nAfter that, cancel before Oct 5 for a full refund, minus the service fee.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Agreement & Button
            const Text(
              'By selecting the button below, I agree to the House Rules and Cancellation Policy.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Send booking request logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking request sent successfully!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  'Send Booking Request →',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTile({required String title, DateTime? date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          // Text(
          //   // date != null ? DateFormat('MMM dd, yyyy').format(date) : 'Select Date',
          //   // style: const TextStyle(fontWeight: FontWeight.w600),
          // ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }
}