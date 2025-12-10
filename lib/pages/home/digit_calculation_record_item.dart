import 'package:const_calc/util/message_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../services/digit_calculation_service.dart';
import '../../util/http_util.dart';

class DigitCalculationRecordItem {
  int id; // 唯一标识
  String name;
  String gender;
  String enName;
  String birth;
  String birthTime;
  String time;
  String tagName;
  String surname;
  String lastName;

  DigitCalculationRecordItem({
    required this.id,
    required this.name,
    required this.gender,
    required this.enName,
    required this.birth,
    required this.birthTime,
    required this.time,
    required this.tagName,
    required this.surname,
    required this.lastName,
  });
}

class DigitCalculationRecordItemWidget extends StatefulWidget {
  final DigitCalculationRecordItem record;
  final bool isMultiSelect;
  final bool isSelected;
  final bool isShowTagMange;
  final Function(bool)? onSelectChange;
  final Function(DigitCalculationRecordItem)? onView;
  final Function(DigitCalculationRecordItem)? onDelete;
  final Function(DigitCalculationRecordItem)? onEdit;

  const DigitCalculationRecordItemWidget({
    super.key,
    required this.record,
    required this.isMultiSelect,
    required this.isSelected,
    this.onSelectChange,
    this.onView,
    this.onDelete,
    this.onEdit,
    this.isShowTagMange = true,
  });

  @override
  State<DigitCalculationRecordItemWidget> createState() =>
      _DigitCalculationRecordItemWidgetState();
}

