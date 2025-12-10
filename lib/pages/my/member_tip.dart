import 'package:const_calc/dto/user.dart';
import 'package:const_calc/services/user_service.dart';
import 'package:flutter/material.dart';

import '../../dto/vip_purview.dart';
import '../../services/my_service.dart';
import '../../util/http_util.dart';
import 'member_privilege_page.dart';

class MemberTip extends StatefulWidget {
  /// vip权益项 ID / code（接口用）
  final String vipRightKey;

  const MemberTip({super.key, required this.vipRightKey});

  @override
  State<MemberTip> createState() => _MemberTipState();
}

class _MemberTipState extends State<MemberTip> {
  String _levelLabel = '基础会员';
  String _shownCount = '';
  int _vipLevelId = -1;

  static const vipMapper = {1: '普通会员', 2: '精英会员', 3: '至尊会员'};

  @override
  void initState() {
    super.initState();
    _fetchMemberInfo();
  }

  Future<void> _fetchMemberInfo() async {
    final User? user = await UserService().getUserInfo();
    if (!mounted) return;

    final vpList = await HttpUtil.request<List<VipPurview>?>(
      () => MyService.getVipPurview(),
      context,
      () => mounted,
    );
    if (!mounted) return;

    VipPurview? vipPurview = vpList
        ?.where((item) => item.purviewName == widget.vipRightKey)
        .cast<VipPurview?>()
        .firstOrNull;

    setState(() {
      _vipLevelId = user?.vipLevelId ?? 1;
      _levelLabel = vipMapper[_vipLevelId] ?? '普通会员';

      switch (_vipLevelId) {
        case 1:
          _shownCount = _showTips(vipPurview?.baseVipValue ?? -2);
          break;
        case 2:
          _shownCount = _showTips(vipPurview?.elitistVipValue ?? -2);
          break;
        case 3:
          _shownCount = _showTips(vipPurview?.supremeVipValue ?? -2);
          break;
      }

    });
  }

  String _showTips(int vipValue) {
    String tips = '';
    switch (vipValue) {
      case 999:
        tips = '显示全部';
        break;
      case -2:
        tips = '没有权限';
        break;
      default:
        tips = '显示 $vipValue 个';
    }
    return tips;
  }

  /// 升级会员点击事件
  void _goUpgradePage() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const MemberPrivilegePage()),
    ).then((value) {
      if (mounted && value == true) {
        _fetchMemberInfo();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(height: 1.1);

    if (_vipLevelId == -1) {
      return SizedBox(width: 1);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '【$_levelLabel】',
            style: baseStyle?.copyWith(color: const Color(0xFF4B4F57)),
          ),
        ),
        const SizedBox(width: 1),
        Text(
          _shownCount,
          style: baseStyle?.copyWith(color: const Color(0xFF6B7280)),
        ),
        const SizedBox(width: 2),
        if ([1, 2].contains(_vipLevelId))
          Text('-', style: baseStyle?.copyWith(color: const Color(0xFFB2B7C3))),
        if ([1, 2].contains(_vipLevelId))
          const SizedBox(width: 2),
        if ([1, 2].contains(_vipLevelId))
          InkWell(
            onTap: _goUpgradePage,
            child: Padding(
              padding: const EdgeInsets.symmetric(),
              child: Text(
                '升级会员',
                style: baseStyle?.copyWith(
                  color: const Color(0xFF4C7EFF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
