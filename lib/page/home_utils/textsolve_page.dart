import 'package:flutter/material.dart';
import 'package:spark/utils/ai_api.dart';
import 'package:spark/utils/NoteDatabase.dart';
import 'package:spark/page/note_view_page.dart';
import 'dart:async';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

class TextSolvePage extends StatefulWidget {
  @override
  _TextSolvePageState createState() => _TextSolvePageState();
}

class _TextSolvePageState extends State<TextSolvePage> {
  late String _question;
  String _reasoning = '';
  String _answer = '';
  String _notes = '';
  bool _isLoading = false;
  bool _isGeneratingNotes = false;
  StreamSubscription<Map<String, String>>? _answerSubscription;
  StreamSubscription<String>? _notesSubscription;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _answerSubscription?.cancel();
    _notesSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // 清理和格式化笔记内容
  String _cleanNotesContent(String content) {
    // 移除可能的代码块标记
    content = content.replaceAll(RegExp(r'^```[\w]*\n?'), '');
    content = content.replaceAll(RegExp(r'\n?```$'), '');

    // 移除多余的空行
    content = content.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // 确保开头不是空行
    content = content.trim();

    return content;
  } // 构建优化的提示词

  String _buildOptimizedPrompt(String userQuestion) {
    return '''
请你作为一个专业的学习助手，详细回答以下问题：

$userQuestion

请按照以下格式进行回答：

## 🤔 分析问题
首先分析问题的核心要点和关键概念

## 💡 详细解答
提供完整、准确的答案，包括：
- 核心概念解释
- 详细步骤说明
- 实际应用示例

## ✅ 总结要点
简明扼要地总结关键信息

要求：
- 答案要详细完整，逻辑清晰
- 使用Markdown格式，便于阅读
- 如果是学科问题，请提供理论基础
- 如果是实践问题，请给出具体步骤
- 使用简洁明了的语言
''';
  }

  // 构建笔记生成的提示词
  String _buildNotesPrompt(String question, String answer) {
    return '''
请基于以下问答内容生成一份结构化的学习笔记。请严格按照Markdown格式输出，不要添加任何代码块标记：

【问题】$question

【解答】$answer

请直接生成以下结构的学习笔记，使用标准Markdown格式：

## 📝 核心知识点
- 关键概念和定义
- 重要原理或规律

## 🎯 要点总结  
- 核心要点梳理
- 重点内容归纳

## 💡 学习要点
- 需要重点记忆的内容
- 容易混淆的地方

## 🔗 相关拓展
- 相关知识点
- 延伸思考

注意：
1. 直接输出Markdown内容，不要使用代码块包装
2. 保持笔记简洁明了，便于复习记忆
3. 使用列表、加粗等Markdown语法优化可读性
''';
  }

  // 生成笔记总结的方法（使用流式输出）
  Future<void> _generateNotes() async {
    setState(() {
      _isGeneratingNotes = true;
      _notes = '';
    });

    try {
      final notesPrompt = _buildNotesPrompt(_question, _answer);
      print('笔记生成提示词: $notesPrompt'); // 调试信息

      _notesSubscription?.cancel();
      _notesSubscription = AIApi.get_ai_stream_request(notesPrompt).listen(
        (chunk) {
          print('收到笔记数据块: "$chunk"'); // 调试信息
          setState(() {
            _notes += chunk;
          });
          print('当前笔记内容: "$_notes"'); // 调试信息
        },
        onDone: () {
          // 清理和格式化最终的笔记内容
          final cleanedNotes = _cleanNotesContent(_notes);
          print('笔记生成完成，清理前: "$_notes"'); // 调试信息
          print('笔记生成完成，清理后: "$cleanedNotes"'); // 调试信息
          setState(() {
            _notes = cleanedNotes;
            _isGeneratingNotes = false;
          });
        },
        onError: (error) {
          print('笔记生成错误: $error'); // 调试信息
          setState(() {
            _isGeneratingNotes = false;
            _notes = '笔记生成失败，请稍后再试';
          });
        },
      );
    } catch (error) {
      print('笔记生成异常: $error'); // 调试信息
      setState(() {
        _isGeneratingNotes = false;
        _notes = '笔记生成失败，请稍后再试';
      });
    }  }

