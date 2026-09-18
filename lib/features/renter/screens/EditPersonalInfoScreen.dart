import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/user_model.dart';
import '../../../services/cloudinary_service.dart';

class EditPersonalInfoScreen extends StatefulWidget {
  final UserModel user;

  const EditPersonalInfoScreen({super.key, required this.user});

  @override
  State<EditPersonalInfoScreen> createState() => _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState extends State<EditPersonalInfoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final CloudinaryService _cloudinaryService = CloudinaryService();

  final ImagePicker _imagePicker = ImagePicker();

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late TextEditingController _occupationController;
  late TextEditingController _addressController;
  late TextEditingController _bioController;

  File? _selectedProfileImage;

  String? _profileImageUrl;

  String _gender = '';
  String _role = '';

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  static const Color _primary = Color(0xFF6B46C1);

  @override
  void initState() {
    super.initState();

    _fullNameController = TextEditingController();

    _phoneController = TextEditingController();

    _emailController = TextEditingController();

    _ageController = TextEditingController();

    _occupationController = TextEditingController();

    _addressController = TextEditingController();

    _bioController = TextEditingController();

    _gender = widget.user.gender;

    _profileImageUrl = widget.user.profileImage;

    _fullNameController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _loadUserFromFirebase();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _occupationController.dispose();
    _addressController.dispose();
    _bioController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD USER
  // ============================================================

  Future<void> _loadUserFromFirebase() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        return;
      }

      final data = userDoc.data()!;

      _fullNameController.text = data['fullName']?.toString() ?? '';

      _phoneController.text = data['phone']?.toString() ?? '';

      _emailController.text = data['email']?.toString() ?? '';

      final age = data['age'];

      if (age is int && age > 0) {
        _ageController.text = age.toString();
      } else {
        _ageController.text = age?.toString() ?? '';
      }

      _occupationController.text = data['occupation']?.toString() ?? '';

      _addressController.text = data['address']?.toString() ?? '';

      _bioController.text = data['bio']?.toString() ?? '';

      _gender = data['gender']?.toString() ?? '';

      _profileImageUrl = data['profileImage']?.toString();

      _role = data['role']?.toString() ?? '';

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('LOAD USER ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickProfileImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile == null) {
        return;
      }

