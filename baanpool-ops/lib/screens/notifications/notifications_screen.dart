import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_onUpdate);
    _service.refresh();
  }

  @override
  void dispose() {
    _service.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _service.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
        actions: [
          if (_service.hasUnread)
            TextButton(
              onPressed: () => _service.markAllAsRead(),
              child: const Text('อ่านทั้งหมด'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'ยังไม่มีการแจ้งเตือน',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _service.refresh(),
              child: ListView.separated(
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final noti = notifications[index];
                  final isRead = noti['is_read'] == true;
                  final type = noti['type'] as String? ?? 'info';
                  final createdAt = DateTime.tryParse(
                    noti['created_at'] as String? ?? '',
                  );

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isRead
                          ? Colors.grey.shade200
                          : _typeColor(type).withValues(alpha: 0.2),
                      child: Icon(
                        _typeIcon(type),
                        color: isRead ? Colors.grey : _typeColor(type),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      noti['title'] as String? ?? '',
                      style: TextStyle(
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          noti['body'] as String? ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (createdAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _timeAgo(createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: isRead
                        ? null
                        : Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                    tileColor: isRead
                        ? null
                        : Colors.blue.withValues(alpha: 0.04),
                    onTap: () {
                      if (!isRead) {
                        _service.markAsRead(noti['id'] as String);
                      }
                      // Navigate to the referenced item
                      final refId = noti['reference_id'] as String?;
                      if (type == 'work_order' && refId != null) {
                        context.push('/work-orders/$refId');
                      } else if (type == 'pm') {
                        context.push('/pm');
                      }
                    },
                  );
                },
              ),
            ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'work_order':
        return Icons.assignment;
      case 'pm':
        return Icons.schedule;
      case 'expense':
        return Icons.receipt_long;
      default:
        return Icons.notifications;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'work_order':
        return Colors.blue;
      case 'pm':
        return Colors.orange;
      case 'expense':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'เมื่อสักครู่';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
