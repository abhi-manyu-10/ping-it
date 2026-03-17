import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ping_it/utils/share_helper.dart'; 
import '../models/ping_model.dart';

class DiscoverScreen extends StatefulWidget {
  final List<Ping> globalPings; // Public pings from strangers
  final Function(Ping) onJoin;
  const DiscoverScreen({
    super.key, 
    required this.globalPings, 
    required this.onJoin, // <--- Add this line
  });
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _locationSearchController = TextEditingController();
  final List<int> _radiusSteps = [1, 5, 10, 15, 20, 25, 50];
  int _currentStepIndex = 1; // Default 5km
  String _currentSearchLocation = "Current Location"; // Toggle for "Park Street", etc.

  // Mock Global Hubs (Public Places)
  final List<Map<String, dynamic>> _globalHubs = [
    
    {
      "name": "Eco Park Turf",
      "location": "New Town",
      "distance": 2.4,
      "vibe": "Competitive",
      "color": Colors.greenAccent,
      "members": ["Abhimanyu", "Rahul", "Sneha"], // Ensure this exists
      "maxSpots": 20,                            // Ensure this exists
      "isSpotlight": true,
    },
    {
      "name": "Maidan Field 4",
      "location": "Maidan",
      "distance": 6.8,
      "vibe": "Chill",
      "color": Colors.orangeAccent,
      "members": ["Ananya", "Vikram"], // Ensure this exists
      "maxSpots": 16,                   // Ensure this exists
      "pings": 5,
      "isSpotlight": false,
    },
    {
      "name": "Coffee House",
      "location": "College Street",
      "distance": 12.5,
      "vibe": "Quiet/Deep",
      "color": Colors.cyanAccent,
      "members": ["Priya", "Arjun", "Kavya", "Rohit"], // Ensure this exists
      "maxSpots": 10,                                  // Ensure this exists
      "pings": 15,
      "isSpotlight": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Logic: Filter hubs based on the selected radius
    final filteredHubs = _globalHubs.where((hub) => hub['distance'] <= _radiusSteps[_currentStepIndex]).toList();
    final spotlightHub = _globalHubs.firstWhere((hub) => hub['isSpotlight'] == true);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. HEADER & GLOBAL TOGGLE
            SliverToBoxAdapter(child: _buildHeader()),

            // 2. RADIUS & LOCATION SELECTOR
            SliverToBoxAdapter(child: _buildDiscoveryControls(isDark)),

            // 3. THE SPOTLIGHT (Always visible if within range or city-wide)
            SliverToBoxAdapter(
              child: _buildSpotlightHub(spotlightHub, isDark),
            ),

            // 4. DISCOVERY GRID
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              sliver: filteredHubs.isEmpty 
                ? SliverToBoxAdapter(child: _buildEmptyDiscovery())
                : SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildGlobalZoneTile(filteredHubs[index], isDark),
                      childCount: filteredHubs.length,
                    ),
                  ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded( // Added Expanded to prevent text overflow
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Discover", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                // USE THE VARIABLE HERE:
                Text(
                  _currentSearchLocation == "Current Location" 
                      ? "Public Pings around you" 
                      : "Public Pings near $_currentSearchLocation", 
                  style: const TextStyle(color: Color(0xFFBB86FC), fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          CircleAvatar(
            backgroundColor: Colors.white10,
            child: IconButton(
              icon: const Icon(Icons.map_outlined, size: 20, color: Colors.white),
              onPressed: () {}, 
            ),
          )
        ],
      ),
    );
  }
  // Function to handle joining and navigating
  void _handleJoin(Map<String, dynamic> hub) {
    HapticFeedback.heavyImpact();

    // 1. Create a stable ID based on the name
    final String stableId = hub['name'].hashCode.toString();

    // 2. Map the data into a Ping object
    Ping newJoinedPing = Ping(
      id: stableId,
      hostId: "global_host", 
      hostName: "Public Hub",
      title: hub['name'],
      description: "Public event at ${hub['location']}",
      category: _getCategoryFromVibe(hub['vibe']), 
      date: "17 Mar 2026", 
      timeWindow: "Open Hours",
      location: hub['location'],
      neededSpots: (hub['maxSpots'] ?? 10) - (hub['members']?.length ?? 0),
      totalSpots: hub['maxSpots'] ?? 10,
      isJoined: hub['isJoined'] ?? false, 
      igGroupLink: "https://www.instagram.com/direct/inbox/", 
    );

    // 3. Send to main.dart (this updates newJoinedPing.isJoined to TRUE)
    widget.onJoin(newJoinedPing); 
    
    // 4. FIXED: Sync exactly with the new state (removed the !)
    setState(() {
      hub['isJoined'] = newJoinedPing.isJoined; 
    });
  }

