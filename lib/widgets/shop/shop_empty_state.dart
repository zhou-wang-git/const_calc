import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ShopEmptyState extends StatelessWidget {
  final String asset;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final bool carded;

  const ShopEmptyState({
    super.key,
    required this.asset,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
    this.carded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          asset,
          width: 118.w,
          height: 118.w,
        ),
        SizedBox(height: 18.h),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13.sp,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
          textAlign: TextAlign.center,
        ),
        if (actionText != null && onAction != null) ...[
          SizedBox(height: 20.h),
          SizedBox(
            height: 40.h,
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor:
                    isDark ? Colors.white : theme.colorScheme.primary,
                foregroundColor: isDark ? Colors.black87 : Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              child: Text(
                actionText!,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: carded
            ? Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
                decoration: BoxDecoration(
                  color: isDark ? theme.cardTheme.color : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: content,
              )
            : content,
      ),
    );
  }
}
