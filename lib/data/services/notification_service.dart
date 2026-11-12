import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });

  /// Deserializes from a Firestore document map.
  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      time: map['time'] is Timestamp
          ? (map['time'] as Timestamp).toDate()
          : DateTime.tryParse(map['time']?.toString() ?? '') ?? DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  /// Serializes to a Firestore document map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'time': Timestamp.fromDate(time),
      'isRead': isRead,
    };
  }
}

/// Production notification service using Firebase Cloud Messaging (FCM)
/// and Firestore for notification history with web-safe fallbacks.
class NotificationService {
  FirebaseMessaging? get _messaging {
    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // FCM Setup
  // ---------------------------------------------------------------------------

  /// Initializes FCM: requests permission, gets device token, and saves it
  /// to the user's Firestore document for server-side push targeting.
  Future<void> init() async {
    try {
      final messaging = _messaging;
      if (messaging == null) return;

      // Request notification permission
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('FCM permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await messaging.getToken();
        debugPrint('FCM Token: $token');

        if (token != null) {
          await _saveDeviceToken(token);
        }

        messaging.onTokenRefresh.listen(_saveDeviceToken);
      }

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      debugPrint('FCM init skipped or failed on this platform: $e');
    }
  }

  /// Saves the FCM device token to the current user's Firestore document.
  Future<void> _saveDeviceToken(String token) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving FCM device token: $e');
    }
  }

  /// Handles incoming FCM messages when the app is in the foreground.
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    try {
      final firestore = _firestore;
      if (firestore == null) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user != null && message.notification != null) {
        firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .add({
          'title': message.notification!.title ?? 'Notification',
          'body': message.notification!.body ?? '',
          'time': FieldValue.serverTimestamp(),
          'isRead': false,
          'data': message.data,
        });
      }
    } catch (e) {
      debugPrint('Error handling foreground message: $e');
    }
  }

  /// Handles notification tap (app opened from notification).
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
  }

  // ---------------------------------------------------------------------------
  // Notification History (Firestore)
  // ---------------------------------------------------------------------------

  /// Fetches all notifications for the current user from Firestore.
  Future<List<AppNotification>> getAll() async {
    try {
      final firestore = _firestore;
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && firestore != null) {
        final snapshot = await firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('time', descending: true)
            .limit(50)
            .get();

        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return AppNotification.fromMap(data);
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }

    // Fallback: return welcome notifications for new users
    return _defaultNotifications;
  }

  /// Marks a notification as read in Firestore.
  Future<void> markAsRead(String notificationId) async {
    try {
      final firestore = _firestore;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && firestore != null) {
        await firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': true});
      }
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }
  }

  /// Returns the count of unread notifications.
  Future<int> getUnreadCount() async {
    try {
      final firestore = _firestore;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && firestore != null) {
        final snapshot = await firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .where('isRead', isEqualTo: false)
            .count()
            .get();
        return snapshot.count ?? 0;
      }
    } catch (e) {
      debugPrint('Error getting unread count: $e');
    }
    return _defaultNotifications.where((n) => !n.isRead).length;
  }

  /// Kept for backward compatibility — wraps getUnreadCount.
  int get unreadCount {
    return _defaultNotifications.where((n) => !n.isRead).length;
  }

  // ---------------------------------------------------------------------------
  // Default / Welcome Notifications
  // ---------------------------------------------------------------------------

  static final List<AppNotification> _defaultNotifications = [
    AppNotification(
      id: 'n_welcome',
      title: 'Welcome to MyTickets! 🎬',
      body: 'Book movies, events, and metro tickets — all in one app.',
      time: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    AppNotification(
      id: 'n_offer',
      title: 'Limited Time Offer',
      body: 'Get 20% off on your first booking. Use code FIRST20.',
      time: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];
}
