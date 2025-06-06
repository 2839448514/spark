import 'package:flutter/material.dart';
import 'package:spark/utils/NoteDatabase.dart';
import 'package:spark/page/note_editor_page.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';

class CategoryNotesPage extends StatefulWidget {
  final Category? category;
  
  const CategoryNotesPage({
    Key? key,
    this.category,
  }) : super(key: key);

  @override
  _CategoryNotesPageState createState() => _CategoryNotesPageState();
}

class _CategoryNotesPageState extends State<CategoryNotesPage> {
  List<Note> _notes = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final notes = await NoteDatabase.getNotesByCategory(widget.category?.id);
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      print('加载笔记时出错: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('无法加载笔记，请稍后重试'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: '重试',
              textColor: Colors.white,
              onPressed: _loadNotes,
            ),
          ),
        );
      }
    }
  }

  Future<void> _searchNotes(String query) async {
    if (query.isEmpty) {
      await _loadNotes();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final allNotes = await NoteDatabase.searchNotes(query);
      // 筛选出当前分类的笔记
      final filteredNotes = allNotes.where((note) => 
        note.categoryId == widget.category?.id
      ).toList();
      
      setState(() {
        _notes = filteredNotes;
        _isLoading = false;
      });
    } catch (e) {
      print('搜索笔记时出错: $e');
      setState(() => _isLoading = false);
    }
  }

  // 构建笔记内容预览
  Widget _buildNoteContentPreview(Note note) {
    try {
      // 尝试解析Quill Delta格式
      final deltaJson = jsonDecode(note.content);
      final document = Document.fromJson(deltaJson);
      final plainText = document.toPlainText();
      
      // 普通笔记，显示纯文本
      return Text(
        plainText.trim().isEmpty ? '空白笔记' : plainText,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[700]),
      );
    } catch (e) {
      // 普通文本内容
      return Text(
        note.content.trim().isEmpty ? '空白笔记' : note.content,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[700]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryName = widget.category?.name ?? '未分类';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: '搜索笔记...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                _searchController.clear();
                                Navigator.pop(context);
                                _loadNotes();
                              },
                              child: Text('取消'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _searchNotes(_searchController.text);
                              },
                              child: Text('搜索'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : _notes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_alt_outlined, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    '该分类下暂无笔记',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '点击 + 按钮创建新笔记',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _notes.length,
              padding: EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      _navigateToEditor(note: note);
                    },
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('删除笔记'),
                          content: Text('确定要删除这个笔记吗？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('取消'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await NoteDatabase.deleteNote(note.id!);
                                _loadNotes();
                              },
                              child: Text('删除', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          _buildNoteContentPreview(note),
                          SizedBox(height: 8),
                          if (note.updatedAt != null)
                            Text(
                              '更新于: ${_formatDateTime(note.updatedAt!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditor(),
        backgroundColor: Colors.deepPurple,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: '添加笔记',
      ),
    );
  }

  // 导航到编辑器页面
  Future<void> _navigateToEditor({Note? note}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(
          note: note,
          defaultCategoryId: widget.category?.id,
        ),
      ),
    );
    
    if (result == true) {
      // 如果保存成功，刷新笔记列表
      _loadNotes();
    }
  }

  String _formatDateTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
