import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  // We now accept the global pings and a reuse function from main.dart
  final List<Map<String, dynamic>> historyPings;
  final Function(Map<String, dynamic>) onReusePing;

  const ProfileScreen({
    super.key,
    required this.historyPings,
    required this.onReusePing,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late TabController _historyTabController;
  int _expandedHistoryIndex = -1;

  @override
  void initState() {
    super.initState();
    _historyTabController = TabController(length: 2, vsync: this);
    _historyTabController.addListener(() {
      if (!_historyTabController.indexIsChanging) {
        setState(() {
          _expandedHistoryIndex = -1;
        });
      }
    });
  }

  @override
  void dispose() {
    _historyTabController.dispose();
    super.dispose();
  }

  // --- IDENTITY STATE (Kept local for now) ---
  String username = "ABHIMANYU";
  String bio = "3rd Year • B.Tech CSE";
  bool isTagsExpanded = false;
  final int maxVisibleTags = 4;

  List<Map<String, dynamic>> vibeTags = [
    {"label": "Football", "color": Colors.greenAccent},
    {"label": "Drawing", "color": Colors.blueAccent},
    {"label": "Singing", "color": Colors.orangeAccent},
    {"label": "Movies", "color": Colors.pinkAccent},
    {"label": "Coding", "color": Colors.cyanAccent},
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(isDark),
            const SizedBox(height: 32),
            _buildStatsRow(),
            const SizedBox(height: 40),
            _buildVibeTagsSection(isDark),
            const SizedBox(height: 48),
            const Text("HISTORY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2, color: Colors.grey)),
            const SizedBox(height: 16),
            _buildHistoryTabs(isDark),
            const SizedBox(height: 20),
            _buildHistoryList(isDark),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- UI BUILDERS ---

  Widget _buildProfileHeader(bool isDark) {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: () => _showEditSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFBB86FC), Color(0xFF6200EE)])),
                  child: const CircleAvatar(radius: 55, backgroundColor: Colors.black),
                ),
              ),
              GestureDetector(
                onTap: () => _showEditSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                  child: const Icon(Icons.bolt, color: Colors.black, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(username, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
          Text(bio, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildVibeTagsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("CURRENT VIBE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2, color: Colors.grey)),
            if (vibeTags.length > maxVisibleTags)
              GestureDetector(
                onTap: () => setState(() => isTagsExpanded = !isTagsExpanded),
                child: Text(
                  isTagsExpanded ? "Show Less" : "+${vibeTags.length - maxVisibleTags} more", 
                  style: const TextStyle(fontSize: 10, color: Color(0xFFBB86FC), fontWeight: FontWeight.bold)
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Removed AnimatedSize here for instant snapping
        Wrap(
          spacing: 10, runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...(isTagsExpanded ? vibeTags : vibeTags.take(maxVisibleTags).toList()).asMap().entries.map((entry) {
              return _buildVibeChip(entry.key, entry.value['label'], entry.value['color'], isDark);
            }).toList(),
            GestureDetector(
              onTap: () => _showAddTagSheet(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.add_rounded, size: 18, color: isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVibeChip(int index, String label, Color color, bool isDark) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.heavyImpact();
        setState(() {
          vibeTags.removeAt(index);
          // Auto-collapse if we drop below the max visible threshold
          if (vibeTags.length <= maxVisibleTags) isTagsExpanded = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.08 : 0.05), 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: color.withOpacity(0.2), width: 0.5)
        ),
        child: Text(label, style: TextStyle(color: color.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }
  Widget _buildHistoryTabs(bool isDark) {
    return TabBar(
      controller: _historyTabController,
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      indicator: const BoxDecoration(),
      dividerColor: Colors.transparent,
      labelColor: isDark ? Colors.white : Colors.black,
      unselectedLabelColor: Colors.grey.shade600,
      labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
      unselectedLabelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.5),
      tabs: const [Tab(text: "My Pings"), Tab(text: "Joined")],
    );
  }

  Widget _buildHistoryList(bool isDark) {
    bool isHostedTab = _historyTabController.index == 0;
    
    // Uses the global list passed from main.dart
    List<Map<String, dynamic>> filteredList = widget.historyPings.where((item) {
      // Assuming 'isHost' is a boolean in your main explore data
      // Adjust this condition based on how your explore data is structured
      bool isHost = item['isHost'] ?? (item['type'] == 'hosted');
      return isHostedTab ? isHost : !isHost;
    }).toList();

    if (filteredList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(child: Text("No pings here yet.", style: TextStyle(color: Colors.grey.shade600))),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final item = filteredList[index];
        final originalIndex = widget.historyPings.indexOf(item);
        return _buildExpandableHistoryCard(item, originalIndex, isDark);
      },
    );
  }

  Widget _buildExpandableHistoryCard(Map<String, dynamic> item, int originalIndex, bool isDark) {
    final Color color = item['color'] ?? const Color(0xFFBB86FC); // Fallback color
    final bool isExpanded = _expandedHistoryIndex == originalIndex;

    // Safely extract data based on your Explore formatting
    String title = item['title'] ?? "Unknown Vibe";
    String date = item['date'] ?? item['time'] ?? "Today";
    String location = item['location'] ?? "Nearby";
    String duration = item['duration'] ?? "TBD";
    List<dynamic> members = item['members'] ?? ["A"]; // Mock member if none

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _expandedHistoryIndex = isExpanded ? -1 : originalIndex;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(isExpanded ? 0.06 : 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded ? color.withOpacity(0.3) : (isDark ? Colors.white10 : Colors.grey.shade100),
            width: isExpanded ? 1.5 : 1, 
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text("$date • $location", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ]),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
            
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text("${members.length} Members", style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(duration, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        height: 25,
                        width: 100, 
                        child: Stack(
                          children: List.generate(members.length, (i) {
                            return Positioned(
                              left: i * 15.0,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: isDark ? color.withOpacity(0.2) : color.withOpacity(0.1),
                                child: Text(members[i].toString().substring(0,1).toUpperCase(), style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold)),
                              ),
                            );
                          }),
                        ),
                      ),
                      // THE REUSE TRIGGER
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          widget.onReusePing(item); // Calls the function passed from main.dart!
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Icon(Icons.refresh_rounded, size: 12, color: color),
                              const SizedBox(width: 4),
                              Text("REUSE", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _buildStatTile("${widget.historyPings.length}", "PINGS"), 
      _buildStatTile("48", "JOINED"), 
      _buildStatTile("4.9", "VIBE")
    ]);
  }

  Widget _buildStatTile(String value, String label) {
    return Column(children: [Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))]);
  }

  // --- SHEETS ---

  void _showAddTagSheet(BuildContext context) {
    final tagController = TextEditingController();
    Color selectedColor = const Color(0xFFBB86FC); // Default starting color
    
    // The palette of colors users can choose from
    final List<Color> colorPalette = [
      Colors.greenAccent, Colors.blueAccent, Colors.orangeAccent, 
      Colors.pinkAccent, const Color(0xFFBB86FC), Colors.cyanAccent,
      Colors.redAccent, Colors.yellowAccent
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24, 
              left: 24, right: 24, top: 20
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161616) : Colors.white, 
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32))
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40, height: 4, 
                    decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text("NEW VIBE TAG", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                const SizedBox(height: 20),
                
                // Vibe Input Field
                TextField(
                  controller: tagController,
                  autofocus: true,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: "What's your vibe?",
                    hintStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text("CHOOSE A COLOR", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 12),
                
                // Color Picker Row
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: colorPalette.map((color) {
                    bool isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setModalState(() => selectedColor = color); // Updates just the bottom sheet
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, 
                          border: Border.all(color: isSelected ? color : Colors.transparent, width: 2)
                        ),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: isDark ? color.withOpacity(0.3) : color.withOpacity(0.8),
                          child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                
                // Post Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (tagController.text.trim().isNotEmpty) {
                        setState(() {
                          vibeTags.add({"label": tagController.text.trim(), "color": selectedColor});
                        });
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? selectedColor.withOpacity(0.15) : selectedColor,
                      foregroundColor: isDark ? selectedColor : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("ADD VIBE", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    final nameController = TextEditingController(text: username);
    final bioController = TextEditingController(text: bio);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32, // Accommodates the keyboard
          left: 24, right: 24, top: 16,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161616) : Colors.white, 
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. The "Grabbable" Drag Handle
            Center(
              child: Container(
                width: 40, 
                height: 4, 
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300, 
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // 2. Title & Minimal Save Button in one row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "EDIT PROFILE", 
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)
                ),
                TextButton(
                  onPressed: () {
                    setState(() { 
                      username = nameController.text.toUpperCase(); 
                      bio = bioController.text; 
                    });
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    // A subtle, translucent background instead of a solid block
                    backgroundColor: isDark ? const Color(0xFFBB86FC).withOpacity(0.1) : const Color(0xFF6200EE).withOpacity(0.1),
                    foregroundColor: isDark ? const Color(0xFFBB86FC) : const Color(0xFF6200EE),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text("Save", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 3. The Fields
            _buildEditField("YOUR NAME", nameController, isDark, Icons.person_outline_rounded),
            const SizedBox(height: 20),
            _buildEditField("BIO / COLLEGE", bioController, isDark, Icons.edit_note_rounded),
            
            // Removed the giant bottom button entirely!
            const SizedBox(height: 10), 
          ],
        ),
      ),
    );
  }

  // Make sure to replace your old _buildEditField with this one!
  Widget _buildEditField(String label, TextEditingController controller, bool isDark, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 10),
        TextField(
          controller: controller, 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20), // Adds visual anchor
            filled: true, 
            fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade100, 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), // Rounder corners
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), // Taller, more comfortable touch target
          )
        ),
      ]
    );
  }
}