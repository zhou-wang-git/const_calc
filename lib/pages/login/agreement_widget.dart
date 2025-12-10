import 'package:flutter/material.dart';

import '../../services/agreement_service.dart';
import '../../util/http_util.dart';
import '../../util/message_util.dart';
import 'agreement_page.dart';

class AgreementWidget extends StatefulWidget {
  final ValueChanged<bool>? onChanged; // ✅ 回调传递选中状态
  final bool initialValue; // ✅ 默认值

  const AgreementWidget({
    super.key,
    this.onChanged,
    this.initialValue = false,
  });

  @override
  State<AgreementWidget> createState() => _AgreementWidgetState();
}

class _AgreementWidgetState extends State<AgreementWidget> {
  late bool _agree;

  @override
  void initState() {
    super.initState();
    _agree = widget.initialValue; // ✅ 初始化
  }

  Future<void> _openAgreement(String type) async {
    final agreement = await HttpUtil.request(
          () => AgreementService().getAgreementInfo(type: type),
      context,
          () => mounted,
    );

    if (!mounted) return;
    if (agreement == null) {
      MessageUtil.info(context, "协议内容为空");
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgreementPage(
          title: agreement.title,
          html: agreement.content,
        ),
      ),
    );
  }

  void _toggleAgree() {
    setState(() {
      _agree = !_agree;
    });
    widget.onChanged?.call(_agree); // ✅ 通知外部
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleAgree,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: FittedBox( // ✅ 自动缩放字体
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min, // ✅ 仅占用文字和图标空间
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ✅ 圆形对号
              Container(
                width: 14, // ✅ 调整小圆圈大小
                height: 14,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _agree ? const Color(0xFFdfbc69) : Colors.grey,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 10),
              ),

              // ✅ 协议文字
              Text.rich(
                TextSpan(
                  text: '登录代表您已仔细阅读并同意 ',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: GestureDetector(
                        onTap: () => _openAgreement('1'),
                        child: const Text(
                          '《用户协议》',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFdfbc69),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                    TextSpan(
                      text: ' 和 ',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: GestureDetector(
                        onTap: () => _openAgreement('2'),
                        child: const Text(
                          '《隐私权政策》',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFdfbc69),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

}
