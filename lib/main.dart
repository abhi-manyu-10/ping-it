import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// --- YOUR NEW MODULAR IMPORTS ---
import 'models/ping_model.dart';
import 'screens/profile_screen.dart';
import 'screens/discover_screen.dart';
import 'utils/share_helper.dart';

void main() {
  runApp(const PingItApp());
}

class PingItApp extends StatelessWidget {
  const PingItApp({super.key});

  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ping It',
      debugShowCheckedModeBanner: false,
      
      // LIGHT THEME (Vibrant Purple)
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6200EE),
          brightness: Brightness.light,
        ),
      ),

      // DARK THEME (The Midnight Upgrade)
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFBB86FC),
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        
        // FIX: Explicitly using CardThemeData to avoid Widget collision
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      
      themeMode: ThemeMode.system, 
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _locationController.dispose();
    _pingController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- STATE VARIABLES ---
  int _selectedIndex = 0;
  String _selectedCategory = "Sports"; 
  Color _selectedColor = Colors.green;
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();
  int _selectedSpots = 5;
  String _searchQuery = "";
  String _activeFilter = "All";
  
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _pingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // --- DATABASE ---
  final List<Ping> _allPings = [
    Ping(
      id: "1",
      hostId: "user_abhimanyu",
      hostName: "Abhimanyu",
      title: "Football Match @ Turf",
      description: "Need 3 more for a 5v5 friendly match. High intensity!",
      category: ActivityCategory.sports,
      timeWindow: "05:00 PM - 07:00 PM",
      location: "Salt Lake Sector V",
      neededSpots: 3,
      totalSpots: 10,
      isFriendHost: true, // Dopamine feature
      igGroupLink: "https://www.instagram.com/direct/inbox/", // IG Handshake
    ),
    Ping(
      id: "2",
      hostId: "user_rahul",
      hostName: "Rahul",
      title: "Jamming Session",
      category: ActivityCategory.music,
      timeWindow: "06:30 PM - 08:00 PM",
      location: "Eco Park",
      neededSpots: 2,
      totalSpots: 5,
    ),
  ];

  TimeOfDay _parseTime(String timeString) {
    try {
      timeString = timeString.trim();
      final parts = timeString.split(RegExp(r'[: ]'));
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      String ampm = parts[2].toUpperCase();
      
      if (ampm == 'PM' && hour != 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;
      
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return TimeOfDay.now(); // Fallback if format is weird
    }
  }

  // --- HELPER: RESET FORM ---
  void _clearNewPingForm() {
    setState(() {
      _pingController.clear();
      _locationController.clear();
      _descriptionController.clear();
      _selectedCategory = "Sports";
      _startTime = TimeOfDay.now();
      _endTime = TimeOfDay.now();
      _selectedSpots = 5;
    });
  }

  // --- ADD THIS RIGHT ABOVE @override Widget build(BuildContext context) ---
  void _handleReusePing(Map<String, dynamic> oldPing) {
    setState(() {
      _selectedIndex = 0;
    });
    
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      // Set all the state variables BEFORE opening the sheet
      setState(() {
        _pingController.text = oldPing['title'] ?? "";
        _locationController.text = oldPing['location'] ?? "";
        
        // 1. Map Category (e.g., "sports" -> "Sports")
        if (oldPing['categoryName'] != null) {
          String cat = oldPing['categoryName'].toString();
          _selectedCategory = cat[0].toUpperCase() + cat.substring(1).toLowerCase();
        }

        // 2. Map Time Window (e.g., "05:00 PM - 07:00 PM")
        String timeStr = oldPing['timeWindow'] ?? "";
        if (timeStr.contains("-")) {
          var timeParts = timeStr.split("-");
          _startTime = _parseTime(timeParts[0]);
          _endTime = _parseTime(timeParts[1]);
        }
      });
      
      _showNewPingSheet(context); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Inside the Scaffold in main.dart

appBar: AppBar(
  title: const Text('Ping It', style: TextStyle(fontWeight: FontWeight.bold)),
  centerTitle: true,
  actions: [
    AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: IconButton(
        key: ValueKey<int>(_selectedIndex), // Tells Flutter to animate the swap
        onPressed: () {
          if (_selectedIndex == 2) {
            _showGlobalSettings(context);
          } else {
            _showGlobalNotifications(context);
          }
        },
        icon: Icon(
          _selectedIndex == 2 
              ? Icons.more_horiz_rounded 
              : Icons.notifications_none_rounded,
        ),
      ),
    ),
    const SizedBox(width: 8),
  ],
),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          _buildActivityFeed(),       
  DiscoverScreen(globalPings: _allPings.map((p) => p.toMap()).toList()), 
          ProfileScreen(
            historyPings: _allPings.map((ping) => {
              "title": ping.title,
              "date": "Today", 
              "location": ping.location,
              "timeWindow": ping.timeWindow, // Passed down for the parser
              "categoryName": ping.category.name, // Passed down to set category
              "type": ping.hostId == "user_abhimanyu" ? "hosted" : "joined",
              "members": ["A", "B", "C"], 
              "color": ping.category == ActivityCategory.sports ? Colors.greenAccent 
                     : ping.category == ActivityCategory.music ? Colors.orangeAccent 
                     : const Color(0xFFBB86FC),
              "duration": ping.timeWindow,
            }).toList(),
            onReusePing: _handleReusePing, 
          ),      
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: AnimatedScale(
        scale: _selectedIndex == 2 ? 0 : 1, 
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack, 
        child: FloatingActionButton.extended(
          onPressed: () {
            _clearNewPingForm(); // Clear the form if they manually hit "New Ping"
            _showNewPingSheet(context);
          },
          label: const Text('New Ping'),
          icon: const Icon(Icons.add_location_alt_outlined),
        ),
      ),
    );
  }

  // Inside _MainNavigationState in main.dart

