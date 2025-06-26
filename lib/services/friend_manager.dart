import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FriendManager {
  static Future<void> sendFriendRequest(
    BuildContext context,
    String currentUserId,
    String receiverId,
    String receiverUsername,
  ) async {
    if (receiverId == currentUserId) return;

    final senderId = currentUserId;
    final senderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(senderId);
    final receiverRef = FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId);

    try {
      await senderRef.update({
        'friend_requests_sent': FieldValue.arrayUnion([receiverId]),
      });
      await receiverRef.update({
        'friend_requests': FieldValue.arrayUnion([senderId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request sent to $receiverUsername')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending request: $e')));
    }
  }

  static Future<void> cancelFriendRequest(
    BuildContext context,
    String currentUserId,
    String receiverId,
    String receiverUsername,
  ) async {
    //if (currentUserId) return;

    final senderId = currentUserId;
    final senderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(senderId);
    final receiverRef = FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(senderRef, {
          'friend_requests_sent': FieldValue.arrayRemove([receiverId]),
        });
        transaction.update(receiverRef, {
          'friend_requests': FieldValue.arrayRemove([senderId]),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cancelled request to $receiverUsername')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  static Future<void> cancelReceivedRequest(
    BuildContext context,
    String currentUserId,
    String senderId,
    String senderUsername,
  ) async {
    final receiverId = currentUserId;
    final receiverRef = FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId);
    final senderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(senderId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(receiverRef, {
          'friend_requests': FieldValue.arrayRemove([senderId]),
        });
        transaction.update(senderRef, {
          'friend_requests_sent': FieldValue.arrayRemove([receiverId]),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cancelled request from $senderUsername')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  static Future<void> unfriend(
    BuildContext context,
    String currentUserId,
    String friendId,
    String friendName,
  ) async {
    final myRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId);
    final friendRef = FirebaseFirestore.instance
        .collection('users')
        .doc(friendId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(myRef, {
          'friends': FieldValue.arrayRemove([friendId]),
        });
        transaction.update(friendRef, {
          'friends': FieldValue.arrayRemove([currentUserId]),
        });
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unfriended $friendName')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to unfriend: $e')));
    }
  }
  static Future<void> acceptFriendRequest(
    BuildContext context,
    String currentUserId,
    String senderId,
    String senderUsername,
  ) async {

    final receiverId = currentUserId;
    final receiverRef = FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId);
    final senderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(senderId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(receiverRef, {
          'friend_requests': FieldValue.arrayRemove([senderId]),
          'friends': FieldValue.arrayUnion([senderId]),
        });

        transaction.update(senderRef, {
          'friend_requests_sent': FieldValue.arrayRemove([receiverId]),
          'friends': FieldValue.arrayUnion([receiverId]),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You and $senderUsername are now friends!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
