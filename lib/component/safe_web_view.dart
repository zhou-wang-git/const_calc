import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/theme_service.dart';

/// 纯组件：可内嵌在任意页面
class SafeWebView extends StatefulWidget {
  final String url;
  final Map<String, String>? headers;

  /// 跳过（直接 CANCEL）的 scheme，默认跳过 mailto/tel/weixin/alipays/intent
  final Set<String> skipSchemes;

  /// 碰到被跳过的 mailto 时，是否把邮箱地址复制到剪贴板（默认 true）
  final bool copyMailtoToClipboard;

  /// 在部分模拟器/机型 Hybrid 组合下会出现“可视不可点”，
  /// 传 true 强制关闭 Hybrid（改走 Texture）做对比。
  final bool forceTextureOnAndroid;

  /// 页面 loadStop 后自动执行一次“解冻脚本”（清理遮罩/恢复 pointer-events）
  final bool unfreezeOnLoadStop;

  /// 是否显示内置的顶部进度条（仅在 Page 里有用，纯组件里可自己做）
  final ValueChanged<String>? onTitleChanged;
  final ValueChanged<double>? onProgress;

  /// 页面主文档加载完成回调（对应 InAppWebView 的 onLoadStop）
  final ValueChanged<Uri?>? onLoadComplete;

  /// 可定制 UA（可选）
  final String? userAgent;

  /// 禁止横向滚动（默认 false）
  final bool disableHorizontalScroll;

  /// 是否同步 App 主题到网页（默认 true）
  final bool syncThemeToWeb;

  const SafeWebView({
    super.key,
    required this.url,
    this.headers,
    this.skipSchemes = const {'mailto', 'tel', 'weixin', 'alipays', 'intent'},
    this.copyMailtoToClipboard = true,
    this.forceTextureOnAndroid = false,
    this.unfreezeOnLoadStop = true,
    this.onTitleChanged,
    this.onProgress,
    this.userAgent,
    this.onLoadComplete,
    this.disableHorizontalScroll = false,
    this.syncThemeToWeb = true,
  });

  @override
  State<SafeWebView> createState() => _SafeWebViewState();
}

class _SafeWebViewState extends State<SafeWebView> {
  InAppWebViewController? _controller;

  String get _jsUnfreeze => r'''
    (function(){
      try {
        document.documentElement.style.pointerEvents = 'auto';
        document.body.style.pointerEvents = 'auto';
        document.documentElement.style.removeProperty('overflow');
        document.body.style.removeProperty('overflow');
      } catch(e){}

      // 禁止横向滚动
      if (''' + widget.disableHorizontalScroll.toString() + r''') {
        try {
          document.documentElement.style.overflowX = 'hidden';
          document.body.style.overflowX = 'hidden';
          document.documentElement.style.width = '100vw';
          document.body.style.width = '100vw';
          document.body.style.maxWidth = '100vw';
          // 禁止触摸横向拖动
          document.addEventListener('touchstart', function(e) {
            var startX = e.touches[0].pageX;
            var startY = e.touches[0].pageY;
            var moveHandler = function(e) {
              var moveX = e.touches[0].pageX;
              var moveY = e.touches[0].pageY;
              var diffX = Math.abs(moveX - startX);
              var diffY = Math.abs(moveY - startY);
              // 如果横向移动大于纵向移动，阻止默认行为
              if (diffX > diffY && diffX > 10) {
                e.preventDefault();
              }
            };
            document.addEventListener('touchmove', moveHandler, { passive: false, once: true });
          }, { passive: true });
        } catch(e){}
      }

      try {
        var W = window.innerWidth, H = window.innerHeight;
        var nodes = document.querySelectorAll('*');
        for (var i=0;i<nodes.length;i++){
          var el = nodes[i];
          var s = getComputedStyle(el);
          if ((s.position==='fixed' || s.position==='absolute')) {
            var zw = parseInt(s.width)||0, zh = parseInt(s.height)||0, zi = parseInt(s.zIndex)||0;
            if (zi>=9999 && zw>=W*0.9 && zh>=H*0.9) el.style.pointerEvents = 'none';
          }
        }
      } catch(e){}

      try {
        const stop = e=>{ try{ e.preventDefault(); e.stopPropagation(); }catch(_){ } };
        document.addEventListener('click', function(e){
          var el = e.target;
          while (el && el !== document){
            if (el.tagName==='A'){
              var href = el.getAttribute('href')||'';
              if (/^mailto:/i.test(href)) { stop(e); return; }
            }
            el = el.parentNode;
          }
        }, true);
        const _open = window.open;
        window.open = function(...args){
          try {
            const u = args[0];
            if (typeof u === 'string' && /^mailto:/i.test(u)) return null; // 仅屏蔽 mailto
          } catch (_) {}
          return _open.apply(window, args); // ← 关键：把所有实参原样传回去
        };
      } catch(e){}
      console.log('unfreeze-applied');
    })();
  ''';

