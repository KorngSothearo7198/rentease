import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Assuming Property model from previous screen
import '../../../models/property_model.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/property_service.dart';

class EditRoomScreen extends StatefulWidget {
  final Property property;

  const EditRoomScreen({super.key, required this.property});

  @override
  State<EditRoomScreen> createState() => _EditRoomScreenState();
}

class _EditRoomScreenState extends State<EditRoomScreen> {
  final _formKey = GlobalKey<FormState>();

  File? selectedImage;

  bool isUploadingImage = false;

  final CloudinaryService cloudinaryService = CloudinaryService();

  final PropertyService propertyService = PropertyService();

  // edit or changes image
  Future<void> changePhoto() async {
    final picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) {
        return;
      }

      setState(() {
        selectedImage = File(image.path);
      });

      await uploadNewImage();
    } catch (e) {
      print("Pick image error: $e");
    }
  }

  // upload image
  Future<void> uploadNewImage() async {
    if (selectedImage == null) {
      return;
    }

    setState(() {
      isUploadingImage = true;
    });

    try {
      final imageUrl = await cloudinaryService.uploadImage(selectedImage!);

      if (imageUrl == null) {
        throw Exception("Upload failed");
      }

      await propertyService.updateProperty(widget.property.id, {
        "imageUrl": imageUrl,
      });

      setState(() {
        widget.property.imageUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Photo updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() {
        isUploadingImage = false;
      });
    }
  }

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
    _priceController = TextEditingController(
      text: widget.property.price.toInt().toString(),
    );
    _locationController = TextEditingController(text: widget.property.location);
    _descriptionController = TextEditingController(
      text: widget.property.description,
    );

    _bedrooms = widget.property.bedrooms;
    _bathrooms = widget.property.bathrooms;
    _status = widget.property.status == PropertyStatus.published
        ? 'Published'
        : 'Draft';

    // Map existing icon list back to amenity names
    _selectedAmenities = List<String>.from(widget.property.amenities);
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
                    child: selectedImage != null
                        ? Image.file(
                            selectedImage!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
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

                        onTap: changePhoto, // select Changes Image

                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isUploadingImage)
                              const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            else
                              const Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white,
                                size: 36,
                              ),
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
                            if (_bathrooms > 1.0)
                              setState(() => _bathrooms -= 0.5);
                          },
                          isDouble: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Status Dropdown
                    const Text(
                      'Listing Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _amenityOptions.entries.map((entry) {
                        final isSelected = _selectedAmenities.contains(
                          entry.key,
                        );
                        return FilterChip(
                          avatar: Icon(
                            entry.value,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF6200EE),
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
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }

                    await propertyService.updateProperty(widget.property.id, {
                      "title": _titleController.text.trim(),
                      "category": _categoryController.text.trim(),
                      "price": double.parse(_priceController.text),
                      "location": _locationController.text.trim(),
                      "description": _descriptionController.text.trim(),
                      "bedrooms": _bedrooms,
                      "bathrooms": _bathrooms,
                      "status": _status == "Published" ? "published" : "draft",
                      "amenities": _selectedAmenities,
                    });

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Room updated successfully"),
                      ),
                    );

                    Navigator.pop(context);
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
            prefixIcon: icon != null
                ? Icon(icon, color: const Color(0xFF6200EE), size: 20)
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
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
                  isDouble
                      ? value.toString().replaceAll('.0', '')
                      : value.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
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
