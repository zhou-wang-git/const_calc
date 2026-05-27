import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../dto/tutor_apply.dart';
import '../../dto/tutor_apply_material.dart';
import '../../services/tutor_service.dart';
import '../../util/http_util.dart';
import '../../util/message_util.dart';
import '../home/tutor_consult_search_filter_bar.dart';

/// 成为导师申请页面
class BecomeTutorPage extends StatefulWidget {
  const BecomeTutorPage({super.key});

  @override
  State<BecomeTutorPage> createState() => _BecomeTutorPageState();
}

class _BecomeTutorPageState extends State<BecomeTutorPage> {
  final _formKey = GlobalKey<FormState>();

  // 表单控制器
  final _nameController = TextEditingController();
  final _englishNameController = TextEditingController();
  final _backgroundController = TextEditingController();
  final _countryController = TextEditingController();
  final _countrySearchController = TextEditingController();

  int _selectedGradeId = 1; // 导师级别
  String _selectedCountry = '';
  String _selectedLocation = '';

  bool _isLoading = false;
  bool _loadingMaterials = true;
  bool _isUploadingMaterial = false;
  bool _loadingCountries = true;
  bool _loadingStatus = true;
  List<LabelValue> _countries = [];
  List<TutorApplyMaterial> _materials = [];
  static const String _locationAsia = '\u4e9a\u6d32';
  static const String _locationNorthAmerica = '\u5317\u7f8e\u6d32';
  static const String _locationEurope = '\u6b27\u6d32';
  static const String _locationOceania = '\u5927\u6d0b\u6d32';
  static const String _locationSouthAmerica = '\u5357\u7f8e\u6d32';
  static const String _locationAfrica = '\u975e\u6d32';
  static const String _locationAntarctica = '\u5357\u6781\u6d32';