  /// 同步主题到网页的 JS
  /// 参数 isDark: true 或 false
  /// 注意：网页 aria-checked="false" 表示深色模式开启（与直觉相反）
  static String _jsSyncTheme(bool isDark) => '''
    (function(){
      try {
        var btn = document.querySelector('.darkmode-toggle');
        if (!btn) {
          console.log('darkmode-toggle button not found');
          return;
        }
        // 网页 aria-checked="false" 表示深色模式，"true" 表示浅色模式
        var ariaChecked = btn.getAttribute('aria-checked');
        var isWebDark = ariaChecked === 'false';
        var appWantsDark = $isDark;
        console.log('aria-checked:', ariaChecked, 'isWebDark:', isWebDark, 'appWantsDark:', appWantsDark);
        // 只有当 App 想要的模式和网页当前模式不一致时才点击切换
        if (appWantsDark && !isWebDark) {
          btn.click();
          console.log('Theme synced: switched to dark mode');
        } else if (!appWantsDark && isWebDark) {
          btn.click();
          console.log('Theme synced: switched to light mode');
        } else {
          console.log('Theme already matched, no action needed');
        }
      } catch(e) {
        console.log('Theme sync error:', e);
      }
    })();
  ''';

  bool get _useHybridOnAndroid {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    return !widget.forceTextureOnAndroid;
  }

  /// 暴露一个解冻方法，方便外部随时调用
  Future<void> unfreeze() async {
    await _controller?.evaluateJavascript(source: _jsUnfreeze);
  }

  /// 同步主题到网页
  Future<void> syncTheme() async {
    if (!widget.syncThemeToWeb) return;
    final isDark = ThemeService().isDarkMode;
    await _controller?.evaluateJavascript(source: _jsSyncTheme(isDark));
  }

  @override
  void initState() {
    super.initState();
    // web平台没有WebView实现
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      InAppWebViewController.setWebContentsDebuggingEnabled(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(widget.url),
        headers: widget.headers,
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        sharedCookiesEnabled: true,
        domStorageEnabled: true,
        databaseEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        preferredContentMode: UserPreferredContentMode.MOBILE,
        transparentBackground: false,
        userAgent: widget.userAgent,

        // —— Android 关键组合 —— //
        useHybridComposition: _useHybridOnAndroid,
        // 如遇可视不可点：传 forceTextureOnAndroid=true
        supportMultipleWindows: true, // 需要设为 true 才能触发 onCreateWindow 回调
        javaScriptCanOpenWindowsAutomatically: true, // 允许 JS 打开窗口以便拦截
        mixedContentMode: MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
        thirdPartyCookiesEnabled: true,

        // 视口（可选）
        useWideViewPort: true,
        loadWithOverviewMode: true,

        // iOS 友好项
        allowsInlineMediaPlayback: true,
        allowsBackForwardNavigationGestures: true,
      ),

      onWebViewCreated: (c) {
        _controller = c;
      },

      onTitleChanged: (c, title) => widget.onTitleChanged?.call(title ?? ''),

      onProgressChanged: (c, p) {
        widget.onProgress?.call(p / 100.0);
      },

      // 避免误进非 http/https 的“半导航状态”
      onLoadStart: (controller, url) async {
        final u = url?.toString() ?? '';
        if (u.isNotEmpty && !u.startsWith('http')) {
          try {
            await controller.stopLoading();
          } catch (_) {}
          try {
            await controller.goBack();
          } catch (_) {}
        }
      },

      shouldOverrideUrlLoading: (controller, action) async {
        final uri = action.request.url;
        if (uri == null) return NavigationActionPolicy.ALLOW;

        final scheme = uri.scheme.toLowerCase();
        if (widget.skipSchemes.contains(scheme)) {
          // 对 mailto 再顺手复制邮箱
          if (scheme == 'mailto' && widget.copyMailtoToClipboard) {
            final email = uri.path;
            if (email.isNotEmpty) {
              await Clipboard.setData(ClipboardData(text: email));
            }
          }
          try {
            await controller.stopLoading();
          } catch (_) {}
          return NavigationActionPolicy.CANCEL;
        }

        return NavigationActionPolicy.ALLOW;
      },

      onLoadStop: (controller, url) async {
        if (widget.unfreezeOnLoadStop) {
          await controller.evaluateJavascript(source: _jsUnfreeze);
        }
        // 同步 App 主题到网页
        if (widget.syncThemeToWeb) {
          final isDark = ThemeService().isDarkMode;
          await controller.evaluateJavascript(source: _jsSyncTheme(isDark));
        }
        // 对外抛出加载完成事件
        final uri = Uri.tryParse(url?.toString() ?? '');
        widget.onLoadComplete?.call(uri);
      },

      // 可选：下载交给系统（外部浏览器/下载器）
      onDownloadStartRequest: (controller, req) async {
        final uri = Uri.tryParse(req.url.toString());
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },

      // 拦截新窗口请求（target="_blank" 或 window.open），在当前 WebView 中打开
      onCreateWindow: (controller, createWindowAction) async {
        final url = createWindowAction.request.url;
        if (url != null) {
          // 在当前 WebView 中加载，而不是打开新窗口
          await controller.loadUrl(urlRequest: createWindowAction.request);
        }
        return false; // 返回 false 表示不创建新窗口
      },

      onConsoleMessage: (c, m) {
        debugPrint('JS: ${m.message}');
      },
      onLoadError: (c, url, code, desc) => debugPrint('LoadError $code: $desc'),
      onLoadHttpError: (c, url, statusCode, desc) =>
          debugPrint('HttpError $statusCode: $desc'),
    );
  }
}

