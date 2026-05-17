import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../db/database_helper.dart';
import '../../models/bike_record.dart';
import 'settings_widgets.dart';

class BikeEditScreen extends StatefulWidget {
  final BikeRecord? bike;
  const BikeEditScreen({super.key, this.bike});

  @override
  State<BikeEditScreen> createState() => _BikeEditScreenState();
}

class _BikeEditScreenState extends State<BikeEditScreen> {
  final _manufacturerCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _photoPath;
  final _picker = ImagePicker();
  bool _saving = false;

  bool get _isNew => widget.bike == null;

  @override
  void initState() {
    super.initState();
    final b = widget.bike;
    if (b != null) {
      _manufacturerCtrl.text = b.manufacturer;
      _modelCtrl.text = b.model;
      _fromDate = b.fromDateMs != null
          ? DateTime.fromMillisecondsSinceEpoch(b.fromDateMs!)
          : null;
      _toDate = b.toDateMs != null
          ? DateTime.fromMillisecondsSinceEpoch(b.toDateMs!)
          : null;
      _photoPath = b.photoPath;
      _notesCtrl.text = b.notes ?? '';
    }
  }

  @override
  void dispose() {
    _manufacturerCtrl.dispose();
    _modelCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1080,
      );
      if (picked == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${dir.path}/bike_photos');
      await photosDir.create(recursive: true);
      final fileName = 'bike_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saved = await File(picked.path).copy('${photosDir.path}/$fileName');

      if (_photoPath != null) {
        final old = File(_photoPath!);
        if (await old.exists()) await old.delete();
      }
      setState(() => _photoPath = saved.path);
    } catch (_) {}
  }

  void _showPhotoOptions() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (ctx) {
        final bottomPad = MediaQuery.of(ctx).viewPadding.bottom;
        return Container(
          padding: EdgeInsets.fromLTRB(0, 8.h, 0, 8.h + bottomPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: cs.onSurface),
                title: const Text('카메라로 촬영'),
                onTap: () {
                  SystemSound.play(SystemSoundType.click);
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: cs.onSurface),
                title: const Text('갤러리에서 선택'),
                onTap: () {
                  SystemSound.play(SystemSoundType.click);
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_photoPath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('사진 삭제', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    SystemSound.play(SystemSoundType.click);
                    Navigator.pop(ctx);
                    final f = File(_photoPath!);
                    if (await f.exists()) await f.delete();
                    setState(() => _photoPath = null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom ? (_fromDate ?? now) : (_toDate ?? now);
    final firstDate = isFrom ? DateTime(2000) : (_fromDate ?? DateTime(2000));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (_toDate != null && picked.isAfter(_toDate!)) _toDate = null;
      } else {
        _toDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final manufacturer = _manufacturerCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    if (manufacturer.isEmpty || model.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제조사와 기종을 입력해주세요')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final bike = BikeRecord(
        id: widget.bike?.id,
        manufacturer: manufacturer,
        model: model,
        fromDateMs: _fromDate?.millisecondsSinceEpoch,
        toDateMs: _toDate?.millisecondsSinceEpoch,
        photoPath: _photoPath,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (_isNew) {
        await DatabaseHelper.instance.insertBike(bike);
      } else {
        await DatabaseHelper.instance.updateBike(bike);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('자전거 삭제'),
        content: const Text('이 자전거를 목록에서 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    if (_photoPath != null) {
      final f = File(_photoPath!);
      if (await f.exists()) await f.delete();
    }
    await DatabaseHelper.instance.deleteBike(widget.bike!.id!);
    if (mounted) Navigator.pop(context);
  }

  String _formatDate(DateTime dt) => DateFormat('yyyy.MM.dd').format(dt);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final panelColor = cs.surfaceContainer;
    final titleColor = cs.onSurface;
    final subtitleColor = cs.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? '자전거 추가' : '자전거 편집'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              '저장',
              style: TextStyle(
                color: _saving ? subtitleColor : cs.primary,
                fontWeight: FontWeight.bold,
                fontSize: 15.sp,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          // 사진 영역
          GestureDetector(
            onTap: () {
              SystemSound.play(SystemSoundType.click);
              _showPhotoOptions();
            },
            child: Container(
              height: 200.h,
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildPhotoArea(cs),
            ),
          ),
          SizedBox(height: 12.h),

          // 제조사 + 기종 + 날짜 패널
          Container(
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                _textFieldRow(
                  icon: Icons.business_outlined,
                  label: '제조사',
                  ctrl: _manufacturerCtrl,
                  hint: '예: Trek, Giant, Specialized',
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                ),
                Divider(height: 1, color: cs.outlineVariant, indent: 16.w),
                _textFieldRow(
                  icon: Icons.directions_bike_outlined,
                  label: '기종',
                  ctrl: _modelCtrl,
                  hint: '예: FX 3 Disc, TCR Advanced',
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                ),
                Divider(height: 1, color: cs.outlineVariant, indent: 16.w),
                _dateRow(
                  icon: Icons.event_available_outlined,
                  label: '사용 시작',
                  date: _fromDate,
                  onTap: () => _pickDate(isFrom: true),
                  onClear: null,
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                ),
                Divider(height: 1, color: cs.outlineVariant, indent: 16.w),
                _dateRow(
                  icon: Icons.event_busy_outlined,
                  label: '사용 종료',
                  date: _toDate,
                  onTap: () => _pickDate(isFrom: false),
                  onClear: _toDate != null ? () => setState(() => _toDate = null) : null,
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // 비고 패널
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                settingsIconBox(Icons.notes_outlined),
                SizedBox(width: 14.w),
                Expanded(
                  child: TextField(
                    controller: _notesCtrl,
                    maxLines: null,
                    minLines: 2,
                    style: TextStyle(color: titleColor, fontSize: 14.sp),
                    decoration: InputDecoration.collapsed(
                      hintText: '비고 (선택사항)',
                      hintStyle: TextStyle(color: subtitleColor, fontSize: 14.sp),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (!_isNew) ...[
            SizedBox(height: 24.h),
            GestureDetector(
              onTap: () {
                SystemSound.play(SystemSoundType.click);
                _delete();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 18.r),
                    SizedBox(width: 6.w),
                    Text(
                      '자전거 삭제',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildPhotoArea(ColorScheme cs) {
    if (_photoPath != null && File(_photoPath!).existsSync()) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(_photoPath!), fit: BoxFit.cover),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.edit, color: Colors.white, size: 16.r),
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 40.r, color: cs.onSurfaceVariant),
        SizedBox(height: 8.h),
        Text('사진 추가', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13.sp)),
        SizedBox(height: 4.h),
        Text(
          '탭하여 카메라 또는 갤러리 선택',
          style: TextStyle(color: cs.outline, fontSize: 11.sp),
        ),
      ],
    );
  }

  Widget _textFieldRow({
    required IconData icon,
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          settingsIconBox(icon),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: subtitleColor, fontSize: 11.sp)),
                SizedBox(height: 2.h),
                TextField(
                  controller: ctrl,
                  style: TextStyle(
                      color: titleColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold),
                  decoration: InputDecoration.collapsed(
                    hintText: hint,
                    hintStyle: TextStyle(
                        color: subtitleColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.normal),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateRow({
    required IconData icon,
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required VoidCallback? onClear,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    return GestureDetector(
      onTap: () {
        SystemSound.play(SystemSoundType.click);
        onTap();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            settingsIconBox(icon),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: titleColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold)),
            ),
            if (date != null && onClear != null)
              GestureDetector(
                onTap: () {
                  SystemSound.play(SystemSoundType.click);
                  onClear();
                },
                child: Padding(
                  padding: EdgeInsets.only(right: 6.w),
                  child: Icon(Icons.close, color: subtitleColor, size: 16.r),
                ),
              ),
            Text(
              date != null ? _formatDate(date) : '미설정',
              style: TextStyle(
                color: date != null ? Colors.indigo : subtitleColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.chevron_right, color: subtitleColor, size: 18.r),
          ],
        ),
      ),
    );
  }
}
