import 'package:flutter/material.dart';

enum EditFieldType { name, gender, birthDate, birthTime }

class EditProfileFieldPage  extends StatefulWidget {
  final EditFieldType type;
  final String title;          // AppBar 标题（例如：修改个人信息）
  final String label;          // 左侧标签（姓名/出生时间…）
  final String initialText;    // 初始展示文本（如 安卓测试 / 09-11 旦时）

  const EditProfileFieldPage({
    super.key,
    required this.type,
    required this.title,
    required this.label,
    required this.initialText,
  });

  @override
  State<EditProfileFieldPage> createState() => _EditProfileFieldPageState();
}

class _EditProfileFieldPageState extends State<EditProfileFieldPage> {
  late String _value;
  final _textCtrl = TextEditingController();

  final _genders = const ['男', '女'];
  final _times = const ['子时','丑时','寅时','卯时','辰时','巳时','午时','未时','申时','酉时','戌时','亥时'];

  @override
  void initState() {
    super.initState();
    _value = widget.initialText;
    if (widget.type == EditFieldType.name) {
      _textCtrl.text = widget.initialText;
    }
  }

  Future<void> _pickBirthDate() async {
    // 解析已有值 YYYY-MM-DD
    DateTime init = DateTime.now();
    final p = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(_value);
    if (p != null) {
      init = DateTime(int.parse(p.group(1)!), int.parse(p.group(2)!), int.parse(p.group(3)!));
    }
    final d = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(() {
        _value = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickFromList(List<String> options) async {
    final r = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView.separated(
          itemCount: options.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => ListTile(
            title: Text(options[i]),
            onTap: () => Navigator.pop(ctx, options[i]),
          ),
        ),
      ),
    );
    if (r != null) setState(() => _value = r);
  }

  void _save() {
    if (widget.type == EditFieldType.name) {
      _value = _textCtrl.text.trim();
      if (_value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入姓名')));
        return;
      }
    }
    Navigator.pop(context, _value); // 把结果返回给上一个页面
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: false, // 不让键盘推挤布局
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 顶部一行：左标签 + 右侧值（不同类型用不同交互）
            if (widget.type == EditFieldType.name)
              _rowInput(label: widget.label, controller: _textCtrl, hint: '请输入${widget.label}')

            else
              InkWell(
                onTap: () async {
                  switch (widget.type) {
                    case EditFieldType.gender:
                      await _pickFromList(_genders);
                      break;
                    case EditFieldType.birthDate:
                      await _pickBirthDate();
                      break;
                    case EditFieldType.birthTime:
                      await _pickFromList(_times);
                      break;
                    case EditFieldType.name:
                      break;
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Text(widget.label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                      const SizedBox(width: 16),
                      Expanded(child: Text(_value, style: const TextStyle(fontSize: 14))),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),

            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 24),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFAB400),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('确认修改', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  
}
Widget _rowInput({
  required String label,
  required TextEditingController controller,
  String? hint,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: controller,
            cursorColor: Colors.grey,
            textInputAction: TextInputAction.done,
            maxLines: 1,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    ),
  );
}
