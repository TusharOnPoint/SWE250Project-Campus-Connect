import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String coverImageUrl;
  final String createdBy;
  final DateTime createdAt;
  final String visibility; // 'public' or 'private'
  final List<String> members; // user UIDs
  final List<String> pendingRequests; // only for private groups
  final Map<String, String> roles; // { uid: role } e.g. { 'abc123': 'admin' }

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.coverImageUrl,
    required this.createdBy,
    required this.createdAt,
    required this.visibility,
    required this.members,
    required this.pendingRequests,
    required this.roles,
  });

  /// Converts GroupModel to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'visibility': visibility,
      'members': members,
      'pendingRequests': pendingRequests,
      'roles': roles,
    };
  }

  /// Creates GroupModel from Firestore map
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      coverImageUrl: map['coverImageUrl'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      visibility: map['visibility'] ?? 'public',
      members: List<String>.from(map['members'] ?? []),
      pendingRequests: List<String>.from(map['pendingRequests'] ?? []),
      roles: Map<String, String>.from(map['roles'] ?? {}),
    );
  }
}
