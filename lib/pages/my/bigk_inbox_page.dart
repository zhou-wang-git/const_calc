import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../dto/bigk/bigk_message.dart';
import '../../services/bigk/bigk_inbox_service.dart';
import '../../util/message_util.dart';

class BigKInboxPage extends StatefulWidget {
  const BigKInboxPage({super.key});

  @override
  State<BigKInboxPage> createState() => _BigKInboxPageState();
}

class _BigKInboxPageState extends State<BigKInboxPage> {
  BigKMessagePage _inbox = const BigKMessagePage();
  BigKMessagePage _notifications = const BigKMessagePage();
  int _unreadCount = 0;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        BigKInboxService.getInbox(perPage: 30),
        BigKInboxService.getNotifications(perPage: 30),
        BigKInboxService.getUnreadCount(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _inbox = results[0] as BigKMessagePage;
        _notifications = results[1] as BigKMessagePage;
        _unreadCount = results[2] as int;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _markInboxRead(BigKMessageItem item) async {
    try {
      await BigKInboxService.markInboxRead(item.id);
      if (!mounted) {
        return;
      }
      await _loadData();
    } catch (e) {
      if (!mounted) {
        return;
      }
      MessageUtil.error(context, '已读操作失败：$e');
    }
  }

  Future<void> _deleteInbox(BigKMessageItem item) async {
    try {
      await BigKInboxService.deleteInboxMessage(item.id);
      if (!mounted) {
        return;
      }
      MessageUtil.success(context, '消息已删除。');
      await _loadData();
    } catch (e) {
      if (!mounted) {
        return;
      }
      MessageUtil.error(context, '删除失败：$e');
    }
  }

  Future<void> _markAllInboxRead() async {
    try {
      await BigKInboxService.markAllInboxRead();
      if (!mounted) {
        return;
      }
      MessageUtil.success(context, '收件箱已全部标记为已读。');
      await _loadData();
    } catch (e) {
      if (!mounted) {
        return;
      }
      MessageUtil.error(context, '全部已读操作失败：$e');
    }
  }

  Future<void> _markNotificationRead(BigKMessageItem item) async {
    try {
      await BigKInboxService.markNotificationRead(item.id);
      if (!mounted) {
        return;
      }
      await _loadData();
    } catch (e) {
      if (!mounted) {
        return;
      }
      MessageUtil.error(context, '已读操作失败：$e');
    }
  }

  Future<void> _markAllNotificationsRead() async {
    try {
      await BigKInboxService.markAllNotificationsRead();
      if (!mounted) {
        return;
      }
      MessageUtil.success(context, '通知已全部标记为已读。');
      await _loadData();
    } catch (e) {
      if (!mounted) {
        return;
      }
      MessageUtil.error(context, '全部已读操作失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('消息中心${_unreadCount > 0 ? ' ($_unreadCount)' : ''}'),
          bottom: const TabBar(
            tabs: <Tab>[
              Tab(text: '收件箱'),
              Tab(text: '通知'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: <Widget>[
                  RefreshIndicator(
                    onRefresh: _loadData,
                    child: _buildInboxList(),
                  ),
                  RefreshIndicator(
                    onRefresh: _loadData,
                    child: _buildNotificationList(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInboxList() {
    if (_loadError != null && _inbox.items.isEmpty) {
      return ListView(
        children: <Widget>[
          const SizedBox(height: 120),
          Center(child: Text(_loadError!)),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _buildHeaderCard(
          title: '系统收件箱',
          subtitle: '来自 BigK 的奖励和系统消息。',
          actionLabel: '全部标为已读',
          onActionTap: _inbox.items.isEmpty ? null : _markAllInboxRead,
        ),
        const SizedBox(height: 16),
        if (_inbox.items.isEmpty)
          _buildEmptyState('收件箱为空。')
        else
          ..._inbox.items.map(
            (item) => _buildMessageTile(
              item,
              canDelete: true,
              onMarkRead: item.isRead ? null : () => _markInboxRead(item),
              onDelete: () => _deleteInbox(item),
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationList() {
    if (_loadError != null && _notifications.items.isEmpty) {
      return ListView(
        children: <Widget>[
          const SizedBox(height: 120),
          Center(child: Text(_loadError!)),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _buildHeaderCard(
          title: '推送历史',
          subtitle: '已送达给用户的通知记录。',
          actionLabel: '全部标为已读',
          onActionTap:
              _notifications.items.isEmpty ? null : _markAllNotificationsRead,
        ),
        const SizedBox(height: 16),
        if (_notifications.items.isEmpty)
          _buildEmptyState('暂无推送通知。')
        else
          ..._notifications.items.map(
            (item) => _buildMessageTile(
              item,
              canDelete: false,
              onMarkRead:
                  item.isRead ? null : () => _markNotificationRead(item),
            ),
          ),
      ],
    );
  }

  Widget _buildHeaderCard({
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback? onActionTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageTile(
    BigKMessageItem item, {
    required VoidCallback? onMarkRead,
    VoidCallback? onDelete,
    required bool canDelete,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isRead
              ? Colors.transparent
              : theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  item.title.isEmpty ? '未命名消息' : item.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!item.isRead)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          if (item.type.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              item.type,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          if (item.body.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              item.body,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _formatDate(item.createdAt),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              if (onMarkRead != null)
                TextButton(
                  onPressed: onMarkRead,
                  child: const Text('标为已读'),
                ),
              if (canDelete && onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '删除',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(child: Text(text)),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '未知时间';
    }
    return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
  }
}
