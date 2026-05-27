import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../dto/bigk/bigk_funding.dart';
import '../../dto/bigk/bigk_profile.dart';
import '../../services/bigk/bigk_auth_service.dart';
import '../../services/bigk/bigk_payment_service.dart';
import '../../services/bigk/bigk_profile_service.dart';
import '../../util/auth_manager.dart';
import '../../util/message_util.dart';

class BigKProfileSettingsPage extends StatefulWidget {
  const BigKProfileSettingsPage({super.key});

  @override
  State<BigKProfileSettingsPage> createState() =>
      _BigKProfileSettingsPageState();
}

class _BigKProfileSettingsPageState extends State<BigKProfileSettingsPage> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _handleController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  BigKProfile? _profile;
  BigKWalletLink _walletLink = const BigKWalletLink();
  BigKNotificationSettings _notificationSettings =
      const BigKNotificationSettings();
  BigKPrivacySettings _privacySettings = const BigKPrivacySettings();
  BigKTransferLimits _limits = const BigKTransferLimits();
  List<BigKSessionInfo> _sessions = const <BigKSessionInfo>[];
  List<BigKCurrency> _currencies = const <BigKCurrency>[];

  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isSavingPreferences = false;
  bool _isSavingPrivacy = false;
  bool _isUploadingAvatar = false;
  bool _isLoggingOut = false;
  String? _loadError;
  String _selectedCurrency = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _handleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        BigKProfileService.getProfile(),
        BigKAuthService().getWalletLink(),
        BigKProfileService.getNotificationSettings(),
        BigKProfileService.getPrivacySettings(),
        BigKProfileService.getLimits(),
        BigKAuthService().getSessions(),
        BigKPaymentService.getCurrencies().catchError((_) => <BigKCurrency>[]),
      ]);

      if (!mounted) {
        return;
      }

      final profile = results[0] as BigKProfile;
      final currencies = (results[6] as List<dynamic>).cast<BigKCurrency>();
      _displayNameController.text = profile.displayName;
      _handleController.text = profile.handle;
      _bioController.text = profile.bio;

      setState(() {
        _profile = profile;
        _walletLink = results[1] as BigKWalletLink;
        _notificationSettings = results[2] as BigKNotificationSettings;
        _privacySettings = results[3] as BigKPrivacySettings;
        _limits = results[4] as BigKTransferLimits;
        _sessions = (results[5] as List<dynamic>).cast<BigKSessionInfo>();
        _currencies = currencies.where((currency) => currency.enabled).toList();
        _selectedCurrency = profile.displayCurrency.isNotEmpty
            ? profile.displayCurrency.toUpperCase()
            : (_currencies.isNotEmpty ? _currencies.first.code : '');
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

  Future<void> _saveProfile() async {
    if (_profile == null || _isSavingProfile) {
      return;
    }
    if (_displayNameController.text.trim().isEmpty ||
        _handleController.text.trim().isEmpty) {
      MessageUtil.info(context, 'Display name and handle are required.');
      return;
    }

    setState(() => _isSavingProfile = true);
    try {
      final updated = await BigKProfileService.updateProfile(
        displayName: _displayNameController.text.trim(),
        handle: _handleController.text.trim(),
        bio: _bioController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = updated;
        _isSavingProfile = false;
      });
      MessageUtil.success(context, 'Profile updated.');
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _isSavingProfile = false);
      MessageUtil.error(context, 'Update failed: $e');
    }
  }

  Future<void> _savePreferences() async {
    if (_isSavingPreferences) {
      return;
    }

    setState(() => _isSavingPreferences = true);
    try {
      await Future.wait<void>(<Future<void>>[
        BigKProfileService.updateNotificationSettings(_notificationSettings),
        if (_selectedCurrency.isNotEmpty)
          BigKProfileService.updateCurrency(_selectedCurrency),
      ]);

      if (!mounted) {
        return;
      }

      setState(() => _isSavingPreferences = false);
      MessageUtil.success(context, 'Preferences updated.');
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _isSavingPreferences = false);
      MessageUtil.error(context, 'Save failed: $e');
    }
  }

  Future<void> _savePrivacy() async {
    if (_isSavingPrivacy) {
      return;
    }

    setState(() => _isSavingPrivacy = true);
    try {
      await BigKProfileService.updatePrivacySettings(_privacySettings);

      if (!mounted) {
        return;
      }

      setState(() => _isSavingPrivacy = false);
      MessageUtil.success(context, 'Privacy updated.');
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _isSavingPrivacy = false);
      MessageUtil.error(context, 'Save failed: $e');
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_isUploadingAvatar) {
      return;
    }

    Uint8List? fileBytes;
    String fileName = 'avatar.jpg';

    try {
      if (kIsWeb || _isDesktopPlatform()) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        if (result == null) {
          return;
        }
        final file = result.files.single;
        fileBytes = file.bytes;
        fileName = file.name;
      } else {
        final image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 90,
          maxWidth: 1024,
          maxHeight: 1024,
        );
        if (image == null) {
          return;
        }
        fileBytes = await image.readAsBytes();
        fileName = image.name;
      }

      if (fileBytes == null || fileBytes.isEmpty) {
        return;
      }

      setState(() => _isUploadingAvatar = true);
      final updated = await BigKProfileService.uploadAvatar(
        fileBytes: fileBytes,
        fileName: fileName,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = updated;
        _isUploadingAvatar = false;
      });
      MessageUtil.success(context, 'Avatar updated.');
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _isUploadingAvatar = false);
      MessageUtil.error(context, 'Avatar upload failed: $e');
    }
  }

  Future<void> _revokeSession(BigKSessionInfo session) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Revoke session'),
              content: Text(
                'Log out ${session.deviceName.isEmpty ? 'this device' : session.deviceName}?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Revoke'),
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
      await BigKAuthService().revokeSession(session.id);
      if (!mounted) {
        return;
      }
      MessageUtil.success(context, 'Session revoked.');
      await _loadData();
    } catch (e) {
      if (!mounted) {
        return;
      }
      MessageUtil.error(context, 'Revoke failed: $e');
    }
  }

  Future<void> _logoutCurrentSession() async {
    if (_isLoggingOut) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Logout'),
              content: const Text('End the current authenticated session?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Logout'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    setState(() => _isLoggingOut = true);
    if (!mounted) {
      return;
    }
    await AuthManager.logout(context);
  }

  Future<void> _revokeAllSessions() async {
    if (_isLoggingOut) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Revoke all sessions'),
              content: const Text(
                'This will sign out every device, including the current one.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    setState(() => _isLoggingOut = true);
    try {
      await BigKAuthService().revokeAllSessions();
    } catch (_) {
      // Continue to local logout even if the revoke response fails.
    }

    if (!mounted) {
      return;
    }

    await AuthManager.logout(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BigK settings'),
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
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _loadError!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  _buildOverviewCard(theme),
                  const SizedBox(height: 16),
                  _buildProfileCard(theme),
                  const SizedBox(height: 16),
                  _buildPreferencesCard(theme),
                  const SizedBox(height: 16),
                  _buildPrivacyCard(theme),
                  const SizedBox(height: 16),
                  _buildLimitsCard(theme),
                  const SizedBox(height: 16),
                  _buildSessionsCard(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCard(ThemeData theme) {
    return _buildCard(
      theme,
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            backgroundImage: (_profile?.avatarUrl ?? '').isNotEmpty
                ? NetworkImage(_profile!.avatarUrl)
                : null,
            child: (_profile?.avatarUrl ?? '').isNotEmpty
                ? null
                : Icon(
                    Icons.person_outline,
                    color: theme.colorScheme.primary,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _profile?.displayName.isNotEmpty == true
                      ? _profile!.displayName
                      : 'BigK profile',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                if ((_profile?.handle ?? '').isNotEmpty)
                  Text('@${_profile!.handle}'),
                if ((_profile?.email ?? '').isNotEmpty)
                  Text(_profile!.email, style: theme.textTheme.bodySmall),
                if (_walletLink.walletId.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Wallet ID: ${_walletLink.walletId}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: _isUploadingAvatar ? null : _pickAndUploadAvatar,
            child: _isUploadingAvatar
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Avatar'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme) {
    return _buildCard(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Profile',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _displayNameController,
            decoration: const InputDecoration(labelText: 'Display name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _handleController,
            decoration: const InputDecoration(labelText: 'Handle'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bioController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Bio'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingProfile ? null : _saveProfile,
              child: _isSavingProfile
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(ThemeData theme) {
    return _buildCard(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Preferences',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (_currencies.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue:
                  _selectedCurrency.isNotEmpty ? _selectedCurrency : null,
              decoration: const InputDecoration(labelText: 'Display currency'),
              items: _currencies
                  .map(
                    (currency) => DropdownMenuItem<String>(
                      value: currency.code,
                      child: Text(currency.displayLabel),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _selectedCurrency = value);
              },
            ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _notificationSettings.pushEnabled,
            title: const Text('Push notifications'),
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              setState(
                () => _notificationSettings = BigKNotificationSettings(
                  pushEnabled: value,
                  emailEnabled: _notificationSettings.emailEnabled,
                  marketingEnabled: _notificationSettings.marketingEnabled,
                  rewardsEnabled: _notificationSettings.rewardsEnabled,
                ),
              );
            },
          ),
          SwitchListTile(
            value: _notificationSettings.emailEnabled,
            title: const Text('Email notifications'),
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              setState(
                () => _notificationSettings = BigKNotificationSettings(
                  pushEnabled: _notificationSettings.pushEnabled,
                  emailEnabled: value,
                  marketingEnabled: _notificationSettings.marketingEnabled,
                  rewardsEnabled: _notificationSettings.rewardsEnabled,
                ),
              );
            },
          ),
          SwitchListTile(
            value: _notificationSettings.marketingEnabled,
            title: const Text('Marketing updates'),
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              setState(
                () => _notificationSettings = BigKNotificationSettings(
                  pushEnabled: _notificationSettings.pushEnabled,
                  emailEnabled: _notificationSettings.emailEnabled,
                  marketingEnabled: value,
                  rewardsEnabled: _notificationSettings.rewardsEnabled,
                ),
              );
            },
          ),
          SwitchListTile(
            value: _notificationSettings.rewardsEnabled,
            title: const Text('Rewards alerts'),
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              setState(
                () => _notificationSettings = BigKNotificationSettings(
                  pushEnabled: _notificationSettings.pushEnabled,
                  emailEnabled: _notificationSettings.emailEnabled,
                  marketingEnabled: _notificationSettings.marketingEnabled,
                  rewardsEnabled: value,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingPreferences ? null : _savePreferences,
              child: _isSavingPreferences
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save preferences'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard(ThemeData theme) {
    return _buildCard(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Privacy',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _privacySettings.isPublic,
            title: const Text('Public profile'),
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              setState(
                () => _privacySettings = BigKPrivacySettings(
                  isPublic: value,
                  showEmail: _privacySettings.showEmail,
                  showPhone: _privacySettings.showPhone,
                  allowFollowers: _privacySettings.allowFollowers,
                ),
              );
            },
          ),
          SwitchListTile(
            value: _privacySettings.showEmail,
            title: const Text('Show email'),
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              setState(
                () => _privacySettings = BigKPrivacySettings(
                  isPublic: _privacySettings.isPublic,
                  showEmail: value,
                  showPhone: _privacySettings.showPhone,
                  allowFollowers: _privacySettings.allowFollowers,
                ),
              );
            },
          ),
          SwitchListTile(
            value: _privacySettings.showPhone,
            title: const Text('Show phone'),
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              setState(
                () => _privacySettings = BigKPrivacySettings(
                  isPublic: _privacySettings.isPublic,
                  showEmail: _privacySettings.showEmail,
                  showPhone: value,
                  allowFollowers: _privacySettings.allowFollowers,
                ),
              );
            },
          ),
          SwitchListTile(
            value: _privacySettings.allowFollowers,
            title: const Text('Allow followers'),
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              setState(
                () => _privacySettings = BigKPrivacySettings(
                  isPublic: _privacySettings.isPublic,
                  showEmail: _privacySettings.showEmail,
                  showPhone: _privacySettings.showPhone,
                  allowFollowers: value,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingPrivacy ? null : _savePrivacy,
              child: _isSavingPrivacy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save privacy'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitsCard(ThemeData theme) {
    return _buildCard(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Limits',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            label: 'Daily remaining',
            value:
                '${_limits.dailyRemaining.toStringAsFixed(2)} ${_limits.currency}',
          ),
          _buildInfoRow(
            label: 'Daily limit',
            value:
                '${_limits.dailyLimit.toStringAsFixed(2)} ${_limits.currency}',
          ),
          _buildInfoRow(
            label: 'Weekly remaining',
            value:
                '${_limits.weeklyRemaining.toStringAsFixed(2)} ${_limits.currency}',
          ),
          _buildInfoRow(
            label: 'Weekly limit',
            value:
                '${_limits.weeklyLimit.toStringAsFixed(2)} ${_limits.currency}',
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsCard(ThemeData theme) {
    return _buildCard(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Sessions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (_sessions.isEmpty)
            Text(
              'No active session records returned by the API.',
              style: theme.textTheme.bodySmall,
            )
          else
            ..._sessions.map(
              (session) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  session.isCurrent
                      ? Icons.phone_android
                      : Icons.devices_other_outlined,
                ),
                title: Text(
                  session.deviceName.isEmpty
                      ? (session.userAgent.isEmpty
                          ? 'Unknown device'
                          : session.userAgent)
                      : session.deviceName,
                ),
                subtitle: Text(
                  <String>[
                    if (session.ipAddress.isNotEmpty) session.ipAddress,
                    _formatDate(session.lastActiveAt ?? session.createdAt),
                  ].join('  '),
                ),
                trailing: session.isCurrent
                    ? const Chip(label: Text('Current'))
                    : IconButton(
                        onPressed: () => _revokeSession(session),
                        icon: const Icon(Icons.logout),
                        tooltip: 'Revoke',
                      ),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              OutlinedButton(
                onPressed: _isLoggingOut ? null : _logoutCurrentSession,
                child: const Text('Logout current session'),
              ),
              ElevatedButton(
                onPressed: _isLoggingOut ? null : _revokeAllSessions,
                child: const Text('Revoke all sessions'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(ThemeData theme, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(value),
        ],
      ),
    );
  }

  bool _isDesktopPlatform() {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Unknown time';
    }
    return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
  }
}
