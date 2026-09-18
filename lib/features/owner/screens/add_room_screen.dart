import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/category_model.dart';
import '../../../models/property_model.dart';
import '../../../services/category_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/property_service.dart';
import '../../../services/subscription_service.dart';
import 'OwnerSubscriptionScreen.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({Key? key}) : super(key: key);

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _formKey = GlobalKey<FormState>();

  // Services
  final PropertyService propertyService = PropertyService();
  final CloudinaryService cloudinaryService = CloudinaryService();
  final CategoryService categoryService = CategoryService();
  final SubscriptionService subscriptionService = SubscriptionService();

  // State Variables
  File? selectedImage;
  bool isUploading = false;
  String? selectedCategory;

  // Controllers
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();

  int bedrooms = 1;
  double bathrooms = 1.0;
  String status = "Published";

  final Map<String, IconData> amenities = {
    "WiFi": Icons.wifi,
    "Parking": Icons.local_parking,
    "AC": Icons.ac_unit,
    "Pool": Icons.pool,
    "Kitchen": Icons.kitchen,
  };

  final List<String> selectedAmenities = [];

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null) return;

      setState(() {
        selectedImage = File(image.path);
      });
    } catch (e) {
      debugPrint("Image picker error: $e");
    }
  }

  Future<void> saveRoom() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a property image")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      setState(() => isUploading = true);

      // 1. CHECK SUBSCRIPTION GATEWAY
      final subCheck = await subscriptionService.canAddProperty(user.uid);

      if (!subCheck['canAdd']) {
        setState(() => isUploading = false);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(subCheck['reason']),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'UPGRADE',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OwnerSubscriptionScreen(),
                  ),
                );
              },
            ),
          ),
        );
        return;
      }

      // 2. Upload Image
      final imageUrl = await cloudinaryService.uploadImage(selectedImage!);
      if (imageUrl == null) {
        throw Exception("Image upload failed");
      }

      // 3. Build Property Model
      final property = Property(
        id: "",
        ownerId: user.uid,
        title: titleController.text.trim(),
        category: selectedCategory ?? "",
        price: double.tryParse(priceController.text.trim()) ?? 0,
        location: locationController.text.trim(),
        description: descriptionController.text.trim(),
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        imageUrl: imageUrl,
        amenities: selectedAmenities,
        status: status == "Published"
            ? PropertyStatus.published
            : PropertyStatus.draft,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      await propertyService.createProperty(property);

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Room created successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => isUploading = false);
      }
    }
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
                onTap: pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: selectedImage == null
                      ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 50,
                        color: Colors.purple,
                      ),
                      SizedBox(height: 8),
                      Text("Upload Property Photo"),
                    ],
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      selectedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
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
                    _buildInputField(
                      controller: titleController,
                      label: 'Property Title',
                      hint: 'e.g., Skyline View Penthouse',
                      icon: Icons.home_outlined,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildCategoryDropdown(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInputField(
                            controller: priceController,
                            label: 'Price (\$/mo)',
                            hint: '3200',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildInputField(
                      controller: locationController,
                      label: 'Location',
                      hint: 'e.g., Upper East Side, Manhattan, NY',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 16),

                    _buildInputField(
                      controller: descriptionController,
                      label: 'Description',
                      hint: 'Write a brief description...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCounter(
                          label: 'Bedrooms',
                          value: bedrooms,
                          onIncrement: () => setState(() => bedrooms++),
                          onDecrement: () {
                            if (bedrooms > 1) setState(() => bedrooms--);
                          },
                        ),
                        _buildCounter(
                          label: 'Bathrooms',
                          value: bathrooms,
                          onIncrement: () => setState(() => bathrooms += 0.5),
                          onDecrement: () {
                            if (bathrooms > 1.0) {
                              setState(() => bathrooms -= 0.5);
                            }
                          },
                          isDouble: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Listing Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: status,
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
                      items: ['Published', 'Draft'].map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => status = val!),
                    ),
                    const SizedBox(height: 20),

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
                      children: amenities.entries.map((entry) {
                        final isSelected =
                        selectedAmenities.contains(entry.key);
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
                                selectedAmenities.add(entry.key);
                              } else {
                                selectedAmenities.remove(entry.key);
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
                  onPressed: isUploading ? null : saveRoom,
                  child: isUploading
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text(
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

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        StreamBuilder<List<CategoryModel>>(
          stream: categoryService.getCategories(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final categories = snapshot.data ?? [];

            if (selectedCategory != null &&
                !categories.any((c) => c.name == selectedCategory)) {
              selectedCategory = null;
            }

            return DropdownButtonFormField<String>(
              value: selectedCategory,
              isExpanded: true,
              hint: Text(
                'Select Category',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              validator: (value) =>
              value == null || value.isEmpty ? 'Category required' : null,
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
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6200EE)),
                ),
              ),
              items: categories.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat.name,
                  child: Text(
                    cat.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedCategory = value);
              },
            );
          },
        ),
      ],
    );
  }

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