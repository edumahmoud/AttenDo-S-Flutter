import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';

// ─── Tracking State ───

enum RiskLevel { low, medium, high, critical }
enum GrowthTrend { improving, stable, declining }

class SubjectPerformance {
  final String subjectId;
  final String subjectName;
  final double averageScore;
  final double attendanceRate;
  final int quizzesTaken;
  final int assignmentsCompleted;
  final int totalAssignments;
  final String? performanceLevel;

  const SubjectPerformance({
    required this.subjectId,
    required this.subjectName,
    this.averageScore = 0,
    this.attendanceRate = 0,
    this.quizzesTaken = 0,
    this.assignmentsCompleted = 0,
    this.totalAssignments = 0,
    this.performanceLevel,
  });
}

class TrackingState {
  final List<StudentPerformance> performanceData;
  final double overallScore;
  final double overallAttendanceRate;
  final double overallAssignmentRate;
  final RiskLevel riskLevel;
  final GrowthTrend growthTrend;
  final double disciplineScore;
  final List<SubjectPerformance> subjectWisePerformance;
  final bool isLoading;
  final String? error;

  const TrackingState({
    this.performanceData = const [],
    this.overallScore = 0,
    this.overallAttendanceRate = 0,
    this.overallAssignmentRate = 0,
    this.riskLevel = RiskLevel.low,
    this.growthTrend = GrowthTrend.stable,
    this.disciplineScore = 100,
    this.subjectWisePerformance = const [],
    this.isLoading = false,
    this.error,
  });

  TrackingState copyWith({
    List<StudentPerformance>? performanceData,
    double? overallScore,
    double? overallAttendanceRate,
    double? overallAssignmentRate,
    RiskLevel? riskLevel,
    GrowthTrend? growthTrend,
    double? disciplineScore,
    List<SubjectPerformance>? subjectWisePerformance,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TrackingState(
      performanceData: performanceData ?? this.performanceData,
      overallScore: overallScore ?? this.overallScore,
      overallAttendanceRate: overallAttendanceRate ?? this.overallAttendanceRate,
      overallAssignmentRate:
          overallAssignmentRate ?? this.overallAssignmentRate,
      riskLevel: riskLevel ?? this.riskLevel,
      growthTrend: growthTrend ?? this.growthTrend,
      disciplineScore: disciplineScore ?? this.disciplineScore,
      subjectWisePerformance:
          subjectWisePerformance ?? this.subjectWisePerformance,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Tracking Controller ───

class TrackingController extends StateNotifier<TrackingState> {
  final SupabaseService _supabaseService;

  TrackingController(this._supabaseService)
      : super(const TrackingState()) {
    fetchPerformanceData();
  }

  Future<void> fetchPerformanceData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final data = await _supabaseService.client
          .from('student_performances')
          .select()
          .eq('student_id', userId);

      final performances = (data as List<dynamic>)
          .map((json) =>
              StudentPerformance.fromJson(json as Map<String, dynamic>))
          .toList();

      // Compute derived metrics
      final overallScore = computeOverallScore(performances);
      final overallAttendanceRate = computeOverallAttendance(performances);
      final overallAssignmentRate = computeOverallAssignmentRate(performances);
      final riskLevel = computeRiskLevel(overallScore, overallAttendanceRate);
      final growthTrend = computeGrowthTrend(performances);
      final disciplineScore = computeDisciplineScore(performances);
      final subjectWise = getSubjectWisePerformance(performances);

      state = state.copyWith(
        performanceData: performances,
        overallScore: overallScore,
        overallAttendanceRate: overallAttendanceRate,
        overallAssignmentRate: overallAssignmentRate,
        riskLevel: riskLevel,
        growthTrend: growthTrend,
        disciplineScore: disciplineScore,
        subjectWisePerformance: subjectWise,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  double computeOverallScore(List<StudentPerformance> data) {
    if (data.isEmpty) return 0;
    final scores = data
        .where((p) => p.averageScore != null)
        .map((p) => p.averageScore!)
        .toList();
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  double computeOverallAttendance(List<StudentPerformance> data) {
    if (data.isEmpty) return 0;
    final rates = data
        .where((p) => p.attendanceRate != null)
        .map((p) => p.attendanceRate!)
        .toList();
    if (rates.isEmpty) return 0;
    return rates.reduce((a, b) => a + b) / rates.length;
  }

  double computeOverallAssignmentRate(List<StudentPerformance> data) {
    int totalCompleted = 0;
    int totalAssignments = 0;
    for (final p in data) {
      totalCompleted += p.assignmentsCompleted ?? 0;
      totalAssignments += p.totalAssignments ?? 0;
    }
    if (totalAssignments == 0) return 0;
    return (totalCompleted / totalAssignments) * 100;
  }

  RiskLevel computeRiskLevel(double score, double attendanceRate) {
    // Composite risk: low scores + low attendance = high risk
    final composite = (score * 0.6) + (attendanceRate * 0.4);
    if (composite < 40) return RiskLevel.critical;
    if (composite < 55) return RiskLevel.high;
    if (composite < 70) return RiskLevel.medium;
    return RiskLevel.low;
  }

  GrowthTrend computeGrowthTrend(List<StudentPerformance> data) {
    // Compare recent performance to older records
    if (data.length < 2) return GrowthTrend.stable;

    // Sort by lastCalculated
    final sorted = List<StudentPerformance>.from(data)
      ..sort((a, b) =>
          (a.lastCalculated ?? a.createdAt)
              .compareTo(b.lastCalculated ?? b.createdAt));

    final midPoint = sorted.length ~/ 2;
    final olderHalf = sorted.sublist(0, midPoint);
    final newerHalf = sorted.sublist(midPoint);

    double olderAvg = _avgScore(olderHalf);
    double newerAvg = _avgScore(newerHalf);

    final diff = newerAvg - olderAvg;
    if (diff > 5) return GrowthTrend.improving;
    if (diff < -5) return GrowthTrend.declining;
    return GrowthTrend.stable;
  }

  double _avgScore(List<StudentPerformance> list) {
    final scores = list
        .where((p) => p.averageScore != null)
        .map((p) => p.averageScore!)
        .toList();
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  double computeDisciplineScore(List<StudentPerformance> data) {
    // Based on attendance and assignment completion
    if (data.isEmpty) return 100;
    final attendance = computeOverallAttendance(data);
    final assignmentRate = computeOverallAssignmentRate(data);
    return (attendance * 0.5) + (assignmentRate * 0.5);
  }

  List<SubjectPerformance> getSubjectWisePerformance(
    List<StudentPerformance> data,
  ) {
    return data
        .map((p) => SubjectPerformance(
              subjectId: p.subjectId,
              subjectName: p.subjectId, // Will be enriched with subject names
              averageScore: p.averageScore ?? 0,
              attendanceRate: p.attendanceRate ?? 0,
              quizzesTaken: p.quizzesTaken ?? 0,
              assignmentsCompleted: p.assignmentsCompleted ?? 0,
              totalAssignments: p.totalAssignments ?? 0,
              performanceLevel: p.performanceLevel,
            ))
        .toList();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Network error. Please check your connection.';
    }
    return 'Failed to load performance data. Please try again.';
  }
}

// ─── Provider ───

final trackingControllerProvider =
    StateNotifierProvider<TrackingController, TrackingState>((ref) {
  return TrackingController(ref.watch(supabaseServiceProvider));
});
