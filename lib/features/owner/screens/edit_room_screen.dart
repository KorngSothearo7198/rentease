import 'package:flutter/material.dart';

// Assuming Property model from previous screen
import '../../../models/property_model.dart';

class EditRoomScreen extends StatefulWidget {
  final Property property;

  const EditRoomScreen({super.key, required this.property});

  @override
  State<EditRoomScreen> createState() => _EditRoomScreenState();
}

class _EditRoomScreenState extends State<EditRoomScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;

  late int _bedrooms;
  late double _bathrooms;
  late String _status;
  late List<String> _selectedAmenities;

  // Amenity Options Mapping
  final Map<String, IconData> _amenityOptions = {
    'Wi-Fi': Icons.wifi,
    'Parking': Icons.local_parking,
    'AC': Icons.ac_unit,
    'Pool': Icons.pool,
    'Kitchen': Icons.kitchen,
    'Laundry': Icons.dry_cleaning,
  };

  @override
  void initState() {
    super.initState();
    // ---------------------------------------------------------------
    // PRE-FILL FORM WITH EXISTING PROPERTY DATA
    // ---------------------------------------------------------------
    _titleController = TextEditingController(text: widget.property.title);
    _categoryController = TextEditingController(text: widget.property.category);
    _priceController = TextEditingController(text: widget.property.price.toInt().toString());
    _locationController = TextEditingController(text: widget.property.location);
    _descriptionController = TextEditingController(text: widget.property.description);

    _bedrooms = widget.property.bedrooms;
    _bathrooms = widget.property.bathrooms;
    _status = widget.property.status == PropertyStatus.published ? 'Published' : 'Draft';

    // Map existing icon list back to amenity names
    _selectedAmenities = [];
    if (widget.property.amenities.contains(Icons.wifi)) _selectedAmenities.add('Wi-Fi');
    if (widget.property.amenities.contains(Icons.local_parking)) _selectedAmenities.add('Parking');
    if (widget.property.amenities.contains(Icons.ac_unit)) _selectedAmenities.add('AC');
    if (widget.property.amenities.contains(Icons.pool)) _selectedAmenities.add('Pool');
    if (widget.property.amenities.contains(Icons.kitchen)) _selectedAmenities.add('Kitchen');
    if (widget.property.amenities.contains(Icons.dry_cleaning)) _selectedAmenities.add('Laundry');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F2FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A00E0)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Property',
          style: TextStyle(
            color: Color(0xFF4A00E0),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------------------------
              // IMAGE PREVIEW & CHANGE OVERLAY
              // ---------------------------------------------------------------
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.property.imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          // Trigger image change/upload dialog
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt_outlined, color: Colors.white, size: 36),
                            SizedBox(height: 6),
                            Text(
                              'Change Photo',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ---------------------------------------------------------------
              // FORM FIELDS
              // ---------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(16.0),
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
                    // Title
                    _buildInputField(
                      controller: _titleController,
                      label: 'Property Title',
                      hint: 'e.g., Skyline View Penthouse',
                      icon: Icons.home_outlined,
                    ),
                    const SizedBox(height: 16),

                    // Category & Price Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            controller: _categoryController,
                            label: 'Category',
                            hint: 'e.g., LUXURY APARTMENT',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInputField(
                            controller: _priceController,
                            label: 'Price (\$/mo)',
                            hint: '3200',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Location
                    _buildInputField(
                      controller: _locationController,
                      label: 'Location',
                      hint: 'e.g., Upper East Side, Manhattan, NY',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildInputField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Write a brief description...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    // Bedrooms & Bathrooms Counters
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCounter(
                          label: 'Bedrooms',
                          value: _bedrooms,
                          onIncrement: () => setState(() => _bedrooms++),
                          onDecrement: () {
                            if (_bedrooms > 1) setState(() => _bedrooms--);
                          },
                        ),
                        _buildCounter(
                          label: 'Bathrooms',
                          value: _bathrooms,
                          onIncrement: () => setState(() => _bathrooms += 0.5),
                          onDecrement: () {
                            if (_bathrooms > 1.0) setState(() => _bathrooms -= 0.5);
                          },
                          isDouble: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Status Dropdown
                    const Text(
                      'Listing Status',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      items: ['Published', 'Draft'].map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _status = val!),
                    ),
                    const SizedBox(height: 20),

                    // Amenities Selection
                    const Text(
                      'Select Amenities',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _amenityOptions.entries.map((entry) {
                        final isSelected = _selectedAmenities.contains(entry.key);
                        return FilterChip(
                          avatar: Icon(
                            entry.value,
                            size: 16,
                            color: isSelected ? Colors.white : const Color(0xFF6200EE),
                          ),
                          label: Text(entry.key),
                          selected: isSelected,
                          selectedColor: const Color(0xFF6200EE),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAmenities.add(entry.key);
                              } else {
                                _selectedAmenities.remove(entry.key);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ---------------------------------------------------------------
              // UPDATE BUTTON
              // ---------------------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6200EE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Perform save/update operation
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Listing updated successfully!')),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    'Update Room Listing',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Input Helper Widget
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: (value) =>
          value == null || value.isEmpty ? 'Field required' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF6200EE), size: 20) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6200EE)),
            ),
          ),
        ),
      ],
    );
  }

  // Counter Control Widget
  Widget _buildCounter({
    required String label,
    required dynamic value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    bool isDouble = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 18),
                onPressed: onDecrement,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  isDouble ? value.toString().replaceAll('.0', '') : value.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: onIncrement,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}