      setState(() {
        _selectedProfileImage = File(pickedFile.path);
      });
    } catch (e) {
      debugPrint('PICK IMAGE ERROR: $e');
    }
  }

  // ============================================================
  // UPLOAD IMAGE
  // ============================================================

  Future<String?> _uploadProfileImage() async {
    if (_selectedProfileImage == null) {
      return _profileImageUrl;
    }

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final imageUrl = await _cloudinaryService.uploadImage(
        _selectedProfileImage!,
      );

      if (imageUrl == null || imageUrl.isEmpty) {
        return null;
      }

      await _firestore.collection('users').doc(widget.user.uid).update({
        'profileImage': imageUrl,
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) {
        return imageUrl;
      }

      setState(() {
        _profileImageUrl = imageUrl;
        _selectedProfileImage = null;
      });

      return imageUrl;
    } catch (e) {
      debugPrint('UPLOAD IMAGE ERROR: $e');

      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _saveInformation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_gender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender.')),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final age = int.tryParse(_ageController.text.trim()) ?? 0;

      String? finalProfileImage = _profileImageUrl;

      if (_selectedProfileImage != null) {
        finalProfileImage = await _uploadProfileImage();

        if (finalProfileImage == null) {
          throw Exception('Failed to upload profile image');
        }
      }

      final updatedAt = Timestamp.now();

      await _firestore.collection('users').doc(widget.user.uid).update({
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gender': _gender,
        'age': age,
        'occupation': _occupationController.text.trim(),
        'address': _addressController.text.trim(),
        'bio': _bioController.text.trim(),
        'profileImage': finalProfileImage ?? '',
        'updatedAt': updatedAt,
      });

      final updatedUser = UserModel(
        uid: widget.user.uid,
        fullName: _fullNameController.text.trim(),
        email: widget.user.email,
        phone: _phoneController.text.trim(),
        profileImage: finalProfileImage,
        role: widget.user.role,
        accountStatus: widget.user.accountStatus,
        gender: _gender,
        age: age,
        occupation: _occupationController.text.trim(),
        address: _addressController.text.trim(),
        bio: _bioController.text.trim(),
        createdAt: widget.user.createdAt,
        updatedAt: updatedAt,
      );

      if (!mounted) return;

      Navigator.pop(context, updatedUser);
    } catch (e) {
      debugPrint('SAVE ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final isDark = theme.brightness == Brightness.dark;

    final background = isDark ? Colors.black : const Color(0xFFF8F5FF);

    final card = isDark ? const Color(0xFF151515) : Colors.white;

    final textPrimary = colors.onSurface;

    final textSecondary = colors.onSurfaceVariant;

    final border = isDark ? const Color(0xFF333333) : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: background,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),

        title: const Text(
          'Edit Personal Info',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),

        centerTitle: true,
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _profileHeader(
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 30),

                    _sectionTitle('BASIC INFORMATION', textSecondary),

                    const SizedBox(height: 12),

                    _textField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      icon: Icons.person_outline_rounded,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      card: card,
                      border: border,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _textField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'Enter your phone number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      card: card,
                      border: border,
                    ),

                    const SizedBox(height: 16),

                    _textField(
                      controller: _emailController,
                      label: 'Email',
                      hint: '',
                      icon: Icons.email_outlined,
                      enabled: false,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      card: card,
                      border: border,
                    ),

                    const SizedBox(height: 24),

                    _sectionTitle('PERSONAL DETAILS', textSecondary),

                    const SizedBox(height: 12),

                    // ==================================================
                    // GENDER
                    // ==================================================
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _gender.isEmpty ? null : _gender,
                          isExpanded: true,
                          dropdownColor: card,

                          style: TextStyle(color: textPrimary, fontSize: 15),

                          hint: Text(
                            'Select Gender',
                            style: TextStyle(color: textSecondary),
                          ),

                          icon: const Icon(Icons.keyboard_arrow_down_rounded),

                          items: const [
                            DropdownMenuItem(
                              value: 'Male',
                              child: Text('Male'),
                            ),
                            DropdownMenuItem(
                              value: 'Female',
                              child: Text('Female'),
                            ),
                            DropdownMenuItem(
                              value: 'Other',
                              child: Text('Other'),
                            ),
                          ],

                          onChanged: (value) {
                            setState(() {
                              _gender = value ?? '';
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _textField(
                      controller: _ageController,
                      label: 'Age',
                      hint: 'Enter your age',
                      icon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      card: card,
                      border: border,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your age';
                        }

                        final age = int.tryParse(value.trim());

                        if (age == null || age < 1 || age > 120) {
                          return 'Please enter a valid age';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _textField(
                      controller: _occupationController,
                      label: 'Occupation',
                      hint: 'e.g. Student, Developer',
                      icon: Icons.work_outline_rounded,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      card: card,
                      border: border,
                    ),

                    const SizedBox(height: 24),

                    _sectionTitle('ADDRESS', textSecondary),

                    const SizedBox(height: 12),

                    _textField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter your address',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      card: card,
                      border: border,
                    ),

                    const SizedBox(height: 24),

                    _sectionTitle('ABOUT YOU', textSecondary),

                    const SizedBox(height: 12),

                    _textField(
                      controller: _bioController,
                      label: 'Bio',
                      hint: 'Tell us something about yourself',
                      icon: Icons.info_outline_rounded,
                      maxLines: 5,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      card: card,
                      border: border,
                    ),

                    const SizedBox(height: 32),

                    // ==================================================
                    // SAVE BUTTON
                    // ==================================================
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveInformation,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _primary.withOpacity(0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),

                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1,
      ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _profileHeader({
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF252525)
                      : const Color(0xFFEDE9FE),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF444444)
                        : const Color(0xFFD8CCFF),
                    width: 3,
                  ),
                ),

                child: ClipOval(
                  child: _selectedProfileImage != null
                      ? Image.file(
                          _selectedProfileImage!,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                        )
                      : (_profileImageUrl != null &&
                            _profileImageUrl!.isNotEmpty)
                      ? Image.network(
                          _profileImageUrl!,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Icon(
                              Icons.person_rounded,
                              size: 52,
                              color: _primary,
                            );
                          },
                        )
                      : const Icon(
                          Icons.person_rounded,
                          size: 52,
                          color: _primary,
                        ),
                ),
              ),

              GestureDetector(
                onTap: _isUploadingImage ? null : _pickProfileImage,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.black : Colors.white,
                      width: 3,
                    ),
                  ),
                  child: _isUploadingImage
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 19,
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            _fullNameController.text.isEmpty
                ? 'Your Name'
                : _fullNameController.text,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            _role.isEmpty ? 'USER' : _role.toUpperCase(),
            style: const TextStyle(
              color: _primary,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          TextButton.icon(
            onPressed: _isUploadingImage ? null : _pickProfileImage,
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: const Text('Change Profile Photo'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color textPrimary,
    required Color textSecondary,
    required Color card,
    required Color border,
    TextInputType? keyboardType,
    bool enabled = true,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,

      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),

      cursorColor: _primary,

      decoration: InputDecoration(
        labelText: label,

        labelStyle: TextStyle(color: textSecondary),

        floatingLabelStyle: const TextStyle(color: _primary),

        hintText: hint,

        hintStyle: TextStyle(color: textSecondary),

        prefixIcon: Icon(icon, color: _primary),

        filled: true,

        fillColor: enabled ? card : border.withOpacity(0.25),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),

        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
      ),
    );
  }
}
