import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      // 1. Request Permission
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print('DEBUG: Notification permission status: ${settings.authorizationStatus}');

      // 2. Setup Local Notifications (for Foreground messages)
      AndroidInitializationSettings initializationSettingsAndroid =
          const AndroidInitializationSettings('@mipmap/ic_launcher');
      InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          // Handle foreground notification tap
          print('DEBUG: Foreground notification tapped');
        },
      );

      // 3. Listen for Foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('DEBUG: Foreground message received: ${message.notification?.title}');
        showLocalNotification(message.notification?.title, message.notification?.body);
      });

      // 4. Handle Notification Tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('DEBUG: App opened via notification: ${message.data}');
        // You can add navigation logic here
      });

      // 5. Check if app was opened via notification from terminated state
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        print('DEBUG: App launched from terminated state via notification');
      }

      // 6. Listen for Auth Changes to update token
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null) {
          updateToken();
        }
      });

      // Initial token update attempt
      await updateToken();
    } catch (e) {
      debugPrint("Notification Initialization Failed: $e");
    }
  }

  Future<void> updateToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? token = await _fcm.getToken();
        if (token != null) {
          print('DEBUG: Updating FCM Token in Firestore for user: ${user.uid}');
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'fcmToken': token,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint("FCM Token Update Failed: $e");
    }
  }

  Future<void> showLocalNotification(String? title, String? body) async {
    AndroidNotificationDetails androidDetails = const AndroidNotificationDetails(
      'emergency_channel',
      'Emergency Alerts',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );
    NotificationDetails details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecond,
      title ?? 'Emergency Alert',
      body ?? 'Someone needs help nearby.',
      details,
    );
  }
}
