enum QuizQuestionType { mcq, boolean_, completion, matching }

class MatchingPair {
  final String key;
  final String value;

  const MatchingPair({
    required this.key,
    required this.value,
  });

  factory MatchingPair.fromJson(Map<String, dynamic> json) {
    return MatchingPair(
      key: json['key'] as String,
      value: json['value'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
    };
  }

  MatchingPair copyWith({
    String? key,
    String? value,
  }) {
    return MatchingPair(
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }
}

class QuizQuestion {
  final String id;
  final String quizId;
  final String question;
  final QuizQuestionType type;
  final List<String>? options;
  final String? correctAnswer;
  final List<MatchingPair>? pairs;
  final int? points;
  final int? orderIndex;

  const QuizQuestion({
    required this.id,
    required this.quizId,
    required this.question,
    required this.type,
    this.options,
    this.correctAnswer,
    this.pairs,
    this.points,
    this.orderIndex,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      quizId: json['quizId'] as String,
      question: json['question'] as String,
      type: _typeFromString(json['type'] as String),
      options: json['options'] != null
          ? List<String>.from(json['options'] as List)
          : null,
      correctAnswer: json['correctAnswer'] as String?,
      pairs: json['pairs'] != null
          ? (json['pairs'] as List)
              .map((e) => MatchingPair.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      points: json['points'] as int?,
      orderIndex: json['orderIndex'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizId': quizId,
      'question': question,
      'type': _typeToString(type),
      'options': options,
      'correctAnswer': correctAnswer,
      'pairs': pairs?.map((e) => e.toJson()).toList(),
      'points': points,
      'orderIndex': orderIndex,
    };
  }

  QuizQuestion copyWith({
    String? id,
    String? quizId,
    String? question,
    QuizQuestionType? type,
    List<String>? options,
    String? correctAnswer,
    List<MatchingPair>? pairs,
    int? points,
    int? orderIndex,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      question: question ?? this.question,
      type: type ?? this.type,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      pairs: pairs ?? this.pairs,
      points: points ?? this.points,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  static QuizQuestionType _typeFromString(String value) {
    switch (value) {
      case 'mcq':
        return QuizQuestionType.mcq;
      case 'boolean':
        return QuizQuestionType.boolean_;
      case 'completion':
        return QuizQuestionType.completion;
      case 'matching':
        return QuizQuestionType.matching;
      default:
        return QuizQuestionType.mcq;
    }
  }

  static String _typeToString(QuizQuestionType type) {
    switch (type) {
      case QuizQuestionType.mcq:
        return 'mcq';
      case QuizQuestionType.boolean_:
        return 'boolean';
      case QuizQuestionType.completion:
        return 'completion';
      case QuizQuestionType.matching:
        return 'matching';
    }
  }
}

class UserAnswer {
  final String id;
  final String userId;
  final String quizId;
  final String questionId;
  final String? answer;
  final List<MatchingPair>? matchingAnswer;
  final bool? isCorrect;
  final DateTime createdAt;

  const UserAnswer({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.questionId,
    this.answer,
    this.matchingAnswer,
    this.isCorrect,
    required this.createdAt,
  });

  factory UserAnswer.fromJson(Map<String, dynamic> json) {
    return UserAnswer(
      id: json['id'] as String,
      userId: json['userId'] as String,
      quizId: json['quizId'] as String,
      questionId: json['questionId'] as String,
      answer: json['answer'] as String?,
      matchingAnswer: json['matchingAnswer'] != null
          ? (json['matchingAnswer'] as List)
              .map((e) => MatchingPair.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      isCorrect: json['isCorrect'] as bool?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'quizId': quizId,
      'questionId': questionId,
      'answer': answer,
      'matchingAnswer': matchingAnswer?.map((e) => e.toJson()).toList(),
      'isCorrect': isCorrect,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserAnswer copyWith({
    String? id,
    String? userId,
    String? quizId,
    String? questionId,
    String? answer,
    List<MatchingPair>? matchingAnswer,
    bool? isCorrect,
    DateTime? createdAt,
  }) {
    return UserAnswer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      quizId: quizId ?? this.quizId,
      questionId: questionId ?? this.questionId,
      answer: answer ?? this.answer,
      matchingAnswer: matchingAnswer ?? this.matchingAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Score {
  final String id;
  final String userId;
  final String quizId;
  final double score;
  final double maxScore;
  final double percentage;
  final DateTime createdAt;

  const Score({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.createdAt,
  });

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      id: json['id'] as String,
      userId: json['userId'] as String,
      quizId: json['quizId'] as String,
      score: (json['score'] as num).toDouble(),
      maxScore: (json['maxScore'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'quizId': quizId,
      'score': score,
      'maxScore': maxScore,
      'percentage': percentage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Score copyWith({
    String? id,
    String? userId,
    String? quizId,
    double? score,
    double? maxScore,
    double? percentage,
    DateTime? createdAt,
  }) {
    return Score(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      quizId: quizId ?? this.quizId,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      percentage: percentage ?? this.percentage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Quiz {
  final String id;
  final String subjectId;
  final String title;
  final String? description;
  final String? lectureId;
  final String createdBy;
  final int? timeLimitMinutes;
  final bool? isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<QuizQuestion>? questions;
  final List<Score>? scores;

  const Quiz({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    this.lectureId,
    required this.createdBy,
    this.timeLimitMinutes,
    this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    this.questions,
    this.scores,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      lectureId: json['lectureId'] as String?,
      createdBy: json['createdBy'] as String,
      timeLimitMinutes: json['timeLimitMinutes'] as int?,
      isPublished: json['isPublished'] as bool?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      questions: json['questions'] != null
          ? (json['questions'] as List)
              .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      scores: json['scores'] != null
          ? (json['scores'] as List)
              .map((e) => Score.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'title': title,
      'description': description,
      'lectureId': lectureId,
      'createdBy': createdBy,
      'timeLimitMinutes': timeLimitMinutes,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'questions': questions?.map((e) => e.toJson()).toList(),
      'scores': scores?.map((e) => e.toJson()).toList(),
    };
  }

  Quiz copyWith({
    String? id,
    String? subjectId,
    String? title,
    String? description,
    String? lectureId,
    String? createdBy,
    int? timeLimitMinutes,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<QuizQuestion>? questions,
    List<Score>? scores,
  }) {
    return Quiz(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      lectureId: lectureId ?? this.lectureId,
      createdBy: createdBy ?? this.createdBy,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      questions: questions ?? this.questions,
      scores: scores ?? this.scores,
    );
  }
}
