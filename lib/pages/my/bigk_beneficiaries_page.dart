import 'package:flutter/material.dart';

import '../../dto/bigk/bigk_contacts.dart';
import '../../services/bigk/bigk_contacts_service.dart';
import '../../util/message_util.dart';

class BigKBeneficiariesPage extends StatefulWidget {
  const BigKBeneficiariesPage({super.key});

  @override
  State<BigKBeneficiariesPage> createState() => _BigKBeneficiariesPageState();
}

class _BigKBeneficiariesPageState extends State<BigKBeneficiariesPage> {
  List<BigKContact> _savedWallets = const <BigKContact>[];
  List<BigKContact> _contacts = const <BigKContact>[];
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
        BigKContactsService.getSavedWallets(perPage: 50),
        BigKContactsService.getContacts(perPage: 50),
      ]);
      if (!mounted) {
        return;
      }

      setState(() {
        _savedWallets = (results[0] as BigKContactPage).items;
        _contacts = (results[1] as BigKContactPage).items;
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

  bool _isSaved(BigKContact contact) {
    return _savedWallets.any(
      (saved) =>
          (saved.walletId.isNotEmpty && saved.walletId == contact.walletId) ||
          (saved.handle.isNotEmpty && saved.handle == contact.handle),
    );
  }

  Future<void> _showCreateDialog({BigKContact? seed}) async {
    final walletIdController =
        TextEditingController(text: seed?.walletId ?? '');
    final handleController = TextEditingController(text: seed?.handle ?? '');
    final aliasController = TextEditingController(
      text: seed?.displayName ?? seed?.alias ?? '',
    );
    bool isSaving = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> submit() async {
                if (walletIdController.text.trim().isEmpty &&
                    handleController.text.trim().isEmpty) {
                  MessageUtil.info(
                    dialogContext,
                    '请输入钱包 ID 或 Handle。',
                  );
                  return;
                }

                setDialogState(() => isSaving = true);
                try {
                  await BigKContactsService.createSavedWallet(
                    walletId: walletIdController.text.trim(),
                    handle: handleController.text.trim(),
                    alias: aliasController.text.trim(),
                  );

                  if (!mounted || !dialogContext.mounted) {
                    return;
                  }

                  Navigator.of(dialogContext).pop();
                  MessageUtil.success(context, '常用钱包已保存。');
                  await _loadData();
                } catch (e) {
                  if (!dialogContext.mounted) {
                    return;
                  }

                  setDialogState(() => isSaving = false);
                  MessageUtil.error(dialogContext, '创建失败：$e');
                }
              }

              return AlertDialog(
                title: const Text('添加常用钱包'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        controller: aliasController,
                        decoration: const InputDecoration(
                          labelText: '备注名',
                          hintText: '选填昵称',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: handleController,
                        decoration: const InputDecoration(
                          labelText: 'Handle',
                          hintText: '@用户名',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: walletIdController,
                        decoration: const InputDecoration(
                          labelText: '钱包 ID',
                          hintText: '外部钱包 ID',
                        ),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('取消'),
                  ),
                  ElevatedButton(
                    onPressed: isSaving ? null : submit,
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('保存'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      walletIdController.dispose();
      handleController.dispose();
      aliasController.dispose();
    }
  }

  Future<void> _showEditDialog(BigKContact wallet) async {
    final aliasController = TextEditingController(text: wallet.alias);
    bool isSaving = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> submit() async {
                setDialogState(() => isSaving = true);
                try {
                  await BigKContactsService.updateSavedWallet(
                    wallet.id,
                    alias: aliasController.text.trim(),
                  );

                  if (!mounted || !dialogContext.mounted) {
                    return;
                  }

                  Navigator.of(dialogContext).pop();
                  MessageUtil.success(context, '常用钱包已更新。');
                  await _loadData();
                } catch (e) {
                  if (!dialogContext.mounted) {
                    return;
                  }

                  setDialogState(() => isSaving = false);
                  MessageUtil.error(dialogContext, '更新失败：$e');
                }
              }

              return AlertDialog(
                title: const Text('编辑备注名'),
                content: TextField(
                  controller: aliasController,
                  decoration: const InputDecoration(
                    labelText: '备注名',
                    hintText: '这个钱包的昵称',
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('取消'),
                  ),
                  ElevatedButton(
                    onPressed: isSaving ? null : submit,
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('更新'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      aliasController.dispose();
    }
  }

  Future<void> _deleteSavedWallet(BigKContact wallet) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('删除常用钱包'),
              content: Text('要从快捷列表中删除 ${wallet.title} 吗？'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('删除'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    try {
      await BigKContactsService.deleteSavedWallet(wallet.id);
      if (!mounted) {
        return;
      }
      MessageUtil.success(context, '常用钱包已删除。');
      await _loadData();
    } catch (e) {
      if (!mounted) {
        return;
      }
      MessageUtil.error(context, '删除失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('常用钱包'),
        actions: <Widget>[
          IconButton(
            onPressed: () => _showCreateDialog(),
            icon: const Icon(Icons.add),
            tooltip: '添加',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  if (_loadError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _loadError!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  _buildSectionCard(
                    context,
                    title: '常用钱包',
                    subtitle: '转账时可快速选择的收款方。',
                    child: _savedWallets.isEmpty
                        ? _buildEmptyState('暂无常用钱包。')
                        : Column(
                            children: _savedWallets
                                .map(
                                  (wallet) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: theme.colorScheme.primary
                                          .withValues(alpha: 0.12),
                                      child: Text(
                                        wallet.title.isEmpty
                                            ? '?'
                                            : wallet.title.characters.first
                                                .toUpperCase(),
                                      ),
                                    ),
                                    title: Text(wallet.title),
                                    subtitle: Text(wallet.subtitle),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showEditDialog(wallet);
                                        } else if (value == 'delete') {
                                          _deleteSavedWallet(wallet);
                                        }
                                      },
                                      itemBuilder: (context) =>
                                          const <PopupMenuEntry<String>>[
                                        PopupMenuItem<String>(
                                          value: 'edit',
                                          child: Text('编辑备注名'),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Text('删除'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: '最近联系人',
                    subtitle: '最近收款人或已同步联系人。',
                    child: _contacts.isEmpty
                        ? _buildEmptyState('暂无最近联系人。')
                        : Column(
                            children: _contacts
                                .map(
                                  (contact) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: theme.colorScheme.primary
                                          .withValues(alpha: 0.12),
                                      child: Text(
                                        contact.title.isEmpty
                                            ? '?'
                                            : contact.title.characters.first
                                                .toUpperCase(),
                                      ),
                                    ),
                                    title: Text(contact.title),
                                    subtitle: Text(contact.subtitle),
                                    trailing: _isSaved(contact)
                                        ? const Chip(label: Text('已保存'))
                                        : TextButton(
                                            onPressed: () => _showCreateDialog(
                                              seed: contact,
                                            ),
                                            child: const Text('保存'),
                                          ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(text),
      ),
    );
  }
}
