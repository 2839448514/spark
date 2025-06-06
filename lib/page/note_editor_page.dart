import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:spark/utils/NoteDatabase.dart';

class NoteEditorPage extends StatefulWidget {
  final Note? note;
  final int? defaultCategoryId;
  
  const NoteEditorPage({
    Key? key, 
    this.note,
    this.defaultCategoryId,
  }) : super(key: key);

  @override
  _NoteEditorPageState createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late QuillController _controller;
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  List<Category> _categories = [];
  int? _selectedCategoryId;
  @override
  void initState() {
    super.initState();
    _initializeEditor();
    _loadCategories();
  }

  void _initializeEditor() {
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _selectedCategoryId = widget.note!.categoryId;
      try {
        // 尝试解析为Quill Delta格式
        final deltaJson = jsonDecode(widget.note!.content);
        final delta = Document.fromJson(deltaJson);
        _controller = QuillController(
          document: delta,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        // 如果不是Delta格式，作为纯文本处理
        Document doc = Document();
        doc.insert(0, widget.note!.content);
        _controller = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } else {
      _controller = QuillController.basic();
      _selectedCategoryId = widget.defaultCategoryId;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await NoteDatabase.getAllCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('加载分类失败: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _editorFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.note != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑笔记' : '新建笔记'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveNote,
            child: Text(
              '保存',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),      body: Column(
        children: [
          // 标题输入框
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: '请输入标题...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // 分类选择器
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.folder, color: Colors.grey[600], size: 20),
                SizedBox(width: 8),
                Text(
                  '分类:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedCategoryId,
                      hint: Text('选择分类', style: TextStyle(color: Colors.grey[500])),
                      isExpanded: true,
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedCategoryId = newValue;
                        });
                      },
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text('未分类', style: TextStyle(color: Colors.grey[600])),
                        ),
                        ..._categories.map<DropdownMenuItem<int?>>((Category category) {
                          return DropdownMenuItem<int?>(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 工具栏
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: QuillSimpleToolbar(
              controller: _controller,
              configurations: QuillSimpleToolbarConfigurations(
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showStrikeThrough: true,
                showColorButton: true,
                showBackgroundColorButton: true,
                showListNumbers: true,
                showListBullets: true,
                showListCheck: false,
                showCodeBlock: false,
                showQuote: true,
                showIndent: true,
                showLink: false,
                showUndo: true,
                showRedo: true,
                showDirection: false,
                showSearchButton: false,
                multiRowsDisplay: false,
              ),
            ),
          ),
          
          // 编辑器区域
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: QuillEditor.basic(
                controller: _controller,
                focusNode: _editorFocusNode,
                scrollController: _scrollController,
                configurations: QuillEditorConfigurations(
                  placeholder: '开始书写您的想法...',
                  padding: EdgeInsets.zero,
                  autoFocus: false,
                  expands: false,
                  scrollable: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = jsonEncode(_controller.document.toDelta().toJson());
    
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请输入标题'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      final now = DateTime.now().toIso8601String();
      
      if (widget.note != null) {        // 更新现有笔记
        final updatedNote = Note(
          id: widget.note!.id,
          title: title,
          content: content,
          categoryId: _selectedCategoryId,
          createdAt: widget.note!.createdAt,
          updatedAt: now,
        );
        await NoteDatabase.updateNote(updatedNote);
      } else {
        // 创建新笔记
        final newNote = Note(
          title: title,
          content: content,
          categoryId: _selectedCategoryId,
          createdAt: now,
          updatedAt: now,
        );
        await NoteDatabase.insertNote(newNote);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('笔记保存成功!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // 返回true表示保存成功
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