void _showGlobalNotifications(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, 
            height: 4, 
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))
          ),
          const SizedBox(height: 24),
          const Text("NOTIFICATIONS", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 24),
          
          // Mock Notifications (Dopamine hits)
          _buildNotificationItem("Rahul joined your Football ping", "2 mins ago"),
          _buildNotificationItem("New Ping nearby: Tech Talk @ Cafe", "1 hour ago"),
          
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Clear All", style: TextStyle(fontSize: 12))
            )
          ),
          const SizedBox(height: 10),
        ],
      ),
    ),
  );
}

// Inside _MainNavigationState in main.dart

void _showGlobalSettings(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent, // Required for the rounded glass look
    builder: (context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 24),
          const Text("SETTINGS", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 24),
          
          _buildSettingsTile(Icons.palette_outlined, "Theme", "System Default"),
          _buildSettingsTile(Icons.notifications_active_outlined, "Notifications", "All alerts on"),
          _buildSettingsTile(Icons.lock_outline, "Privacy", "Manage visibility"),
          
          const Divider(height: 40, color: Colors.white10),
          
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

Widget _buildSettingsTile(IconData icon, String title, String subtitle) {
  return ListTile(
    leading: Icon(icon, color: Colors.white70),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
    onTap: () { /* Handle logic later */ },
  );
}

Widget _buildNotificationItem(String msg, String time) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0),
    child: Row(
      children: [
        const CircleAvatar(radius: 4, backgroundColor: Color(0xFFBB86FC)),
        const SizedBox(width: 16),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    ),
  );
}

  // --- ACTIVITY FEED WIDGET ---

  Widget _buildActivityFeed() {
    // DOPAMINE SORT: Prioritize Friends on top
    final List<Ping> sortedPings = List.from(_allPings);
    sortedPings.sort((a, b) {
      if (a.isFriendHost && !b.isFriendHost) return -1;
      if (!a.isFriendHost && b.isFriendHost) return 1;
      return 0;
    });

    final filteredPings = sortedPings.where((ping) {
      final matchesSearch = ping.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat = _activeFilter == "All" || 
                         ping.category.name.toLowerCase() == _activeFilter.toLowerCase();
      return matchesSearch && matchesCat;
    }).toList();

    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(
          child: filteredPings.isEmpty 
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: filteredPings.length,
                itemBuilder: (context, index) {
                  final ping = filteredPings[index];
                  final originalIndex = _allPings.indexOf(ping);

                  return Dismissible(
                    key: Key(ping.id + originalIndex.toString()),
                    direction: DismissDirection.endToStart,
                    background: _buildDeleteBackground(),
                    onDismissed: (direction) {
                      setState(() {
                        _allPings.removeAt(originalIndex);
                      });
                    },
                    child: _buildPingCard(context, ping, originalIndex),
                  );
                },
              ),
        ),
      ],
    );
  }

  // --- PING CARD WIDGET ---

  Widget _buildPingCard(BuildContext context, Ping ping, int index) {
    final Color color = ping.color;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: ping.isFriendHost ? 4 : 0,
      shadowColor: ping.isFriendHost ? color.withOpacity(0.4) : Colors.transparent,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            ping.isExpanded = !ping.isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // TOP ROW
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: color.withOpacity(0.1),
                        child: Icon(ping.icon, color: color, size: 20),
                      ),
                      if (ping.isFriendHost)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.stars, color: Colors.amber, size: 14),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ping.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          "${ping.hostName} ${ping.isFriendHost ? '(Friend)' : ''} • ${ping.neededSpots} spots left",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    ping.isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),

              // EXPANDABLE SECTION
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    const Divider(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        ping.description,
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _buildDetailItem(Icons.access_time, "Time", ping.timeWindow)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildDetailItem(Icons.people_outline, "Limit", "${ping.totalSpots} total")),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _launchMapsSearch(ping.location),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ping.location,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _showAskDialog(ping),
                          icon: const Icon(Icons.chat_bubble_outline),
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: ping.hostName == "Abhimanyu" ? null : () => _toggleJoin(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ping.hostName == "Abhimanyu"
                                  ? (isDark ? Colors.white10 : Colors.grey.shade200)
                                  : (ping.isJoined ? (isDark ? Colors.grey[800] : Colors.grey.shade300) : color),
                              foregroundColor: ping.hostName == "Abhimanyu" ? Colors.grey : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(ping.hostName == "Abhimanyu" ? "Hosting" : (ping.isJoined ? "Joined (Open IG)" : "Join")),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: () {
                            ShareHelper.showSharePreview(context, {
                              "title": ping.title,
                              "time": ping.timeWindow,
                              "location": ping.location,
                              "color": ping.color,
                              "icon": ping.icon,
                            });
                          },
                          icon: Icon(Icons.ios_share_rounded, color: color),
                          style: IconButton.styleFrom(
                            backgroundColor: color.withOpacity(0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                crossFadeState: ping.isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- LOGIC FUNCTIONS ---

  void _toggleJoin(int index) async {
    final ping = _allPings[index];
    setState(() {
      if (!ping.isJoined && ping.neededSpots > 0) {
        ping.neededSpots -= 1;
        ping.isJoined = true;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Joined ${ping.hostName}'s Ping! Opening Instagram..."),
            backgroundColor: ping.color,
          ),
        );

        if (ping.igGroupLink != null) {
          _launchIG(ping.igGroupLink!);
        }
      } else if (ping.isJoined) {
        ping.neededSpots += 1;
        ping.isJoined = false;
      }
    });
  }

  Future<void> _launchIG(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showAskDialog(Ping ping) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Ask ${ping.hostName}"),
        content: const TextField(
          decoration: InputDecoration(hintText: "e.g., Is equipment provided?"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Send")),
        ],
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            "$label: $value",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bolt_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text("No pings here yet...", style: TextStyle(color: Colors.grey, fontSize: 16)),
          TextButton(onPressed: () => _showNewPingSheet(context), child: const Text("Start the vibe")),
        ],
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.redAccent),
    );
  }

  // --- SEARCH AND FILTER WIDGET ---

  Widget _buildSearchAndFilter() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 5),
      color: isDark ? Colors.transparent : Colors.white,
      child: Column(
        children: [
          Container(
            height: 45,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: "Search pings...",
                prefixIcon: Icon(Icons.search, size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 35,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ["All", "Sports", "Music", "Art", "Hangout"].map((cat) {
                bool isSelected = _activeFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _activeFilter = cat),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- CREATION SHEET & HELPERS ---

  void _showNewPingSheet(BuildContext context) {
    // Removed the hardcoded _startTime and _endTime resets here so the "Reuse" data stays intact!

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20, right: 20, top: 20,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- UPDATED HEADER WITH CLEAR BUTTON ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Create a New Ping", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          // Clears the underlying data AND rebuilds the sheet to show empty fields
                          _clearNewPingForm(); 
                          setModalState(() {}); 
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text("Clear", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Plan field
                  TextField(
                    controller: _pingController,
                    decoration: InputDecoration(
                      labelText: "What's the plan?",
                      prefixIcon: Icon(Icons.edit_note_rounded, color: _selectedColor),
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey.shade200,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Location field
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: "Where is it happening?",
                      prefixIcon: Icon(Icons.location_on_rounded, color: _selectedColor),
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey.shade200,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description Field (Optional)
                  TextField(
                    controller: _descriptionController,
                    maxLines: 1, 
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: "Extra Info (Optional)",
                      hintText: "e.g., Bring your own water, or 'Beginners welcome!'",
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: Icon(Icons.description_outlined, color: _selectedColor.withOpacity(0.7)),
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text("Select Category:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _categoryChip(Icons.sports_soccer, "Sports", Colors.green, setModalState),
                      _categoryChip(Icons.mic_external_on, "Music", Colors.orange, setModalState),
                      _categoryChip(Icons.brush, "Art", Colors.blue, setModalState),
                      _categoryChip(Icons.groups, "Hangout", Colors.purple, setModalState),
                    ],
                  ),
                  const SizedBox(height: 25),

                  const Text("Time Duration:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: InkWell(
                        onTap: () => _pickTime(context, setModalState, true),
                        borderRadius: BorderRadius.circular(12),
                        child: _buildTimeBox("From", _startTime.format(context)),
                      )),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 12.0), child: Icon(Icons.arrow_forward_rounded, color: Colors.grey, size: 18)),
                      Expanded(child: InkWell(
                        onTap: () => _pickTime(context, setModalState, false),
                        borderRadius: BorderRadius.circular(12),
                        child: _buildTimeBox("Until", _endTime.format(context)),
                      )),
                    ],
                  ),
                  const SizedBox(height: 25),

                  const Text("Participants Needed:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [Icon(Icons.people_outline, size: 20, color: _selectedColor.withOpacity(0.7)), const SizedBox(width: 10), const Text("Spots Needed")]),
                        Row(children: [
                          IconButton(onPressed: () => setModalState(() { if (_selectedSpots > 1) _selectedSpots--; }), icon: const Icon(Icons.remove_circle_outline), color: _selectedColor),
                          Text("$_selectedSpots", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(onPressed: () => setModalState(() { if (_selectedSpots < 25) _selectedSpots++; }), icon: const Icon(Icons.add_circle_outline), color: _selectedColor),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _addNewPing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: const Text("Post Ping", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  void _addNewPing() {
  if (_pingController.text.isNotEmpty) {
    setState(() {
      _allPings.insert(0, Ping(
        id: DateTime.now().toString(),
        hostId: "user_abhimanyu", // Your ID
        hostName: "Abhimanyu", 
        title: _pingController.text,
        // PASS THE DESCRIPTION HERE
        description: _descriptionController.text.isNotEmpty 
            ? _descriptionController.text 
            : "Join the vibe!", 
        category: _getCategoryFromString(_selectedCategory),
        timeWindow: "${_startTime.format(context)} - ${_endTime.format(context)}",
        location: _locationController.text.isNotEmpty ? _locationController.text : "TBD",
        neededSpots: _selectedSpots,
        totalSpots: _selectedSpots + 1,
        isJoined: true,
        isFriendHost: true, // You are your own friend!
      ));
      
      // CLEAR EVERYTHING
      _pingController.clear();
      _locationController.clear();
      _descriptionController.clear(); // Add this
    });
    Navigator.pop(context);
  }
}

  ActivityCategory _getCategoryFromString(String cat) {
    switch (cat) {
      case "Sports": return ActivityCategory.sports;
      case "Music": return ActivityCategory.music;
      case "Art": return ActivityCategory.art;
      case "Hangout": return ActivityCategory.hangout;
      default: return ActivityCategory.other;
    }
  }

  // --- RE-ADDED UTILITY WIDGETS ---

  Widget _categoryChip(IconData icon, String label, Color color, StateSetter setModalState) {
    bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setModalState(() { 
          _selectedCategory = label;
          _selectedColor = color;
        });
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : Colors.black.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
            ),
            child: Icon(icon, color: isSelected ? color : Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: isSelected ? color : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String label, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: _selectedColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _selectedColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: _selectedColor.withOpacity(0.6))),
          Text(time, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _selectedColor)),
        ],
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, StateSetter setModalState, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      initialEntryMode: TimePickerEntryMode.input,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: _selectedColor),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      setModalState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _launchMapsSearch(String locationName) async {
    final String query = Uri.encodeComponent("$locationName, Kolkata");
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    try {
      bool launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open Maps app")));
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}