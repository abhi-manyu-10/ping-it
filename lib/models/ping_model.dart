import 'package:flutter/material.dart';

enum ActivityCategory { sports, music, art, hangout, other }

class Ping {
  final String id;
  String hostId;
  String hostName;
  String title;
  String description;
  ActivityCategory category;
  String date; // NEW: Added Date
  String timeWindow;
  String location;
  int neededSpots;
  int totalSpots;
  bool isJoined;
  bool isFriendHost;
  bool isExpanded;
  String? igGroupLink;

  Ping({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.title,
    this.description = "",
    required this.category,
    required this.date, // NEW
    required this.timeWindow,
    required this.location,
    required this.neededSpots,
    required this.totalSpots,
    this.isJoined = false,
    this.isFriendHost = false,
    this.isExpanded = false,
    this.igGroupLink,
  });

  IconData get icon {
    switch (category) {
      case ActivityCategory.sports: return Icons.sports_soccer;
      case ActivityCategory.music: return Icons.mic_external_on;
      case ActivityCategory.art: return Icons.brush;
      case ActivityCategory.hangout: return Icons.groups;
      default: return Icons.local_activity;
    }
  }

  Color get color {
    switch (category) {
      case ActivityCategory.sports: return Colors.greenAccent;
      case ActivityCategory.music: return Colors.orangeAccent;
      case ActivityCategory.art: return Colors.blueAccent;
      case ActivityCategory.hangout: return Colors.purpleAccent;
      default: return const Color(0xFFBB86FC);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "hostId": hostId,
      "title": title,
      "location": location,
      "date": date,
      "timeWindow": timeWindow,
      "categoryName": category.name,
      "neededSpots": neededSpots,
      "totalSpots": totalSpots,
      "color": color,
    };
  }
}

// NEW: The Hub Folder Class
class PingHub {
  final String id;
  String hostId;
  String hostName;
  String title;
  String location;
  ActivityCategory category;
  List<Ping> pings; // The nested folder contents
  bool isExpanded;

  PingHub({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.title,
    required this.location,
    required this.category,
    required this.pings,
    this.isExpanded = false,
  });

  Color get color {
    switch (category) {
      case ActivityCategory.sports: return Colors.greenAccent;
      case ActivityCategory.music: return Colors.orangeAccent;
      case ActivityCategory.art: return Colors.blueAccent;
      case ActivityCategory.hangout: return Colors.purpleAccent;
      default: return const Color(0xFFBB86FC);
    }
  }
}