  // Small helper to match your ActivityCategory enum
  ActivityCategory _getCategoryFromVibe(String? vibe) {
    if (vibe == "Competitive") return ActivityCategory.sports;
    if (vibe == "High Energy") return ActivityCategory.music;
    if (vibe == "Chill") return ActivityCategory.hangout;
    return ActivityCategory.art;
  }

  Widget _buildDiscoveryControls(bool isDark) {
    int currentRadius = _radiusSteps[_currentStepIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
      child: Column(
        children: [
          // 1. LOCATION SEARCH BAR (The "Teleport" Tool)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _locationSearchController, // Link the controller here
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  setState(() => _currentSearchLocation = val);
                  // Optional: Add a small haptic pop when searching
                  HapticFeedback.mediumImpact(); 
                }
              },
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search a location (e.g. Park Street)",
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.location_searching_rounded, size: 18, color: Color(0xFFBB86FC)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // 2. RANGE PILL (The Discrete Slider)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.radar, size: 18, color: Color(0xFFBB86FC)),
                const SizedBox(width: 12),
                Text("Radius: ", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                Text("${currentRadius}km", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFBB86FC))),
                Expanded(
                  child: Slider(
                    value: _currentStepIndex.toDouble(),
                    min: 0,
                    max: (_radiusSteps.length - 1).toDouble(),
                    divisions: _radiusSteps.length - 1,
                    activeColor: const Color(0xFFBB86FC),
                    inactiveColor: isDark ? Colors.white10 : Colors.grey.shade300,
                    onChanged: (val) {
                      if (val.toInt() != _currentStepIndex) {
                        HapticFeedback.selectionClick(); // Satisfying click on each step
                        setState(() => _currentStepIndex = val.toInt());
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotlightHub(Map hub, bool isDark) {
    return GestureDetector(
      onTap: () => _showPublicPingDetails(hub, isDark),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(colors: [hub['color'], hub['color'].withOpacity(0.4)]),
          boxShadow: [BoxShadow(color: hub['color'].withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Stack(
          children: [
            Positioned(right: -10, bottom: -10, child: Icon(Icons.bolt_rounded, size: 120, color: Colors.white.withOpacity(0.15))),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(hub['name'], style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people_alt_outlined, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text("${(hub['members'] as List?)?.length ?? 0}/${hub['maxSpots'] ?? 0} members")
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalZoneTile(Map hub, bool isDark) {
    return GestureDetector(
      onTap: () => _showPublicPingDetails(hub, isDark),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${hub['distance']}km away", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10)),
            const Spacer(),
            Text(hub['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, height: 1.2)),
            const SizedBox(height: 8),
            Text("${(hub['members'] as List?)?.length ?? 0} joined")
          ],
        ),
      ),
    );
  }

  void _showPublicPingDetails(Map ping, bool isDark) {
    final List members = ping['members'] as List? ?? [];
    final bool isJoined = ping['isJoined'] ?? false;
    final Color pingColor = ping['color'] as Color? ?? const Color(0xFFBB86FC);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85, // Taller to fit all info
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TOP INFO BAR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: pingColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(ping['vibe']?.toUpperCase() ?? "PUBLIC", style: TextStyle(color: pingColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
                ),
                Text(ping['date'] ?? "Mar 18, 2026", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            
            // 2. TITLE & LOCATION
            Text(ping['name'] ?? "Event", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.1)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(ping['location'] ?? "Nearby", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                const Spacer(),
                // GOOGLE MAPS SHORTCUT
                TextButton.icon(
                  onPressed: () => _openInMaps(ping['location'] ?? "Kolkata"),
                  icon: const Icon(Icons.directions, size: 16, color: Color(0xFFBB86FC)),
                  label: const Text("Open in Maps", style: TextStyle(fontSize: 12, color: Color(0xFFBB86FC))),
                ),
              ],
            ),

            const Divider(height: 40, color: Colors.white10),

            // 3. HOST INFO & DM FEATURE
            Row(
              children: [
                CircleAvatar(backgroundColor: pingColor.withOpacity(0.2), child: Text(ping['host']?[0] ?? "H", style: TextStyle(color: pingColor))),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("HOSTED BY", style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.w900)),
                    Text(ping['host'] ?? "Anonymous", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const Spacer(),
                // DM BUTTON
                IconButton(
                  onPressed: () { /* Open DM logic */ },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  style: IconButton.styleFrom(backgroundColor: Colors.white10, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 4. TIME & DURATION
            Row(
              children: [
                _buildInfoPill(Icons.access_time_rounded, ping['time'] ?? "6:00 PM"),
                const SizedBox(width: 12),
                _buildInfoPill(Icons.timer_outlined, ping['duration'] ?? "2 hours"),
              ],
            ),

            const SizedBox(height: 32),

            // 5. MEMBERS ROSTER (Visual grid)
            Text("MEMBERS (${members.length}/${ping['maxSpots'] ?? 10})", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 1)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: members.map((m) => CircleAvatar(
                radius: 18,
                backgroundColor: m == "You" ? const Color(0xFFBB86FC) : Colors.white10,
                child: Text(m[0], style: const TextStyle(fontSize: 12, color: Colors.white)),
              )).toList(),
            ),

            const Spacer(),

            // 6. THE REFINED JOIN BUTTON
            // 6. ACTION ROW (Share + Join)
            Row(
              children: [
                // THE SHARE BUTTON (Triggers your existing Flashcard/QR logic)
                Container(
                  height: 54,
                  width: 54,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share_rounded, size: 20),
                    onPressed: () {
                    HapticFeedback.mediumImpact();
                    
                    // Change 'showShareCard' to 'showSharePreview'
                    ShareHelper.showSharePreview(context, {
                      "name": ping['name'] ?? "Event",
                      "host": ping['host'] ?? "Anonymous",
                      "time": ping['time'] ?? "6:00 PM",
                      "location": ping['location'] ?? "Nearby",
                      "vibe": ping['vibe'] ?? "Public",
                      "color": ping['color'] ?? const Color(0xFFBB86FC),
                    });
                  },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                // THE REFINED JOIN BUTTON
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        // 1. Close the bottom sheet FIRST
                        Navigator.pop(context);
                        
                        // 2. THEN trigger the join & dialog
                        _handleJoin(ping as Map<String, dynamic>);
                      },
                      style: ElevatedButton.styleFrom(
                        // If joined, make it dark; if not, use the vibe color
                        backgroundColor: isJoined ? const Color(0xFF1A1A1A) : pingColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        side: isJoined ? BorderSide(color: pingColor.withOpacity(0.5)) : BorderSide.none,
                      ),
                      child: Text(
                        isJoined ? "LEAVE PING" : "JOIN PING", // Dynamic label
                        style: const TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.w900, 
                          letterSpacing: 1
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper for info pills
  Widget _buildInfoPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }

  

  Widget _buildEmptyDiscovery() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(Icons.location_off_rounded, size: 48, color: Colors.grey.withOpacity(0.3)),
        const SizedBox(height: 16),
        const Text("No public pings in this range", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        TextButton(onPressed: () => setState(() => _currentSearchLocation), child: const Text("Expand Search to City-wide")),
      ],
    );
  }

  Future<void> _openInMaps(String location) async {
    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}";
    final Uri url = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
  }
}