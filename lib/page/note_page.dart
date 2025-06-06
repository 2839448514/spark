import 'package:flutter/material.dart';
import 'package:spark/utils/NoteDatabase.dart';
import 'package:spark/page/note_editor_page.dart';
import 'package:spark/page/category_notes_page.dart';

class NotePage extends StatefulWidget {
  @override
  _NotePageState createState() => new _NotePageState();
}

class _NotePageState extends State<NotePage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _categoriesWithCount = [];
  bool _isLoading = true;
  bool _fabExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadCategories();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _fabExpanded = !_fabExpanded;
      if (_fabExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }
  
  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categoriesWithCount = await NoteDatabase.getCategoriesWithCount();
      
      // 添加"未分类"项
      final uncategorizedNotes = await NoteDatabase.getNotesByCategory(null);
      final uncategorizedCount = uncategorizedNotes.length;
      
      List<Map<String, dynamic>> result = [
        {
          'id': null,
          'name': '未分类',
          'description': '未分类的笔记',
          'createdAt': null,
          'noteCount': uncategorizedCount,
        },
        ...categoriesWithCount,
      ];
      
      setState(() {
        _categoriesWithCount = result;
        _isLoading = false;
      });
    } catch (e) {
      print('加载分类时出错: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('无法加载分类，请稍后重试'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: '重试',
              textColor: Colors.white,
              onPressed: _loadCategories,
            ),
          ),
        );
      }
    }
  }

  // 显示添加分类的对话框
  void _showAddCategoryDialog() {
    String categoryName = '';
    String categoryDescription = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('添加分类'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: '分类名称',
                  hintText: '输入分类名称',
                ),
                onChanged: (value) => categoryName = value,
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: '分类描述（可选）',
                  hintText: '输入分类描述',
                ),
                onChanged: (value) => categoryDescription = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                if (categoryName.trim().isNotEmpty) {
                  Navigator.pop(context);
                  await _addCategory(categoryName.trim(), categoryDescription.trim());
                }
              },
              child: Text('添加'),
            ),
          ],
        );
      },
    );
  }

  // 添加分类
  Future<void> _addCategory(String name, String description) async {
    try {
      final category = Category(
        name: name,
        description: description.isEmpty ? null : description,
        createdAt: DateTime.now().toIso8601String(),
      );
      
      await NoteDatabase.insertCategory(category);
      await _loadCategories();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分类"$name"添加成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('添加分类时出错: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加分类失败，请稍后重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 显示分类选项菜单
  void _showCategoryOptions(Map<String, dynamic> category) {
    // 如果是"未分类"，不显示编辑/删除选项
    if (category['id'] == null) {
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('编辑分类'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditCategoryDialog(category);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('删除分类', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteCategoryDialog(category);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 显示编辑分类对话框
  void _showEditCategoryDialog(Map<String, dynamic> category) {
    String categoryName = category['name'] ?? '';
    String categoryDescription = category['description'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('编辑分类'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: '分类名称',
                ),
                controller: TextEditingController(text: categoryName),
                onChanged: (value) => categoryName = value,
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: '分类描述（可选）',
                ),
                controller: TextEditingController(text: categoryDescription),
                onChanged: (value) => categoryDescription = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                if (categoryName.trim().isNotEmpty) {
                  Navigator.pop(context);
                  await _updateCategory(category['id'], categoryName.trim(), categoryDescription.trim());
                }
              },
              child: Text('保存'),
            ),
          ],
        );
      },
    );
  }

  // 更新分类
  Future<void> _updateCategory(int id, String name, String description) async {
    try {
      final category = Category(
        id: id,
        name: name,
        description: description.isEmpty ? null : description,
        createdAt: '', // 保持原有创建时间
      );
      
      await NoteDatabase.updateCategory(category);
      await _loadCategories();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分类更新成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('更新分类时出错: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新分类失败，请稍后重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 显示删除分类确认对话框
  void _showDeleteCategoryDialog(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('删除分类'),
          content: Text('确定要删除分类"${category['name']}"吗？\n\n该分类下的所有笔记将移至"未分类"。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteCategory(category['id']);
              },
              child: Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // 删除分类
  Future<void> _deleteCategory(int id) async {
    try {
      await NoteDatabase.deleteCategory(id);
      await _loadCategories();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分类删除成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('删除分类时出错: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除分类失败，请稍后重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 导航到编辑器页面
  Future<void> _navigateToEditor({Note? note}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(
          note: note,
        ),
      ),
    );
    
    if (result == true) {
      // 如果保存成功，刷新分类列表
      _loadCategories();
    }
  }

  String _formatDateTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
  }

  // 构建扩展悬浮按钮菜单
  Widget _buildFloatingActionButton() {
    return Stack(
      children: [
        // 背景遮罩
        if (_fabExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleFab,
              child: Container(
                color: Colors.black26,
              ),
            ),
          ),
        
        // 悬浮按钮菜单
        Positioned(
          bottom: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 创建分类按钮
              AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _expandAnimation.value,
                    child: Opacity(
                      opacity: _expandAnimation.value,
                      child: Container(
                        margin: EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '创建分类',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            FloatingActionButton(
                              heroTag: "fab_category",
                              mini: true,
                              backgroundColor: Colors.orange,
                              onPressed: () {
                                _toggleFab();
                                _showAddCategoryDialog();
                              },
                              child: Icon(Icons.create_new_folder, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // 创建笔记按钮
              AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _expandAnimation.value,
                    child: Opacity(
                      opacity: _expandAnimation.value,
                      child: Container(
                        margin: EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '创建笔记',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            FloatingActionButton(
                              heroTag: "fab_note",
                              mini: true,
                              backgroundColor: Colors.blue,
                              onPressed: () {
                                _toggleFab();
                                _navigateToEditor();
                              },
                              child: Icon(Icons.note_add, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // 主悬浮按钮
              FloatingActionButton(
                heroTag: "fab_main",
                onPressed: _toggleFab,
                backgroundColor: Colors.deepPurple,
                child: AnimatedBuilder(
                  animation: _expandAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _expandAnimation.value * 0.785398, // 45度 in radians
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('我的笔记'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddCategoryDialog,
            tooltip: '添加分类',
          ),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : _categoriesWithCount.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_outlined, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    '没有分类',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '点击悬浮按钮创建您的第一个分类',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _categoriesWithCount.length,
              padding: EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final category = _categoriesWithCount[index];
                final noteCount = category['noteCount'] ?? 0;
                
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () async {
                      // 导航到分类下的笔记页面
                      Category? categoryObj = null;
                      if (category['id'] != null) {
                        categoryObj = await NoteDatabase.getCategoryById(category['id']);
                      }
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryNotesPage(
                            category: categoryObj,
                          ),
                        ),
                      );
                    },
                    onLongPress: () => _showCategoryOptions(category),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: category['id'] == null 
                                ? Colors.grey[400] 
                                : Colors.deepPurple[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              category['id'] == null 
                                ? Icons.folder_open 
                                : Icons.folder,
                              color: category['id'] == null 
                                ? Colors.grey[600] 
                                : Colors.deepPurple[700],
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category['name'] ?? '未命名',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (category['description'] != null && category['description'].isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      category['description'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$noteCount 个笔记',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    if (category['createdAt'] != null)
                                      Text(
                                        '创建于: ${_formatDateTime(category['createdAt'])}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
}