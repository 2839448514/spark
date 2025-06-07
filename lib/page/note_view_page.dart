import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:spark/utils/NoteDatabase.dart';
import 'package:markdown/markdown.dart' as md;

// 自定义内联数学语法，识别 $...$ 公式
class MathSyntax extends md.InlineSyntax {
  MathSyntax() : super(r"\$(.+?)\$");

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('math', match[1]!));
    return true;
  }
}

// 自定义解析器，将 'math' 标签渲染为 Math.tex 小部件
class MathBuilder extends MarkdownElementBuilder {
  @override
  Widget visitText(md.Text text, TextStyle? preferredStyle) {
    return Math.tex(text.text, textStyle: preferredStyle);
  }
}

// 支持 \( ... \) 内联数学语法
class InlineMathSyntax extends md.InlineSyntax {
  InlineMathSyntax() : super(r'\\\((.+?)\\\)');
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('math', match[1]!));
    return true;
  }
}

// 支持 \[ ... \] 显示数学语法
class DisplayMathSyntax extends md.InlineSyntax {
  DisplayMathSyntax() : super(r'\\\[(.+?)\\\]');
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('mathBlock', match[1]!));
    return true;
  }
}

// 自定义块级数学解析构建器，将 'mathBlock' 标签渲染为显示公式
class MathBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Math.tex(element.textContent, textStyle: preferredStyle, mathStyle: MathStyle.display);
  }
}

/// 笔记查看页面，渲染 Markdown 内容并支持公式
class NoteViewPage extends StatelessWidget {
  final Note note;
  const NoteViewPage({Key? key, required this.note}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(note.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: MarkdownBody(
          data: note.content,
          selectable: true,
          inlineSyntaxes: [MathSyntax(), InlineMathSyntax(), DisplayMathSyntax()],
          builders: {'math': MathBuilder(), 'mathBlock': MathBlockBuilder()},
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
        ),
      ),
    );
  }
}
