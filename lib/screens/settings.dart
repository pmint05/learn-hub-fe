import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_hub/configs/router_config.dart';
import 'package:learn_hub/models/user.dart';
import 'package:learn_hub/providers/app_auth_provider.dart';
import 'package:learn_hub/providers/theme_provider.dart';
import 'package:learn_hub/screens/welcome.dart';
import 'package:learn_hub/services/db.dart';
import 'package:learn_hub/services/image_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _fullNameController = TextEditingController(text: "");
  final _usernameController = TextEditingController(text: "");
  final _emailController = TextEditingController(text: "");
  final _phoneController = TextEditingController(text: "");
  final _birthdayController = TextEditingController(text: "");
  String _selectedGender = "Male";

  File? _selectedImageFile;
  String? _previewImagePath;

  late final AppUser currentUser =
      Provider.of<AppAuthProvider>(context, listen: false).appUser!;

  bool _googleLinked = true;
  late ThemeProvider themeProvider = Provider.of<ThemeProvider>(
    context,
    listen: false,
  );

  late bool _isDarkMode = themeProvider.themeMode == ThemeMode.dark;

  bool _isUpdating = false;

  Future<void> _saveUserProfile() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final user = authProvider.user;
      final appUser = authProvider.appUser;

      if (user == null || appUser == null) {
        throw Exception("User is not logged in");
      }

      // Track what's changed to build update map
      final Map<String, dynamic> firestoreUpdates = {};

      if (_selectedImageFile != null) {
        try {
          // Create ImageServer instance
          final imageServer = ImageServer();

          // Upload the image
          final response = await imageServer.uploadImage(
            image: _selectedImageFile!,
            name: 'profile_${user.uid}',
          );

          // Get the thumbnail URL
          final thumbUrl = ImageServer.getThumbnailUrl(response);

          if (thumbUrl != null) {
            firestoreUpdates['photoURL'] = thumbUrl;
          } else {
            throw Exception("Failed to get thumbnail URL");
          }
        } catch (e) {
          throw Exception("Image upload failed: $e");
        }
      }

      // Check each field for changes
      if (_fullNameController.text != (appUser.displayName ?? '') &&
          _fullNameController.text.trim().isNotEmpty) {
        firestoreUpdates['displayName'] = _fullNameController.text.trim();
      }

      if (_usernameController.text != (appUser.username ?? '') &&
          _usernameController.text.trim().isNotEmpty) {
        if (_usernameController.text != appUser.username) {
          final usernameExists = await DB.instance.checkUsernameExist(
            _usernameController.text.trim(),
          );

          if (usernameExists) {
            throw Exception("Username already taken");
          }
        }
        firestoreUpdates['username'] = _usernameController.text.trim();
      }

      if (_phoneController.text.trim() != (appUser.phoneNumber ?? '') &&
          _phoneController.text.trim().isNotEmpty) {
        firestoreUpdates['phoneNumber'] = _phoneController.text.trim();
      }

      if (_birthdayController.text.trim() != (appUser.birthday ?? '') &&
          _birthdayController.text.trim().isNotEmpty) {
        firestoreUpdates['birthday'] = _birthdayController.text.trim();
      }

      if (_selectedGender != appUser.gender) {
        firestoreUpdates['gender'] = _selectedGender;
      }

      // Only update Firestore if there are changes
      if (firestoreUpdates.isNotEmpty) {
        await authProvider.updateUserData(firestoreUpdates);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully!")),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("No changes made")));
        }
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating profile: ${e.toString()}")),
        );
      }
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _pickAndPreview() async {
    if (await Permission.mediaLibrary.request().isDenied) {
      if (mounted) {
        showGeneralDialog(
          context: context,
          pageBuilder: (_, __, ___) {
            return AlertDialog(
              title: const Text("Permission Denied"),
              content: const Text("Please allow access to your media library."),
              actions: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
        _previewImagePath = pickedFile.path;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fullNameController.text = currentUser.displayName ?? '';
    _usernameController.text = currentUser.username ?? '';
    _emailController.text = currentUser.email ?? '';
    _phoneController.text = currentUser.phoneNumber ?? '';
    _birthdayController.text = currentUser.birthday ?? '';
    _selectedGender = currentUser.gender ?? 'Male';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            if (_isUpdating)
              Column(
                children: [
                  const LinearProgressIndicator(
                    minHeight: 4,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: _pickAndPreview,
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                    child:
                        _previewImagePath != null
                            ? ClipOval(
                              child: Image.file(
                                File(_previewImagePath!),
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            )
                            : currentUser.photoURL != null &&
                                currentUser.photoURL!.isNotEmpty
                            ? ClipOval(
                              child:
                                  currentUser.photoURL!.startsWith('http')
                                      ? Image.network(
                                        currentUser.photoURL!,
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                                  PhosphorIconsRegular.user,
                                                  size: 36,
                                                  color: cs.onSurface
                                                      .withValues(alpha: 0.5),
                                                ),
                                      )
                                      : Image.file(
                                        File(currentUser.photoURL!),
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                      ),
                            )
                            : Text(
                              currentUser.displayName?.isNotEmpty == true
                                  ? currentUser.displayName![0].toUpperCase()
                                  : "?",
                              style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                  ),
                ),
                GestureDetector(
                  onTap: _pickAndPreview,
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(bottom: 2, right: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField("Display name", _fullNameController),
            const SizedBox(height: 16),
            _buildTextField("Username", _usernameController),
            const SizedBox(height: 16),
            _buildTextField(
              "Email",
              _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: false,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              "Phone number",
              _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              "Your birthday",
              _birthdayController,
              readOnly: true,
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _birthdayController.text =
                        "${picked.day}/${picked.month}/${picked.year}";
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            _buildGenderDropdown(),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Preferences",
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            _buildSwitcher(
              title: "Dark mode",
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                  themeProvider.toggleTheme();
                });
              },
              icon: PhosphorIconsRegular.moon,
            ),
            const SizedBox(height: 24), // 24px spacing from Google switch
            SizedBox(
              width: double.maxFinite,
              height: 48, // Larger button height
              child: ElevatedButton(
                onPressed: _saveUserProfile,
                child: const Text(
                  "Save",
                  style: TextStyle(fontSize: 15), // Larger text
                ),
              ),
            ),
            const SizedBox(height: 24),
            Divider(
              // height: 48,
              thickness: 1,
              color: cs.surfaceDim,
            ),
            const SizedBox(height: 12),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Danger zone",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 42,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.error.withValues(alpha: 0.12),
                  foregroundColor: cs.onError,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                onPressed: () async {
                  try {
                    final authProvider = Provider.of<AppAuthProvider>(
                      context,
                      listen: false,
                    );
                    await authProvider.signOut();
                    if (context.mounted) {
                      context.goNamed(AppRoute.welcome.name);
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logout failed: ${e.toString()}')),
                    );
                  }
                },
                child: Text('Logout', style: TextStyle(color: cs.error)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    bool enabled = true,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      enabled: enabled && !_isUpdating,
      keyboardType: keyboardType,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color:
            !enabled || _isUpdating
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                : null,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color:
              !enabled || _isUpdating
                  ? Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5)
                  : null,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: "Gender",
        labelStyle: Theme.of(context).textTheme.bodyLarge,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      style: Theme.of(context).textTheme.bodyLarge,
      items: const [
        DropdownMenuItem(value: "Male", child: Text("Male")),
        DropdownMenuItem(value: "Female", child: Text("Female")),
      ],
      onChanged: (String? newValue) {
        setState(() {
          _selectedGender = newValue ?? "Male";
        });
      },
    );
  }

  Widget _buildGoogleLinkedSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/images/google.svg', width: 24, height: 24),
          const SizedBox(width: 12),
          Text("Google", style: Theme.of(context).textTheme.bodyLarge),
          const Spacer(),
          Switch(
            value: _googleLinked,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) {
              setState(() {
                _googleLinked = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitcher({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? icon,
  }) {
    WidgetStateProperty<Color?> trackColor =
        WidgetStateProperty<Color?>.fromMap(<WidgetStatesConstraint, Color>{
          WidgetState.selected: Theme.of(context).colorScheme.primary,
          WidgetState.disabled: Colors.grey.shade400,
          WidgetState.scrolledUnder: Colors.grey.shade400,
        });
    final WidgetStateProperty<Color?> overlayColor =
        WidgetStateProperty<Color?>.fromMap(<WidgetState, Color>{
          WidgetState.selected: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.54),
          WidgetState.disabled: Colors.grey.shade400,
        });
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 24),
          if (icon != null) const SizedBox(width: 12),
          Text(title, style: Theme.of(context).textTheme.bodyLarge),

          const Spacer(),
          Switch(
            overlayColor: overlayColor,
            trackColor: trackColor,
            thumbColor: const WidgetStatePropertyAll<Color>(Colors.black),
            value: value,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
