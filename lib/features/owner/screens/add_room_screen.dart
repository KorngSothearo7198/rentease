import 'package:flutter/material.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({Key? key}) : super(key: key);

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _bedrooms = 1;
  double _bathrooms = 1.0;
  String _status = 'Published'; // 'Published' or 'Draft'

  // Selected Amenities
  final Map<String, IconData> _amenityOptions = {
    'Wi-Fi': Icons.wifi,
    'Parking': Icons.local_parking,
    'AC': Icons.ac_unit,
    'Pool': Icons.pool,
    'Kitchen': Icons.kitchen,
    'Laundry': Icons.dry_cleaning,
  };
  final List<String> _selectedAmenities = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F2FE), // Matching background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A00E0)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add New House',
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
              // IMAGE UPLOAD PLACEHOLDER
              // ---------------------------------------------------------------
              GestureDetector(
                onTap: () {
                  // Implement image picking logic
                },
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF6200EE).withOpacity(0.3), width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.cloud_upload_outlined, size: 48, color: Color(0xFF6200EE)),
                      SizedBox(height: 8),
                      Text(
                        'Upload Property Photo',
                        style: TextStyle(
                          color: Color(0xFF6200EE),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'PNG or JPG up to 10MB',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ---------------------------------------------------------------
              // FORM FIELDS CONTAINER
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
              // SAVE BUTTON
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
                      // Save action logic here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Room added successfully!')),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    'Save Room Listing',
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

  // Input Field Helper
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

  // Counter Control Helper
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