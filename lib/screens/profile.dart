import 'package:flutter/material.dart';
import 'package:learn_hub/providers/app_auth_provider.dart';
import 'package:learn_hub/screens/welcome.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _fullnameController = TextEditingController(text: "Anh Lân Đi Bộ");
  final _usernameController = TextEditingController(text: "@anhlandibo_");
  final _emailController = TextEditingController(text: "anhlandibo@gmail.com");
  final _phoneController = TextEditingController(text: "0123456789");
  final _birthdayController = TextEditingController(text: "Date of Birth");

  String _selectedGender = "Male";
  bool _googleLinked = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      body: ShaderMask(
        shaderCallback:
            (bounds) => LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0.0, 0.05, 0.9, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: Text(
                      "R",
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
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
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField("Fullname", _fullnameController),
              const SizedBox(height: 16),
              _buildTextField("Username", _usernameController),
              const SizedBox(height: 16),
              _buildTextField(
                "Email",
                _emailController,
                keyboardType: TextInputType.emailAddress,
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
                    initialDate: DateTime(1990, 1, 1),
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
                  "Account linked",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              _buildGoogleLinkedSwitch(),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profile saved!")),
                  );
                },
                child: const Text("Save"),
              ),
              SizedBox(height: 12),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    Theme.of(context).scaffoldBackgroundColor,
                  ),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                        width: 1,
                      ),
                    ),
                  ),
                ),
                onPressed: () async {
                  try {
                    final authProvider = Provider.of<AppAuthProvider>(
                      context,
                      listen: false,
                    );
                    await authProvider.signOut();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logout failed: ${e.toString()}')),
                    );
                  }
                },
                child: Text(
                  'Logout',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              const SizedBox(height: 72),
            ],
          ),
        ),
      ),
      // bottomNavigationBar: Padding(
      //   padding: const EdgeInsets.all(16),
      //   child: SizedBox(
      //     height: 48,
      //     width: double.infinity,
      //     child: ElevatedButton(
      //       onPressed: () async {
      //         try {
      //           final authProvider = Provider.of<AppAuthProvider>(
      //             context,
      //             listen: false,
      //           );
      //           await authProvider.signOut();
      //           Navigator.of(context).pushAndRemoveUntil(
      //             MaterialPageRoute(builder: (context) => WelcomeScreen()),
      //             (route) => false,
      //           );
      //         } catch (e) {
      //           ScaffoldMessenger.of(context).showSnackBar(
      //             SnackBar(content: Text('Logout failed: ${e.toString()}')),
      //           );
      //         }
      //       },
      //       child: Text('Logout'),
      //     ),
      //   ),
      // ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        bool readOnly = false,
        VoidCallback? onTap,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.bodyMedium,
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
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: const InputDecoration(
          border: InputBorder.none,
          labelText: "Gender",
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
      ),
    );
  }

  Widget _buildGoogleLinkedSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Image.asset('../assets/images/google.png', width: 24, height: 24),
          Icon(PhosphorIconsRegular.googleLogo),
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
}
