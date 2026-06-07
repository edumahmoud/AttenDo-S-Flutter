import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';

class AiService {
  final ApiService _apiService;

  AiService(this._apiService);

  // =========================================================================
  // Summary Generation
  // =========================================================================

  /// Generate an AI summary for the given content and source type.
  Future<Map<String, dynamic>> generateSummary({
    required String content,
    required String sourceType,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/gemini/summary',
        data: {
          'content': content,
          'source_type': sourceType,
        },
      );
      return response.data!;
    } catch (e) {
      rethrow;
    }
  }

  // =========================================================================
  // Quiz Generation
  // =========================================================================

  /// Generate a quiz based on a summary ID and an optional config map.
  Future<Map<String, dynamic>> generateQuiz({
    required String summaryId,
    Map<String, dynamic>? config,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/gemini/quiz',
        data: {
          'summary_id': summaryId,
          'config': config,
        },
      );
      return response.data!;
    } catch (e) {
      rethrow;
    }
  }

  // =========================================================================
  // Answer Evaluation
  // =========================================================================

  /// Evaluate a student's answer to a question.
  Future<Map<String, dynamic>> evaluateAnswer({
    required String question,
    required String answer,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/gemini/evaluate',
        data: {
          'question': question,
          'answer': answer,
        },
      );
      return response.data!;
    } catch (e) {
      rethrow;
    }
  }

  // =========================================================================
  // Concept Explanation
  // =========================================================================

  /// Ask the AI to explain a concept.
  Future<Map<String, dynamic>> explainConcept({
    required String question,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/gemini/explain',
        data: {'question': question},
      );
      return response.data!;
    } catch (e) {
      rethrow;
    }
  }

  // =========================================================================
  // Health Check
  // =========================================================================

  /// Check whether the Gemini/AI backend is healthy.
  Future<bool> checkHealth() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/api/gemini/health',
      );
      return response.data?['status'] == 'ok';
    } catch (e) {
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod Providers
// ---------------------------------------------------------------------------

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(ref.watch(apiServiceProvider));
});
