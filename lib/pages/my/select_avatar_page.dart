import 'dart:io';
import 'dart:typed_data';
import 'package:const_calc/dto/avatar.dart';
import 'package:const_calc/services/http_service.dart';
import 'package:const_calc/services/my_service.dart';
import 'package:const_calc/util/message_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../dto/upload_file.dart';
import '../../util/http_util.dart';

class PickedImage {
  final Uint8List bytes; // 三端通用上传（web 必须）
  final String fileName;
  final String? mimeType; // image/jpeg 等
  final String? path; // 移动端方便预览
  final String? url; // 网络路径

  PickedImage({
    required this.bytes,
    required this.fileName,
    this.mimeType,
    this.path,
    this.url,
  });
}

/// 选择头像页：支持从内置“头像库”选择，或上传一张图片（留好接口）
class SelectAvatarPage extends StatefulWidget {
  const SelectAvatarPage({super.key});

  @override
  State<SelectAvatarPage> createState() => _SelectAvatarPageState();
}

class _SelectAvatarPageState extends State<SelectAvatarPage> {
  final _picker = ImagePicker(); // ✅ 新增

  List<String> _presets = const [];
  PickedImage? _picked; // ✅ 自定义图片（用于预览与返回）
  int? _selectedIndex; // 选中的预设索引

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAvatarList();
    });
  }

  Future<void> _initAvatarList() async {
    final List<Avatar>? avatarList = await HttpUtil.request<List<Avatar>>(
      () => MyService.getAvatar(),
      context,
      () => mounted,
    );
    if (avatarList == null) return;
    setState(() {
      _presets = avatarList
          .map((avatar) => avatar.imageUrl)
          .where((url) => url.isNotEmpty)
          .toList();
    });
  }

  void _selectPreset(int index) {
    setState(() {
      _selectedIndex = index;
      _picked = null; // ✅ 预设和上传互斥
    });
  }

  // ✅ 实现选择图片（相册），三端可用
  Future<void> _handleUpload() async {
    // 清空选择状态
    setState(() {
      _selectedIndex = null;
      _picked = null;
    });

    Uint8List? bytes;
    String fileName = 'image.jpg';
    String? localPath;

    try {
      if (kIsWeb) {
        // ✅ Web：使用 file_picker 更稳定
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true, // 重要：拿到 bytes
        );
        if (result == null) return;

        final f = result.files.single;
        bytes = f.bytes;
        fileName = f.name;
        // Web 没有本地路径，预览用 bytes 即可
      } else {
        // ✅ 移动端：继续用 image_picker
        final XFile? x = await _picker.pickImage(
          source: ImageSource.gallery, // 需要相机就改成 camera
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 90,
        );
        if (x == null) return;

        bytes = await x.readAsBytes();
        fileName = x.name;
        localPath = x.path; // 便于移动端本地预览
      }

      if (bytes == null || bytes.isEmpty) return;

      // 上传
      final uploadFile = await HttpUtil.request<UploadFile>(
            () => MyService.uploadFile(fileName: fileName, fileBytes: bytes!),
        // ignore: use_build_context_synchronously
        context,
            () => mounted,
      );
      if (uploadFile == null) return;

      if (!mounted) return;
      setState(() {
        _picked = PickedImage(
          bytes: bytes!,
          fileName: fileName,
          path: kIsWeb ? null : localPath,
          url: uploadFile.url,
        );
        _selectedIndex = null;
      });
    } catch (e) {
      if (!mounted) return;
      MessageUtil.error(context, '选择/上传图片失败：$e');
    }
  }

  // ✅ 保存：优先返回自定义图片；否则返回预设 URL
  void _save() async {
    if (_picked == null && _selectedIndex == null) {
      MessageUtil.info(context, '请先选择一个头像或上传图片');
      return;
    }

    String avatar = '';
    if (_picked != null) {
      avatar = _picked?.url ?? '';
    } else {
      avatar = _presets[_selectedIndex!];
    }

    await HttpUtil.request<void>(
      () => MyService.updateAvatar(avatar: avatar),
      context,
      () => mounted,
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? theme.scaffoldBackgroundColor : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white70 : Colors.black87;
    final cardBgColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);
    final borderColor = isDark ? Colors.white24 : const Color(0xFFE5E5E5);
    final uploadBgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F8F8);
    final iconColor = isDark ? Colors.white54 : Colors.grey;

    return Scaffold(
      resizeToAvoidBottomInset: false, // 不让键盘推挤布局
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          '选择头像',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        centerTitle: true,
        backgroundColor: isDark ? theme.cardTheme.color : Colors.white,
        foregroundColor: textColor,
        elevation: 0.5,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择一张头像，或上传您自己的照片',
              style: TextStyle(fontSize: 14, color: subTextColor),
            ),
            const SizedBox(height: 16),
            Text(
              '从头像库中选择一个头像',
              style: TextStyle(fontSize: 13, color: subTextColor),
            ),

            const SizedBox(height: 8),
            // 预设头像宫格
            GridView.builder(
              itemCount: _presets.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemBuilder: (_, i) {
                final selected =
                    _selectedIndex == i && _picked == null; // ✅ 改用 _picked 判断

                return InkWell(
                  onTap: () => _selectPreset(i),
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1, // 正方形卡片
                    child: Stack(
                      children: [
                        // 卡片底+选中边框
                        Container(
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? const Color(0xFFFAB400) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),

                        // 图片铺满
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox.expand(
                            child: Image.network(
                              '${HttpService.domain}${_presets[i]}',
                              fit: BoxFit.cover, // 铺满并裁切
                              alignment: Alignment.center,
                            ),
                          ),
                        ),

                        // 右上角选中标记
                        if (selected)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFAB400),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(Icons.check, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 18),
            Text(
              '或上传您的头像',
              style: TextStyle(fontSize: 13, color: subTextColor),
            ),
            const SizedBox(height: 8),

            // 上传入口
            // 上传入口
            InkWell(
              onTap: _picked == null ? _handleUpload : null, // 无图时点击选择
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: uploadBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor,
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _picked == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.file_upload_outlined,
                            size: 36,
                            color: iconColor,
                          ),
                          const SizedBox(height: 8),
                          Text('上传图片', style: TextStyle(color: iconColor)),
                        ],
                      )
                    : Stack(
                        children: [
                          // 预览图
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: kIsWeb
                                ? Image.memory(
                                    _picked!.bytes,
                                    fit: BoxFit.cover,
                                    width: 140,
                                    height: 140,
                                  )
                                : Image.file(
                                    File(_picked!.path!),
                                    fit: BoxFit.cover,
                                    width: 140,
                                    height: 140,
                                  ),
                          ),

                          // 整张图片可点击：重新选择
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _handleUpload, // ✅ 重新选择
                              ),
                            ),
                          ),

                          // 右上角删除按钮（不触发下层 InkWell）
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque, // ✅ 优先消费手势
                              onTap: () {
                                setState(() {
                                  _picked = null;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFAB400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  '保存',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
