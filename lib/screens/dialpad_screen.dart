import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'call_screen.dart';

class DialpadScreen extends StatefulWidget {
  const DialpadScreen({Key? key}) : super(key: key);

  @override
  State<DialpadScreen> createState() => _DialpadScreenState();
}

class _DialpadScreenState extends State<DialpadScreen> {
  String _phoneNumber = '';
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];

  // T9 mapping
  final Map<String, String> t9Map = {
    'A': '2', 'B': '2', 'C': '2',
    'D': '3', 'E': '3', 'F': '3',
    'G': '4', 'H': '4', 'I': '4',
    'J': '5', 'K': '5', 'L': '5',
    'M': '6', 'N': '6', 'O': '6',
    'P': '7', 'Q': '7', 'R': '7', 'S': '7',
    'T': '8', 'U': '8', 'V': '8',
    'W': '9', 'X': '9', 'Y': '9', 'Z': '9',
  };

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    if (await Permission.contacts.request().isGranted) {
      final contacts = await FlutterContacts.getAll(properties: {ContactProperty.phone});
      setState(() {
        _allContacts = contacts;
      });
    }
  }

  void _filterContacts() {
    if (_phoneNumber.isEmpty) {
      setState(() {
        _filteredContacts = [];
      });
      return;
    }

    final query = _phoneNumber;
    final results = _allContacts.where((contact) {
      // Match phone number
      if (contact.phones.any((p) => p.number.replaceAll(RegExp(r'\D'), '').contains(query))) {
        return true;
      }
      
      // Match T9 name
      final name = (contact.displayName ?? '').toUpperCase();
      String t9Name = '';
      for (int i = 0; i < name.length; i++) {
        t9Name += t9Map[name[i]] ?? name[i];
      }
      
      return t9Name.contains(query);
    }).toList();

    setState(() {
      _filteredContacts = results.take(3).toList(); // Show top 3 matches
    });
  }

  void _onKeypadPressed(String value) {
    setState(() {
      _phoneNumber += value;
    });
    _filterContacts();
  }

  void _onBackspace() {
    if (_phoneNumber.isNotEmpty) {
      setState(() {
        _phoneNumber = _phoneNumber.substring(0, _phoneNumber.length - 1);
      });
      _filterContacts();
    }
  }

  void _onBackspaceLongPress() {
    if (_phoneNumber.isNotEmpty) {
      setState(() {
        _phoneNumber = '';
      });
      _filterContacts();
    }
  }

  Future<void> _makeCall([String? specificNumber]) async {
    final numberToCall = specificNumber ?? _phoneNumber;
    if (numberToCall.isEmpty) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          displayName: numberToCall,
          number: numberToCall,
          isIncoming: false,
        ),
      ),
    );
  }

  Widget _buildDialKey(String number, String letters) {
    return GestureDetector(
      onTap: () => _onKeypadPressed(number),
      onLongPress: () {
        if (number == '0') {
          _onKeypadPressed('+');
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                if (letters.isNotEmpty)
                  Text(
                    letters,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  )
                else
                  const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent, // Background comes from HomeScreen
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Top section with number and create actions
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _phoneNumber,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_phoneNumber.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: GestureDetector(
                          onTap: () {},
                          child: const Text("Add Number", style: TextStyle(color: Colors.blueAccent, fontSize: 16)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Keypad section
            Expanded(
              flex: 7,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDialKey('1', ''),
                        _buildDialKey('2', 'ABC'),
                        _buildDialKey('3', 'DEF'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDialKey('4', 'GHI'),
                        _buildDialKey('5', 'JKL'),
                        _buildDialKey('6', 'MNO'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDialKey('7', 'PQRS'),
                        _buildDialKey('8', 'TUV'),
                        _buildDialKey('9', 'WXYZ'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDialKey('*', ''),
                        _buildDialKey('0', '+'),
                        _buildDialKey('#', ''),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Call button section
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _makeCall,
                      child: Container(
                        width: 75,
                        height: 75,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34C759), // iOS Green
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.call,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  if (_phoneNumber.isNotEmpty)
                    Positioned(
                      right: 50,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _onBackspace,
                          onLongPress: _onBackspaceLongPress,
                          child: const Icon(
                            Icons.backspace,
                            color: Colors.white70,
                            size: 28,
                          ),
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
