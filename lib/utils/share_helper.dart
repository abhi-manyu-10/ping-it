import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

// THE GLOBAL KEY FOR PERFECT CAPTURE
final GlobalKey shareKey = GlobalKey();

class ShareHelper {
  static void showSharePreview(BuildContext context, Map<String, dynamic> ping) {
    int currentPage = 0;
    final PageController pageController = PageController(viewportFraction: 0.8);

    // Unify the data keys (Handle both 'name' and 'title')
    final String displayTitle = ping['name'] ?? ping['title'] ?? "Ping Invite";
    final String displayHost = ping['host'] ?? "A Friend";
    final Color pingColor = ping['color'] as Color? ?? const Color(0xFFBB86FC);

    // Generate the deep link
    final String shareLink = "https://pingit.app/join/${displayTitle.hashCode}";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          // Dynamic Themes
          final List<List<Color>> themes = [
            [const Color(0xFF0F0F0F), Colors.black], // Noir
            [const Color(0xFF1A237E), const Color(0xFF311B92)], // Deep Space
            [pingColor, pingColor.withOpacity(0.6)], // Brand Vibe
            [Colors.pink.shade900, Colors.orange.shade900], // Sunset
          ];

          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Color(0xFF0F0F0F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 24),
                const Text("SELECT THEME", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
                const SizedBox(height: 24),
                
                // THE CAPTURE STACK
                Expanded(
                  child: Stack(
                    children: [
                      // GHOST (For Image Generation)
                      Positioned(
                        left: -1000, 
                        child: RepaintBoundary(
                          key: shareKey,
                          child: SizedBox(
                            width: 360, height: 500,
                            child: _buildSocialShareCard(ping, themes[currentPage], shareLink, displayTitle, displayHost),
                          ),
                        ),
                      ),

                      // VIEWER (For User Interaction)
                      PageView.builder(
                        controller: pageController,
                        itemCount: themes.length,
                        onPageChanged: (index) => setSheetState(() => currentPage = index),
                        itemBuilder: (context, index) {
                          return AnimatedScale(
                            scale: currentPage == index ? 1.0 : 0.9,
                            duration: const Duration(milliseconds: 300),
                            child: _buildSocialShareCard(ping, themes[index], shareLink, displayTitle, displayHost),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // SOCIAL ACTIONS
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _socialIcon(Icons.link_rounded, "Copy Link", Colors.blue, () {
                        Clipboard.setData(ClipboardData(text: shareLink));
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link copied! Sticker it on your Story.")));
                      }),
                      _socialIcon(FontAwesomeIcons.instagram, "Instagram", Colors.pink, () => _shareToSocials()),
                      _socialIcon(FontAwesomeIcons.whatsapp, "WhatsApp", Colors.green, () => _shareToSocials()),
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
      await Future.delayed(const Duration(milliseconds: 150));
      final RenderRepaintBoundary? boundary = shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || boundary.debugNeedsLayout) return;

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

  // Updated Card with All Event Info
  static Widget _buildSocialShareCard(Map<String, dynamic> ping, List<Color> colors, String link, String title, String host) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          // Decorative Background Aura
          Positioned(bottom: -50, right: -50, child: Icon(Icons.blur_on, size: 250, color: Colors.white.withOpacity(0.05))),
          
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(children: [Icon(Icons.bolt, color: Colors.amber, size: 18), SizedBox(width: 8), Text("PING IT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 10))]),
                    Text(ping['vibe']?.toString().toUpperCase() ?? "PUBLIC", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
                const Spacer(),
                
                // EVENT INFO
                Text(title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.0)),
                const SizedBox(height: 12),
                Text(
                  "By $host\n${ping['date'] ?? 'Today'} @ ${ping['time'] ?? 'Live'}\n${ping['location'] ?? 'Nearby'}",
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
                ),
                
                const Spacer(),

                // QR FOOTER
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: QrImageView(data: link, size: 50, padding: EdgeInsets.zero, version: QrVersions.auto),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("SCAN TO JOIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                          Text("or tap link in story", style: TextStyle(color: Colors.white70, fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}