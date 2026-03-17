import 'package:flutter/material.dart';

enum ActivityCategory { sports, music, art, hangout, tech, other }

class Ping {
  final String id;
  final String hostId; // To check against user's friend list
  final String hostName;
  final String title;
  String date;
  final String description; // For the "Ask Question" context
  final ActivityCategory category;
  final String timeWindow; 
  final String location;
  final String? igGroupLink; // THE IG UPGRADE
  
  int neededSpots;
  final int totalSpots;
  
  bool isJoined;
  bool isExpanded;
  bool isFriendHost; // For the "Friends on Top" dopamine effect

  Ping({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.title,
    this.description = "No description provided.",
    required this.category,
    required this.timeWindow,
    required this.location,
    this.igGroupLink,
    required this.neededSpots,
    required this.totalSpots,
    this.isJoined = false,
    this.isExpanded = false,
    this.isFriendHost = false,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "hostId": hostId,
      "title": title,
      "location": location,
      "timeWindow": timeWindow,
      "categoryName": category.name,
      "neededSpots": neededSpots,
      "totalSpots": totalSpots,
      // We can add logic here later to determine color based on category
    };
  }

  // SMART GETTERS
  Color get color {
    switch (category) {
      case ActivityCategory.sports: return const Color(0xFF4CAF50);
      case ActivityCategory.music: return const Color(0xFFFF9800);
      case ActivityCategory.art: return const Color(0xFF2196F3);
      case ActivityCategory.hangout: return const Color(0xFFE91E63);
      case ActivityCategory.tech: return const Color(0xFF9C27B0);
      default: return Colors.blueGrey;
    }
  }

  IconData get icon {
    switch (category) {
      case ActivityCategory.sports: return Icons.sports_soccer;
      case ActivityCategory.music: return Icons.mic_external_on;
      case ActivityCategory.art: return Icons.brush;
      case ActivityCategory.hangout: return Icons.groups;
      case ActivityCategory.tech: return Icons.code;
      default: return Icons.bolt;
    }
  }
}