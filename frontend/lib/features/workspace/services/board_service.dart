import 'package:realtime_drawing/features/board/models/board_model.dart';

import '../../../services/api_service.dart';

class BoardService {
  final ApiService _apiService = ApiService();
  
  Future<List<Board>> getBoards() async {
    try {
      final response = await _apiService.getBoards();
      final boardsData = response.data['boards'] as List<dynamic>;
      return boardsData
          .map((b) => Board.fromJson(b as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch boards: $e');
    }
  }
  
  Future<Board> getBoard(String boardId) async {
    try {
      final response = await _apiService.getBoard(boardId);
      return Board.fromJson(response.data['board'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch board: $e');
    }
  }
  
  Future<Board> createBoard({
    required String name,
    String? description,
    bool isPublic = false,
    BoardSettings? settings,
  }) async {
    try {
      final response = await _apiService.createBoard(
        name: name,
        description: description,
        isPublic: isPublic,
        settings: settings?.toJson(),
      );
      return Board.fromJson(response.data['board'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create board: $e');
    }
  }
  
  Future<void> deleteBoard(String boardId) async {
    try {
      await _apiService.deleteBoard(boardId);
    } catch (e) {
      throw Exception('Failed to delete board: $e');
    }
  }
  
  Future<void> updateBoardSettings(
    String boardId,
    BoardSettings settings,
  ) async {
    try {
      await _apiService.updateBoardSettings(boardId, settings.toJson());
    } catch (e) {
      throw Exception('Failed to update board settings: $e');
    }
  }
  
  Future<void> addMember(
    String boardId,
    String userId,
    BoardRole role,
  ) async {
    try {
      await _apiService.addBoardMember(
        boardId,
        userId,
        role.name,
      );
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }
  
  Future<void> removeMember(String boardId, String userId) async {
    try {
      await _apiService.removeBoardMember(boardId, userId);
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }
}

