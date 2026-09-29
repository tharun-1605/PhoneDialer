import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'call_screen.dart';
import 'contact_details_screen.dart';

class RecentsScreen extends StatefulWidget {
  const RecentsScreen({Key? key}) : super(key: key);

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen> {
  Iterable<CallLogEntry> _callLogs = [];
  bool _permissionDenied = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCallLogs();
  }

  Future<void> _fetchCallLogs() async {
    try {
      if (await Permission.phone.request().isGranted && await Permission.contacts.request().isGranted) {
        Iterable<CallLogEntry> entries = await CallLog.get();
        setState(() {
          _callLogs = entries;
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
      print('Error fetching call logs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _selectedTab = 0; // 0 for All, 1 for Missed

  IconData _getCallTypeIcon(CallType? type) {
    if (type == CallType.missed || type == CallType.rejected) {
      return Icons.phone_missed;
    }
    return Icons.phone;
  }

  String _getCallTypeString(CallType? type) {
    switch (type) {
      case CallType.incoming:
        return "Incoming Call";
      case CallType.outgoing:
        return "Outgoing Call";
      case CallType.missed:
      case CallType.rejected:
        return "Missed Call";
      default:
        return "mobile";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Edit & Segmented Control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Edit", style: TextStyle(color: Colors.blueAccent, fontSize: 18)),
                  ),
                  Container(
                    width: 160,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 0),
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0 ? Colors.white.withOpacity(0.3) : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: const Text("All", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 1),
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1 ? Colors.white.withOpacity(0.3) : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: const Text("Missed", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Large Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text("Recents", style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
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

            const SizedBox(height: 8),

            // List
            Expanded(
              child: _permissionDenied
                  ? const Center(child: Text('Permission Denied', style: TextStyle(color: Colors.white)))
                  : _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _callLogs.isEmpty
                          ? const Center(child: Text('No Recent Calls', style: TextStyle(color: Colors.white)))
                          : ListView.builder(
                              itemCount: _callLogs.length,
                              itemBuilder: (context, index) {
                                final entry = _callLogs.elementAt(index);
                                final bool isMissed = entry.callType == CallType.missed || entry.callType == CallType.rejected;
                                
                                if (_selectedTab == 1 && !isMissed) {
                                  return const SizedBox.shrink(); // Hide if "Missed" tab selected and not missed
                                }

                                final callDate = DateTime.fromMillisecondsSinceEpoch(entry.timestamp ?? 0);
                                final dateString = DateFormat('h:mm a').format(callDate);
                                final displayName = entry.name?.isNotEmpty == true ? entry.name! : (entry.number ?? 'Unknown Caller');

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.grey.shade800,
                                    child: Text(
                                      displayName[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    displayName,
                                    style: TextStyle(
                                      color: isMissed ? Colors.redAccent : Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Icon(
                                        _getCallTypeIcon(entry.callType),
                                        size: 14,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getCallTypeString(entry.callType),
                                        style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        dateString,
                                        style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ContactDetailsScreen(
                                                displayName: displayName,
                                                number: entry.number ?? '',
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Icon(Icons.info_outline, color: Colors.blueAccent, size: 26),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    // Direct call
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CallScreen(
                                          displayName: displayName,
                                          number: entry.number ?? '',
                                          isIncoming: false,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
