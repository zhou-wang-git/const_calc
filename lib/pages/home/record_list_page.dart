import 'package:const_calc/pages/home/record_list_search_filter_bar.dart';
import 'package:const_calc/util/message_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../component/bottom_date_picker.dart';
import '../../component/bottom_time_zodiac_picker.dart';
import '../../dto/digit_calculation_info.dart';
import '../../services/digit_calculation_service.dart';
import '../../util/dialog_util.dart';
import '../../util/http_util.dart';
import 'digit_calculation_record_item.dart';
import 'fortune_detail_page.dart';
import 'name_result_page.dart';

class RecordListPage extends StatefulWidget {
  const RecordListPage({super.key});

  @override
  State<RecordListPage> createState() => _RecordListPageState();
}

class _RecordListPageState extends State<RecordListPage>
    with TickerProviderStateMixin {
  int _tabIndex = 0;
  bool _isMultiSelect = false;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _pageIndex = 1;
  final int _pageSize = 10;
  final List<int> _selectedIds = [];
  final ScrollController _scrollController = ScrollController();
  List<DigitCalculationRecordItem> records = [];
  RecordListSearchFilterParams? _filterParams;

  @override
  void initState() {
    super.initState();
    _loadData(); // 首次加载
    _scrollController.addListener(_onScroll);
  }

  /// 监听滚动
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100.h &&
        !_isLoadingMore &&
        _hasMore) {
      _loadData();
    }
  }

  /// 编辑测算记录弹窗
  Future<void> _showUserEditDialog(
    BuildContext context,
    DigitCalculationRecordItem record,
  ) async {
    final TextEditingController nameController = TextEditingController(
      text: record.name,
    );
    final TextEditingController enNameController = TextEditingController(
      text: record.enName,
    );
    final TextEditingController surnameController = TextEditingController(
      text: record.surname,
    );
    final TextEditingController lastNameController = TextEditingController(
      text: record.lastName,
    );
    String birthday = record.birth;
    String birthTime = record.birthTime;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBgColor = isDark ? theme.cardTheme.color : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final labelColor = isDark ? Colors.white70 : Colors.black87;
    final borderColor = isDark ? Colors.white24 : const Color(0xFFDDDDDD);

    return showDialog(
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
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24.h),

                    // 1. 姓名
                    if (_tabIndex == 0) ...[
                      _buildFormRow(
                        label: '姓名：',
                        isDark: isDark,
                        child: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true, // 紧凑
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(fontSize: 14.sp, color: textColor),
                        ),
                      ),
                    ] else ...[
                      _buildFormRow(
                        label: '姓：',
                        isDark: isDark,
                        child: TextField(
                          controller: surnameController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true, // 紧凑
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(fontSize: 14.sp, color: textColor),
                        ),
                      ),
                      _buildFormRow(
                        label: '名：',
                        isDark: isDark,
                        child: TextField(
                          controller: lastNameController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true, // 紧凑
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(fontSize: 14.sp, color: textColor),
                        ),
                      ),
                    ],

                    // 2. 英文名
                    _buildFormRow(
                      label: '英文名：',
                      isDark: isDark,
                      child: TextField(
                        controller: enNameController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(fontSize: 14.sp, color: textColor),
                      ),
                    ),

                    // 3. 出生日期（选择器）
                    _buildFormRow(
                      label: '出生日期：',
                      isDark: isDark,
                      child: InkWell(
                        onTap: () async {
                          BottomDatePicker.showDatePicker(
                            context: context,
                            onConfirm:
                                (String formattedDate, DateTime rawDate) {
                                  setState(() {
                                    birthday = formattedDate;
                                  });
                                },
                          );
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                birthday,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: textColor,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.date_range,
                              size: 18,
                              color: isDark ? Colors.white54 : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 4. 出生时间（选择器）
                    _buildFormRow(
                      label: '出生时间：',
                      isDark: isDark,
                      child: InkWell(
                        onTap: () async {
                          BottomTimeZodiacPicker.showTimeZodiacPicker(
                            context,
                            initialValue: birthTime,
                            onConfirm: (String selected) {
                              setState(() {
                                birthTime = selected;
                              });
                            },
                          );
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                birthTime,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: textColor,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.access_time,
                              size: 18,
                              color: isDark ? Colors.white54 : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // 底部按钮
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 32.h,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.grey[800] : const Color(0xFFF3F3F3),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              ),
                              child: Text(
                                '取消',
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
                                if (nameController.text.isEmpty &&
                                    _tabIndex == 0) {
                                  MessageUtil.info(context, '姓名必填');
                                  return;
                                }
                                if (surnameController.text.isEmpty &&
                                    _tabIndex == 1) {
                                  MessageUtil.info(context, '姓必填');
                                  return;
                                }
                                if (lastNameController.text.isEmpty &&
                                    _tabIndex == 1) {
                                  MessageUtil.info(context, '名必填');
                                  return;
                                }
                                if (birthday.isEmpty) {
                                  MessageUtil.info(context, '生日必填');
                                  return;
                                }

                                final confirmed = await DialogUtil.confirm(
                                  context,
                                  title: "",
                                  content: "确认修改吗?",
                                  cancelText: "取消",
                                  confirmText: "确认",
                                );
                                if (!mounted || !confirmed) return;

                                String name = nameController.text;
                                if (_tabIndex == 1) {
                                  name = '${surnameController.text}${lastNameController.text}';
                                }
                                final parts = birthday.split('-'); // yyyy-MM-dd
                                await HttpUtil.request<void>(
                                  () => DigitCalculationService.updateUserInfo(
                                    id: record.id.toString(),
                                    name: name,
                                    ename: enNameController.text,
                                    year: parts[0],
                                    month: parts[1],
                                    day: parts[2],
                                    birthTime: birthTime,
                                    surname: surnameController.text,
                                    lastName: lastNameController.text,
                                  ),
                                  context,
                                  () => mounted,
                                );

                                MessageUtil.info(context, '修改成功');
                                Navigator.pop(context);

                                _pageIndex = 1;
                                _selectedIds.clear();
                                records.clear();
                                _loadData();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFC107),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              ),
                              child: Text(
                                '确定',
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

  // 行组件：左侧固定宽度标签，右侧控件，统一区块高度/下划线
  Widget _buildFormRow({
    required String label,
    required Widget child,
    bool isDark = false,
    double rowHeight = 48, // 和 _buildInput 高度一致
    double gap = 0, // 行间距
  }) {
    final labelColor = isDark ? Colors.white70 : Colors.black87;
    final borderColor = isDark ? Colors.white24 : const Color(0xFFDDDDDD);

    return Container(
      height: rowHeight,
      margin: EdgeInsets.only(bottom: gap.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 14.sp, color: labelColor),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 80.w,
          child: Text(
            '$label：',
            style: TextStyle(fontSize: 14.sp, color: Colors.black87),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: REdgeInsets.symmetric(vertical: 8.h),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: const Color(0xFFDDDDDD),
                  width: 1.r,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: const Color(0xFFAAAAAA),
                  width: 1.5.r,
                ),
              ),
            ),
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
      ],
    );
  }

  /// 加载数据（分页）
  Future<void> _loadData() async {
    setState(() => _isLoadingMore = true);

    final List<DigitCalculationInfo>? recordList =
        await HttpUtil.request<List<DigitCalculationInfo>?>(
          () => DigitCalculationService.getRecordList(
            recordsType: _tabIndex.toString(),
            pageNo: _pageIndex.toString(),
            pageSize: _pageSize.toString(),
            sex: _filterParams?.gender ?? '',
            birthStart: _filterParams?.birthStart ?? '',
            birthEnd: _filterParams?.birthEnd ?? '',
            csStart: _filterParams?.calcStart ?? '',
            csEnd: _filterParams?.calcEnd ?? '',
            sx: _filterParams?.zodiac ?? '',
            star: _filterParams?.constellation ?? '',
            main: _filterParams?.mainTrait ?? '',
            keywords: _filterParams?.keyword ?? '',
          ),
          context,
          () => mounted,
        );

    if (recordList == null) return;

    setState(() {
      if (recordList.isEmpty || recordList.length < _pageSize) {
        _hasMore = false;
      }
      records.addAll(recordList.map((e) => e.toItem()).toList());
      _pageIndex++;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF3F3F3);
    final appBarBgColor = isDark ? theme.appBarTheme.backgroundColor : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      resizeToAvoidBottomInset: false, // 不让键盘推挤布局
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarBgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '测算记录',
          style: TextStyle(
            color: textColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: _isMultiSelect
            ? [
                TextButton(
                  onPressed: () async {
                    final confirmed = await DialogUtil.confirm(
                      context,
                      title: "",
                      content: "确认删除吗?",
                      cancelText: "取消",
                      confirmText: "确认",
                    );

                    if (!mounted || !confirmed) return;

                    await HttpUtil.request<void>(
                      () => DigitCalculationService.delRecord(
                        id: _selectedIds.join(','),
                      ),
                      // ignore: use_build_context_synchronously
                      context,
                      () => mounted,
                    );

                    // ignore: use_build_context_synchronously
                    MessageUtil.info(context, '删除成功');

                    _pageIndex = 1;
                    _selectedIds.clear();
                    records.clear();
                    _loadData();
                  },
                  child: Text(
                    '删除',
                    style: TextStyle(color: textColor),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isMultiSelect = false;
                      _selectedIds.clear();
                    });
                  },
                  child: Text(
                    '取消',
                    style: TextStyle(color: textColor),
                  ),
                ),
              ]
            : [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isMultiSelect = true;
                    });
                  },
                  child: Text(
                    '多选',
                    style: TextStyle(color: textColor),
                  ),
                ),
              ],
      ),
      body: Container(
        color: bgColor,
        child: Column(
          children: [
            // 顶部 Tab 区域
            Container(
              decoration: BoxDecoration(
                color: isDark ? theme.cardTheme.color : Colors.white,
                border: Border(
                  top: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFE5E5E5), width: 1),
                ),
              ),
              padding: REdgeInsets.symmetric(horizontal: 32.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTab('数字测算', 0, isDark),
                  SizedBox(width: 110.w),
                  _buildTab('姓名测算', 1, isDark),
                ],
              ),
            ),

            // 搜索框区域
            RecordListSearchFilterBar(
              showMainPerson: _tabIndex == 0,
              onSearch: (RecordListSearchFilterParams value) {
                setState(() {
                  _filterParams = value;
                  _isMultiSelect = false;
                  _hasMore = true;
                  _isLoadingMore = false;
                  _pageIndex = 1;
                  _selectedIds.clear();
                  records.clear();
                  _loadData();
                });
              },
            ),

            // 列表区域
            Expanded(
              child: ListView.builder(
                itemCount: records.length,
                controller: _scrollController,
                itemBuilder: (context, index) {
                  final record = records[index];
                  final isSelected = _selectedIds.contains(record.id);

                  return DigitCalculationRecordItemWidget(
                    record: record,
                    isMultiSelect: _isMultiSelect,
                    isSelected: isSelected,
                    isShowTagMange: true,
                    onSelectChange: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedIds.add(record.id);
                        } else {
                          _selectedIds.remove(record.id);
                        }
                      });
                    },
                    onView: (r) {
                      if (_tabIndex == 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FortuneDetailPage(id: r.id),
                          ),
                        );
                      } else if (_tabIndex == 1) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NameResultPage(id: r.id.toString()),
                          ),
                        );
                      }
                    },
                    onDelete: (r) async {
                      final confirmed = await DialogUtil.confirm(
                        context,
                        title: "",
                        content: "确认删除吗?",
                        cancelText: "取消",
                        confirmText: "确认",
                      );

                      if (!mounted || !confirmed) return;

                      await HttpUtil.request<void>(
                        () => DigitCalculationService.delRecord(
                          id: record.id.toString(),
                        ),
                        // ignore: use_build_context_synchronously
                        context,
                        () => mounted,
                      );

                      // ignore: use_build_context_synchronously
                      MessageUtil.info(context, '删除成功');

                      _pageIndex = 1;
                      _selectedIds.clear();
                      records.clear();
                      _loadData();
                    },
                    onEdit: (r) => _showUserEditDialog(context, r),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index, bool isDark) {
    final bool isSelected = _tabIndex == index;
    final unselectedColor = isDark ? Colors.white70 : Colors.black87;

    return GestureDetector(
      onTap: () {
        if (_tabIndex != index) {
          setState(() {
            _tabIndex = index;
            _pageIndex = 1;
            _selectedIds.clear();
            records.clear();
            _loadData();
          });
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              color: isSelected ? const Color(0xFFFFC107) : unselectedColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          SizedBox(height: 4.h),
          Container(
            height: 3.h,
            width: 24.w,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFC107) : Colors.transparent,
              borderRadius: BorderRadius.circular(1.5.r),
            ),
          ),
        ],
      ),
    );
  }
}
