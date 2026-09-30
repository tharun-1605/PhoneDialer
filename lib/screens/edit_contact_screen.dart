import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'call_screen.dart';

class EditContactScreen extends StatefulWidget {
  final String displayName;
  final String number;
  final Uint8List? photoThumbnail;

  const EditContactScreen({
    Key? key,
    required this.displayName,
    required this.number,
    this.photoThumbnail,
  }) : super(key: key);

  @override
  State<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _companyController;
  late TextEditingController _phoneController;
  
  Uint8List? _currentPhoto;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentPhoto = widget.photoThumbnail;
    // Simple split for demo purposes
    List<String> names = widget.displayName.split(' ');
    _firstNameController = TextEditingController(text: names.isNotEmpty ? names[0] : '');
    _lastNameController = TextEditingController(text: names.length > 1 ? names.sublist(1).join(' ') : '');
    _companyController = TextEditingController();
    _phoneController = TextEditingController(text: widget.number);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _currentPhoto = bytes;
        });
      }
    } catch (e) {
      debugPrint('Failed to pick image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E), // iOS grouped background color
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.blueAccent, fontSize: 17)),
        ),
        leadingWidth: 80,
        title: const Text("Edit Contact", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Save updated contact back via flutter_contacts
              Navigator.pop(context);
            },
            child: const Text("Done", style: TextStyle(color: Colors.blueAccent, fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Contact Photo & Poster
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey.shade700,
                    backgroundImage: _currentPhoto != null ? MemoryImage(_currentPhoto!) : null,
                    child: _currentPhoto == null
                        ? const Icon(Icons.person, size: 80, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text("Add Photo", style: TextStyle(color: Colors.white, fontSize: 14)),
                    ),
                  ),
                  if (_currentPhoto != null) ...[
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: () {
                        // Open CallScreen in preview mode
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CallScreen(
                              displayName: _firstNameController.text + " " + _lastNameController.text,
                              number: _phoneController.text.isNotEmpty ? _phoneController.text : "Mobile",
                              isIncoming: true,
                              photoThumbnail: _currentPhoto,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        "Preview Contact Poster",
                        style: TextStyle(color: Colors.blueAccent, fontSize: 15),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Name Fields Section
            _buildSection([
              _buildTextField("First name", _firstNameController),
              const Divider(color: Colors.grey, height: 1, indent: 16),
              _buildTextField("Last name", _lastNameController),
              const Divider(color: Colors.grey, height: 1, indent: 16),
              _buildTextField("Company", _companyController),
            ]),
            
            // Add Phone Section
            const SizedBox(height: 20),
            _buildSection([
              _buildActionRow(Icons.add_circle, Colors.green, "add phone", customWidget: Expanded(
                child: TextField(
                  controller: _phoneController,
                  style: const TextStyle(color: Colors.white, fontSize: 17),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Phone",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 17),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              )),
            ]),
            
            // Add Email Section
            const SizedBox(height: 20),
            _buildSection([
              _buildActionRow(Icons.add_circle, Colors.green, "add email"),
            ]),
            
            // Ringtones Section
            const SizedBox(height: 20),
            _buildSection([
              _buildNavigationRow("Ringtone", "Default"),
              const Divider(color: Colors.grey, height: 1, indent: 16),
              _buildNavigationRow("Text Tone", "Default"),
            ]),

            // Additional Add Options
            const SizedBox(height: 20),
            _buildSection([
              _buildActionRow(Icons.add_circle, Colors.green, "add url"),
            ]),
            const SizedBox(height: 20),
            _buildSection([
              _buildActionRow(Icons.add_circle, Colors.green, "add address"),
            ]),
            const SizedBox(height: 20),
            _buildSection([
              _buildActionRow(Icons.add_circle, Colors.green, "add birthday"),
            ]),
            const SizedBox(height: 20),
            _buildSection([
              _buildActionRow(Icons.add_circle, Colors.green, "add date"),
            ]),
            const SizedBox(height: 20),
            _buildSection([
              _buildActionRow(Icons.add_circle, Colors.green, "add related name"),
            ]),
            const SizedBox(height: 20),
            _buildSection([
              _buildActionRow(Icons.add_circle, Colors.green, "add social profile"),
            ]),
            const SizedBox(height: 20),
            _buildSection([
              _buildActionRow(Icons.add_circle, Colors.green, "add instant message"),
            ]),
            
            // Notes Section
            const SizedBox(height: 20),
            _buildSection([
              Container(
                height: 100,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: const TextField(
                  maxLines: null,
                  style: TextStyle(color: Colors.white, fontSize: 17),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Notes",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 17),
                  ),
                ),
              ),
            ]),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2C2C2E), // Card background
        border: Border(
          top: BorderSide(color: Color(0xFF38383A), width: 0.5),
          bottom: BorderSide(color: Color(0xFF38383A), width: 0.5),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 17),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 17),
        ),
      ),
    );
  }

  Widget _buildActionRow(IconData icon, Color iconColor, String text, {Widget? customWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 16),
          if (customWidget != null) 
            customWidget
          else
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 17)),
        ],
      ),
    );
  }

  Widget _buildNavigationRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 17)),
          Row(
            children: [
              Text(value, style: const TextStyle(color: Colors.grey, fontSize: 17)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
