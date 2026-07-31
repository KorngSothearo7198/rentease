import 'package:flutter/material.dart';

import '../../../models/property_model.dart';
import 'add_room_screen.dart';
import 'edit_room_screen.dart';

// -----------------------------------------------------------------------------
// MAIN SCREEN
// -----------------------------------------------------------------------------
class ManageHousesScreen extends StatefulWidget {
  const ManageHousesScreen({super.key});

  @override
  State<ManageHousesScreen> createState() => _ManageHousesScreenState();
}

class _ManageHousesScreenState extends State<ManageHousesScreen> {
  // Sample Data
  List<Property> properties = [
    Property(
      id: '1',
      title: 'Skyline View Penthouse',
      category: 'LUXURY APARTMENT',
      price: 3200,
      location: 'Upper East Side, Manhattan, NY',
      description:
      'Experience unparalleled luxury with breathtaking panoramic views of the ci...',
      bedrooms: 3,
      bathrooms: 2,
      imageUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688',
      status: PropertyStatus.published,
      listedDate: 'Oct 12, 2023',
      lastUpdated: '2 days ago',
      amenities: [
        Icons.wifi,
        Icons.local_parking,
        Icons.ac_unit,
        Icons.pool,
      ],
    ),
    Property(
      id: '2',
      title: 'SoHo Industrial Loft',
      category: 'MINIMALIST LOFT',
      price: 4500,
      location: 'SoHo District, New York, NY',
      description:
      'Spacious open-concept loft with authentic industrial features and high...',
      bedrooms: 1,
      bathrooms: 1.5,
      imageUrl: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2',
      status: PropertyStatus.draft,
      listedDate: 'Nov 05, 2023',
      lastUpdated: '5 hours ago',
      amenities: [
        Icons.wifi,
        Icons.kitchen,
        Icons.dry_cleaning,
      ],
    ),
  ];

  // Navigate to Edit Screen & handle updated property data
  void _onEdit(Property property) async {
    final updatedProperty = await Navigator.push<Property>(
      context,
      MaterialPageRoute(
        builder: (context) => EditRoomScreen(property: property),
      ),
    );

    if (updatedProperty != null) {
      setState(() {
        final index = properties.indexWhere((p) => p.id == updatedProperty.id);
        if (index != -1) {
          properties[index] = updatedProperty;
        }
      });
    }
  }

  // Navigate to Add Screen & handle newly created property data
  void _onAdd() async {
    final newProperty = await Navigator.push<Property>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddRoomScreen(),
      ),
    );

    if (newProperty != null) {
      setState(() {
        properties.add(newProperty);
      });
    }
  }

  // Delete Action Confirmation
  void _onDelete(Property property) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Are you sure you want to delete "${property.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                properties.removeWhere((item) => item.id == property.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Listing deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F2FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFA77BFF)), // Lightened purple for dark theme contrast
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage My\nRoom',
          style: TextStyle(
            color: Color(0xFF4A00E0),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF6200EE),
              radius: 20,
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                onPressed: _onAdd,
              ),
            ),
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];
          return PropertyCard(
            property: property,
            onEdit: () => _onEdit(property),
            onDelete: () => _onDelete(property),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PROPERTY CARD WIDGET
// -----------------------------------------------------------------------------
class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PropertyCard({
    Key? key,
    required this.property,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isPublished = property.status == PropertyStatus.published;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE HEADER SECTION WITH BADGES AND ACTIONS
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  property.imageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              // Status Badge (Top-Left)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isPublished ? Colors.green : Colors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isPublished ? 'Published' : 'Draft',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Action Buttons (Top-Right)
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      color: const Color(0xFF6200EE),
                      onTap: onEdit,
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      color: Colors.red,
                      onTap: onDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // CONTENT SECTION
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Tag & Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      property.category,
                      style: const TextStyle(
                        color: Color(0xFF6200EE),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '\$${property.price.toInt()}',
                            style: const TextStyle(
                              color: Color(0xFF6200EE),
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          const TextSpan(
                            text: '/mo',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Title
                Text(
                  property.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Color(0xFF6200EE), size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.location,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  property.description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Bedrooms & Bathrooms
                Row(
                  children: [
                    const Icon(Icons.king_bed_outlined, color: Color(0xFF6200EE), size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '${property.bedrooms} Bedrooms',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.bathtub_outlined, color: Color(0xFF6200EE), size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '${property.bathrooms.toString().replaceAll('.0', '')} Bathrooms',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Amenities List
                Row(
                  children: property.amenities
                      .map((icon) => Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Icon(icon, color: Colors.grey[700], size: 20),
                  ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Footer Dates
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Listed on ${property.listedDate}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                    Text(
                      'Last updated ${property.lastUpdated}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
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

  // Helper method for circular action buttons
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
      ),
    );
  }
}