  static const Map<String, String> _countryLocationMap = {
    '\u4e2d\u56fd': _locationAsia,
    '\u4e2d\u56fd\u9999\u6e2f': _locationAsia,
    '\u4e2d\u56fd\u6fb3\u95e8': _locationAsia,
    '\u4e2d\u56fd\u53f0\u6e7e': _locationAsia,
    '\u65e5\u672c': _locationAsia,
    '\u97e9\u56fd': _locationAsia,
    '\u65b0\u52a0\u5761': _locationAsia,
    '\u9a6c\u6765\u897f\u4e9a': _locationAsia,
    '\u6cf0\u56fd': _locationAsia,
    '\u8d8a\u5357': _locationAsia,
    '\u83f2\u5f8b\u5bbe': _locationAsia,
    '\u5370\u5ea6\u5c3c\u897f\u4e9a': _locationAsia,
    '\u5370\u5ea6': _locationAsia,
    '\u5df4\u57fa\u65af\u5766': _locationAsia,
    '\u5b5f\u52a0\u62c9\u56fd': _locationAsia,
    '\u65af\u91cc\u5170\u5361': _locationAsia,
    '\u5c3c\u6cca\u5c14': _locationAsia,
    '\u963f\u8054\u914b': _locationAsia,
    '\u6c99\u7279\u963f\u62c9\u4f2f': _locationAsia,
    '\u5361\u5854\u5c14': _locationAsia,
    '\u79d1\u5a01\u7279': _locationAsia,
    '\u963f\u66fc': _locationAsia,
    '\u5df4\u6797': _locationAsia,
    '\u4ee5\u8272\u5217': _locationAsia,
    '\u571f\u8033\u5176': _locationAsia,
    '\u4fc4\u7f57\u65af': _locationEurope,
    '\u4e4c\u514b\u5170': _locationEurope,
    '\u767d\u4fc4\u7f57\u65af': _locationEurope,
    '\u7acb\u9676\u5b9b': _locationEurope,
    '\u62c9\u8131\u7ef4\u4e9a': _locationEurope,
    '\u7231\u6c99\u5c3c\u4e9a': _locationEurope,
    '\u82f1\u56fd': _locationEurope,
    '\u7231\u5c14\u5170': _locationEurope,
    '\u6cd5\u56fd': _locationEurope,
    '\u5fb7\u56fd': _locationEurope,
    '\u610f\u5927\u5229': _locationEurope,
    '\u897f\u73ed\u7259': _locationEurope,
    '\u8461\u8404\u7259': _locationEurope,
    '\u8377\u5170': _locationEurope,
    '\u6bd4\u5229\u65f6': _locationEurope,
    '\u5362\u68ee\u5821': _locationEurope,
    '\u745e\u58eb': _locationEurope,
    '\u5965\u5730\u5229': _locationEurope,
    '\u4e39\u9ea6': _locationEurope,
    '\u632a\u5a01': _locationEurope,
    '\u745e\u5178': _locationEurope,
    '\u82ac\u5170': _locationEurope,
    '\u51b0\u5c9b': _locationEurope,
    '\u6ce2\u5170': _locationEurope,
    '\u6377\u514b': _locationEurope,
    '\u65af\u6d1b\u4f10\u514b': _locationEurope,
    '\u5308\u7259\u5229': _locationEurope,
    '\u65af\u6d1b\u6587\u5c3c\u4e9a': _locationEurope,
    '\u514b\u7f57\u5730\u4e9a': _locationEurope,
    '\u585e\u5c14\u7ef4\u4e9a': _locationEurope,
    '\u7f57\u9a6c\u5c3c\u4e9a': _locationEurope,
    '\u4fdd\u52a0\u5229\u4e9a': _locationEurope,
    '\u5e0c\u814a': _locationEurope,
    '\u7f8e\u56fd': _locationNorthAmerica,
    '\u52a0\u62ff\u5927': _locationNorthAmerica,
    '\u58a8\u897f\u54e5': _locationNorthAmerica,
    '\u5df4\u62ff\u9a6c': _locationNorthAmerica,
    '\u54e5\u65af\u8fbe\u9ece\u52a0': _locationNorthAmerica,
    '\u6fb3\u5927\u5229\u4e9a': _locationOceania,
    '\u65b0\u897f\u5170': _locationOceania,
    '\u57c3\u53ca': _locationAfrica,
    '\u6469\u6d1b\u54e5': _locationAfrica,
    '\u963f\u5c14\u53ca\u5229\u4e9a': _locationAfrica,
    '\u7a81\u5c3c\u65af': _locationAfrica,
    '\u5c3c\u65e5\u5229\u4e9a': _locationAfrica,
    '\u80af\u5c3c\u4e9a': _locationAfrica,
    '\u57c3\u585e\u4fc4\u6bd4\u4e9a': _locationAfrica,
    '\u5357\u975e': _locationAfrica,
    '\u963f\u6839\u5ef7': _locationSouthAmerica,
    '\u5df4\u897f': _locationSouthAmerica,
    '\u667a\u5229': _locationSouthAmerica,
    '\u79d8\u9c81': _locationSouthAmerica,
    '\u54e5\u4f26\u6bd4\u4e9a': _locationSouthAmerica,
  };

  final List<LabelValue> _locationOptionsV2 = const [
    LabelValue(_locationAsia, _locationAsia),
    LabelValue(_locationNorthAmerica, _locationNorthAmerica),
    LabelValue(_locationEurope, _locationEurope),
    LabelValue(_locationOceania, _locationOceania),
    LabelValue(_locationSouthAmerica, _locationSouthAmerica),
    LabelValue(_locationAfrica, _locationAfrica),
    LabelValue(_locationAntarctica, _locationAntarctica),
  ];

  // 申请状态: null=未申请, 0=待审核, 1=已通过, 2=已拒绝
  TutorApply? _existingApply;

  // 地区选项
  final List<LabelValue> _locations = const [
    LabelValue("亚洲", "亚洲"),
    LabelValue("北美洲", "北美洲"),
    LabelValue("欧洲", "欧洲"),
    LabelValue("大洋洲", "大洋洲"),
    LabelValue("南美洲", "南美洲"),
    LabelValue("非洲", "非洲"),
    LabelValue("南极洲", "南极洲"),
  ];

  // 导师级别选项
  final List<Map<String, dynamic>> _grades = const [
    {'id': 1, 'name': '启蒙导师'},
    {'id': 2, 'name': '大宗导师'},
    {'id': 3, 'name': '传承导师'},
  ];

  // 流程步骤
  final List<Map<String, dynamic>> _steps = const [
    {'title': '个人面试', 'number': 1},
    {'title': '提交档案', 'number': 2},
    {'title': '委员审核', 'number': 3},
  ];