class _DigitCalculationRecordItemWidgetState
    extends State<DigitCalculationRecordItemWidget> {
  // ===== 固定尺寸常量（使用 screenutil）=====
  static double get kTopActionHeight => 24.h; // 顶部右侧 编辑/复选框 高度
  static double get kTopActionWidth => 28.w; // 顶部右侧区域宽度
  static double get kBottomActionHeight => 32.h; // 底部 查看/删除 区域高度

  /// 标签弹窗
  Future<String?> _showTagDialog({
    required BuildContext context,
    String title = "标签",
    String hintText = "请输入标签",
    String cancelText = "取消",
    String confirmText = "确定",
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBgColor = isDark ? theme.cardTheme.color : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white38 : Colors.grey;
    final labelColor = isDark ? Colors.white70 : Colors.black87;

    final TextEditingController controller = TextEditingController();
    List<String> tags = widget.record.tagName.isEmpty
        ? [] // 初始状态，无标签
        : widget.record.tagName.split(','); // 如果已有标签，分割成列表

    // 输入框为空，标签不联动
    controller.clear();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.r),
          ),
          contentPadding: REdgeInsets.fromLTRB(24.w, 0.h, 24.w, 24.h),
          content: SizedBox(
            width: 0.7.sw,
            child: StatefulBuilder(
              builder: (context, dialogSetState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),
                    Text(
                      title,
                      style: TextStyle(fontSize: 16.sp, color: isDark ? Colors.white60 : Colors.grey),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '注：只能设置2个标签，每个标签只能设置4个字符。',
                      style: TextStyle(fontSize: 10.sp, color: Colors.red),
                    ),
                    SizedBox(height: 4.h),
                    TextField(
                      controller: controller,
                      maxLines: 1,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: TextStyle(
                          color: hintColor,
                          fontSize: 14.sp,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4.r),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white38 : Colors.grey,
                            width: 1.r,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4.r),
                          borderSide: BorderSide(
                            color: Colors.blue,
                            width: 1.5.r,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    // 显示已添加的标签
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 4.h,
                      children: tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: isDark ? Colors.grey[700] : null,
                          labelStyle: TextStyle(color: textColor),
                          deleteIconColor: isDark ? Colors.white70 : null,
                          onDeleted: () {
                            dialogSetState(() {
                              tags.remove(tag);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 30.h),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 32.h,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.grey[800] : Colors.grey.shade200,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                                padding: REdgeInsets.symmetric(),
                              ),
                              child: Text(
                                cancelText,
                                style: TextStyle(
                                  color: labelColor,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 15.w),
                        Expanded(
                          child: SizedBox(
                            height: 32.h,
                            child: ElevatedButton(
                              onPressed: () async {
                                String inputTag = controller.text.trim();

                                // 校验标签输入
                                if (inputTag.isNotEmpty) {
                                  if (inputTag.contains(',')) {
                                    if (context.mounted) {
                                      MessageUtil.info(context, "标签不能包含逗号");
                                    }
                                    return;
                                  }
                                  if (inputTag.length > 4) {
                                    if (context.mounted) {
                                      MessageUtil.info(context, "标签最多只能输入4个字符");
                                    }
                                    return;
                                  }

                                  // 如果标签数量超过3个
                                  if (tags.length > 1) {
                                    if (context.mounted) {
                                      MessageUtil.info(context, "最多只能添加2个标签");
                                    }
                                    return;
                                  }

                                  // 添加新标签
                                  dialogSetState(() {
                                    tags.add(inputTag);
                                  });
                                  controller.clear(); // 清空输入框
                                }

                                // 保存标签
                                Navigator.pop(context, tags.join(','));

                                // 更新后端标签
                                await HttpUtil.request<void>(
                                  () => DigitCalculationService.updateTags(
                                    curid: widget.record.id.toString(),
                                    tags: tags.join(','),
                                  ),
                                  context,
                                  () => mounted,
                                );

                                if (mounted) {
                                  setState(() {
                                    widget.record.tagName = tags.join(',');
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFC107),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                                padding: REdgeInsets.symmetric(),
                              ),
                              child: Text(
                                confirmText,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBgColor = isDark ? theme.cardTheme.color : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final labelColor = isDark ? Colors.white70 : Colors.black;
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF666666);
    final borderColor = isDark ? Colors.white54 : Colors.black;
    final iconColor = isDark ? Colors.white : Colors.black;

    final ButtonStyle compactBtnGrey = ElevatedButton.styleFrom(
      backgroundColor: isDark ? Colors.grey[600] : Colors.grey[700],
      alignment: Alignment.center,
      padding: REdgeInsets.symmetric(horizontal: 6),
      minimumSize: Size(0, 25.h),
      fixedSize: Size.fromHeight(25.h),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: const StadiumBorder(),
    );

    return GestureDetector(
      onTap: widget.isMultiSelect
          ? () => widget.onSelectChange?.call(!widget.isSelected)
          : null,
      child: Container(
        margin: REdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: REdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBgColor,
          border: Border.all(color: borderColor, width: 1.r),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== 顶部：姓名 / 性别 / 复选框 or 编辑 =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 姓名
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      text: '姓名：',
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                      children: [
                        TextSpan(
                          text: widget.record.name,
                          style: TextStyle(
                            color: const Color(0xFFFFC107),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 性别
                Padding(
                  padding: REdgeInsets.only(right: 12),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '性别：',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: labelColor,
                            height: 1.1,
                          ),
                        ),
                        TextSpan(
                          text: widget.record.gender,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFC107),
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                  ),
                ),

                SizedBox(width: 8.w),

                // ✅ 固定高度/宽度占位，避免 isMultiSelect 切换高度抖动
                Align(
                  alignment: Alignment.bottomCenter,
                  // Aligns the content to the bottom center
                  child: SizedBox(
                    height: kTopActionHeight,
                    width: kTopActionWidth,
                    child: widget.isMultiSelect
                        ? Transform.translate(
                            offset: Offset(0, 1),
                            child: Transform.scale(
                              scale: 0.85,
                              child: Checkbox(
                                value: widget.isSelected,
                                checkColor: isDark ? Colors.black : Colors.white,
                                activeColor: isDark ? Colors.white : Colors.black,
                                side: BorderSide(color: iconColor),
                                onChanged: (v) =>
                                    widget.onSelectChange?.call(v ?? false),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: const VisualDensity(
                                  horizontal: -4,
                                  vertical: -4,
                                ),
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: () => widget.onEdit?.call(widget.record),
                            child: Transform.translate(
                              offset: Offset(0, 1),
                              child: Transform.scale(
                                scale: 0.8,
                                child: SizedBox(
                                  height: 20.h,
                                  child: SvgPicture.asset(
                                    'assets/icons/edit-pen-fill.svg',
                                    fit: BoxFit.contain,
                                    color: iconColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),

            // ===== 英文名 =====
            SizedBox(height: 4.h),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '英文名：',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: labelColor,
                      height: 1.1,
                    ),
                  ),
                  TextSpan(
                    text: widget.record.enName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFC107),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // ===== 生日 + 标签 =====
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 左：生日
                Expanded(
                  child: Text(
                    '生日：${widget.record.birth}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: subTextColor,
                      height: 1.1,
                    ),
                  ),
                ),

                // 右：标签 + 按钮（隐藏时保持占位）
                SizedBox(
                  height: 25.h,
                  child: Visibility(
                    visible: !widget.isMultiSelect,
                    maintainState: true,
                    maintainAnimation: true,
                    maintainSize: true,
                    child: Row(
                      children: [
                        if (widget.isShowTagMange) ...[
                          if (widget.record.tagName.isNotEmpty) ...[
                            SizedBox(
                              child: Wrap(
                                spacing: 8.w, // 标签之间的水平间距
                                runSpacing: 4.h, // 标签换行的垂直间距
                                children: widget.record.tagName.split(',').map((
                                  tag,
                                ) {
                                  return Container(
                                    height: 25.h,
                                    padding: REdgeInsets.symmetric(
                                      horizontal: 12.w,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFC107),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Transform.translate(
                                        offset: Offset(0, -0.5),
                                        child: Text(
                                          tag.trim(), // 去除多余的空格
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            height: 1.0, // 设置行高为1，确保文本垂直居中
                                            color: Colors.black, // 标签文字保持黑色，因为背景是黄色
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            SizedBox(width: 8),
                          ],
                          ElevatedButton(
                            onPressed: () => _showTagDialog(context: context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : Colors.black,
                              padding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: Align(
                              alignment: Alignment.center,
                              child: Transform.translate(
                                offset: Offset(0, -0.5),
                                child: Text(
                                  '标签管理',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.0, // 设置行高为1，确保文本垂直居中
                                    color: isDark ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ===== 底部：时间 + 操作按钮 =====
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '测算时间：${widget.record.time}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? Colors.white54 : Colors.grey,
                    height: 1.1,
                  ),
                ),

                SizedBox(
                  height: kBottomActionHeight,
                  child: Visibility(
                    visible: !widget.isMultiSelect,
                    maintainState: true,
                    maintainAnimation: true,
                    maintainSize: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () => widget.onView?.call(widget.record),
                          style: compactBtnGrey,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.visibility,
                                size: 14.sp,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6.w),
                              Transform.translate(
                                offset: const Offset(-3.0, -1.0),
                                // 往上挪 1px，数值可调
                                child: Text(
                                  '查看',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 6.w),

                        ElevatedButton(
                          onPressed: () => widget.onDelete?.call(widget.record),
                          style: compactBtnGrey,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 16.sp,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6.w),
                              Transform.translate(
                                offset: const Offset(-3.0, -1.0),
                                // 往上挪 1px，数值可调
                                child: Text(
                                  '删除',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
