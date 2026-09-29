import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'contact_details_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Contact> _contacts = [];
  bool _permissionDenied = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    try {
      if (await Permission.contacts.request().isGranted) {
        List<Contact> contacts = await FlutterContacts.getAll(properties: {ContactProperty.phone, ContactProperty.photoThumbnail});
        setState(() {
          _contacts = contacts;
          _permissionDenied = false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _permissionDenied = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching contacts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort contacts alphabetically
    final sortedContacts = List<Contact>.from(_contacts)
      ..sort((a, b) => (a.displayName ?? '').toLowerCase().compareTo((b.displayName ?? '').toLowerCase()));

    // Build flattened list with headers
    List<dynamic> listItems = [];
    String currentLetter = '';
    for (var c in sortedContacts) {
      String firstLetter = (c.displayName ?? '#').trim().isNotEmpty 
          ? (c.displayName ?? '#').trim().substring(0, 1).toUpperCase()
          : '#';
      if (!RegExp(r'[A-Z]').hasMatch(firstLetter)) firstLetter = '#';
      
      if (firstLetter != currentLetter) {
        listItems.add(firstLetter); // Header
        currentLetter = firstLetter;
      }
      listItems.add(c); // Contact
    }

    final alphabets = "ABCDEFGHIJKLMNOPQRSTUVWXYZ#".split('');

    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit background from HomeScreen
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.arrow_back_ios, color: Colors.blueAccent, size: 22),
                      const Text("Lists", style: TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.w400)),
                    ],
                  ),
                  const Icon(Icons.add, color: Colors.blueAccent, size: 28),
                ],
              ),
            ),

            // Large Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text("Contacts", style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Icon(Icons.search, color: Colors.white.withOpacity(0.5), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text("Search", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 17)),
                    ),
                    Icon(Icons.mic, color: Colors.white.withOpacity(0.5), size: 20),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Main List Area
            Expanded(
              child: _permissionDenied
                  ? const Center(child: Text('Permission Denied', style: TextStyle(color: Colors.white)))
                  : _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : Stack(
                          children: [
                            ListView.builder(
                              itemCount: listItems.length + 1, // +1 for My Card
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  // My Card
                                  return Column(
                                    children: [
                                      ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                        leading: const CircleAvatar(
                                          radius: 30,
                                          backgroundColor: Colors.grey,
                                          child: Icon(Icons.person, size: 40, color: Colors.white),
                                        ),
                                        title: const Text(
                                          "User Card",
                                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
                                        ),
                                        subtitle: Text(
                                          "My Card",
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  );
                                }

                                final item = listItems[index - 1];

                                if (item is String) {
                                  // Alphabet Header
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 4.0),
                                        child: Text(
                                          item,
                                          style: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Divider(height: 1, color: Colors.grey.shade800, indent: 16),
                                    ],
                                  );
                                } else if (item is Contact) {
                                  // Contact Row (No Avatar for regular contacts in iOS)
                                  return Column(
                                    children: [
                                      ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                                        title: Text(
                                          item.displayName ?? 'Unknown',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ContactDetailsScreen(
                                                displayName: item.displayName ?? 'Unknown',
                                                number: item.phones.isNotEmpty ? item.phones.first.number : '',
                                                photoThumbnail: item.photo?.thumbnail,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      Divider(height: 1, color: Colors.grey.shade800, indent: 16),
                                    ],
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),

                            // Right side Alphabet Scrollbar
                            Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: alphabets.map((letter) {
                                    return Text(
                                      letter,
                                      style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold, height: 1.2),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