  static const List<String> _allowedMaterialExtensions = [
    'jpg',
    'jpeg',
    'png',
    'bmp',
    'gif',
    'webp',
    'pdf',
    'doc',
    'docx',
    'txt',
    'zip',
    'rar',
    '7z',
  ];

  static const List<Map<String, dynamic>> _materialConfigs = [
    {
      'type': 'id_card',
      'label': '身份证明 *',
      'icon': Icons.badge_outlined,
      'hint': '身份证、护照或其他身份证明（必传）',
    },
    {
      'type': 'resume',
      'label': '个人简历',
      'icon': Icons.description_outlined,
      'hint': '支持 PDF / Word / TXT',
    },
    {
      'type': 'case_file',
      'label': '案例材料',
      'icon': Icons.work_outline,
      'hint': '上传能体现经验的案例资料',
    },
    {
      'type': 'certificate',
      'label': '资格证书',
      'icon': Icons.verified_outlined,
      'hint': '上传培训、认证、资质证明',
    },
    {
      'type': 'other',
      'label': '其他资料',
      'icon': Icons.folder_open_outlined,
      'hint': '其他补充文件',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadApplyStatus(),
      _loadMaterials(),
      _loadCountries(),
    ]);
  }

  Future<void> _loadApplyStatus() async {
    try {
      final apply = await TutorService.getTutorApplyStatus();
      if (mounted) {
        setState(() {
          _existingApply = apply;
          _loadingStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingStatus = false);
      }
    }
  }

  Future<void> _loadCountries() async {
    try {
      final list = await TutorService.getCountryList();
      if (mounted) {
        setState(() {
          _countries = list;
          _loadingCountries = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingCountries = false;
        });
      }
    }
  }

  Future<void> _loadMaterials() async {
    try {
      final materials = await TutorService.getTutorApplyMaterials();
      if (mounted) {
        setState(() {
          _materials = materials;
          _loadingMaterials = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMaterials = false);
      }
    }
  }

  Future<void> _pickAndUploadMaterial(Map<String, dynamic> config) async {
    if (_isUploadingMaterial) return;
    if (_materials.length >= 10) {
      MessageUtil.info(context, '最多上传 10 份资料');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: kIsWeb,
      type: kIsWeb ? FileType.custom : FileType.any,
      allowedExtensions: kIsWeb ? _allowedMaterialExtensions : null,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final pickedFile = result.files.single;
    final nameParts = pickedFile.name.split('.');
    final extension =
        (pickedFile.extension ?? (nameParts.length > 1 ? nameParts.last : ''))
            .toLowerCase();
    if (!_allowedMaterialExtensions.contains(extension)) {
      if (!mounted) return;
      MessageUtil.info(context, '当前仅支持图片、PDF、Word、TXT 和压缩包');
      return;
    }

    Uint8List? bytes = pickedFile.bytes;
    if ((bytes == null || bytes.isEmpty) && !kIsWeb) {
      try {
        bytes = await pickedFile.xFile.readAsBytes();
      } catch (_) {
        bytes = null;
      }
    }

    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      MessageUtil.error(context, '读取文件失败，请重试');
      return;
    }

    if (bytes.length > 20 * 1024 * 1024) {
      if (!mounted) return;
      MessageUtil.info(context, '单个文件不能超过 20MB');
      return;
    }

    if (!mounted) return;

    setState(() => _isUploadingMaterial = true);
    try {
      final uploaded = await HttpUtil.request<TutorApplyMaterial>(
        () => TutorService.uploadTutorApplyMaterial(
          materialType: config['type'] as String,
          materialName: config['label'] as String,
          fileName: pickedFile.name,
          fileBytes: bytes!,
        ),
        context,
        () => mounted,
      );

      if (uploaded == null || !mounted) {
        return;
      }

      setState(() {
        _materials = [
          uploaded,
          ..._materials.where((item) => item.id != uploaded.id)
        ];
      });
      MessageUtil.success(context, '资料上传成功');
    } finally {
      if (mounted) {
        setState(() => _isUploadingMaterial = false);
      }
    }
  }

  Future<void> _deleteMaterial(TutorApplyMaterial material) async {
    await HttpUtil.request<void>(
      () => TutorService.deleteTutorApplyMaterial(id: material.id),
      context,
      () => mounted,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _materials.removeWhere((item) => item.id == material.id);
    });
    MessageUtil.success(context, '资料已删除');
  }

  Future<void> _openMaterial(TutorApplyMaterial material) async {
    if (material.fileUrl.isEmpty) {
      MessageUtil.info(context, '文件地址无效');
      return;
    }

    final uri = Uri.tryParse(material.fileUrl);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.platformDefault)) {
      if (!mounted) return;
      MessageUtil.error(context, '打开资料失败');
    }
  }

  List<LabelValue> _availableCountries() {
    if (_selectedLocation.isEmpty) {
      return _countries;
    }
    final filtered = _countries.where((country) {
      final location = _countryLocationMap[country.value] ??
          _countryLocationMap[country.label];
      return location == _selectedLocation;
    }).toList();
    return filtered;
  }

  void _applyCountrySelection(String country) {
    final location = _countryLocationMap[country];
    setState(() {
      _selectedCountry = country;
      _countryController.text = country;
      if (location != null && location.isNotEmpty) {
        _selectedLocation = location;
      }
    });
  }

  void _onLocationSelected(String location) {
    setState(() {
      _selectedLocation = location;
      if (_selectedCountry.isNotEmpty) {
        final mapped = _countryLocationMap[_selectedCountry];
        if (mapped != null && mapped != location) {
          _selectedCountry = '';
          _countryController.clear();
        }
      }
    });
  }

  bool get _hasUploadedIdentityProof {
    return _materials.any((item) => item.materialType == 'id_card');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _englishNameController.dispose();
    _backgroundController.dispose();
    _countryController.dispose();
    _countrySearchController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCountry.isEmpty && _countries.isEmpty) {
      _selectedCountry = _countryController.text.trim();
    }

    if (_selectedCountry.isEmpty) {
      MessageUtil.info(context, '请选择局在地');
      return;
    }

    if (_selectedLocation.isEmpty) {
      final inferredLocation = _countryLocationMap[_selectedCountry];
      if (inferredLocation != null && inferredLocation.isNotEmpty) {
        _selectedLocation = inferredLocation;
      }
    }

    if (_selectedLocation.isEmpty) {
      MessageUtil.info(context, '请选择地区');
      return;
    }

    if (!_hasUploadedIdentityProof) {
      MessageUtil.info(context, '请先上传身份证明');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await HttpUtil.request(
        () => TutorService.submitTutorApply(
          chineseName: _nameController.text.trim(),
          englishName: _englishNameController.text.trim(),
          gradeId: _selectedGradeId,
          country: _selectedCountry,
          location: _selectedLocation,
          background: _backgroundController.text.trim(),
          materialIds: _materials.map((item) => item.id).toList(),
        ),
        context,
        () => mounted,
      );

      if (mounted) {
        MessageUtil.success(context, '申请提交成功，请等待审核');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        MessageUtil.error(context, '提交失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showCountryPicker(
    ThemeData theme,
    Color cardColor,
    Color textColor,
    Color hintColor,
  ) async {
    _countrySearchController.clear();

    final selectedCountry = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        String keyword = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final query = keyword.trim().toLowerCase();
            final availableCountries = _availableCountries();
            final filteredCountries = availableCountries.where((country) {
              if (query.isEmpty) return true;
              return country.label.toLowerCase().contains(query) ||
                  country.value.toLowerCase().contains(query);
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.72,
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: hintColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '选择局在地',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _countrySearchController,
                        onChanged: (value) {
                          setSheetState(() => keyword = value);
                        },
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: '搜索局在地/地区',
                          hintStyle: TextStyle(color: hintColor),
                          prefixIcon:
                              Icon(Icons.search, color: hintColor, size: 20),
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: hintColor.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: hintColor.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: theme.colorScheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filteredCountries.isEmpty
                            ? Center(
                                child: Text(
                                  '未找到匹配局在地',
                                  style: TextStyle(color: hintColor),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filteredCountries.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: hintColor.withOpacity(0.2),
                                ),
                                itemBuilder: (_, index) {
                                  final country = filteredCountries[index];
                                  final isSelected =
                                      country.value == _selectedCountry;
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      country.label,
                                      style: TextStyle(color: textColor),
                                    ),
                                    trailing: isSelected
                                        ? Icon(
                                            Icons.check,
                                            color: theme.colorScheme.primary,
                                            size: 18,
                                          )
                                        : null,
                                    onTap: () =>
                                        Navigator.pop(context, country.value),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    _countrySearchController.clear();

    if (!mounted || selectedCountry == null || selectedCountry.isEmpty) {
      return;
    }
    _applyCountrySelection(selectedCountry);
  }

  Future<void> _showCountryPickerV2(
    ThemeData theme,
    Color cardColor,
    Color textColor,
    Color hintColor,
  ) async {
    _countrySearchController.clear();

    final selectedCountry = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        String keyword = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final query = keyword.trim().toLowerCase();
            final availableCountries = _availableCountries();
            final filteredCountries = availableCountries.where((country) {
              if (query.isEmpty) return true;
              return country.label.toLowerCase().contains(query) ||
                  country.value.toLowerCase().contains(query);
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.72,
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: hintColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '\u9009\u62e9\u5c40\u5728\u5730',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _countrySearchController,
                        onChanged: (value) {
                          setSheetState(() => keyword = value);
                        },
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText:
                              '\u641c\u7d22\u5c40\u5728\u5730/\u5730\u533a',
                          hintStyle: TextStyle(color: hintColor),
                          prefixIcon:
                              Icon(Icons.search, color: hintColor, size: 20),
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: hintColor.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: hintColor.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: theme.colorScheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filteredCountries.isEmpty
                            ? Center(
                                child: Text(
                                  '\u672a\u627e\u5230\u5339\u914d\u5c40\u5728\u5730',
                                  style: TextStyle(color: hintColor),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filteredCountries.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: hintColor.withOpacity(0.2),
                                ),
                                itemBuilder: (_, index) {
                                  final country = filteredCountries[index];
                                  final isSelected =
                                      country.value == _selectedCountry;
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      country.label,
                                      style: TextStyle(color: textColor),
                                    ),
                                    trailing: isSelected
                                        ? Icon(
                                            Icons.check,
                                            color: theme.colorScheme.primary,
                                            size: 18,
                                          )
                                        : null,
                                    onTap: () =>
                                        Navigator.pop(context, country.value),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    _countrySearchController.clear();

    if (!mounted || selectedCountry == null || selectedCountry.isEmpty) {
      return;
    }
    _applyCountrySelection(selectedCountry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final cardColor = theme.cardTheme.color ?? Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white54 : Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('成为导师'),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: _buildBody(theme, primaryColor, cardColor, textColor, hintColor),
    );
  }

  Widget _buildBody(ThemeData theme, Color primaryColor, Color cardColor,
      Color textColor, Color hintColor) {
    // 加载中
    if (_loadingStatus) {
      return const Center(child: CircularProgressIndicator());
    }

    // 检查申请状态
    if (_existingApply != null) {
      final status = _existingApply!.status;
      if (status == 0) {
        // 待审核
        return _buildStatusPage(
          theme: theme,
          primaryColor: primaryColor,
          icon: Icons.hourglass_empty,
          iconColor: Colors.orange,
          title: '申请审核中',
          message: '您的导师申请正在审核中，请耐心等待。',
        );
      } else if (status == 1) {
        // 已通过
        return _buildStatusPage(
          theme: theme,
          primaryColor: primaryColor,
          icon: Icons.check_circle,
          iconColor: Colors.green,
          title: '您已是导师',
          message: '恭喜！您的导师申请已通过审核。',
        );
      }
      // status == 2 被拒绝，允许重新申请，继续显示表单
    }

    // 显示申请表单
    return Column(
      children: [
        _buildProcessIndicator(theme, primaryColor),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 如果被拒绝，显示提示
                  if (_existingApply != null &&
                      _existingApply!.status == 2) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '您之前的申请未通过，可重新提交申请',
                              style: TextStyle(color: textColor, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildTextField(
                    label: '中文姓名',
                    controller: _nameController,
                    required: true,
                    hintColor: hintColor,
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: '英文姓名',
                    controller: _englishNameController,
                    hintColor: hintColor,
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 16),
                  _buildGradeSelector(theme, cardColor, textColor),
                  const SizedBox(height: 16),
                  _buildLocationCountryRow(
                    theme,
                    cardColor,
                    textColor,
                    hintColor,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: '个人简介',
                    controller: _backgroundController,
                    maxLines: 5,
                    hintColor: hintColor,
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 16),
                  _buildMaterialSection(theme, cardColor, textColor, hintColor),
                  const SizedBox(height: 12),
                  _buildSubmitButton(primaryColor),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 状态页面（待审核/已通过）
  Widget _buildStatusPage({
    required ThemeData theme,
    required Color primaryColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: iconColor),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('返回', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// 流程指示器
  Widget _buildProcessIndicator(ThemeData theme, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      color: theme.colorScheme.surface,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == _steps.length - 1;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 88,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: primaryColor,
                        child: Text(
                          '${step['number']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step['title'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 30,
                    height: 2,
                    color: primaryColor.withOpacity(0.3),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 文本输入框
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    int maxLines = 1,
    required Color hintColor,
    required Color cardColor,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: '请输入$label',
            hintStyle: TextStyle(color: hintColor),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: hintColor.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: hintColor.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入$label';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  /// 导师级别选择器
  Widget _buildGradeSelector(
      ThemeData theme, Color cardColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '导师级别 *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final itemWidth = (constraints.maxWidth - spacing * 2) / 3;

            return Row(
              children: _grades.asMap().entries.map((entry) {
                final index = entry.key;
                final grade = entry.value;
                final isSelected = _selectedGradeId == grade['id'];

                return Padding(
                  padding: EdgeInsets.only(
                    right: index == _grades.length - 1 ? 0 : spacing,
                  ),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGradeId = grade['id']),
                    child: Container(
                      width: itemWidth,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            isSelected ? theme.colorScheme.primary : cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        grade['name'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// 国家选择器
  Widget _buildCountrySelector(
      ThemeData theme, Color cardColor, Color textColor, Color hintColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '局在地 *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        if (_loadingCountries)
          _buildSelectorFrame(
            cardColor: cardColor,
            hintColor: hintColor,
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: hintColor),
                ),
                const SizedBox(width: 8),
                Text('加载中...', style: TextStyle(color: hintColor)),
              ],
            ),
          )
        else
          _countries.isEmpty
              ? TextFormField(
                  controller: _countryController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: '请输入局在地',
                    hintStyle: TextStyle(color: hintColor),
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: hintColor.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: hintColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (value) => _selectedCountry = value.trim(),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: hintColor.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedCountry.isEmpty ? null : _selectedCountry,
                      hint: Text('请选择局在地', style: TextStyle(color: hintColor)),
                      items: _countries.map((c) {
                        return DropdownMenuItem(
                          value: c.value,
                          child:
                              Text(c.label, style: TextStyle(color: textColor)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCountry = value);
                        }
                      },
                    ),
                  ),
                ),
      ],
    );
  }

  /// 地区选择器
  Widget _buildCountrySelectorSearch(
    ThemeData theme,
    Color cardColor,
    Color textColor,
    Color hintColor,
  ) {
    if (_loadingCountries || _countries.isEmpty) {
      return _buildCountrySelector(theme, cardColor, textColor, hintColor);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '鍥藉 *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showCountryPicker(
            theme,
            cardColor,
            textColor,
            hintColor,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: hintColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedCountry.isEmpty ? '璇烽€夋嫨鍥藉' : _selectedCountry,
                    style: TextStyle(
                      color: _selectedCountry.isEmpty ? hintColor : textColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: hintColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCountryRow(
    ThemeData theme,
    Color cardColor,
    Color textColor,
    Color hintColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final locationField = _buildLocationDropdownSelector(
          theme,
          cardColor,
          textColor,
          hintColor,
        );
        final countryField = _buildCountrySelectorSearchV2(
          theme,
          cardColor,
          textColor,
          hintColor,
        );

        if (constraints.maxWidth < 280) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              locationField,
              const SizedBox(height: 12),
              countryField,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: locationField),
            const SizedBox(width: 12),
            Expanded(child: countryField),
          ],
        );
      },
    );
  }

  Widget _buildSelectorFrame({
    required Color cardColor,
    required Color hintColor,
    required Widget child,
  }) {
    return Container(
      height: 48,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hintColor.withOpacity(0.3)),
      ),
      child: child,
    );
  }

  Widget _buildCountrySelectorSearchV2(
    ThemeData theme,
    Color cardColor,
    Color textColor,
    Color hintColor,
  ) {
    if (_loadingCountries) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '国家 *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: hintColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: hintColor),
                ),
                const SizedBox(width: 8),
                Text(
                  '\u52a0\u8f7d\u4e2d...',
                  style: TextStyle(color: hintColor),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_countries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '国家 *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _countryController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: '请输入国家',
              hintStyle: TextStyle(color: hintColor),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: hintColor.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: hintColor.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.2,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            onChanged: (value) {
              final country = value.trim();
              _selectedCountry = country;
              final inferredLocation = _countryLocationMap[country];
              if (inferredLocation != null && inferredLocation.isNotEmpty) {
                setState(() => _selectedLocation = inferredLocation);
              }
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '国家 *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showCountryPickerV2(
            theme,
            cardColor,
            textColor,
            hintColor,
          ),
          child: _buildSelectorFrame(
            cardColor: cardColor,
            hintColor: hintColor,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedCountry.isEmpty ? '请选择国家' : _selectedCountry,
                    style: TextStyle(
                      color: _selectedCountry.isEmpty ? hintColor : textColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: hintColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationDropdownSelector(
    ThemeData theme,
    Color cardColor,
    Color textColor,
    Color hintColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '\u5dde *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        _buildSelectorFrame(
          cardColor: cardColor,
          hintColor: hintColor,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedLocation.isEmpty ? null : _selectedLocation,
              hint: Text(
                '\u8bf7\u9009\u62e9\u5dde',
                style: TextStyle(color: hintColor),
              ),
              items: _locationOptionsV2.map((loc) {
                return DropdownMenuItem<String>(
                  value: loc.value,
                  child: Text(
                    loc.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textColor),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _onLocationSelected(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialSection(
    ThemeData theme,
    Color cardColor,
    Color textColor,
    Color hintColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '申请资料',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '身份证明必须上传，其他材料可选，支持图片/PDF/Word/压缩包',
                style: TextStyle(fontSize: 12, color: hintColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 12.0;
            final maxWidth = constraints.maxWidth;
            final preferredColumns = maxWidth >= 860
                ? 4
                : maxWidth >= 620
                    ? 3
                    : maxWidth >= 320
                        ? 2
                        : 1;
            final columns = math.min(
                _materialConfigs.length, math.max(1, preferredColumns));

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _materialConfigs.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                mainAxisExtent: 96,
              ),
              itemBuilder: (context, index) {
                final config = _materialConfigs[index];
                return OutlinedButton.icon(
                  onPressed: _isUploadingMaterial
                      ? null
                      : () => _pickAndUploadMaterial(config),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    backgroundColor: cardColor,
                    alignment: Alignment.centerLeft,
                    side: BorderSide(color: Colors.grey.withOpacity(0.25)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    config['icon'] as IconData,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  label: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config['label'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        config['hint'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: hintColor, fontSize: 11),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 12),
        if (_isUploadingMaterial)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text('资料上传中...',
                    style: TextStyle(color: hintColor, fontSize: 12)),
              ],
            ),
          ),
        if (_loadingMaterials)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_materials.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Text(
              '请先上传身份证明。单个文件最大 20MB，最多可上传 10 份。',
              style: TextStyle(color: hintColor, fontSize: 12),
            ),
          )
        else
          Column(
            children: _materials.map((material) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      material.isImage
                          ? Icons.image_outlined
                          : Icons.insert_drive_file_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            material.materialName.isNotEmpty
                                ? material.materialName
                                : material.fileName,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${material.materialTypeText} · ${material.fileSizeText.isNotEmpty ? material.fileSizeText : '${material.fileSize} B'}',
                            style: TextStyle(color: hintColor, fontSize: 12),
                          ),
                          if (material.reviewRemark.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '备注：${material.reviewRemark}',
                              style: const TextStyle(
                                  color: Colors.orange, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: '查看',
                      onPressed: () => _openMaterial(material),
                      icon: const Icon(Icons.open_in_new, size: 20),
                    ),
                    IconButton(
                      tooltip: '删除',
                      onPressed: () => _deleteMaterial(material),
                      icon: const Icon(Icons.delete_outline, size: 20),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  /// 提交按钮
  Widget _buildSubmitButton(Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                '提交申请',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}