  // 保存笔记到数据库
  Future<void> _saveNoteToDatabase() async {
    if (_notes.isEmpty || _question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('没有可保存的笔记内容'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {      // 查找或创建"搜题笔记"分类
      final categories = await NoteDatabase.getAllCategories();
      Category? searchNotesCategory;
      
      // 查找是否已存在"搜题笔记"分类
      for (final category in categories) {
        if (category.name == '搜题笔记') {
          searchNotesCategory = category;
          break;
        }
      }

      // 如果分类不存在，创建一个
      if (searchNotesCategory == null) {
        final newCategory = Category(
          name: '搜题笔记',
          description: '通过AI问答生成的学习笔记',
          createdAt: DateTime.now().toIso8601String(),
        );
        final categoryId = await NoteDatabase.insertCategory(newCategory);
        searchNotesCategory = Category(
          id: categoryId,
          name: '搜题笔记',
          description: '通过AI问答生成的学习笔记',
          createdAt: DateTime.now().toIso8601String(),
        );
      }

      // 创建笔记
      final note = Note(
        title: _question.length > 50 ? '${_question.substring(0, 50)}...' : _question,
        content: _notes,
        categoryId: searchNotesCategory.id,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await NoteDatabase.insertNote(note);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('笔记已成功保存到"搜题笔记"分类'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: '查看',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NoteViewPage(note: note),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('保存笔记失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存笔记失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 获取AI答案（使用流式输出，包含思考过程）
  Future<void> _getAIAnswer(String question) async {
    setState(() {
      _isLoading = true;
      _reasoning = '';
      _answer = '';
      _notes = '';
    });

    try {
      final optimizedPrompt = _buildOptimizedPrompt(question);

      _answerSubscription?.cancel();
      _answerSubscription = AIApi.get_ai_stream_request_with_reasoning(
        optimizedPrompt,
      ).listen(
        (chunk) {
          print('收到数据块: $chunk'); // 调试信息
          setState(() {
            if (chunk.containsKey('reasoning')) {
              _reasoning += chunk['reasoning']!;
              print('更新思考过程: ${chunk['reasoning']}'); // 调试信息
            }
            if (chunk.containsKey('content')) {
              _answer += chunk['content']!;
              print('更新答案内容: ${chunk['content']}'); // 调试信息
            }
            if (chunk.containsKey('error')) {
              _answer = chunk['error']!;
            }
          });
        },
        onDone: () {
          setState(() {
            _isLoading = false;
          });
          // 答案生成完成后，自动生成笔记
          if (_answer.isNotEmpty &&
              !_answer.contains('请求失败') &&
              !_answer.contains('API请求失败')) {
            _generateNotes();
          }
        },
        onError: (error) {
          setState(() {
            _isLoading = false;
            _answer = '请求失败，请稍后再试';
          });
        },
      );
    } catch (error) {
      setState(() {
        _isLoading = false;
        _answer = '请求失败，请稍后再试';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('文字解答')),
      body: SingleChildScrollView(
        // 整个页面可以滚动
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: '请输入您的问题',
                hintText: '例如：如何解决1+1=2问题？',
              ),
              maxLines: 4,
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed:
                    _isLoading
                        ? null
                        : () {
                          _question = _controller.text.trim();
                          if (_question.isEmpty) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('请输入问题')));
                            return;
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('问题已提交，正在思考中...')),
                            );
                            _getAIAnswer(_question);
                          }
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isLoading
                        ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('思考中...'),
                          ],
                        )
                        : Text('提交问题', style: TextStyle(fontSize: 16)),
              ),
            ),
            SizedBox(height: 24), // 思考过程区域
            if (_reasoning.isNotEmpty || _isLoading) ...[
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '思考过程',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                        Spacer(),
                        if (_isLoading && _reasoning.isEmpty)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.orange,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (_reasoning.isNotEmpty)
                      Text(
                        _reasoning,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      )
                    else if (_isLoading)
                      Text(
                        '正在思考中...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    // 思考过程的流式输出光标效果
                    if (_isLoading && _reasoning.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '正在思考中...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ], // 答案和笔记区域（左右分栏）
            if (_answer.isNotEmpty ||
                (_isLoading && _reasoning.isNotEmpty)) ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 左侧答案区域
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '答案',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            if (_answer.isNotEmpty)
                              Container(
                                width: double.infinity,
                                constraints: BoxConstraints(minHeight: 100),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      MarkdownBody(
                                        data: _answer,
                                        styleSheet: MarkdownStyleSheet(
                                          p: TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey[800],
                                            height: 1.6,
                                          ),
                                          h1: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[700],
                                          ),
                                          h2: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[600],
                                          ),
                                          h3: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[500],
                                          ),
                                          strong: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[800],
                                          ),
                                          em: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.blue[600],
                                          ),
                                          code: TextStyle(
                                            backgroundColor: Colors.grey[100],
                                            fontFamily: 'monospace',
                                            fontSize: 14,
                                          ),
                                          blockquote: TextStyle(
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (_isLoading)
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      '正在生成答案...',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey[500],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // 显示流式输出的光标效果
                            if (_isLoading && _answer.isNotEmpty)
                              Container(
                                margin: EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 500),
                                        decoration: BoxDecoration(
                                          color:
                                              _isLoading
                                                  ? Colors.blue
                                                  : Colors.transparent,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    if (_isLoading)
                                      Text(
                                        '正在生成中...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    // 右侧笔记区域
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [                            Row(
                              children: [
                                Icon(
                                  Icons.note_alt,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '学习笔记',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                                Spacer(),
                                if (_notes.isNotEmpty && !_isGeneratingNotes)
                                  ElevatedButton.icon(
                                    onPressed: () => _saveNoteToDatabase(),
                                    icon: Icon(Icons.save, size: 16),
                                    label: Text('保存笔记'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size(0, 32),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                if (_isGeneratingNotes)
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.green,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 12),
                            if (_notes.isNotEmpty)
                              Container(
                                width: double.infinity,
                                constraints: BoxConstraints(minHeight: 100),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // 添加调试信息显示
                                      if (_notes.contains('```'))
                                        Container(
                                          margin: EdgeInsets.only(bottom: 8),
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.orange[100],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            '⚠️ 检测到代码块格式，可能影响显示',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange[700],
                                            ),
                                          ),
                                        ),
                                      MarkdownBody(
                                        data: _notes,
                                        inlineSyntaxes: [MathSyntax(), InlineMathSyntax(), DisplayMathSyntax()],
                                        builders: {'math': MathBuilder(), 'mathBlock': MathBlockBuilder()},
                                        styleSheet: MarkdownStyleSheet(
                                          p: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                            height: 1.6,
                                          ),
                                          h1: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[700],
                                          ),
                                          h2: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[600],
                                          ),
                                          h3: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[500],
                                          ),
                                          strong: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[800],
                                          ),
                                          em: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.green[600],
                                          ),
                                          listBullet: TextStyle(
                                            color: Colors.green[600],
                                          ),
                                          code: TextStyle(
                                            backgroundColor: Colors.green[100],
                                            fontFamily: 'monospace',
                                            fontSize: 13,
                                            color: Colors.green[800],
                                          ),
                                          codeblockDecoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: Colors.green[200]!,
                                              width: 1,
                                            ),
                                          ),
                                          codeblockPadding: EdgeInsets.all(12),
                                          blockquote: TextStyle(
                                            color: Colors.green[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                          blockquoteDecoration: BoxDecoration(
                                            border: Border(
                                              left: BorderSide(
                                                color: Colors.green[300]!,
                                                width: 4,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // 显示流式输出的光标效果
                                      if (_isGeneratingNotes)
                                        Container(
                                          margin: EdgeInsets.only(top: 8),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  borderRadius:
                                                      BorderRadius.circular(1),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                '正在生成笔记...',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                            else if (_isGeneratingNotes)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '正在生成学习笔记...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    backgroundColor: Colors.green[100],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.green,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                '等待答案完成后自动生成笔记...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ], // 空状态提示
            if (_reasoning.isEmpty && _answer.isEmpty && !_isLoading) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      '请输入您的问题并点击提交按钮',
                      style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'AI 将实时生成详细答案和学习笔记',
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton:
          _answer.isNotEmpty
              ? FloatingActionButton(
                onPressed:
                    _isGeneratingNotes
                        ? null
                        : () {
                          if (_answer.isNotEmpty) {
                            _generateNotes();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('正在重新生成学习笔记...')),
                            );
                          }
                        },
                backgroundColor:
                    _isGeneratingNotes ? Colors.grey : Colors.green,
                child:
                    _isGeneratingNotes
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Icon(Icons.refresh, color: Colors.white),
                tooltip: '重新生成笔记',
              )
              : null,
    );
  }
}

// 自定义内联数学语法，识别 $...$ 公式
class MathSyntax extends md.InlineSyntax { MathSyntax() : super(r"\$(.+?)\$");
  @override bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('math', match[1]!)); return true; }
}
// 支持 \( ... \) 内联数学
class InlineMathSyntax extends md.InlineSyntax { InlineMathSyntax() : super(r"\\\((.+?)\\\)");
  @override bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('math', match[1]!)); return true; }
}
// 支持 \[ ... \] 显示数学
class DisplayMathSyntax extends md.InlineSyntax { DisplayMathSyntax() : super(r"\\\[(.+?)\\\]");
  @override bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('mathBlock', match[1]!)); return true; }
}
// 渲染内联数学
class MathBuilder extends MarkdownElementBuilder {
  @override Widget visitText(md.Text text, TextStyle? style) => Math.tex(text.text, textStyle: style);
}
// 渲染块级数学
class MathBlockBuilder extends MarkdownElementBuilder {
  @override Widget visitElementAfter(md.Element element, TextStyle? style) => Math.tex(element.textContent, textStyle: style, mathStyle: MathStyle.display);
}
