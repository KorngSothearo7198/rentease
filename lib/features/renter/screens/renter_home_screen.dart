import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:rentease/features/renter/screens/profile_screen.dart';
import 'package:rentease/features/renter/screens/property_detail_screen.dart';
import 'package:rentease/features/renter/screens/search_screen.dart';
import 'bottom_nav_bar.dart';
import 'favorites_screen.dart';

class RenterHomeScreen extends StatefulWidget {
  const RenterHomeScreen({super.key});

  @override
  State<RenterHomeScreen> createState() => _RenterHomeScreenState();
}

class _RenterHomeScreenState extends State<RenterHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeFeedScreen(),
    const SearchScreen(),
    FavoritesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      body: _screens[_currentIndex],
      bottomNavigationBar: CapsuleBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

// ==================== MAIN HOME FEED ====================

class HomeFeedScreen extends StatelessWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1035),
              Color(0xFF2D1B69),
              // Color(0xFF4C1D95),
              // Color(0xFF6B46C1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ========== LOCATION HEADER ==========
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.18)),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFFFBBF24),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LOCATION',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white60,
                                  letterSpacing: 1.1,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'San Francisco, CA',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ========== SEARCH BAR ==========
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.18)),
                              ),
                              child: const TextField(
                                style: TextStyle(color: Colors.white, fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'Search houses, apartments...',
                                  hintStyle: TextStyle(color: Colors.white54, fontSize: 15),
                                  prefixIcon: Icon(Icons.search_rounded, color: Colors.white70),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 54,
                        width: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withOpacity(0.45),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.tune_rounded, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ========== CATEGORY CHIPS ==========
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: const [
                      _CategoryChip(label: 'All', isSelected: true),
                      _CategoryChip(label: 'House'),
                      _CategoryChip(label: 'Apartment'),
                      _CategoryChip(label: 'Villa'),
                      _CategoryChip(label: 'Studio'),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ========== FEATURED HOUSES ==========
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Featured Houses',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFBBF24),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'See all',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  height: 300,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: const [
                      _FeaturedPropertyCard(
                        imageUrl:
                        'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800&q=80',
                        title: 'The Grand Estate Villa',
                        location: 'Beverly Hills, CA',
                        price: 4500,
                        rating: 4.9,
                      ),
                      SizedBox(width: 16),
                      _FeaturedPropertyCard(
                        imageUrl:
                        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&q=80',
                        title: 'Skyview Penthouse',
                        location: 'Downtown SF',
                        price: 3200,
                        rating: 4.7,
                      ),
                      SizedBox(width: 16),
                      _FeaturedPropertyCard(
                        imageUrl:
                        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80',
                        title: 'Modern Hillside Home',
                        location: 'Pacific Heights',
                        price: 5100,
                        rating: 4.8,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ========== RECOMMENDED ==========
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Recommended for you',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const _RecommendedPropertyCard(
                  imageUrl:
                  'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800&q=80',
                  title: 'Cozy Minimalist Studio',
                  location: 'Mission District, SF',
                  price: 1800,
                  beds: 1,
                  baths: 1,
                ),
                const _RecommendedPropertyCard(
                  imageUrl:
                  'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&q=80',
                  title: 'Urban Brick Loft',
                  location: 'SoMa, SF',
                  price: 2400,
                  beds: 1,
                  baths: 1,
                  sqft: 850,
                ),
                const _RecommendedPropertyCard(
                  imageUrl:
                  'https://images.unsplash.com/photo-1605276374104-dee2a0ed3cd6?w=800&q=80',
                  title: 'Sunny Family House',
                  location: 'Sunset District, SF',
                  price: 3500,
                  beds: 3,
                  baths: 2,
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== REUSABLE WIDGETS ====================

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _CategoryChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFBBF24)
              : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFBBF24)
                : Colors.white.withOpacity(0.18),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1A1035) : Colors.white,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}

class _FeaturedPropertyCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String location;
  final int price;
  final double rating;

  const _FeaturedPropertyCard({
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.price,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PropertyDetailScreen(
              title: title,
              price: price.toString(),
              address: location,
              imageUrl: imageUrl,
            ),
          ),
        );
      },
      child: Container(
        width: 270,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white.withOpacity(0.1),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: Image.network(
                    imageUrl,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Rating badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.white.withOpacity(0.6)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '\$$price /mo',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFBBF24),
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

class _RecommendedPropertyCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String location;
  final int price;
  final int beds;
  final int baths;
  final int? sqft;

  const _RecommendedPropertyCard({
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.price,
    required this.beds,
    required this.baths,
    this.sqft,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    imageUrl,
                    width: 110,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _miniInfo(Icons.bed_rounded, '$beds'),
                          const SizedBox(width: 12),
                          _miniInfo(Icons.bathtub_outlined, '$baths'),
                          if (sqft != null) ...[
                            const SizedBox(width: 12),
                            _miniInfo(Icons.square_foot_rounded, '$sqft'),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$$price /mo',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFFFBBF24),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white60),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(fontSize: 12.5, color: Colors.white70),
        ),
      ],
    );
  }
}