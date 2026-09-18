import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/user_model.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final UserService _userService = UserService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _occupationController;
  late TextEditingController _addressController;
  late TextEditingController _bioController;

  String? _profileImage;
  File? _selectedImage;

  bool _isSaving = false;
  bool _isUploadingImage = false;

  static const Color _darkPurple = Color(0xFF1A1035);

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.user.fullName,
    );

    _emailController = TextEditingController(
      text: widget.user.email,
    );

    _phoneController = TextEditingController(
      text: widget.user.phone,
    );

    _occupationController = TextEditingController(
      text: widget.user.occupation,
    );

    _addressController = TextEditingController(
      text: widget.user.address,
    );

    _bioController = TextEditingController(
      text: widget.user.bio,
    );

    _profileImage = widget.user.profileImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    _addressController.dispose();
    _bioController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF312E81),
              Color(0xFF4338CA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    30,
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildProfilePicture(),

                        const SizedBox(height: 28),

                        _buildGlassField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person_outline_rounded,
                        ),

                        const SizedBox(height: 16),

                        // Email is displayed but not edited.
                        _buildGlassField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType:
                          TextInputType.emailAddress,
                          enabled: false,
                        ),

                        const SizedBox(height: 16),

                        _buildGlassField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),

                        const SizedBox(height: 16),

                        _buildGlassField(
                          controller: _occupationController,
                          label: 'Occupation / Business',
                          icon: Icons.business_outlined,
                        ),

                        const SizedBox(height: 16),

                        _buildGlassField(
                          controller: _addressController,
                          label: 'Location',
                          icon: Icons.location_on_outlined,
                        ),

                        const SizedBox(height: 16),

                        _buildGlassField(
                          controller: _bioController,
                          label: 'About / Bio',
                          icon: Icons.info_outline_rounded,
                          maxLines: 4,
                        ),

                        const SizedBox(height: 32),

                        // _buildSecondaryButton(
                        //   icon: Icons.lock_outline_rounded,
                        //   label: 'Change Password',
                        //   onTap: () {
                        //     // TODO
                        //   },
                        // ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 16),

          const Expanded(
            child: Text(
              'Edit Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          GestureDetector(
            onTap: _isSaving ? null : _saveProfile,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFBBF24),
                    Color(0xFFF59E0B),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _isSaving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _darkPurple,
                ),
              )
                  : const Text(
                'Save',
                style: TextStyle(
                  color: _darkPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  Widget _buildProfilePicture() {
    ImageProvider? imageProvider;

    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (_profileImage != null &&
        _profileImage!.trim().isNotEmpty) {
      imageProvider = NetworkImage(_profileImage!);
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA78BFA).withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 56,
            backgroundColor: Colors.white.withOpacity(0.15),
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(
              Icons.person,
              color: Colors.white,
              size: 55,
            )
                : null,
          ),
        ),

        GestureDetector(
          onTap: _isUploadingImage
              ? null
              : _pickAndUploadImage,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFBBF24),
                  Color(0xFFF59E0B),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFBBF24)
                      .withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isUploadingImage
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _darkPurple,
              ),
            )
                : const Icon(
              Icons.camera_alt_rounded,
              color: _darkPurple,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PICK IMAGE + CLOUDINARY
  // ============================================================

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile =
      await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return;
      }

      final file = File(pickedFile.path);

      setState(() {
        _selectedImage = file;
        _isUploadingImage = true;
      });

      final uploadedUrl =
      await _cloudinaryService.uploadImage(file);

      if (uploadedUrl == null ||
          uploadedUrl.trim().isEmpty) {
        throw Exception(
          'Cloudinary did not return an image URL',
        );
      }

      final success =
      await _userService.updateProfileImage(
        uid: widget.user.uid,
        imageUrl: uploadedUrl,
      );

      if (!success) {
        throw Exception(
          'Failed to update profile image in Firestore',
        );
      }

      if (!mounted) return;

      setState(() {
        _profileImage = uploadedUrl;
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile image updated successfully',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('❌ Profile image error: $e');

      if (!mounted) return;

      setState(() {
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update profile image: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final success =
      await _userService.updatePersonalInfo(
        uid: widget.user.uid,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        gender: widget.user.gender,
        age: widget.user.age,
        occupation: _occupationController.text.trim(),
        address: _addressController.text.trim(),
        bio: _bioController.text.trim(),
      );

      if (!success) {
        throw Exception(
          'Failed to update personal information',
        );
      }

      // IMPORTANT:
      // updatePersonalInfo() returns bool.
      // Navigator.pop() must return UserModel, NOT bool.

      final updatedUser = UserModel(
        uid: widget.user.uid,
        fullName: _nameController.text.trim(),
        email: widget.user.email,
        phone: _phoneController.text.trim(),
        profileImage: _profileImage,
        role: widget.user.role,
        accountStatus: widget.user.accountStatus,
        gender: widget.user.gender,
        age: widget.user.age,
        occupation: _occupationController.text.trim(),
        address: _addressController.text.trim(),
        bio: _bioController.text.trim(),
        createdAt: widget.user.createdAt,
        updatedAt: Timestamp.now(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Profile updated successfully',
          ),
          backgroundColor: const Color(0xFF6B46C1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // RETURN UserModel
      Navigator.pop(context, updatedUser);
    } catch (e) {
      debugPrint('❌ Save profile error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save profile: $e',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // GLASS FIELD
  // ============================================================

  Widget _buildGlassField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
            ),
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: Colors.white.withOpacity(0.6),
              ),
              prefixIcon: Icon(
                icon,
                color: Colors.white70,
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: enabled
                ? (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Please enter $label';
              }
              return null;
            }
                : null,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECONDARY BUTTON
  // ============================================================

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8,
            sigmaY: 8,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white70,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}