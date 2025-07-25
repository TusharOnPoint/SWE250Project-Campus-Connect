import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FriendRelationInfo {
  final String currentUserId;
  final String otherUserId;
  final String otherUsername;

  FriendRelationInfo({
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUsername,
  });
}

class FriendManager {
  static Future<void> sendFriendRequest(
    BuildContext context,
    FriendRelationInfo info,
  ) async {
    if (info.otherUserId == info.currentUserId) return;

    final senderRef = FirebaseFirestore.instance.collection('users').doc(info.currentUserId);
    final receiverRef = FirebaseFirestore.instance.collection('users').doc(info.otherUserId);

    try {
      await senderRef.update({
        'friend_requests_sent': FieldValue.arrayUnion([info.otherUserId]),
      });
      await receiverRef.update({
        'friend_requests': FieldValue.arrayUnion([info.currentUserId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request sent to ${info.otherUsername}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending request: $e')),
      );
    }
  }

  static Future<void> cancelFriendRequest(
    BuildContext context,
    FriendRelationInfo info,
  ) async {
    final senderRef = FirebaseFirestore.instance.collection('users').doc(info.currentUserId);
    final receiverRef = FirebaseFirestore.instance.collection('users').doc(info.otherUserId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(senderRef, {
          'friend_requests_sent': FieldValue.arrayRemove([info.otherUserId]),
        });
        transaction.update(receiverRef, {
          'friend_requests': FieldValue.arrayRemove([info.currentUserId]),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cancelled request to ${info.otherUsername}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  static Future<void> cancelReceivedRequest(
    BuildContext context,
    FriendRelationInfo info,
  ) async {
    final receiverRef = FirebaseFirestore.instance.collection('users').doc(info.currentUserId);
    final senderRef = FirebaseFirestore.instance.collection('users').doc(info.otherUserId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(receiverRef, {
          'friend_requests': FieldValue.arrayRemove([info.otherUserId]),
        });
        transaction.update(senderRef, {
          'friend_requests_sent': FieldValue.arrayRemove([info.currentUserId]),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cancelled request from ${info.otherUsername}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  static Future<void> unfriend(
    BuildContext context,
    FriendRelationInfo info,
  ) async {
    final myRef = FirebaseFirestore.instance.collection('users').doc(info.currentUserId);
    final friendRef = FirebaseFirestore.instance.collection('users').doc(info.otherUserId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(myRef, {
          'friends': FieldValue.arrayRemove([info.otherUserId]),
        });
        transaction.update(friendRef, {
          'friends': FieldValue.arrayRemove([info.currentUserId]),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unfriended ${info.otherUsername}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unfriend: $e')),
      );
    }
  }

  static Future<void> acceptFriendRequest(
    BuildContext context,
    FriendRelationInfo info,
  ) async {
    final receiverRef = FirebaseFirestore.instance.collection('users').doc(info.currentUserId);
    final senderRef = FirebaseFirestore.instance.collection('users').doc(info.otherUserId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(receiverRef, {
          'friend_requests': FieldValue.arrayRemove([info.otherUserId]),
          'friends': FieldValue.arrayUnion([info.otherUserId]),
        });

        transaction.update(senderRef, {
          'friend_requests_sent': FieldValue.arrayRemove([info.currentUserId]),
          'friends': FieldValue.arrayUnion([info.currentUserId]),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You and ${info.otherUsername} are now friends!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
