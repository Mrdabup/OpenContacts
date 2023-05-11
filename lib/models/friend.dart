import 'package:contacts_plus_plus/models/session.dart';
import 'package:contacts_plus_plus/models/user_profile.dart';
import 'package:flutter/material.dart';

class Friend extends Comparable {
  final String id;
  final String username;
  final String ownerId;
  final UserStatus userStatus;
  final UserProfile userProfile;
  final FriendStatus friendStatus;
  final DateTime latestMessageTime;

  Friend({required this.id, required this.username, required this.ownerId, required this.userStatus, required this.userProfile,
    required this.friendStatus, required this.latestMessageTime,
  });

  factory Friend.fromMap(Map map) {
    return Friend(
      id: map["id"],
      username: map["friendUsername"] ?? map["username"],
      ownerId: map["ownerId"] ?? map["id"],
      userStatus: UserStatus.fromMap(map["userStatus"]),
      userProfile: UserProfile.fromMap(map["profile"] ?? {}),
      friendStatus: FriendStatus.fromString(map["friendStatus"]),
      latestMessageTime: map["latestMessageTime"] == null
          ? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.parse(map["latestMessageTime"]),
    );
  }

  Friend copyWith({
    String? id, String? username, String? ownerId, UserStatus? userStatus, UserProfile? userProfile,
    FriendStatus? friendStatus, DateTime? latestMessageTime}) {
    return Friend(
      id: id ?? this.id,
      username: username ?? this.username,
      ownerId: ownerId ?? this.ownerId,
      userStatus: userStatus ?? this.userStatus,
      userProfile: userProfile ?? this.userProfile,
      friendStatus: friendStatus ?? this.friendStatus,
      latestMessageTime: latestMessageTime ?? this.latestMessageTime,
    );
  }

  Map toMap({bool shallow=false}) {
    return {
      "id": id,
      "username": username,
      "ownerId": ownerId,
      "userStatus": userStatus.toMap(shallow: shallow),
      "profile": userProfile.toMap(),
      "friendStatus": friendStatus.name,
      "latestMessageTime": latestMessageTime.toIso8601String(),
    };
  }

  @override
  int compareTo(covariant Friend other) {
    return username.compareTo(other.username);
  }
}

enum FriendStatus {
  none,
  searchResult,
  requested,
  ignored,
  blocked,
  accepted;

  factory FriendStatus.fromString(String text) {
    return FriendStatus.values.firstWhere((element) => element.name.toLowerCase() == text.toLowerCase(),
      orElse: () => FriendStatus.none,
    );
  }
}

enum OnlineStatus {
  offline,
  invisible,
  away,
  busy,
  online;

  static final List<Color> _colors = [
    Colors.white54,
    Colors.white54,
    Colors.yellow,
    Colors.red,
    Colors.green,
  ];

  Color get color => _colors[index];

  factory OnlineStatus.fromString(String? text) {
    return OnlineStatus.values.firstWhere((element) => element.name.toLowerCase() == text?.toLowerCase(),
      orElse: () => OnlineStatus.offline,
    );
  }

  int compareTo(OnlineStatus other) {
    if (this == other) return 0;
    if (this == OnlineStatus.online) return -1;
    if (other == OnlineStatus.online) return 1;
    if (this == OnlineStatus.away) return -1;
    if (other == OnlineStatus.away) return 1;
    if (this == OnlineStatus.busy) return -1;
    if (other == OnlineStatus.busy) return 1;
    return 0;
  }
}

class UserStatus {
  final OnlineStatus onlineStatus;
  final DateTime lastStatusChange;
  final List<Session> activeSessions;
  final String neosVersion;

  const UserStatus({required this.onlineStatus, required this.lastStatusChange, required this.activeSessions,
    required this.neosVersion,
  });

  factory UserStatus.empty() => UserStatus(
    onlineStatus: OnlineStatus.offline,
    lastStatusChange: DateTime.now(),
    activeSessions: [],
    neosVersion: "",
  );

  factory UserStatus.fromMap(Map map) {
    final statusString = map["onlineStatus"] as String?;
    final status = OnlineStatus.fromString(statusString);
    return UserStatus(
      onlineStatus: status,
      lastStatusChange: DateTime.parse(map["lastStatusChange"]),
      activeSessions: (map["activeSessions"] as List? ?? []).map((e) => Session.fromMap(e)).toList(),
      neosVersion: map["neosVersion"] ?? "",
    );
  }

  Map toMap({bool shallow=false}) {
    return {
      "onlineStatus": onlineStatus.name,
      "lastStatusChange": lastStatusChange.toIso8601String(),
      "activeSessions": shallow ? [] : activeSessions.map((e) => e.toMap(),),
      "neosVersion": neosVersion,
    };
  }

  UserStatus copyWith({OnlineStatus? onlineStatus, DateTime? lastStatusChange, List<Session>? activeSessions,
    String? neosVersion
  })
  => UserStatus(
      onlineStatus: onlineStatus ?? this.onlineStatus,
      lastStatusChange: lastStatusChange ?? this.lastStatusChange,
      activeSessions: activeSessions ?? this.activeSessions,
    neosVersion: neosVersion ?? this.neosVersion,
  );
}