import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DiscoverScreen extends StatefulWidget {
  final List<Map<String, dynamic>> globalPings;

  const DiscoverScreen({super.key, required this.globalPings});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _placeSearchController = TextEditingController();
  String _searchQuery = "";
  int _expandedHubIndex = -1;

  // Mock Hubs with enriched data
  final List<Map<String, dynamic>> _hubs = [
    {
      "name": "Winter Carnival '26",
      "location": "Central Park",
      "type": "Festival",
      "popularity": "High Heat",
      "color": Colors.orangeAccent,
      "pings": [
        {"title": "Giant Wheel Meetup", "time": "06:00 PM", "host": "Abhimanyu", "members": ["Rahul", "Sneha", "Kabir"], "spots": "4 left"},
        {"title": "Food Stalls Hop", "time": "07:30 PM", "host": "Rahul", "members": ["Abhimanyu", "Priya"], "spots": "Full"},
      ]
    },
    {
      "name": "Skyline Apartments",
      "location": "Block C",
      "type": "Complex",
      "popularity": "Regular",
      "color": Colors.blueAccent,
      "pings": [
        {"title": "Sunday Yoga", "time": "08:00 AM", "host": "Sneha", "members": ["Anjali", "Vikram"], "spots": "10 left"},
      ]
    },
    {
      "name": "Salt Lake Turf",
      "location": "Sector V",
      "type": "Sports",
      "popularity": "Trending",
      "color": Colors.greenAccent,
      "pings": [
        {"title": "5v5 Friendly", "time": "05:00 PM", "host": "Kabir", "members": ["Arjun", "Deep", "Sayan"], "spots": "2 left"},
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    List<Map<String, dynamic>> filteredHubs = _hubs.where((hub) =>
      hub['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
      hub['location'].toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            
            // 1. HIGH-CONTRAST SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.07) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _placeSearchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "Find a Hub (Malls, Turfs, Complexes...)",
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),

            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                itemCount: filteredHubs.length,
                itemBuilder: (context, index) {
                  return _buildPlaceHub(index, filteredHubs[index], isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      // Reduced top padding from 24 to 8 for a tighter look
      padding: EdgeInsets.fromLTRB(24, 8, 24, 8), 
      child: Text(
        "Discover", 
        style: TextStyle(
          fontSize: 24, // Reduced from 32
          fontWeight: FontWeight.w600, // Slightly lighter than w900
          fontStyle: FontStyle.italic, // Gives it that "cursive" slant
          letterSpacing: 0.5, // Tighter spacing for elegance
          fontFamily: 'Georgia', // Using a serif fallback for a classic feel
        ),
      ),
    );
  }

  Widget _buildPlaceHub(int index, Map<String, dynamic> hub, bool isDark) {
    bool isExpanded = _expandedHubIndex == index;
    Color color = hub['color'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isExpanded ? color.withOpacity(0.4) : (isDark ? Colors.white10 : Colors.grey.shade200),
          width: isExpanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expandedHubIndex = isExpanded ? -1 : index);
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Row(
              children: [
                Text(hub['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                const SizedBox(width: 8),
                if (hub['popularity'] == 'Trending' || hub['popularity'] == 'High Heat')
                  Icon(Icons.bolt, color: Colors.amber.shade400, size: 16),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hub['location'], style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                // POPULARITY BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text("${hub['pings'].length} PINGS • ${hub['popularity']}", 
                    style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
              ],
            ),
            trailing: Icon(isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: color),
          ),
          if (isExpanded) 
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  const Divider(color: Colors.white10, height: 32),
                  ...hub['pings'].map<Widget>((ping) => _buildPingRow(ping, color, isDark)).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPingRow(Map ping, Color color, bool isDark) {
    return InkWell(
      onTap: () => _showPingDetails(ping, color, isDark),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ping['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text("Host: ${ping['host']} • ${ping['spots']}", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  void _showPingDetails(Map ping, Color color, bool isDark) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(ping['title'].toString().toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: color, fontSize: 13)),
                Text(ping['time'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 32),
            
            _buildMemberTile("HOST", ping['host'], color, isDark, true),
            const SizedBox(height: 24),
            
            const Text("MEMBERS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey, letterSpacing: 1)),
            const SizedBox(height: 16),
            
            // Fixed Member Spacing
            Wrap(
              runSpacing: 12,
              children: ping['members'].map<Widget>((m) => _buildMemberTile("", m, color, isDark, false)).toList(),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(String label, String name, Color color, bool isDark, bool isHost) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0), // Added spacing between members
      child: InkWell(
        onTap: () => print("Profile of $name"),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isHost ? color.withOpacity(0.2) : (isDark ? Colors.white10 : Colors.grey.shade200),
              child: Text(name[0], style: TextStyle(color: isHost ? color : (isDark ? Colors.white70 : Colors.black87), fontWeight: FontWeight.w900, fontSize: 12)),
            ),
            const SizedBox(width: 16), // Increased gap from 12 to 16
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (isHost) Text("Organizer", style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_outward_rounded, size: 14, color: isDark ? Colors.white24 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}