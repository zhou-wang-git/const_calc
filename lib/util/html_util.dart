import 'package:html/parser.dart' as parser;

import '../services/http_service.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class HtmlUtil {
  static String appendHTML(String? fullHtmlContent) {
    String styledHtmlContent =
        '''
      <style>
        /* 通用紧凑布局重置 */
        body, p, div, span, h1, h2, h3, h4, h5, h6, ul, ol, li, br {
          margin: 0;
          padding: 0;
          line-height: 1.2;
        }
      
        br {
          display: block;
          margin: 0;
          line-height: 0.6em;
          height: 0.6em;
        }
      
        p {
          margin: 0;
          padding: 0;
        }
      
        ul, ol {
          padding-left: 16px; /* 保留缩进 */
        }
      
        li {
          margin-bottom: 4px;
        }
      
        table {
          border-spacing: 0;
          border-collapse: collapse;
        }
      
        td, th {
          padding: 4px;
        }
      </style>
      ${fullHtmlContent ?? ''}
    ''';

    styledHtmlContent = removeEmptyPTagsAndSpans(styledHtmlContent);
    styledHtmlContent = stripFontStyles(styledHtmlContent);
    styledHtmlContent = removeBrInsidePWhenHasContent(styledHtmlContent);
    styledHtmlContent = collapseConsecutiveBrParagraphs(styledHtmlContent);
    styledHtmlContent = styledHtmlContent.replaceAllMapped(
      RegExp(r'src="(?!https?://)([^"]+)"'),
      (match) {
        final path = match.group(1)!;
        // 如果是 / 开头，直接拼接 baseUrl
        if (path.startsWith('/')) {
          return 'src="${HttpService.domain}$path"';
        }
        // 否则相对路径按需拼接目录
        return 'src="${HttpService.domain}/$path"';
      },
    );

    return styledHtmlContent;
  }

  /// 清洗“空的” <p> 与 <span>：
  /// - 空文本 / 空白 / &nbsp; / 仅含空 span => 删除
  /// - 含 <br> / <img> / <iframe> / <video> / <audio> / 任何可见内容 => 保留
  /// - <p><br/></p> 会保留（换行）
  static String removeEmptyPTagsAndSpans(String html) {
    final frag = html_parser.parseFragment(html);

    bool isEffectivelyEmpty(dom.Element el) {
      // 如果包含这些可见子元素，认为非空
      const visibleTags = {
        'br', 'img', 'iframe', 'video', 'audio', 'hr', 'canvas', 'svg', 'embed', 'object'
      };

      for (final node in el.nodes) {
        if (node is dom.Element) {
          final tag = node.localName?.toLowerCase();
          if (tag == null) continue;

          // 有可见元素 => 非空
          if (visibleTags.contains(tag)) return false;

          // 子元素若是 span/p 等，需要递归判断其是否“空”
          if (tag == 'span' || tag == 'p') {
            if (!isEffectivelyEmpty(node)) return false; // 里面不空 => 整体不空
            // 否则继续看其它兄弟节点
            continue;
          }

          // 其它任意标签，默认视为有内容（避免误删）
          return false;
        } else if (node is dom.Text) {
          final text = node.text
              .replaceAll('\u00A0', '') // &nbsp;
              .trim();
          if (text.isNotEmpty) return false; // 有可见文字 => 非空
        }
      }
      // 全是空白 / 空 span / 空 p => 视为空
      return true;
    }

    void prune(dom.Node node) {
      // 先处理子节点（自底向上删除更安全）
      for (final child in List<dom.Node>.from(node.nodes)) {
        prune(child);
      }
      if (node is dom.Element) {
        final tag = node.localName?.toLowerCase();
        if (tag == 'p' || tag == 'span') {
          // 仅在“确实空”的情况下删除该元素（不触碰样式属性）
          if (isEffectivelyEmpty(node)) {
            node.remove();
          }
        }
      }
    }

    prune(frag);
    return frag.outerHtml; // 返回清理后的 HTML 片段
  }

  /// 请洗字体样式
  static String stripFontStyles(String html) {
    final frag = parser.parseFragment(html);
    const keys = {
      'font-family','font-size','font','color','line-height','letter-spacing','text-wrap'
    };

    void walk(dom.Node node) {
      if (node is dom.Element) {
        // 过滤 style
        final style = node.attributes['style'];
        if (style != null && style.trim().isNotEmpty) {
          final kept = style.split(';')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty && !keys.any((k) => s.toLowerCase().startsWith('$k:')));
          final newStyle = kept.join('; ');
          if (newStyle.isEmpty) {
            node.attributes.remove('style');
          } else {
            node.attributes['style'] = newStyle;
          }
        }
        // unwrap <font>
        if (node.localName?.toLowerCase() == 'font') {
          final parent = node.parent;
          if (parent != null) {
            final idx = parent.nodes.indexOf(node);
            parent.nodes.removeAt(idx);
            parent.nodes.insertAll(idx, node.nodes.toList());
          }
        }
      }
      for (final c in node.nodes.toList()) {
        walk(c);
      }
    }

    walk(frag);
    return frag.outerHtml;
  }

  /// 清洗：对含有内容且包含 <br> 的 <p>，移除其中的 <br>
  static String removeBrInsidePWhenHasContent(String html) {
    final dom.DocumentFragment fragment = html_parser.parseFragment(html);

    for (final dom.Element p in fragment.querySelectorAll('p')) {
      final bool hasBr = p.querySelector('br') != null;
      final bool hasText = p.text.trim().isNotEmpty;

      if (hasBr && hasText) {
        // 删除该 <p> 内部所有 <br>
        for (final br in p.querySelectorAll('br')) {
          br.remove();
        }
      }
    }

    // 重新序列化 fragment
    return fragment.nodes.map((n) {
      if (n is dom.Element) {
        return n.outerHtml;
      } else if (n is dom.Text) {
        return n.text;
      } else {
        return n.toString();
      }
    }).join();
  }


  /// 判断 <p> 是否只包含 <br>（允许空白/换行/nbsp）
  static bool _isPOnlyBr(dom.Element p) {
    // 过滤掉纯空白文本节点
    final nonEmptyTextNodes = p.nodes.whereType<dom.Text>().where(
          (t) => t.text.replaceAll('\u00A0', '').trim().isNotEmpty,
    );
    if (nonEmptyTextNodes.isNotEmpty) return false;

    // 必须至少有一个 <br>，且所有子元素都是 <br>
    final children = p.children;
    if (children.isEmpty) return false;
    if (!children.every((c) => c.localName?.toLowerCase() == 'br')) return false;

    return true;
  }

  /// 折叠：将兄弟级别中连续的 <p><br/></p> … 合并为一个（保留第一个）
  /// 例：
  /// <p><br/></p><p><br/></p>  =>  <p><br/></p>
  static String collapseConsecutiveBrParagraphs(String html) {
    final dom.DocumentFragment fragment = html_parser.parseFragment(html);

    // 遍历所有父节点，逐个处理其子节点序列
    void processParent(dom.Node parent) {
      final List<dom.Node> children = List.from(parent.nodes); // 拷贝一份，便于遍历时修改
      int i = 0;

      while (i < children.length) {
        final node = children[i];

        if (node is dom.Element && node.localName?.toLowerCase() == 'p' && _isPOnlyBr(node)) {
          // 找到一段连续的“只含 <br> 的 <p>”
          int j = i + 1;
          while (j < children.length) {
            final next = children[j];
            if (next is dom.Element && next.localName?.toLowerCase() == 'p' && _isPOnlyBr(next)) {
              j++;
            } else {
              break;
            }
          }
          // 删除 i+1...j-1（保留第一个 i）
          for (int k = j - 1; k > i; k--) {
            children[k].remove();
          }
          // 重置 children 快照（因为我们删了节点）
          children
            ..clear()
            ..addAll(parent.nodes);

          // 移动到下一个位置
          i = i + 1;
          continue;
        }

        // 递归进入元素，处理其内部（应对嵌套结构）
        if (node is dom.Element) {
          processParent(node);
          // children 快照可能被内部操作影响，这里刷新一次
          children
            ..clear()
            ..addAll(parent.nodes);
        }

        i++;
      }
    }

    // 从 fragment 顶层开始处理
    processParent(fragment);

    // 序列化
    return fragment.nodes.map((n) {
      if (n is dom.Element) return n.outerHtml;
      if (n is dom.Text) return n.text;
      return n.toString();
    }).join();
  }

}
