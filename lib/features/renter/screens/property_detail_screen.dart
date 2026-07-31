// import 'package:flutter/material.dart';
// import 'package:rentease/features/renter/screens/chat_list_screen.dart';
// import 'package:rentease/features/renter/screens/request_booking_screen.dart';
//
// import 'chat_detail_screen.dart';
//
// class PropertyDetailScreen extends StatelessWidget {
//   final String title;
//   final String price;
//   final String address;
//   final String imageUrl;
//   // final int beds;
//   // final int baths;
//   // final int sqft;
//   final String description;
//
//   const PropertyDetailScreen({
//     super.key,
//     required this.title,
//     required this.price,
//     required this.address,
//     required this.imageUrl,
//     // required this.beds,
//     // required this.baths,
//     // required this.sqft,
//     this.description = "Luxurious modern apartment with stunning city views, premium finishes, and world-class amenities.",
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           // Hero Image with Back Button
//           SliverAppBar(
//             expandedHeight: 380,
//             pinned: true,
//             flexibleSpace: FlexibleSpaceBar(
//               background: Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   Image.network(
//                     imageUrl,
//                     fit: BoxFit.cover,
//                   ),
//                   Container(
//                     decoration: const BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topCenter,
//                         end: Alignment.bottomCenter,
//                         colors: [Colors.transparent, Colors.black45],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             leading: IconButton(
//               icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//               onPressed: () => Navigator.pop(context),
//             ),
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.favorite_border, color: Colors.white),
//                 onPressed: () {},
//               ),
//             ],
//           ),
//
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Title & Price
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: Text(
//                           title,
//                           style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       Text(
//                         '\$$price/mo',
//                         style: const TextStyle(
//                           fontSize: 26,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF6B46C1),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 8),
//                   Text(address, style: const TextStyle(fontSize: 16, color: Colors.grey)),
//
//                   const SizedBox(height: 20),
//
//                   // Specs
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceAround,
//                     // children: [
//                     //   _buildSpecItem(Icons.king_bed, '$beds Bed'),
//                     //   _buildSpecItem(Icons.bathtub, '$baths Bath'),
//                     //   _buildSpecItem(Icons.square_foot, '$sqft sqft'),
//                     // ],
//                     children: [
//                       _buildSpecItem(Icons.king_bed, ' Bed'),
//                       _buildSpecItem(Icons.bathtub, ' Bath'),
//                       _buildSpecItem(Icons.square_foot, ' sqft'),
//                     ],
//                   ),
//
//                   const Divider(height: 40),
//
//                   // Description
//                   const Text(
//                     'Description',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     description,
//                     style: const TextStyle(fontSize: 16, height: 1.6),
//                   ),
//
//                   const SizedBox(height: 30),
//
//                   // Features
//                   const Text(
//                     'Features',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 12),
//                   Wrap(
//                     spacing: 10,
//                     runSpacing: 10,
//                     children: const [
//                       FeatureChip('Balcony'),
//                       FeatureChip('City View'),
//                       FeatureChip('Parking'),
//                       FeatureChip('Gym'),
//                       FeatureChip('Pool'),
//                       FeatureChip('24/7 Security'),
//                     ],
//                   ),
//
//                   const SizedBox(height: 40),
//
//                   // Action Buttons
//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton(
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (_) =>  ChatListScreen()),
//                             );
//                           },
//                           style: OutlinedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                           ),
//                           child: const Text('Contact Owner'),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (_) => const RequestBookingScreen()),
//                             );
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF6B46C1),
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                           ),
//                           child: const Text('Book Now' , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold ),),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 30),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSpecItem(IconData icon, String text) {
//     return Column(
//       children: [
//         Icon(icon, color: const Color(0xFF6B46C1), size: 28),
//         const SizedBox(height: 6),
//         Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
//       ],
//     );
//   }
// }
//
// class FeatureChip extends StatelessWidget {
//   final String label;
//   const FeatureChip(this.label, {super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Chip(
//       label: Text(label),
//       backgroundColor: const Color(0xFFF8F5FF),
//       side: const BorderSide(color: Color(0xFF6B46C1)),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';
import 'chat_list_screen.dart';
import 'request_booking_screen.dart';
// import 'chat_screen.dart';

class PropertyDetailScreen extends StatelessWidget {
  final String title;
  final String price;
  final String address;
  final String imageUrl;
  final int beds;
  final int baths;
  final int sqft;
  final String description;

  const PropertyDetailScreen({
    super.key,
    this.title = "Skyline View Penthouse",
    this.price = "3200",
    this.address = "420 Madison Avenue, New York",
    this.imageUrl = "https://source.unsplash.com/random/800x600/?modernkitchen",
    this.beds = 2,
    this.baths = 2,
    this.sqft = 1450,
    this.description =
    "Experience unparalleled urban living in this stunning penthouse. Featuring floor-to-ceiling windows with panoramic city views, high-end finishes throughout, and a private terrace perfect for sunset relaxation. Designed for the modern professional seeking both comfort and style.",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: Stack(
        children: [
          // Scrollable Content
          CustomScrollView(
            slivers: [
              // Hero Image
              SliverAppBar(
                expandedHeight: 340,
                pinned: true,
                backgroundColor: Colors.white,
                leading: IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.arrow_back, color: Colors.black),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.share, color: Colors.black),
                    ),
                    onPressed: () {},
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                      ),
                      // Page indicators
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: index == 0 ? 20 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: index == 0 ? Colors.white : Colors.white54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag + Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'LUXURY APARTMENT',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            '\$$price /mo',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B46C1),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 18, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            address,
                            style: TextStyle(color: Colors.grey[600], fontSize: 15),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.grey[700],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Facilities
                      const Text(
                        'Facilities',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          _FacilityItem(icon: Icons.wifi, label: 'WiFi'),
                          _FacilityItem(icon: Icons.local_parking, label: 'Parking'),
                          _FacilityItem(icon: Icons.ac_unit, label: 'AC'),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Owner Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 26,
                              backgroundImage: NetworkImage(
                                'https://static.wikia.nocookie.net/oggyandthecockroaches/images/d/d9/OGGY_PERSO.png/revision/latest?cb=20181112161051',
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sarah Jenkins',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Property Owner',
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            // Call Button
                            CircleAvatar(
                              backgroundColor: const Color(0xFF6B46C1).withOpacity(0.1),
                              child: IconButton(
                                icon: const Icon(Icons.phone, color: Color(0xFF6B46C1)),
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Message Button
                            CircleAvatar(
                              backgroundColor: const Color(0xFF6B46C1).withOpacity(0.1),
                              child: IconButton(
                                icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF6B46C1)),
                                onPressed: () {
                                  Navigator.push(
                              context,
                              // MaterialPageRoute(builder: (_) =>  ChatListScreen()),
                                 MaterialPageRoute(builder: (_) =>  ChaerDetailScreen()),
                            );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Location
                      const Text(
                        'Location',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.grey[300],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.location_on,
                            size: 50,
                            color: Color(0xFF6B46C1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Favorite
                  Container(
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Book Now
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RequestBookingScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B46C1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Book Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Facility Item Widget
class _FacilityItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FacilityItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF6B46C1), size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}