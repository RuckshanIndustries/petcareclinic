import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to categorize notifications
  Stream<QuerySnapshot> _getNotificationsStream() {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: _auth.currentUser!.uid)
        .orderBy('timestamp', descending: true) // To show paid appointments on top
        .snapshots();
  }


  // Building the notification UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getNotificationsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var notifications = snapshot.data!.docs;

          // Display paid appointments on top
          var paidAppointments = notifications.where((notif) => notif['status'] == 'paid').toList();
          var otherNotifications = notifications.where((notif) => notif['status'] != 'paid').toList();

          // Combine lists: paid appointments first
          var allNotifications = [...paidAppointments, ...otherNotifications];

          return ListView.builder(
            itemCount: allNotifications.length,
            itemBuilder: (context, index) {
              var notification = allNotifications[index];
              String notificationType = notification['type']; // e.g., 'appointment', 'payment', 'price_set'

              // Customize UI based on the notification type
              return ListTile(
                title: Text(notification['title']),
                subtitle: Text(notification['body']),
                trailing: Text(notification['timestamp'].toDate().toString()),
                onTap: () {
                  // Handle tap, like navigating to a specific screen based on the notification type
                },
                leading: Icon(
                  _getNotificationIcon(notificationType),
                  color: _getNotificationColor(notificationType),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper function to get icon for the notification type
  IconData _getNotificationIcon(String notificationType) {
    switch (notificationType) {
      case 'appointment':
        return Icons.calendar_today;
      case 'price_set':
        return Icons.attach_money;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  // Helper function to get color based on notification type
  Color _getNotificationColor(String notificationType) {
    switch (notificationType) {
      case 'appointment':
        return Colors.blue;
      case 'price_set':
        return Colors.green;
      case 'payment':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
