import 'package:flutter/material.dart';
import 'package:rentease/features/renter/screens/property_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  FavoritesScreen({super.key});

  final List<Map<String, dynamic>> favorites = [
    {
      "title": "The Griffith Residences",
      "price": 3200,
      "address": "1420 N Vermont Ave, Los Angeles",
      "beds": 2,
      "baths": 2,
      "image": "https://photos.zolo.ca/ph01-1-market-street-toronto-C13448008-1-p.jpg?2026-06-15+16%3A06%3A56",
      // "isru": true
    },
    {
      "title": "Ocean Avenue Estates",
      "price": 6100,
      "address": "100 Ocean Ave, Santa Monica",
      "beds": 3,
      "baths": 2,
      "image": "https://photos.zolo.ca/ph01-1-market-street-toronto-C13448008-1-p.jpg?2026-06-15+16%3A06%3A56",
    },
    {
      "title": "Beverly Hills Modern Villa",
      "price": 8500,
      "address": "Beverly Hills, CA",
      "beds": 5,
      "baths": 4,
      "image": "https://photos.zolo.ca/ph01-1-market-street-toronto-C13448008-1-p.jpg?2026-06-15+16%3A06%3A56",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: favorites.isEmpty
          ? const Center(child: Text("No favorites yet"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PropertyDetailScreen(
                            title: item['title'],
                            price: item['price'].toString(),
                            address: item['address'],
                            imageUrl: item['image'],
                            // beds: item['beds'],
                            // baths: item['baths'],
                            // sqft: 1200,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.network(item['image'], height: 200, width: double.infinity, fit: BoxFit.cover),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text(item['address'], style: TextStyle(color: Colors.grey[600])),
                                    const SizedBox(height: 8),
                                    Text(
                                      '\$${item['price']}/mo',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6B46C1)),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.favorite, color: Colors.red),
                                    onPressed: () {},
                                  ),
                                  Text("${item['beds']}B • ${item['baths']}Ba"),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}