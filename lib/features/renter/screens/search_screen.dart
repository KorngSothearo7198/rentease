import 'package:flutter/material.dart';
import 'package:rentease/features/renter/screens/notification_screen.dart';
import 'package:rentease/features/renter/screens/property_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String searchQuery = "Apartments in Los Angeles";
  String selectedFilter = "All";

  // Defined Color Palette for Consistency
  static const Color primaryBg = Color(0xFF2D1B69);        // Main Deep Purple Background
  static const Color cardBg = Color(0xFF1E1245);           // Slightly Darker Card Background
  static const Color accentPurple = Color(0xFFFBBF24);     // Vibrant Purple Accent for Icons & Price
  static const Color textMuted = Color(0xFFB3A8D1);         // High Contrast Muted Text

  final List<Map<String, dynamic>> properties = [
    {
      "title": "The Griffith Residences",
      "price": 3200,
      "address": "1420 N Vermont Ave, Los Angeles, CA 90027",
      "beds": 2,
      "baths": 2,
      "sqft": 1150,
      "image": "https://photos.zolo.ca/ph01-1-market-street-toronto-C13448008-1-p.jpg?2026-06-15+16%3A06%3A56",
      "tag": "LIVING GREEN",
    },
    {
      "title": "Arts District Lofts",
      "price": 4500,
      "address": "800 E 3rd St, Los Angeles, CA 90013",
      "beds": 1,
      "baths": 1.5,
      "sqft": 980,
      "image": "https://photos.zolo.ca/ph01-1-market-street-toronto-C13448008-1-p.jpg?2026-06-15+16%3A06%3A56",
      "tag": "ESTATE GOLD",
    },
    {
      "title": "Ocean Avenue Estates",
      "price": 6100,
      "address": "100 Ocean Ave, Santa Monica, CA 90402",
      "beds": 3,
      "baths": 2,
      "sqft": 1600,
      "image": "https://photos.zolo.ca/ph01-1-market-street-toronto-C13448008-1-p.jpg?2026-06-15+16%3A06%3A56",
      "tag": "",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: accentPurple),
                  const SizedBox(width: 8),
                  const Text(
                    'Los Angeles, CA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search houses, apartments...',
                    hintStyle: const TextStyle(color: textMuted),
                    prefixIcon: const Icon(Icons.search, color: textMuted),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.filter_list, color: accentPurple),
                      onPressed: () {},
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onChanged: (value) {},
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Filter Chips
            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildFilterChip("All", true),
                  _buildFilterChip("Price"),
                  _buildFilterChip("2+ Beds"),
                  _buildFilterChip("Apartments"),
                  _buildFilterChip("More Filters"),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "124 Results found",
                  style: TextStyle(fontSize: 16, color: textMuted),
                ),
              ),
            ),

            // Results List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: properties.length,
                itemBuilder: (context, index) {
                  final prop = properties[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PropertyDetailScreen(
                            title: prop['title'],
                            price: prop['price'].toString(),
                            address: prop['address'],
                            imageUrl: prop['image'],
                          ),
                        ),
                      );
                    },
                    child: _buildPropertyCard(prop),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, [bool isSelected = false]) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (val) {},
        backgroundColor: cardBg,
        selectedColor: accentPurple,
        side: BorderSide(
          color: isSelected ? accentPurple : Colors.white.withOpacity(0.15),
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> prop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  prop['image'],
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              if (prop['tag'] != null && prop['tag'] != "")
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981), // Vibrant Emerald Green
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      prop['tag'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 12,
                right: 12,
                child: CircleAvatar(
                  backgroundColor: cardBg.withOpacity(0.8),
                  radius: 18,
                  child: const Icon(Icons.favorite_border, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        prop['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      '\$${prop['price']}/mo',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: accentPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  prop['address'],
                  style: const TextStyle(color: textMuted, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.king_bed, size: 18, color: accentPurple),
                    Text(
                      ' ${prop['beds']} Bed  ',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const Icon(Icons.bathtub, size: 18, color: accentPurple),
                    Text(
                      ' ${prop['baths']} Bath  ',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const Icon(Icons.square_foot, size: 18, color: accentPurple),
                    Text(
                      ' ${prop['sqft']} sqft',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}