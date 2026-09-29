import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'call_screen.dart';
import 'edit_contact_screen.dart';

class ContactDetailsScreen extends StatelessWidget {
  final String displayName;
  final String number;
  final Uint8List? photoThumbnail;

  const ContactDetailsScreen({
    Key? key,
    required this.displayName,
    required this.number,
    this.photoThumbnail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // or Color(0xFF1C1C1E) for grouped background
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Liquid Glass background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a1a2e),
                  Color(0xFF000000),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back_ios, color: Colors.blueAccent, size: 20),
                          Text("Back", style: TextStyle(color: Colors.blueAccent, fontSize: 16)),
                        ],
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text("Edit", style: TextStyle(color: Colors.blueAccent, fontSize: 16)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditContactScreen(
                              displayName: displayName,
                              number: number,
                              photoThumbnail: photoThumbnail,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Center(
                          child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade600,
                backgroundImage: photoThumbnail != null
                    ? MemoryImage(photoThumbnail!) 
                    : null,
                child: photoThumbnail == null
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.w400),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              displayName,
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionBox(context, Icons.message, "message", () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open Messages app')));
                  }),
                  _buildActionBox(context, Icons.call, "call", () {
                    if (number.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CallScreen(
                            displayName: displayName,
                            number: number,
                            isIncoming: false,
                          ),
                        ),
                      );
                    }
                  }),
                  _buildActionBox(context, Icons.videocam, "video", () {}),
                  _buildActionBox(context, Icons.mail, "mail", () {}),
                ],
              ),
            ),
            const SizedBox(height: 30),
            if (number.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: const Text("mobile", style: TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(number, style: const TextStyle(color: Colors.blueAccent, fontSize: 18)),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text("Notes", style: TextStyle(color: Colors.white)),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text("Send Message", style: TextStyle(color: Colors.blueAccent)),
                      onTap: () {},
                    ),
                    const Divider(color: Colors.grey, height: 1, indent: 16),
                    ListTile(
                      title: const Text("Share Contact", style: TextStyle(color: Colors.blueAccent)),
                      onTap: () {},
                    ),
                    const Divider(color: Colors.grey, height: 1, indent: 16),
                    ListTile(
                      title: const Text("Add to Favorites", style: TextStyle(color: Colors.blueAccent)),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBox(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 24),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
