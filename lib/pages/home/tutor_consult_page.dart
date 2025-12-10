import 'package:const_calc/dto/Tutor.dart';
import 'package:const_calc/dto/tag.dart';
import 'package:const_calc/pages/home/tutor_consult_search_filter_bar.dart';
import 'package:const_calc/pages/home/tutor_detail_page.dart';
import 'package:flutter/material.dart';

import '../../services/http_service.dart';
import '../../services/tutor_service.dart';
import '../../util/http_util.dart';

Map<int, String> gradeMapper = {1: '启蒙导师', 2: '大宗导师', 3: '传承导师'};

class TutorConsultPage extends StatefulWidget {
  const TutorConsultPage({super.key});

  @override
  State<TutorConsultPage> createState() => _TutorConsultPageState();
}

class _TutorConsultPageState extends State<TutorConsultPage> {
  int _filterIndex = 0;
  final List<Tutor> _tutorList = [];
  int _page = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  bool _isLoading = false;
  List<Tag> _tags = [];

  TutorConsultSearchFilterParams? _searchFilterParams;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTutorList();
    _initTags();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !_isLoading &&
          _hasMore) {
        _loadTutorList();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initTags() async {
    final tagList = await HttpUtil.request(
      () => TutorService.getTagList(),
      context,
      () => mounted,
    );
    if (tagList == null) return;
    setState(() {
      _tags = tagList;
    });
  }

  Future<void> _loadTutorList({bool refresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;

    if (refresh) {
      _page = 1;
      _hasMore = true;
      _tutorList.clear();
    }

    try {
      final list = await HttpUtil.request(
        () => TutorService.getTutorPage(
          pageNo: _page.toString(),
          pageSize: _pageSize.toString(),
          name: _searchFilterParams?.keyword ?? '',
          tagIds: _filterIndex != 0 ? _filterIndex.toString() : '',
          sex: _searchFilterParams?.gender ?? '',
          location: _searchFilterParams?.location ?? '',
          levelName: _searchFilterParams?.status ?? '',
          gradeId: _searchFilterParams?.level ?? '',
          experienceYears: _searchFilterParams?.experienceYearsStart == null
              ? ''
              : '${_searchFilterParams?.experienceYearsStart},${_searchFilterParams?.experienceYearsEnd}',
          hourlyConsultationFee: _searchFilterParams?.priceStart == null
              ? ''
              : '${_searchFilterParams?.priceStart},${_searchFilterParams?.priceEnd}',
        ),
        context,
        () => mounted,
      );

      if (list != null) {
        setState(() {
          _tutorList.addAll(list);
          if (list.length < _pageSize) {
            _hasMore = false;
          } else {
            _page++;
          }
        });
      }
    } finally {
      _isLoading = false;
    }
  }

  void _onTabChange(int index) {
    if (_filterIndex == index) return;
    setState(() => _filterIndex = index);
    _loadTutorList(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final primaryColor = theme.colorScheme.primary;
    final cardColor = theme.cardTheme.color ?? Colors.white;
    final subTextColor =
        theme.textTheme.bodySmall?.color ?? Colors.grey.shade600;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: theme.appBarTheme.iconTheme?.color ?? textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '导师咨询',
          style: theme.appBarTheme.titleTextStyle ??
              TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: Column(
        children: [
          TutorConsultSearchFilterBar(
            onSearch: (TutorConsultSearchFilterParams value) {
              setState(() {
                _searchFilterParams = value;
              });
              _loadTutorList(refresh: true);
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTab('全部', 0, primaryColor, cardColor, subTextColor),
                    const SizedBox(width: 8),
                    ..._tags.expand(
                      (tag) => [
                        _buildTab(
                            tag.name, tag.value, primaryColor, cardColor, subTextColor),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _tutorList.length + 1,
              itemBuilder: (_, index) {
                if (index == _tutorList.length) {
                  return _hasMore
                      ? const SizedBox.shrink()
                      : const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text('没有更多了', style: TextStyle(color: Colors.grey)),
                          ),
                        );
                }
                return _buildTutorCard(_tutorList[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index, Color primaryColor,
      Color cardColor, Color subTextColor) {
    final selected = _filterIndex == index;
    return GestureDetector(
      onTap: () => _onTabChange(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? primaryColor : cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : subTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _badgeAndYears(Tutor tutor) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final highlightColor = isDark ? const Color(0xFFFFD54F) : primaryColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 20,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Image.asset(
                'assets/icons/zs.png',
                fit: BoxFit.contain,
                height: 20,
              ),
              Positioned(
                bottom: 3.5,
                left: 25,
                child: Text(
                  gradeMapper[tutor.gradeId] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0XFFBF6D1C),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Container(
          height: 16,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: highlightColor, width: 1),
          ),
          child: Text(
            '从业${tutor.experienceYears}年',
            style: TextStyle(fontSize: 10, height: 0.5, color: highlightColor),
          ),
        ),
      ],
    );
  }

  Widget _buildTutorCard(Tutor tutor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color ?? Colors.white;
    final shadowColor = theme.shadowColor.withOpacity(0.12);
    final titleColor =
        theme.textTheme.titleLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final subColor =
        theme.textTheme.bodySmall?.color ?? (isDark ? Colors.white70 : Colors.black54);
    final borderColor = isDark ? theme.dividerColor : const Color(0xFFEDEDED);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: borderColor.withOpacity(0.3),
            blurRadius: 0.5,
            spreadRadius: 0.2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: Image.network(
                  '${HttpService.domain}${tutor.avatar}',
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Image.asset('assets/icons/avatar.png', width: 48, height: 48),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tutor.chineseName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _badgeAndYears(tutor),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TutorDetailPage(tutor: tutor),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              minimumSize: const Size(72, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              '点击查询',
                              style: TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tutor.background,
            style: TextStyle(fontSize: 12, color: subColor),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