/// 搭好 Scaffold + AppBar + 进度条 + 返回拦截的整页
class SafeWebViewPage extends StatefulWidget {
  final String url;

  /// 优先使用的 AppBar 标题；不传则使用网页 title
  final String? title;

  /// 当未传 title 且网页还没返回 title 时的占位标题
  final String fallbackTitle;

  final Set<String> skipSchemes;
  final bool copyMailtoToClipboard;
  final bool forceTextureOnAndroid;
  final bool unfreezeOnLoadStop;
  final String? userAgent;
  final Map<String, String>? headers;
  final bool disableHorizontalScroll;

  /// 是否同步 App 主题到网页（默认 true）
  final bool syncThemeToWeb;

  const SafeWebViewPage({
    super.key,
    required this.url,
    this.title,
    this.fallbackTitle = '网页',
    this.skipSchemes = const {'mailto', 'tel', 'weixin', 'alipays', 'intent'},
    this.copyMailtoToClipboard = true,
    this.forceTextureOnAndroid = false,
    this.unfreezeOnLoadStop = true,
    this.userAgent,
    this.headers,
    this.disableHorizontalScroll = false,
    this.syncThemeToWeb = true,
  });

  @override
  State<SafeWebViewPage> createState() => _SafeWebViewPageState();
}

class _SafeWebViewPageState extends State<SafeWebViewPage> {
  final _wvKey = GlobalKey<_SafeWebViewState>();
  double _progress = 0.0;
  String _title = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showProgress = _progress > 0 && _progress < 1;

    // 计算最终显示的标题
    final displayTitle =
        widget.title ?? (_title.isNotEmpty ? _title : widget.fallbackTitle);

    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: Text(
            displayTitle,
            style: TextStyle(
              color: theme.appBarTheme.titleTextStyle?.color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.bolt),
              tooltip: '解冻',
              onPressed: () => _wvKey.currentState?.unfreeze(),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _wvKey.currentState?._controller?.reload(),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: showProgress ? 2 : 0,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: _progress,
                child: Container(
                  height: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: SafeWebView(
            key: _wvKey,
            url: widget.url,
            headers: widget.headers,
            skipSchemes: widget.skipSchemes,
            copyMailtoToClipboard: widget.copyMailtoToClipboard,
            forceTextureOnAndroid: widget.forceTextureOnAndroid,
            unfreezeOnLoadStop: widget.unfreezeOnLoadStop,
            userAgent: widget.userAgent,
            disableHorizontalScroll: widget.disableHorizontalScroll,
            syncThemeToWeb: widget.syncThemeToWeb,
            onTitleChanged: (t) => setState(() => _title = t),
            onProgress: (v) {
              if ((v - _progress).abs() >= 0.05 || v == 1.0 || v == 0.0) {
                setState(() => _progress = v);
              }
            },
          ),
        ),
      ),
    );
  }
}
