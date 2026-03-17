import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui; // For BackdropFilter blur

import 'models/ping_model.dart';
import 'screens/profile_screen.dart';
import 'screens/discover_screen.dart';
import 'utils/share_helper.dart';

// 1. THE GLOBAL KEY FOR SNACKBARS
// This forces SnackBars to the root of the app, preventing them from getting stuck in the center.


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
    
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6200EE), brightness: Brightness.light),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFBB86FC), brightness: Brightness.dark, surface: const Color(0xFF121212)),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        cardTheme: CardThemeData(color: const Color(0xFF1E1E1E), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();
  int _selectedSpots = 5;
  String _searchQuery = "";
  String _activeFilter = "All";
  bool _isFabMenuOpen = false;
  
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _pingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // For Editing state tracking
  Ping? _editingPing;
  PingHub? _editingHub;

  // --- DATABASE ---
  final List<Ping> _allPings = [
    Ping(
      id: "1", hostId: "user_abhimanyu", hostName: "Abhimanyu", title: "Football Match @ Turf", description: "Need 3 more for a 5v5 friendly match. High intensity!",
      category: ActivityCategory.sports, date: "17 Mar 2026", timeWindow: "05:00 PM - 07:00 PM", location: "Salt Lake Sector V", neededSpots: 3, totalSpots: 10, isFriendHost: true, igGroupLink: "https://www.instagram.com/direct/inbox/",
    ),
  ];

  final List<PingHub> _allHubs = [
    PingHub(
      id: "hub1", hostId: "user_rahul", hostName: "Rahul", title: "Winter Carnival", location: "Central Park", category: ActivityCategory.hangout,
      pings: [
        Ping(id: "h1_1", hostId: "user_rahul", hostName: "Rahul", title: "Food Stalls Walk", description: "Grab food together!", category: ActivityCategory.hangout, date: "18 Mar 2026", timeWindow: "06:00 PM - 08:00 PM", location: "Central Park Gate 2", neededSpots: 5, totalSpots: 10, isFriendHost: true, igGroupLink: "https://www.instagram.com/direct/inbox/")
      ],
    )
  ];
  final List<Ping> _discoverJoinedPings = [];

  // Helper to dynamically collect ALL pings (standalone + inside hubs)
  List<Ping> get _globalPings => [
    ..._allPings, 
    ..._allHubs.expand((h) => h.pings), 
    ..._discoverJoinedPings
  ];
  // --- FORMATTERS ---
  String _formatDate(DateTime d) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}";
  }

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
    } catch (e) { return TimeOfDay.now(); }
  }

  // --- REUSE & FORMS ---
  void _clearForms() {
    setState(() {
      _pingController.clear(); _locationController.clear(); _descriptionController.clear();
      _selectedCategory = "Sports"; _selectedDate = DateTime.now();
      _startTime = TimeOfDay.now(); _endTime = TimeOfDay.now(); _selectedSpots = 5;
      _editingPing = null; _editingHub = null;
    });
  }

  void _handleReusePing(Map<String, dynamic> oldPing) {
    setState(() => _selectedIndex = 0);
    _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    
    Future.delayed(const Duration(milliseconds: 300), () {
      _clearForms();
      setState(() {
        _pingController.text = oldPing['title'] ?? "";
        _locationController.text = oldPing['location'] ?? "";
        
        if (oldPing['categoryName'] != null) {
          String cat = oldPing['categoryName'].toString();
          _selectedCategory = cat[0].toUpperCase() + cat.substring(1).toLowerCase();
        }
        
        String timeStr = oldPing['timeWindow'] ?? "";
        if (timeStr.contains("-")) {
          var timeParts = timeStr.split("-");
          _startTime = _parseTime(timeParts[0]);
          _endTime = _parseTime(timeParts[1]);
        }
      });
      _showNewPingSheet(context, null); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ping It', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: IconButton(
              key: ValueKey<int>(_selectedIndex),
              onPressed: () => _selectedIndex == 2 ? _showGlobalSettings(context) : _showGlobalNotifications(context),
              icon: Icon(_selectedIndex == 2 ? Icons.more_horiz_rounded : Icons.notifications_none_rounded),
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
            _isFabMenuOpen = false;
          });
        },
        children: [
          _buildActivityFeed(),       
          DiscoverScreen(
            globalPings: const [], 
            onJoin: (Ping ping) => _toggleJoin(ping),
          ),
          ProfileScreen(
            historyPings: _globalPings
                .where((ping) => ping.hostId == "user_abhimanyu" || ping.isJoined)
                .map((ping) => {
                  "title": ping.title,
                  "date": ping.date, 
                  "location": ping.location,
                  "timeWindow": ping.timeWindow, 
                  "categoryName": ping.category.name, 
                  "type": ping.hostId == "user_abhimanyu" ? "hosted" : "joined",
                  "members": ["A", "B", "C"],
                  "color": ping.color,
                  "duration": ping.timeWindow,
                }).toList(),
            onReusePing: _handleReusePing, 
          ),      
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
        child: SizedBox(
          height: 300, 
          width: 220, 
          child: Stack(
            alignment: Alignment.bottomRight,
            clipBehavior: Clip.none, 
            children: [
              // 1. BLUR BACKDROP
              if (_isFabMenuOpen)
                Positioned(
                  top: -MediaQuery.of(context).size.height,
                  left: -MediaQuery.of(context).size.width,
                  right: -MediaQuery.of(context).size.width,
                  bottom: -MediaQuery.of(context).size.height,
                  child: GestureDetector(
                    onTap: () => setState(() => _isFabMenuOpen = false),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, child) {
                        return BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 8.0 * value, sigmaY: 8.0 * value),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.light
                                  ? Colors.white.withOpacity(0.4 * value) 
                                  : Colors.black.withOpacity(0.4 * value),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // 2. NEW HUB BUTTON
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350), 
                curve: Curves.easeInOutCubic,
                bottom: _isFabMenuOpen ? 145 : 10,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isFabMenuOpen ? 1 : 0,
                  child: _buildFabSubButton(
                    icon: Icons.hub_rounded,
                    label: "New Hub",
                    color: Colors.amber,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _isFabMenuOpen = false);
                      _clearForms();
                      _showNewHubSheet(context);
                    },
                  ),
                ),
              ),

              // 3. NEW PING BUTTON
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300), 
                curve: Curves.easeInOutCubic,
                bottom: _isFabMenuOpen ? 80 : 10,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isFabMenuOpen ? 1 : 0,
                  child: _buildFabSubButton(
                    icon: Icons.location_on_rounded,
                    label: "New Ping",
                    color: const Color(0xFFBB86FC),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _isFabMenuOpen = false);
                      _clearForms();
                      _showNewPingSheet(context, null);
                    },
                  ),
                ),
              ),

              // 4. MAIN TRIGGER BUTTON
              FloatingActionButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _isFabMenuOpen = !_isFabMenuOpen);
                },
                backgroundColor: const Color(0xFFBB86FC),
                foregroundColor: Colors.black,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: AnimatedRotation(
                  turns: _isFabMenuOpen ? 0.375 : 0, 
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  child: const Icon(Icons.add, size: 28),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFabSubButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 4), 
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(8)),
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent, 
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(30),
              splashColor: Colors.white24,
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Icon(icon, color: Colors.black, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ACTIVITY FEED ---
  Widget _buildActivityFeed() {
    List<dynamic> combinedFeed = [..._allPings, ..._allHubs];

    final filteredFeed = combinedFeed.where((item) {
      String itemTitle = (item is Ping) ? item.title : (item as PingHub).title;
      String itemCategoryName = (item is Ping) ? item.category.name : (item as PingHub).category.name;

      final matchesSearch = itemTitle.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat = _activeFilter == "All" || itemCategoryName.toLowerCase() == _activeFilter.toLowerCase();
      
      return matchesSearch && matchesCat;
    }).toList();

    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(
          child: filteredFeed.isEmpty 
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: filteredFeed.length,
                itemBuilder: (context, index) {
                  final item = filteredFeed[index];
                  if (item is PingHub) return _buildHubFolderCard(context, item);
                  if (item is Ping) return _buildPingCard(context, item);
                  return const SizedBox(); 
                },
              ),
        ),
      ],
    );
  }

  // --- HUB FOLDER CARD ---
  Widget _buildHubFolderCard(BuildContext context, PingHub hub) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onLongPress: () => _showPingOptions(hub), 
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: hub.color.withOpacity(0.5), width: 1.5)),
        color: isDark ? Colors.white.withOpacity(0.02) : hub.color.withOpacity(0.05),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => setState(() => hub.isExpanded = !hub.isExpanded),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.folder_open_rounded, color: hub.color, size: 24),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("HUB • ${hub.location.toUpperCase()}", style: TextStyle(color: hub.color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            Text(hub.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                    Icon(hub.isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
                if (hub.isExpanded) ...[
                  const Divider(height: 32),
                  ...hub.pings.map((p) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: _buildPingCard(context, p, isNested: true, parentHub: hub))).toList(),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () { _clearForms(); _showNewPingSheet(context, hub); }, 
                      icon: Icon(Icons.add, color: hub.color, size: 18),
                      label: Text("Add Ping to Hub", style: TextStyle(color: hub.color, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(backgroundColor: hub.color.withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- PING CARD ---
  Widget _buildPingCard(BuildContext context, Ping ping, {bool isNested = false, PingHub? parentHub}) {
    final Color color = ping.color;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: () => _showPingOptions(ping, parentHub: parentHub), 
      child: Card(
        elevation: ping.isFriendHost && !isNested ? 4 : 0,
        shadowColor: ping.isFriendHost ? color.withOpacity(0.4) : Colors.transparent,
        margin: EdgeInsets.only(bottom: isNested ? 4 : 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => ping.isExpanded = !ping.isExpanded),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 22, backgroundColor: color.withOpacity(0.1), child: Icon(ping.icon, color: color, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ping.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("${ping.hostName} • ${ping.date}", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(ping.isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      const Divider(height: 24),
                      Align(alignment: Alignment.centerLeft, child: Text(ping.description, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87))),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: _buildDetailItem(Icons.access_time, "Time", ping.timeWindow)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildDetailItem(Icons.people_outline, "Limit", "${ping.neededSpots} left")),
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
                                  style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 13, decoration: TextDecoration.underline),
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
                            // THE FIX: 
                            // If hosting -> do nothing (null)
                            // If joined -> open IG
                            // If not joined -> run the join logic
                            onPressed: ping.hostName == "Abhimanyu" 
                                ? null 
                                : () {
                                    if (ping.isJoined) {
                                      if (ping.igGroupLink != null) {
                                        _launchIG(ping.igGroupLink!);
                                      }
                                    } else {
                                      _toggleJoin(ping);
                                    }
                                  },
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
                                "id": ping.id,
                                "title": ping.title,
                                "date": ping.date,
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
      ),
    );
  }

  // --- RESTORED LOGIC FUNCTIONS WITH GLOBAL KEY SNACKBAR ---
  void _toggleJoin(Ping ping) async {
    setState(() {
      if (!ping.isJoined) {
        if (ping.neededSpots > 0) {
          ping.neededSpots -= 1;
          ping.isJoined = true;

          // Shadow list routing (duplicate-free)
          bool isInExploreHub = _allHubs.expand((h) => h.pings).any((p) => p.id == ping.id);
          bool isStandaloneExplore = _allPings.any((p) => p.id == ping.id);

          if (!isInExploreHub && !isStandaloneExplore) {
            if (!_discoverJoinedPings.any((p) => p.id == ping.id)) {
              _discoverJoinedPings.add(ping);
            }
          }

          // MINIMALIST WORKAROUND: Clean Dialog instead of a buggy SnackBar
          HapticFeedback.heavyImpact();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1A1A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: ping.color),
                  const SizedBox(width: 10),
                  const Text("Joined!", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text("You're on the list for ${ping.title}. Ready to say hi to the group?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), // Closes dialog
                  child: const Text("LATER", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (ping.igGroupLink != null) _launchIG(ping.igGroupLink!);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ping.color, 
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text("OPEN IG", style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          );
        }
      } else {
        // LEAVING LOGIC: Silent & Tactile
        ping.neededSpots += 1;
        ping.isJoined = false;

        _discoverJoinedPings.removeWhere((p) => p.id == ping.id);

        // Just a nice physical click, no annoying popups blocking the screen
        HapticFeedback.mediumImpact(); 
      }
    });
  }

  void _showAskDialog(Ping ping) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Ask ${ping.hostName}"),
        content: const TextField(decoration: InputDecoration(hintText: "e.g., Is equipment provided?")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Send")),
        ],
      ),
    );
  }

  Future<void> _launchMapsSearch(String locationName) async {
    final String query = Uri.encodeComponent("$locationName, Kolkata");
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query"); 
    try {
      bool launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        if (mounted) {
          // Back to the standard context!
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not open Maps app"))
          );
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _showPingOptions(dynamic item, {PingHub? parentHub}) {
    final bool isHost = item.hostId == "user_abhimanyu";
    final bool isJoined = (item is Ping) ? item.isJoined : false;

    if (!isHost && !isJoined) return;

    HapticFeedback.heavyImpact();

    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isHost ? "HOST CONTROLS" : "PING OPTIONS", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 12, letterSpacing: 2)),
            const SizedBox(height: 24),

            if (isHost)
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blueAccent),
                title: const Text("Edit Details", style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  if (item is Ping) {
                    _editingPing = item;
                    _pingController.text = item.title;
                    _locationController.text = item.location;
                    _descriptionController.text = item.description;
                    _showNewPingSheet(context, parentHub); 
                  } else if (item is PingHub) {
                    _editingHub = item;
                    _pingController.text = item.title;
                    _locationController.text = item.location;
                    _showNewHubSheet(context);
                  }
                },
              ),

            if (isHost)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: const Text("Delete Ping", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                onTap: () {
                  setState(() {
                    if (item is Ping) {
                      if (parentHub != null) { parentHub.pings.remove(item); } else { _allPings.remove(item); }
                    } else if (item is PingHub) {
                      _allHubs.remove(item);
                    }
                  });
                  Navigator.pop(context);
                },
              ),

            if (!isHost && isJoined)
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.orangeAccent),
                title: const Text("Leave Ping", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _toggleJoin(item); 
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // --- CREATION SHEETS (HUB & PING) ---
  void _showNewHubSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_editingHub == null ? "Create a Hub" : "Edit Hub", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () { _clearForms(); setModalState((){}); }, child: const Text("Clear", style: TextStyle(color: Colors.redAccent))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(controller: _pingController, decoration: InputDecoration(labelText: "Hub Name (e.g. Winter Carnival)", prefixIcon: const Icon(Icons.folder), filled: true, fillColor: isDark ? Colors.white10 : Colors.grey.shade200, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                  const SizedBox(height: 18),
                  TextField(controller: _locationController, decoration: InputDecoration(labelText: "Location", prefixIcon: const Icon(Icons.location_on), filled: true, fillColor: isDark ? Colors.white10 : Colors.grey.shade200, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                  const SizedBox(height: 20),
                  const Text("Select Category:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_categoryChip(Icons.sports_soccer, "Sports", Colors.green, setModalState), _categoryChip(Icons.mic_external_on, "Music", Colors.orange, setModalState), _categoryChip(Icons.brush, "Art", Colors.blue, setModalState), _categoryChip(Icons.groups, "Hangout", Colors.purple, setModalState)]),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_pingController.text.isNotEmpty) {
                          setState(() {
                            if (_editingHub != null) {
                              _editingHub!.title = _pingController.text;
                              _editingHub!.location = _locationController.text;
                            } else {
                              _allHubs.insert(0, PingHub(id: DateTime.now().toString(), hostId: "user_abhimanyu", hostName: "Abhimanyu", title: _pingController.text, location: _locationController.text, category: _getCategoryFromString(_selectedCategory), pings: []));
                            }
                            _clearForms();
                          });
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: _selectedColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: Text(_editingHub == null ? "Post Hub" : "Save Changes", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _showNewPingSheet(BuildContext context, PingHub? targetHub) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_editingPing == null ? "Create a Ping" : "Edit Ping", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () { _clearForms(); setModalState((){}); }, child: const Text("Clear", style: TextStyle(color: Colors.redAccent))),
                      if (targetHub != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: targetHub.color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text("Inside ${targetHub.title}", style: TextStyle(color: targetHub.color, fontSize: 10, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(controller: _pingController, decoration: InputDecoration(labelText: "What's the plan?", prefixIcon: Icon(Icons.edit_note_rounded, color: _selectedColor), filled: true, fillColor: isDark ? Colors.white10 : Colors.grey.shade200, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                  const SizedBox(height: 18),
                  TextField(controller: _locationController, decoration: InputDecoration(labelText: "Where is it happening?", prefixIcon: Icon(Icons.location_on_rounded, color: _selectedColor), filled: true, fillColor: isDark ? Colors.white10 : Colors.grey.shade200, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                  const SizedBox(height: 20),
                  
                  const Text("Date & Time:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: InkWell(onTap: () => _pickDate(context, setModalState), borderRadius: BorderRadius.circular(12), child: _buildTimeBox("Date", _formatDate(_selectedDate)))),
                      const SizedBox(width: 8),
                      Expanded(child: InkWell(onTap: () => _pickTime(context, setModalState, true), borderRadius: BorderRadius.circular(12), child: _buildTimeBox("From", _startTime.format(context)))),
                      const SizedBox(width: 8),
                      Expanded(child: InkWell(onTap: () => _pickTime(context, setModalState, false), borderRadius: BorderRadius.circular(12), child: _buildTimeBox("Until", _endTime.format(context)))),
                    ],
                  ),
                  const SizedBox(height: 25),

                  const Text("Select Category:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_categoryChip(Icons.sports_soccer, "Sports", Colors.green, setModalState), _categoryChip(Icons.mic_external_on, "Music", Colors.orange, setModalState), _categoryChip(Icons.brush, "Art", Colors.blue, setModalState), _categoryChip(Icons.groups, "Hangout", Colors.purple, setModalState)]),
                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_pingController.text.isNotEmpty) {
                          setState(() {
                            if (_editingPing != null) {
                              _editingPing!.title = _pingController.text;
                              _editingPing!.location = _locationController.text;
                              _editingPing!.date = _formatDate(_selectedDate);
                            } else {
                              Ping newPing = Ping(id: DateTime.now().toString(), hostId: "user_abhimanyu", hostName: "Abhimanyu", title: _pingController.text, date: _formatDate(_selectedDate), timeWindow: "${_startTime.format(context)} - ${_endTime.format(context)}", location: _locationController.text, category: _getCategoryFromString(_selectedCategory), neededSpots: _selectedSpots, totalSpots: _selectedSpots + 1, isFriendHost: true);
                              if (targetHub != null) {
                                targetHub.pings.insert(0, newPing);
                                targetHub.isExpanded = true;
                              } else {
                                _allPings.insert(0, newPing);
                              }
                            }
                            _clearForms();
                          });
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: _selectedColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: Text(_editingPing == null ? "Post Ping" : "Save Changes", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  // --- MINOR HELPERS ---
  Future<void> _pickDate(BuildContext context, StateSetter setModalState) async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (picked != null) setModalState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(BuildContext context, StateSetter setModalState, bool isStart) async {
    final picked = await showTimePicker(context: context, initialTime: isStart ? _startTime : _endTime);
    if (picked != null) setModalState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  Widget _buildTimeBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: _selectedColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: _selectedColor.withOpacity(0.2))),
      child: Column(children: [Text(label, style: TextStyle(fontSize: 10, color: _selectedColor.withOpacity(0.6))), Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _selectedColor))]),
    );
  }

  Widget _categoryChip(IconData icon, String label, Color color, StateSetter setModalState) {
    bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setModalState(() { _selectedCategory = label; _selectedColor = color; }),
      child: Column(children: [
        AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isSelected ? color.withOpacity(0.2) : Colors.black.withOpacity(0.05), shape: BoxShape.circle, border: Border.all(color: isSelected ? color : Colors.transparent, width: 2)), child: Icon(icon, color: isSelected ? color : Colors.grey)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: isSelected ? color : Colors.grey)),
      ]),
    );
  }

  Widget _buildSearchAndFilter() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 5),
      color: isDark ? Colors.transparent : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 45,
            decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(hintText: "Search pings...", prefixIcon: Icon(Icons.search, size: 18), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 10)),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: ["All", "Sports", "Music", "Art", "Hangout"].map((cat) {
                bool isSelected = _activeFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600)),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _activeFilter = val ? cat : "All"),
                    backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
                    selectedColor: const Color(0xFFBB86FC).withOpacity(0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    showCheckmark: false, 
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() { return const Center(child: Text("No pings here yet...")); }
  Widget _buildDetailItem(IconData icon, String label, String value) { return Row(children: [Icon(icon, size: 16, color: Colors.grey), const SizedBox(width: 4), Flexible(child: Text("$label: $value", overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))]); }
  
  ActivityCategory _getCategoryFromString(String cat) {
    switch (cat) { case "Sports": return ActivityCategory.sports; case "Music": return ActivityCategory.music; case "Art": return ActivityCategory.art; case "Hangout": return ActivityCategory.hangout; default: return ActivityCategory.other; }
  }

  void _showGlobalNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            const Text("NOTIFICATIONS", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),
            _buildNotificationItem("Rahul joined your Football ping", "2 mins ago"),
            _buildNotificationItem("New Ping nearby: Tech Talk @ Cafe", "1 hour ago"),
            const SizedBox(height: 20),
            Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Clear All", style: TextStyle(fontSize: 12)))),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showGlobalSettings(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, 
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
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

  Future<void> _launchIG(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Reverted to the standard context!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open Instagram")),
        );
      }
    }
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
}