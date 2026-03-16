import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// THE GLOBAL KEY FOR PERFECT CAPTURE
final GlobalKey shareKey = GlobalKey();

class ShareHelper {
  static void showSharePreview(BuildContext context, Map<String, dynamic> ping) {
    int currentPage = 0;
    final PageController pageController = PageController(viewportFraction: 0.85);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          // Define themes here so both the Ghost and the Viewer can use them
          final List<List<Color>> themes = [
            [Colors.black, Colors.grey.shade900],
            [Colors.blue.shade900, Colors.purple.shade900],
            [ping['color'] ?? Colors.deepPurple, (ping['color'] as Color?)?.withAlpha(120) ?? Colors.black],
          ];

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 15),
                Container(
                  width: 40, 
                  height: 5, 
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))
                ),
                const SizedBox(height: 30),
                
                // THE STACK: Ghost (Hidden) + Viewer (Visible)
                Stack(
                  children: [
                    // 1. THE GHOST WIDGET (Off-screen capture target)
                    // This ensures NO carousel bleed in the shared image.
                    Positioned(
                      left: -1000, // Move it far off screen
                      child: RepaintBoundary(
                        key: shareKey,
                        child: SizedBox(
                          width: 320,  // Fixed dimensions for 9:16 export
                          height: 568, 
                          child: _buildSocialShareCard(ping, themes[currentPage]),
                        ),
                      ),
                    ),

                    // 2. THE VIEWER (What the user swiped on)
                    SizedBox(
                      height: 460, // Slightly reduced to prevent bottom overflow
                      child: PageView.builder(
                        controller: pageController,
                        itemCount: 3,
                        onPageChanged: (index) => setSheetState(() => currentPage = index),
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) => _buildSocialShareCard(ping, themes[index]),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // THE INDICATOR
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentPage == index ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  )),
                ),
                
                const Spacer(),
                
                // ACTION BUTTONS
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _socialIcon(Icons.link, "Copy Link", Colors.grey, () {
                        Clipboard.setData(const ClipboardData(text: "Join my Ping! https://pingit.app/invite"));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link copied to clipboard!")));
                      }),
                      _socialIcon(FontAwesomeIcons.whatsapp, "WhatsApp", Colors.green, () => _shareToSocials()),
                      _socialIcon(FontAwesomeIcons.instagram, "Stories", Colors.pink, () => _shareToSocials()),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Future<void> _shareToSocials() async {
    try {
      // Small delay to ensure the "Ghost" has rendered the specific theme
      await Future.delayed(const Duration(milliseconds: 150));

      final RenderRepaintBoundary? boundary = shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null || boundary.debugNeedsLayout) return;

      // High-res capture for the Play Store quality
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final String path = '${directory.path}/ping_share_${DateTime.now().millisecondsSinceEpoch}.png';
      final File imageFile = File(path);
      await imageFile.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(path, mimeType: 'image/png')]);
    } catch (e) {
      debugPrint("Capture failed: $e");
    }
  }

  static Widget _socialIcon(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(backgroundColor: Colors.white10, radius: 25, child: Icon(icon, color: Colors.white, size: 20)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  static Widget _buildSocialShareCard(Map<String, dynamic> ping, List<Color> gradientColors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Decorative Aura
            Positioned(top: -60, right: -60, child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)))),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BRANDING
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [const Icon(Icons.bolt, color: Colors.amber, size: 20), const SizedBox(width: 6), Text("PING IT", style: TextStyle(color: Colors.white.withOpacity(0.9), letterSpacing: 4, fontWeight: FontWeight.w900, fontSize: 11))]),
                      Text("LIVE", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(flex: 2),
                  // GLASS ICON
                  Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.1))), child: Icon(ping['icon'] ?? Icons.bolt, color: Colors.white, size: 52)),
                  const SizedBox(height: 28),
                  // TYPOGRAPHY
                  Text(ping['title'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1.0, letterSpacing: -0.5)),
                  const SizedBox(height: 10),
                  Text("@ ${ping['location'] ?? 'Kolkata'}\n${ping['time']}", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15, fontWeight: FontWeight.w500, height: 1.4)),
                  const Spacer(flex: 3),
                  // FOOTER (Strictly size-controlled to prevent overflow)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.qr_code_2, color: Colors.black, size: 28)),
                        const SizedBox(width: 12),
                        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          Text("SCAN TO JOIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                          Text("pingit.app/join", style: TextStyle(color: Colors.white54, fontSize: 9)),
                        ])),
                      ],
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