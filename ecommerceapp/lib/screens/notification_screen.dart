import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'shoes_details.dart';

class NotificationsScreen extends StatefulWidget {
  final String token;
  final String userId;

  const NotificationsScreen({
    super.key,
    required this.token,
    required this.userId,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  bool _isFrench = true;
  bool _hasError = false;
  int _unreadCount = 0;

  final String baseUrl = 'http://localhost:5000';

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/profile/${widget.userId}/notifications'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _notifications = List<dynamic>.from(data);
          _unreadCount = _notifications.where((n) => !n['isRead']).length;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/profile/${widget.userId}/notifications/$notificationId/read'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        _fetchNotifications();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/profile/${widget.userId}/notifications/read-all'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        _fetchNotifications();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFrench
                ? 'Toutes les notifications marquées comme lues'
                : 'All notifications marked as read'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<void> _refreshNotifications() async {
    await _fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        fontFamily: 'Montserrat',
        scaffoldBackgroundColor: Colors.transparent,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Text(_isFrench ? 'Notifications' : 'Notifications'),
              if (_unreadCount > 0) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.red,
                  radius: 12,
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (_unreadCount > 0)
              IconButton(
                icon: const Icon(Icons.mark_email_read),
                tooltip: _isFrench ? 'Tout marquer comme lu' : 'Mark all as read',
                onPressed: _markAllAsRead,
              ),
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: () => setState(() => _isFrench = !_isFrench),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshNotifications,
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                'http://localhost:5000/images/background.png',
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.25),
                colorBlendMode: BlendMode.darken,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.grey[300]);
                },
              ),
            ),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isFrench ? 'Erreur de chargement' : 'Loading error',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _refreshNotifications,
              child: Text(_isFrench ? 'Réessayer' : 'Retry'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Text(
          _isFrench ? 'Aucune notification' : 'No notifications',
          style: const TextStyle(fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      child: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          final date = DateTime.parse(notification['createdAt']).toLocal();
          final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: notification['isRead'] ? Colors.grey[100] : Colors.white,
            elevation: notification['isRead'] ? 1 : 2,
            child: ListTile(
              leading: Icon(
                _getNotificationIcon(notification['title']),
                color: notification['isRead'] ? Colors.grey : _getNotificationColor(notification['title']),
              ),
              title: Text(
                notification['title'],
                style: TextStyle(
                  fontWeight: notification['isRead'] ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification['message']),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              trailing: notification['isRead']
                  ? null
                  : const Icon(Icons.brightness_1, color: Colors.red, size: 12),
              onTap: () {
                if (!notification['isRead']) {
                  _markAsRead(notification['_id']);
                }
                if (notification['productId'] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShoeDetailsScreen(
                        shoeId: notification['productId'],
                        token: widget.token,
                        userId: widget.userId,
                      ),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(String title) {
    if (title.toLowerCase().contains('commande')) {
      return Icons.shopping_bag;
    } else if (title.toLowerCase().contains('bienvenue')) {
      return Icons.emoji_events;
    } else if (title.toLowerCase().contains('profil')) {
      return Icons.person;
    } else if (title.toLowerCase().contains('promo')) {
      return Icons.discount;
    }
    return Icons.notifications;
  }

  Color _getNotificationColor(String title) {
    if (title.toLowerCase().contains('commande')) {
      return Colors.green;
    } else if (title.toLowerCase().contains('bienvenue')) {
      return Colors.blue;
    } else if (title.toLowerCase().contains('important')) {
      return Colors.orange;
    } else if (title.toLowerCase().contains('promo')) {
      return Colors.purple;
    }
    return Colors.blue;
  }
}
