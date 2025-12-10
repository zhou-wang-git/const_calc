import 'package:const_calc/services/user_service.dart';
import 'package:const_calc/util/message_util.dart';
import 'package:flutter/material.dart';
import '../../component/bottom_calendar_picker.dart';
import '../../component/bottom_time_zodiac_picker.dart';
import '../../dto/user.dart';
import '../../services/my_service.dart';
import '../../util/http_util.dart';

enum EditFieldType { name, gender, birthDate, birthTime } // NEW

class EditUserInfoPage extends StatefulWidget {
  final EditFieldType fieldKey;

  const EditUserInfoPage({super.key, required this.fieldKey});

  @override
  State<EditUserInfoPage> createState() => _EditUserInfoPageState();
}

class _EditUserInfoPageState extends State<EditUserInfoPage> {
  String? _value;

  final _titles = const {
    EditFieldType.name: '修改姓名',
    EditFieldType.gender: '修改性别',
    EditFieldType.birthDate: '修改出生日期',
    EditFieldType.birthTime: '修改出生时间', // NEW
  };

  Future<void> _submit() async {
    final v = _value?.trim() ?? '';
    if (v.isEmpty) {
      final msg = {
        EditFieldType.name: '请输入姓名',
        EditFieldType.gender: '请选择性别',
        EditFieldType.birthDate: '请选择出生日期',
        EditFieldType.birthTime: '请选择出生时间', // NEW
      }[widget.fieldKey]!;
      MessageUtil.info(context, msg);
      return;
    }

    // 修改出生时间一个接口
    if (widget.fieldKey == EditFieldType.birthDate) {
      List<String> date = _value!.split('-');
      await HttpUtil.request<void>(
        () => MyService.updateBirthday(
          year: date[0],
          month: date[1],
          day: date[2],
          curid: '0',
        ),
        context,
        () => mounted,
      );
    } else {
      // 其他信息一个接口
      final User? user = await UserService().getUserInfo();
      if (user == null) return;
      String? name = widget.fieldKey == EditFieldType.name
          ? _value
          : user.realName;
      String? sex = widget.fieldKey == EditFieldType.gender
          ? _value == '男'
                ? '2'
                : '1'
          : user.sex;
      String? birthTime = widget.fieldKey == EditFieldType.birthTime
          ? _value
          : user.birthTime;

      await HttpUtil.request<void>(
        () => MyService.updateMember(
          name: name ?? '',
          sex: sex,
          birthTime: birthTime ?? '',
          curid: '0',
        ),
        // ignore: use_build_context_synchronously
        context,
        () => mounted,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop(true); // ✅ 关闭并把“已修改”结果带回去
  }

  @override
  Widget build(BuildContext context) {
    final fieldBuilders =
        <EditFieldType, Widget Function(ValueChanged<String>)>{
          EditFieldType.name: (onChanged) => NameField(onChanged: onChanged),
          EditFieldType.gender: (onChanged) =>
              GenderField(onChanged: onChanged),
          EditFieldType.birthDate: (onChanged) =>
              BirthDateField(onChanged: onChanged),
          EditFieldType.birthTime: (onChanged) =>
              BirthTimeField(onChanged: onChanged), // NEW
        };

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            _titles[widget.fieldKey]!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              fieldBuilders[widget.fieldKey]!((val) => _value = val),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFAB400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text(
                    '提交',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// —— 姓名 ——
class NameField extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const NameField({super.key, required this.onChanged});

  @override
  State<NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<NameField> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.onChanged(_controller.text);
    _initUserInfo();
  }

  Future<void> _initUserInfo() async {
    final User? userInfo = await UserService().getUserInfo();
    if (userInfo == null) return;
    setState(() {
      _controller.text = userInfo.realName;
    });
    widget.onChanged(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          labelText: '姓名',
          labelStyle: TextStyle(fontSize: 14, color: Colors.black87),
          hintText: '请输入姓名',
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

/// —— 性别 ——
class GenderField extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const GenderField({super.key, required this.onChanged});

  @override
  State<GenderField> createState() => _GenderFieldState();
}

class _GenderFieldState extends State<GenderField> {
  static const _genders = ['男', '女'];
  final _controller = TextEditingController(text: '男'); // 默认值

  @override
  void initState() {
    super.initState();
    widget.onChanged(_controller.text);
    _initUserInfo();
  }

  Future<void> _initUserInfo() async {
    final User? userInfo = await UserService().getUserInfo();
    if (userInfo == null) return;
    setState(() {
      _controller.text = userInfo.sex == '1' ? '女' : '男';
    });
    widget.onChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
      ),
      child: DropdownButtonFormField<String>(
        value: _controller.text,
        decoration: const InputDecoration(
          labelText: '性别',
          labelStyle: TextStyle(fontSize: 14, color: Colors.black87),
          border: InputBorder.none,
        ),
        items: _genders
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (val) {
          if (val != null) {
            _controller.text = val;
            widget.onChanged(val);
          }
        },
      ),
    );
  }
}

/// —— 出生日期（BottomCalendarPicker） ——
class BirthDateField extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const BirthDateField({super.key, required this.onChanged});

  @override
  State<BirthDateField> createState() => _BirthDateFieldState();
}

class _BirthDateFieldState extends State<BirthDateField> {
  final _controller = TextEditingController(
    text: '2000-01-01',
  ); // 默认日期User? _user;

  @override
  void initState() {
    super.initState();
    widget.onChanged(_controller.text);
    _initUserInfo();
  }

  Future<void> _initUserInfo() async {
    final User? userInfo = await UserService().getUserInfo();
    if (userInfo == null) return;
    setState(() {
      _controller.text = '${userInfo.year}-${userInfo.month}-${userInfo.day}';
    });
  }

  Future<void> _pickDate() async {
    await BottomCalendarPicker.show(
      context: context,
      format: 'yyyy-MM-dd',
      initialDate: DateTime.now(),
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      onConfirm: (formatted, _) {
        setState(() => _controller.text = formatted);
        widget.onChanged(formatted);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
          ),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                '出生日期',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
            Text(
              _controller.text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

/// —— 出生时间（BottomTimeZodiacPicker） ——
class BirthTimeField extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const BirthTimeField({super.key, required this.onChanged});

  @override
  State<BirthTimeField> createState() => _BirthTimeFieldState();
}

class _BirthTimeFieldState extends State<BirthTimeField> {
  final _controller = TextEditingController(text: '未知'); // 默认时辰

  Future<void> _pickTimeZodiac() async {
    await BottomTimeZodiacPicker.showTimeZodiacPicker(
      context,
      initialValue: _controller.text,
      onConfirm: (selected) {
        setState(() => _controller.text = selected);
        widget.onChanged(selected);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    widget.onChanged(_controller.text);
    _initUserInfo();
  }

  Future<void> _initUserInfo() async {
    final User? userInfo = await UserService().getUserInfo();
    if (userInfo == null) return;
    setState(() {
      _controller.text = userInfo.birthTime ?? '';
    });
    widget.onChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _pickTimeZodiac,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
          ),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                '出生时间',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
            Text(
              _controller.text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.access_time, size: 16, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
