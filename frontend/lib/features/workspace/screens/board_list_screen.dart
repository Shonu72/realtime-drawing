import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtime_drawing/features/board/models/board_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../board/screens/board_screen.dart';
import '../services/board_service.dart';
import 'package:realtime_drawing/core/utils/helpers.dart';
import 'create_board_screen.dart';

class BoardListScreen extends StatefulWidget {
  const BoardListScreen({super.key});

  @override
  State<BoardListScreen> createState() => _BoardListScreenState();
}

class _BoardListScreenState extends State<BoardListScreen> {
  final BoardService _boardService = BoardService();
  List<Board> _boards = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadBoards();
  }
  
  Future<void> _loadBoards() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final boards = await _boardService.getBoards();
      setState(() {
        _boards = boards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _handleDeleteBoard(String boardId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Board'),
        content: const Text('Are you sure you want to delete this board?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _boardService.deleteBoard(boardId);
        _loadBoards();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Board deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete board: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Boards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBoards,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBoards,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _boards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No boards yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first board to get started',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBoards,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _boards.length,
                        itemBuilder: (context, index) {
                          final board = _boards[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                child: const Icon(Icons.edit, color: Colors.white),
                              ),
                              title: Text(board.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (board.description != null)
                                    Text(board.description!),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Updated ${Helpers.formatDateTime(board.updatedAt)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  if (board.isOwner(authProvider.user?.id ?? ''))
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                ],
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _handleDeleteBoard(board.id);
                                  }
                                },
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BoardScreen(
                                      boardId: board.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateBoardScreen(),
            ),
          );
          if (result == true) {
            _loadBoards();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Board'),
      ),
    );
  }
}

